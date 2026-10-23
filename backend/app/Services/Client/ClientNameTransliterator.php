<?php

namespace App\Services\Client;

/**
 * Uzbek Cyrillic → Latin for client names (Trello #512).
 *
 * The apostrophe in o' / g' and the tutuq belgisi is ASCII `'`, not `ʻ`/`’`:
 * client names go into SMS bodies, and one non-GSM-7 character halves the
 * per-part limit for the whole message.
 */
class ClientNameTransliterator {
    /** @var array<string, string> lower-case source letter => lower-case Latin */
    private const MAP = [
        'а' => 'a', 'б' => 'b', 'в' => 'v', 'г' => 'g', 'д' => 'd',
        'ё' => 'yo', 'ж' => 'j', 'з' => 'z', 'и' => 'i', 'й' => 'y',
        'к' => 'k', 'л' => 'l', 'м' => 'm', 'н' => 'n', 'о' => 'o',
        'п' => 'p', 'р' => 'r', 'с' => 's', 'т' => 't', 'у' => 'u',
        'ф' => 'f', 'х' => 'x', 'ч' => 'ch', 'ш' => 'sh', 'щ' => 'sh',
        'ъ' => "'", 'ы' => 'i', 'ь' => '', 'э' => 'e', 'ю' => 'yu',
        'я' => 'ya', 'ў' => "o'", 'қ' => 'q', 'ғ' => "g'", 'ҳ' => 'h',
        // 'е' and 'ц' depend on their position — see letter().
    ];

    private const VOWELS = 'аеёиоуўэюяыaeiou';

    public static function hasCyrillic(string $text): bool {
        return preg_match('/\p{Cyrillic}/u', $text) === 1;
    }

    /**
     * The Latin form of [name]. A name typed all in lower case comes back
     * with each word capitalised ("алишер валиев" → "Alisher Valiev");
     * otherwise the original casing is kept.
     */
    public function toLatin(string $name): string {
        $chars = mb_str_split($name);
        $out = '';
        foreach ($chars as $i => $char) {
            $out .= $this->letter($chars, $i);
        }

        if (mb_strtolower($name) === $name) {
            $out = $this->capitaliseWords($out);
        }

        return $out;
    }

    /** @param list<string> $chars */
    private function letter(array $chars, int $i): string {
        $char = $chars[$i];
        $lower = mb_strtolower($char);
        $prev = $i > 0 ? mb_strtolower($chars[$i - 1]) : '';
        $wordStart = $prev === '' || ! preg_match('/\p{L}/u', $prev);

        $latin = match ($lower) {
            // Ye at the start of a word and after a vowel or a sign: Ергаш →
            // Yergash, Оев → Oyev; e elsewhere: Беков → Bekov.
            'е' => $wordStart || str_contains(self::VOWELS, $prev) || $prev === 'ъ' || $prev === 'ь' ? 'ye' : 'e',
            // S at the start of a word, ts inside it: Цех → Sex, Лицей → Litsey.
            'ц' => $wordStart ? 's' : 'ts',
            default => self::MAP[$lower] ?? null,
        };

        if ($latin === null) {
            return $char;
        }
        if ($lower === $char || $latin === '') {
            return $latin;
        }

        // Upper-case source: a fully capitalised word keeps every letter
        // capital (ШОХ → SHOX); otherwise only the first (Шох → Shox).
        $next = $chars[$i + 1] ?? '';
        $wordIsCaps = ($next !== '' && preg_match('/\p{Lu}/u', $next))
            || (! $wordStart && preg_match('/\p{Lu}/u', $chars[$i - 1]));

        return $wordIsCaps ? mb_strtoupper($latin) : mb_strtoupper(mb_substr($latin, 0, 1)).mb_substr($latin, 1);
    }

    /** Capitalise the first letter after a start, space, hyphen, dot or bracket. */
    private function capitaliseWords(string $text): string {
        return preg_replace_callback(
            '/(^|[\s\-.(])(\p{Ll})/u',
            fn (array $m) => $m[1].mb_strtoupper($m[2]),
            $text,
        ) ?? $text;
    }
}
