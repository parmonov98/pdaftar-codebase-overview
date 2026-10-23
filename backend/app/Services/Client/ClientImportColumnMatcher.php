<?php

namespace App\Services\Client;

/**
 * Proposes which spreadsheet column holds which client field (#651).
 *
 * People import the lists they already have, so headers arrive as "Ism",
 * "Mijoz telefoni", "Имя", "Телефон", "Qarz summasi" — not `name` and
 * `phone_number`. Both importers (mobile and web) ask this one class, so a
 * file is recognised the same way on every platform.
 *
 * It only SUGGESTS: the user confirms or changes the mapping before the
 * import starts, and `start` validates whatever they chose.
 */
class ClientImportColumnMatcher {
    /** Field keys as the mobile API names them. */
    public const NAME = 'name';

    public const PHONE = 'phone';

    public const ADDRESS = 'address';

    public const DEBT = 'debt_amount';

    public const DUE_DATE = 'repayment_date';

    public const FIELDS = [self::NAME, self::PHONE, self::ADDRESS, self::DEBT, self::DUE_DATE];

    public const REQUIRED = [self::NAME, self::PHONE];

    /**
     * Whole-header synonyms (already normalised: lower case, Latin, `_`).
     *
     * @var array<string, array<int, string>>
     */
    private const EXACT = [
        self::PHONE => ['phone_number', 'phone', 'phones', 'tel', 'telefon', 'telefon_raqami', 'telefon_raqam', 'raqam', 'raqami', 'telefoni', 'mobile', 'mobil', 'nomer', 'nomer_telefona', 'telefon_nomer', 'mobilnyy', 'sotovyy', 'kontakt'],
        self::DEBT => ['debt_amount', 'debt', 'qarz', 'qarzi', 'qarz_summasi', 'hozirgi_qarz_summasi', 'summa', 'summasi', 'amount', 'balans', 'balance', 'dolg', 'summa_dolga', 'qarzdorlik', 'qoldiq', 'qoldigi', 'ostatok', 'saldo'],
        self::DUE_DATE => ['due_date', 'repayment_date', 'qaytarish_sanasi', 'muddat', 'muddati', 'sana', 'date', 'due', 'deadline', 'srok', 'data', 'data_vozvrata', 'srok_vozvrata', 'tolov_sanasi', 'tolash_sanasi'],
        self::ADDRESS => ['address', 'manzil', 'manzili', 'adres', 'manzil_adres', 'yashash_manzili'],
        self::NAME => ['name', 'client_name', 'full_name', 'ism', 'ismi', 'ism_familiya', 'ism_sharif', 'familiya_ism', 'fio', 'f_i_o', 'mijoz', 'mijoz_ismi', 'mijozlar', 'xaridor', 'klient', 'client', 'customer', 'imya', 'familiya', 'nomi', 'kontragent', 'pokupatel'],
    ];

    /**
     * Words that identify a field inside a longer header ("Mijoz telefoni",
     * "Qarz summasi (so'm)"). Checked in FIELDS_BY_SPECIFICITY order, so a
     * header naming both the client and the phone becomes the phone.
     *
     * @var array<string, array<int, string>>
     */
    private const CONTAINS = [
        self::PHONE => ['phone', 'telefon', 'tel', 'raqam', 'nomer', 'mobil'],
        self::DEBT => ['qarz', 'debt', 'summa', 'amount', 'dolg', 'balans', 'balance', 'qoldiq', 'ostatok', 'saldo'],
        self::DUE_DATE => ['muddat', 'sana', 'date', 'deadline', 'srok', 'data'],
        self::ADDRESS => ['manzil', 'address', 'adres'],
        self::NAME => ['name', 'ism', 'fio', 'mijoz', 'xaridor', 'klient', 'client', 'imya', 'familiya'],
    ];

    /** Most specific first: a phone or a sum header often also says "mijoz". */
    private const FIELDS_BY_SPECIFICITY = [self::PHONE, self::DEBT, self::DUE_DATE, self::ADDRESS, self::NAME];

