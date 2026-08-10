<?php

namespace App\Services\SMS;

class SmsPartsCalculatorService {
    // GSM 7-bit character set (GSM 0338)
    private const GSM_7BIT_CHARS = '@£$¥èéùìòÇØøÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !"#¤%&\'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà';

    // GSM 7-bit extended characters (require escape sequence)
    private const GSM_7BIT_EXTENDED = "\x0A\x0C\x0D\x1B\x1C\x1D\x1E\x1F";

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
        if ($this->isGsm7Bit($message)) {
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
     * Check if message contains only GSM 7-bit characters.
     *
     * @param  string  $message  The SMS message text
     */
    private function isGsm7Bit(string $message): bool {
        $length = mb_strlen($message, 'UTF-8');

        for ($i = 0; $i < $length; $i++) {
            $char = mb_substr($message, $i, 1, 'UTF-8');
            $charCode = mb_ord($char, 'UTF-8');

            // Check if character is in GSM 7-bit charset
            if (mb_strpos(self::GSM_7BIT_CHARS, $char, 0, 'UTF-8') === false) {
                // Check if it's an extended GSM character
                if (mb_strpos(self::GSM_7BIT_EXTENDED, $char, 0, 'UTF-8') === false) {
                    return false;
                }
            }
        }

        return true;
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
        $length = mb_strlen($message, 'UTF-8');

        return match ($encoding) {
            0 => $this->calculateGsm7BitParts($length), // GSM 0338
            1 => $this->calculateAsciiParts($length),    // ASCII
            8 => $this->calculateUcs2Parts($length),     // UCS2
            default => $this->calculateUcs2Parts($length), // Default to UCS2 for safety
        };
    }

    /**
     * Calculate parts for GSM 7-bit encoding.
     *
     * @param  int  $length  Message length
     * @return int Number of parts
     */
    private function calculateGsm7BitParts(int $length): int {
        if ($length <= self::GSM_7BIT_SINGLE) {
            return 1;
        }

        return (int) ceil(($length - self::GSM_7BIT_SINGLE) / self::GSM_7BIT_MULTIPART) + 1;
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

        return (int) ceil(($length - self::ASCII_SINGLE) / self::ASCII_MULTIPART) + 1;
    }

    /**
     * Calculate parts for UCS2 encoding.
     *
     * @param  int  $length  Message length
     * @return int Number of parts
     */
    private function calculateUcs2Parts(int $length): int {
        if ($length <= self::UCS2_SINGLE) {
            return 1;
        }

        return (int) ceil(($length - self::UCS2_SINGLE) / self::UCS2_MULTIPART) + 1;
    }
}
