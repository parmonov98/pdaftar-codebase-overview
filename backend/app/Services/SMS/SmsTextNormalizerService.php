<?php

namespace App\Services\SMS;

/**
 * Fold an SMS body onto the GSM 03.38 alphabet wherever it can be done
 * without changing what the recipient reads.
 *
 * A *single* character outside GSM 03.38 flips the whole message to UCS-2,
 * where the segment limit drops from 160 characters to 70 (67 once
 * concatenated). The same 156-character Latin body therefore costs 1 SMS
 * written with a plain `'` and 3 written with a typographic `’` — identical
 * text on the handset, triple the charge. See SmsPartsCalculatorService.
 *
 * Two sources feed non-GSM characters into otherwise-Latin bodies:
 *
 *   - **Apostrophes.** `ʻ` (U+02BB, the correct Uzbek oʻ/gʻ letter) and
 *     `’`/`‘` (iOS smart punctuation substitutes `'` as you type) reach us
 *     through shop names, client names and hand-edited templates. Measured
 *     on prod 2026-08-09..14: 2 731 of 36 057 charged parts (7.6%) existed
 *     only because of these, and 704 multi-part messages in a 5 000-row
 *     sample would have been a single SMS without them.
 *
 *   - **Invisibles.** One shop pasted a template whose `{{placeholders}}`
 *     were wrapped in U+2060 WORD JOINER — invisible on screen, fatal to
 *     the encoding. Every send off that template cost 4 parts instead of 2
 *     for two and a half weeks, until the template was re-saved. Word/Docs paste also
 *     brings NBSP and zero-width marks.
 *
 * Cyrillic bodies are deliberately left alone: they are UCS-2 by nature and
 * nothing here can help them. Emoji are left alone for the same reason —
 * and U+200C/U+200D are NOT stripped, because they join emoji sequences
 * (👨‍⚕️) and carry meaning in Arabic/Persian names, both of which occur in
 * real `clients.name` rows.
 */
class SmsTextNormalizerService {
    /**
     * Characters that render as an apostrophe but sit outside GSM 03.38.
     *
     * U+02BB/U+02BC are the typographically correct Uzbek letters; they are
     * replaced only in the SMS channel, never in stored shop or client data.
     */
    private const APOSTROPHES = [
        "\u{02B9}", // ʹ modifier prime
        "\u{02BB}", // ʻ modifier turned comma — Uzbek oʻ/gʻ
        "\u{02BC}", // ʼ modifier apostrophe
        "\u{02BD}", // ʽ modifier reversed comma
        "\u{0060}", // ` grave accent
        "\u{00B4}", // ´ acute accent
        "\u{2018}", // ‘ left single quote
        "\u{2019}", // ’ right single quote — iOS smart punctuation
        "\u{201A}", // ‚ single low-9 quote
        "\u{201B}", // ‛ single high-reversed-9 quote
        "\u{2032}", // ′ prime
    ];

    /** Characters that render as a double quote but sit outside GSM 03.38. */
    private const QUOTES = [
        "\u{201C}", // “
        "\u{201D}", // ”
        "\u{201E}", // „
        "\u{201F}", // ‟
        "\u{2033}", // ″ double prime
    ];

    /** Dash-like characters outside GSM 03.38. */
    private const DASHES = [
        "\u{2010}", // ‐ hyphen
        "\u{2011}", // ‑ non-breaking hyphen
        "\u{2012}", // ‒ figure dash
        "\u{2013}", // – en dash
        "\u{2014}", // — em dash
        "\u{2015}", // ― horizontal bar
        "\u{2212}", // − minus sign
    ];

    /** Space-like characters outside GSM 03.38. */
    private const SPACES = [
        "\u{00A0}", // no-break space — found in a stored phone number
        "\u{1680}", "\u{2000}", "\u{2001}", "\u{2002}", "\u{2003}",
        "\u{2004}", "\u{2005}", "\u{2006}", "\u{2007}", "\u{2008}",
        "\u{2009}", "\u{200A}", "\u{202F}", "\u{205F}", "\u{3000}",
    ];

    /**
     * Zero-width and bidi formatting marks, dropped outright.
     *
     * U+200C ZWNJ and U+200D ZWJ are excluded on purpose — see the class
     * docblock. Removing them would mangle emoji and Arabic names for no
     * encoding gain, since those are UCS-2 regardless.
     */
    private const INVISIBLES = [
        "\u{00AD}", // soft hyphen
        "\u{061C}", // Arabic letter mark
        "\u{180E}", // Mongolian vowel separator
        "\u{200B}", // zero-width space
        "\u{200E}", // left-to-right mark
        "\u{200F}", // right-to-left mark
        "\u{2060}", // word joiner — the pasted-template incident
        "\u{2061}", "\u{2062}", "\u{2063}", "\u{2064}",
        "\u{FEFF}", // zero-width no-break space / BOM
    ];

    /**
     * Normalize an SMS body for transmission.
     *
     * Idempotent, and a no-op for text that is already pure GSM 03.38 or
     * genuinely needs UCS-2 (Cyrillic, emoji).
     */
    public static function normalize(?string $text): string {
        if ($text === null || $text === '') {
            return (string) $text;
        }

        $replacements = array_merge(
            array_fill_keys(self::APOSTROPHES, "'"),
            array_fill_keys(self::QUOTES, '"'),
            array_fill_keys(self::DASHES, '-'),
            array_fill_keys(self::SPACES, ' '),
            array_fill_keys(self::INVISIBLES, ''),
            ["\u{2026}" => '...'], // … horizontal ellipsis
        );

        // Line separators become the plain newline GSM 03.38 already carries.
        $replacements["\u{2028}"] = "\n";
        $replacements["\u{2029}"] = "\n";

        return strtr($text, $replacements);
    }

    /**
     * Whether normalization would change the text — used by the audit
     * command to report scope without rewriting anything.
     */
    public static function wouldChange(?string $text): bool {
        return self::normalize($text) !== (string) $text;
    }

    /**
     * Substitute `{{key}}` / `{key}` placeholders, normalizing each value on
     * the way in.
     *
     * **Every SMS render path must use this instead of its own foreach.**
     * The substitution loop had been copy-pasted into 19 files, and the
     * first attempt at this fix (PR #1646) only normalized the two values
     * that happened to flow through SmsPlaceholderService::nameForSms() —
     * so a client name containing `‘` still went out at 3 parts minutes
     * after that deploy, because ProcessDebtBalanceAndSms builds its own
     * variable array.
     *
     * Values are normalized; the template body is NOT. That asymmetry is
     * deliberate and load-bearing: values land in Eskiz's `%w` wildcard
     * slots, so folding them cannot break an approved template's match,
     * whereas rewriting the body would and would need re-moderation. It
     * costs almost nothing — 18 messages / 27 parts over a 5-day prod
     * window stay UCS-2 because their shop's template carries an
     * apostrophe in its own static text.
     *
     * Telegram render paths deliberately do NOT use this: Telegram has no
     * GSM constraint, so folding `ʻ` to `'` there would degrade Uzbek
     * typography for no gain.
     *
     * @param  array<string, mixed>  $variables
     */
    public static function substitute(string $text, array $variables): string {
        foreach ($variables as $key => $value) {
            $value = self::normalize((string) $value);

            $text = str_replace('{{'.$key.'}}', $value, $text);
            $text = str_replace('{'.$key.'}', $value, $text);
        }

        return $text;
    }
}