    private const CYRILLIC = [
        'а' => 'a', 'б' => 'b', 'в' => 'v', 'г' => 'g', 'ғ' => 'g', 'д' => 'd', 'е' => 'e', 'ё' => 'yo', 'ж' => 'j',
        'з' => 'z', 'и' => 'i', 'й' => 'y', 'к' => 'k', 'қ' => 'q', 'л' => 'l', 'м' => 'm', 'н' => 'n', 'ң' => 'n',
        'о' => 'o', 'ө' => 'o', 'п' => 'p', 'р' => 'r', 'с' => 's', 'т' => 't', 'у' => 'u', 'ў' => 'o', 'ү' => 'u',
        'ұ' => 'u', 'ф' => 'f', 'х' => 'x', 'ҳ' => 'h', 'һ' => 'h', 'ц' => 'ts', 'ч' => 'ch', 'ш' => 'sh', 'щ' => 'sh',
        'ъ' => '', 'ы' => 'y', 'ь' => '', 'э' => 'e', 'ю' => 'yu', 'я' => 'ya', 'ә' => 'a', 'і' => 'i',
    ];

    /**
     * @param  array<int, mixed>  $headers  the header row as read from the file
     * @return array<string, int|null> field => column index (null when not found)
     */
    public function suggest(array $headers): array {
        $normalised = [];
        foreach ($headers as $index => $header) {
            $key = $this->normalise((string) ($header ?? ''));
            if ($key !== '') {
                $normalised[(int) $index] = $key;
            }
        }

        $mapping = array_fill_keys(self::FIELDS, null);
        $taken = [];

        // Pass 1: whole-header synonyms. Pass 2: a keyword inside the header.
        foreach ([self::EXACT, self::CONTAINS] as $pass => $table) {
            foreach (self::FIELDS_BY_SPECIFICITY as $field) {
                if ($mapping[$field] !== null) {
                    continue;
                }
                foreach ($normalised as $index => $key) {
                    if (isset($taken[$index])) {
                        continue;
                    }
                    $hit = $pass === 0
                        ? in_array($key, $table[$field], true)
                        : $this->containsWord($key, $table[$field]);
                    if ($hit) {
                        $mapping[$field] = $index;
                        $taken[$index] = true;
                        break;
                    }
                }
            }
        }

        return $mapping;
    }

    /**
     * Words that make an amount header a signed balance rather than a debt:
     * client lists -- pDaftar's own export ("Balans UZS") and other apps'
     * ("UZS qoldiq") -- write what the client owes with a minus and money
     * paid ahead with a plus.
     */
    private const BALANCE_WORDS = ['qoldiq', 'balans', 'balance', 'ostatok', 'saldo'];

    public function isBalanceHeader(string $header): bool {
        return $this->containsWord($this->normalise($header), self::BALANCE_WORDS);
    }

    /** A header that holds money owed or a balance ("Qarz", "USD qoldiq"). */
    public function isAmountHeader(string $header): bool {
        $key = $this->normalise($header);

        return in_array($key, self::EXACT[self::DEBT], true) || $this->containsWord($key, self::CONTAINS[self::DEBT]);
    }

    /**
     * Required fields a mapping leaves out.
     *
     * @param  array<string, int|null>  $mapping
     * @return array<int, string>
     */
    public function missingRequired(array $mapping): array {
        return array_values(array_filter(self::REQUIRED, fn (string $field) => ! isset($mapping[$field])));
    }

    public function normalise(string $header): string {
        $value = mb_strtolower(trim($header));
        $value = strtr($value, self::CYRILLIC);
        // oʻ / gʻ and every apostrophe variant fold away: "qo'shimcha" == "qoshimcha".
        $value = str_replace(['ʻ', 'ʼ', "'", '’', '‘', '`'], '', $value);
        $value = preg_replace('/[^a-z0-9]+/', '_', $value) ?? '';

        return trim($value, '_');
    }

    /** @param  array<int, string>  $words */
    private function containsWord(string $key, array $words): bool {
        foreach ($words as $word) {
            // Match at a word start, so "tel" finds "telefon" but not "hotel".
            if (preg_match('/(^|_)'.preg_quote($word, '/').'/', $key)) {
                return true;
            }
        }

        return false;
    }
}
