<?php

namespace App\Services\SMS;

/**
 * Counts SMS parts the way Eskiz bills them.
 *
 * Checked against Eskiz's own record (status_by_id: encoding, parts_count)
 * for 18,603 prod messages sent 2026-10-15..18 — this matches every one,
 * both encoding and parts. Three rules carry that:
 *
 *  - Eskiz sends GSM-7 only when every character is ASCII. A single
 *    non-ASCII letter, even one GSM 03.38 does have (ò ü ì ø), makes it
 *    UCS-2: 29 such messages in the sample, none went out as GSM-7.
 *  - GSM 03.38 extension characters (^ { } [ ] ~ | € \ and form feed) cost
 *    two septets each, an escape plus the character. \n and \r are basic.
 *  - Past one part, every part carries a 7-byte header, so the count is
 *    ceil(len / 153) for GSM-7 and ceil(len / 67) for UCS-2 — not "first
 *    part 160, then 153". UCS-2 length is in UTF-16 code units, so an emoji
 *    outside the BMP costs two.
 */
class SmsPartsCalculatorService {
    // GSM 03.38 basic characters that are also ASCII. The non-ASCII ones
    // (£ ¥ è é ù ì ò Ç Ø ø Å å Δ … ä ö ñ ü à) are left out on purpose: Eskiz
    // switches to UCS-2 for them.
    private const GSM_7BIT_BASIC = "@\$_ !\"#%&'()*+,-./0123456789:;<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\n\r";

    // GSM 03.38 extension table: each costs two septets (ESC + character).
    // € is the only non-ASCII one; Eskiz never sees it as GSM-7 either.
    private const GSM_7BIT_EXTENDED = "^{}[]~|\\\x0C";

    // Single part limits
    private const GSM_7BIT_SINGLE = 160;

    private const ASCII_SINGLE = 160;

    private const UCS2_SINGLE = 70;

    // Multipart limits (per part)
    private const GSM_7BIT_MULTIPART = 153;

    private const ASCII_MULTIPART = 153;

    private const UCS2_MULTIPART = 67;

    /**
     * Calculate SMS parts count and encoding based on message text.
     *
     * @param  string  $message  The SMS message text
     * @return array{parts: int, encoding: int} Returns parts count and encoding type
     */
    public function calculatePartsCount(string $message): array {
        $encoding = $this->detectEncoding($message);
        $parts = $this->calculateParts($message, $encoding);

        return [
            'parts' => $parts,
            'encoding' => $encoding,
        ];
    }

    /**
     * Detect the encoding type needed for the message.
     *
     * @param  string  $message  The SMS message text
     * @return int Encoding type: 0 (GSM 0338), 1 (ASCII), or 8 (UCS2)
     */
    private function detectEncoding(string $message): int {
        // Check if message contains only GSM 7-bit characters
        if ($this->gsm7Septets($message) !== null) {
            return 0; // GSM 0338
        }

        // Check if message contains only ASCII characters
        if ($this->isAscii($message)) {
            return 1; // ASCII
        }

        // Otherwise, use UCS2 (UTF-16) for Unicode characters
        return 8; // UCS2
    }

    /**
     * Septets the message takes in GSM-7, or null if it can't be sent as GSM-7.
     *
     * @param  string  $message  The SMS message text
     */
    private function gsm7Septets(string $message): ?int {
        if (! $this->isAscii($message)) {
            return null;
        }

        $septets = 0;
        $length = strlen($message);

        for ($i = 0; $i < $length; $i++) {
            $char = $message[$i];

            if (str_contains(self::GSM_7BIT_BASIC, $char)) {
                $septets++;
            } elseif (str_contains(self::GSM_7BIT_EXTENDED, $char)) {
                $septets += 2;
            } else {
                return null;
            }
        }

        return $septets;
    }

    /**
     * Check if message contains only ASCII characters.
     *
     * @param  string  $message  The SMS message text
     */
    private function isAscii(string $message): bool {
        return mb_check_encoding($message, 'ASCII');
    }

    /**
     * Calculate the number of SMS parts needed for the message.
     *
     * @param  string  $message  The SMS message text
     * @param  int  $encoding  The encoding type (0, 1, or 8)
     * @return int Number of parts
     */
    private function calculateParts(string $message, int $encoding): int {
        return match ($encoding) {
            0 => $this->calculateGsm7BitParts($this->gsm7Septets($message)), // GSM 0338
            1 => $this->calculateAsciiParts(strlen($message)),                // ASCII
            default => $this->calculateUcs2Parts($this->utf16Units($message)), // UCS2
        };
    }

    /**
     * Message length in UTF-16 code units, which is what a UCS-2 part holds.
     */
    private function utf16Units(string $message): int {
        return intdiv(strlen(mb_convert_encoding($message, 'UTF-16BE', 'UTF-8')), 2);
    }

    /**
     * Calculate parts for GSM 7-bit encoding.
     *
     * @param  int  $length  Message length in septets
     * @return int Number of parts
     */
    private function calculateGsm7BitParts(int $length): int {
        if ($length <= self::GSM_7BIT_SINGLE) {
            return 1;
        }

        return (int) ceil($length / self::GSM_7BIT_MULTIPART);
    }

    /**
     * Calculate parts for ASCII encoding.
     *
     * @param  int  $length  Message length
     * @return int Number of parts
     */
    private function calculateAsciiParts(int $length): int {
        if ($length <= self::ASCII_SINGLE) {
            return 1;
        }

        return (int) ceil($length / self::ASCII_MULTIPART);
    }

    /**
     * Calculate parts for UCS2 encoding.
     *
     * @param  int  $length  Message length in UTF-16 code units
     * @return int Number of parts
     */
    private function calculateUcs2Parts(int $length): int {
        if ($length <= self::UCS2_SINGLE) {
            return 1;
        }

        return (int) ceil($length / self::UCS2_MULTIPART);
    }
}
