# pDaftar — Codebase Structural Overview

**The directory architecture of [pDaftar](https://pdaftar.uz): a Laravel 12 backend and a Flutter client serving bookkeeping, debt tracking, inventory, SMS and payments to small businesses across Uzbekistan.**

[![Laravel](https://img.shields.io/badge/Laravel-12-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.4-777BB4?logo=php&logoColor=white)](https://php.net)
[![Flutter](https://img.shields.io/badge/Flutter-3-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/license-source--available-red)](LICENSE)

---

## What this repository is — read this first

This is **not** the pDaftar source code. It is a **structural overview** of it.

- The **source contents are withheld.** The directory architecture is recorded
  in two manifests, **[`backend/STRUCTURE.md`](backend/STRUCTURE.md)** and
  **[`mobile/STRUCTURE.md`](mobile/STRUCTURE.md)**, which list every directory
  that holds source — **895 of them**, at full depth — with how many files and
  lines each actually contains in production. Nothing is invented.
- **A sample of real files is published in full** — six backend services, two
  statistics controllers with their routes, two complete Flutter feature
  packages, the app's profile screen and its localization strings in nine
  languages — so the actual code can be judged, not just its shape. See
  [Published in full here](#published-in-full-here).
- **A second, larger module is published in full in its own repository:**
  **[pdaftar-shopping-list](https://github.com/parmonov98/pdaftar-shopping-list)** —
  a complete 11,200-line Flutter feature package, the real contents of
  `mobile/packages/pdaftar_shopping_list/` in production.

The purpose is to make the scale and architecture of a closed-source commercial
codebase verifiable to reviewers without publishing the codebase itself.

**Nothing here is padded.** The manifests are faithful copies of the real
trees, and every number below was measured from the production trees, not
estimated. Each manifest includes the command to reproduce its counts.

## The system, in numbers

| | Backend | Mobile | Total |
| --- | ---: | ---: | ---: |
| Source files | 2,253 | 1,190 | **3,443** |
| Lines of source | 250,722 | 298,899 | **549,621** |
| — hand-written | 250,722 | 228,248 | **478,970** |
| — generated (committed codegen) | — | 70,651 | **70,651** |
| Directories (in production) | 477 | 594 | **1,071** |
| Test files | 190 | 35 | **225** |
| Lines of test code | 29,681 | 3,671 | **33,352** |

Backend counts are first-party PHP only — no `vendor/`, no framework code.
Mobile counts are first-party Dart only — no `.dart_tool/`, no `build/`, no pub
dependencies. Neither figure includes the other's language, config, assets,
or native platform code.

## Backend — Laravel 12 / PHP 8.4

```
backend/app/
├── Ai/            AI agents (OpenAI, Gemini, Claude) for expense parsing
├── Console/       69 artisan commands (schedulers, backfills, reports)
├── Constants/     Domain enums — Payment, Plan, OwnerTariff, Order, Ugc, …
├── Contracts/     Interfaces, incl. currency-exchange providers
├── DTO/           Typed transfer objects per aggregate
├── Filament/      235 classes — the admin panel
├── Http/          193 controllers, split Mobile/ · Web/ · Auth/,
│                  + form requests, API resources, middleware
├── Jobs/          99 queued jobs — SMS dispatch, payments, exports
├── Models/        142 Eloquent models
├── Repositories/  Data-access layer over Eloquent
├── Services/      131 services — the business-logic layer
├── Telegram/      Telegram bot handlers (multiple bots)
└── UseCases/      55 feature-scoped use cases

backend/database/migrations/   547 migrations
backend/tests/                 190 test files, 29,681 lines
backend/routes/                mobile_api.php (1,285 lines) · web_api.php (606)
```

| | |
| --- | ---: |
| Eloquent models | 142 |
| Service classes | 131 |
| HTTP controllers | 193 |
| Queue jobs | 99 |
| Console commands | 69 |
| Migrations | 547 |
| Filament admin classes | 235 |

Controllers are thin; business logic lives in `Services/` and `UseCases/`.
Validation via form requests, response shaping via API resources, and anything
slow — SMS, payments, exports, report generation — goes through a queued job on
Redis + Horizon.

<details>
<summary><b>Full backend folder tree</b> — 3 levels deep, with file and line counts</summary>

```
backend/
├── app/                                         1326 files  180,204 lines
│   ├── Ai/                                         1 file        72 lines
│   │   └── Agents/                                 1 file        72 lines
│   ├── Casts/                                      2 files      119 lines
│   ├── Console/                                   69 files    6,923 lines
│   │   └── Commands/                              69 files    6,923 lines
│   ├── Constants/                                 45 files      797 lines
│   │   ├── AppRating/                              2 files       53 lines
│   │   ├── EmployeeTransaction/                    1 file         8 lines
│   │   ├── ErrorResponse/                          2 files       23 lines
│   │   ├── InAppBanner/                            4 files      211 lines
│   │   ├── Order/                                  1 file         9 lines
│   │   ├── OtpConstants/                           1 file        11 lines
│   │   ├── OwnerTariff/                            2 files       36 lines
│   │   ├── Payment/                                1 file        12 lines
│   │   ├── Plan/                                   1 file         8 lines
│   │   ├── Platform/                               1 file        13 lines
│   │   ├── ReferalCode/                            1 file        12 lines
│   │   ├── RegexConstants/                         1 file         8 lines
│   │   ├── ResponseConstants/                     11 files      112 lines
│   │   ├── ShopExpense/                            1 file        16 lines
│   │   ├── ShopExpenseCategory/                    1 file        14 lines
│   │   ├── SocialTask/                             2 files       40 lines
│   │   ├── SupplierTransaction/                    2 files       35 lines
│   │   ├── TermsAndConditions/                     1 file        12 lines
│   │   ├── TransactionConfirmation/                1 file        20 lines
│   │   ├── Ugc/                                    5 files       92 lines
│   │   ├── User/                                   1 file        10 lines
│   │   └── UserOrder/                              1 file        30 lines
│   ├── Contracts/                                  1 file        19 lines
│   │   └── CurrencyExchange/                       1 file        19 lines
│   ├── DTO/                                       23 files    1,388 lines
│   │   ├── Client/                                 1 file       108 lines
│   │   ├── Debt/                                   1 file        98 lines
│   │   ├── Order/                                  1 file        39 lines
│   │   ├── OwnerOrder/                             1 file        37 lines
│   │   ├── Repayment/                              1 file        79 lines
│   │   ├── Shop/                                   2 files       66 lines
│   │   ├── ShoppingList/                           8 files      504 lines
│   │   ├── SmsOrder/                               1 file        45 lines
│   │   ├── Supplier/                               2 files      105 lines
│   │   ├── SupplierInvoice/                        3 files      159 lines
│   │   ├── User/                                   1 file       115 lines
│   │   └── WalletOrder/                            1 file        33 lines
│   ├── Exceptions/                                11 files      272 lines
│   │   └── Custom/                                11 files      272 lines
│   ├── Filament/                                 235 files   22,865 lines
│   │   ├── Exports/                                1 file       143 lines
│   │   ├── Pages/                                  4 files      482 lines
│   │   ├── Resources/                            201 files   19,589 lines
│   │   ├── Support/                                1 file        65 lines
│   │   ├── Traits/                                 1 file        31 lines
│   │   └── Widgets/                               27 files    2,555 lines
│   ├── Filters/                                    2 files       77 lines
│   │   └── BaseFilter/                             1 file        31 lines
│   ├── Helpers/                                    1 file       186 lines
│   ├── Http/                                     420 files   68,215 lines
│   │   ├── Controllers/                          193 files   57,074 lines
│   │   ├── Middleware/                            22 files      699 lines
│   │   ├── Requests/                             137 files    6,292 lines
│   │   └── Resources/                             68 files    4,150 lines
│   ├── Jobs/                                      99 files   14,102 lines
│   │   ├── Informs/                                3 files      968 lines
│   │   ├── Shop/                                   2 files      173 lines
│   │   ├── ShoppingList/                           6 files      599 lines
│   │   └── SMS/                                   18 files    1,552 lines
│   ├── Mail/                                       1 file        49 lines
│   ├── Models/                                   142 files   16,124 lines
│   ├── MoonShine/                                  1 file       460 lines
│   │   └── Resources/                              1 file       460 lines
│   ├── Notifications/                             15 files    1,508 lines
│   ├── Observers/                                  7 files      546 lines
│   ├── Overrides/                                  4 files      391 lines
│   │   └── Watchtower/                             4 files      391 lines
│   ├── Policies/                                   6 files      526 lines
│   ├── Providers/                                 11 files      604 lines
│   │   └── Filament/                               1 file       104 lines
│   ├── Repositories/                              13 files    2,612 lines
│   │   ├── Shop/                                   1 file       815 lines
│   │   └── Subs/                                   1 file       391 lines
│   ├── Services/                                 131 files   28,989 lines
│   │   ├── AI/                                     4 files      410 lines
│   │   ├── AiSupport/                              3 files      696 lines
│   │   ├── Analytics/                              1 file       144 lines
│   │   ├── Auth/                                   3 files      296 lines
│   │   ├── Client/                                 6 files      683 lines
│   │   ├── CurrencyExchange/                       3 files      156 lines
│   │   ├── Dashboard/                              1 file       157 lines
│   │   ├── Expense/                                7 files    1,575 lines
│   │   ├── Firebase/                               1 file         0 lines
│   │   ├── GoogleDocumentAI/                       1 file       501 lines
│   │   ├── InAppBanner/                            1 file       196 lines
│   │   ├── Mobile/                                 1 file       603 lines
│   │   ├── Monitoring/                             2 files      117 lines
│   │   ├── Nakladnoy/                              2 files      525 lines
│   │   ├── OtpService/                             6 files      717 lines
│   │   ├── Payment/                                7 files      709 lines
│   │   ├── Shop/                                   4 files    1,786 lines
│   │   ├── SMS/                                   16 files    4,701 lines
│   │   ├── SmsMailing/                             1 file       289 lines
│   │   ├── SpeechToText/                           7 files      917 lines
│   │   ├── Statistics/                             1 file       319 lines
│   │   ├── Stock/                                  2 files      376 lines
│   │   ├── Subscription/                           1 file       116 lines
│   │   ├── Telegram/                               6 files    1,041 lines
│   │   ├── TelegramMailing/                        4 files      518 lines
│   │   ├── TextToSpeech/                           2 files      309 lines
│   │   ├── TransactionConfirmation/                1 file        77 lines
│   │   ├── UserOrder/                              1 file       365 lines
│   │   ├── VoiceCall/                              2 files    1,360 lines
│   │   ├── Warehouse/                              1 file       105 lines
│   │   └── Web/                                    9 files    4,582 lines
│   ├── Sorts/                                      2 files       70 lines
│   │   └── BaseSort/                               1 file        31 lines
│   ├── SwaggerProcessors/                          1 file        50 lines
│   ├── Task/                                       2 files       44 lines
│   │   ├── Debt/                                   1 file        33 lines
│   │   └── Repayment/                              1 file        11 lines
│   ├── Telegram/                                  20 files    8,842 lines
│   │   ├── Commands/                               3 files      765 lines
│   │   ├── Handlers/                              15 files    7,208 lines
│   │   ├── Services/                               1 file       829 lines
│   │   └── Support/                                1 file        40 lines
│   ├── Traits/                                     3 files      139 lines
│   └── UseCases/                                  55 files    4,118 lines
│       ├── Client/                                 5 files      315 lines
│       ├── Debt/                                   3 files      456 lines
│       ├── Order/                                  1 file        99 lines
│       ├── OwnerOrder/                             1 file       199 lines
│       ├── Repayment/                              2 files      110 lines
│       ├── Shop/                                   6 files      593 lines
│       ├── ShoppingList/                          17 files      867 lines
│       ├── SmsOrder/                               1 file       188 lines
│       ├── Supplier/                               5 files      169 lines
│       ├── SupplierInvoice/                        5 files      482 lines
│       ├── Unit/                                   4 files      104 lines
│       ├── User/                                   4 files      445 lines
│       └── WalletOrder/                            1 file        91 lines
├── config/                                        36 files    5,053 lines
├── database/                                     598 files   27,169 lines
│   ├── factories/                                 21 files      596 lines
│   ├── migrations/                               547 files   24,124 lines
│   └── seeders/                                   30 files    2,449 lines
├── resources/                                     97 files    6,483 lines
│   ├── lang/                                      76 files    3,491 lines
│   │   ├── en/                                    13 files      444 lines
│   │   ├── ru/                                    16 files      824 lines
│   │   ├── uz/                                    16 files      828 lines
│   │   └── vendor/                                31 files    1,395 lines
│   └── views/                                     21 files    2,992 lines
│       ├── admin/                                  5 files      835 lines
│       ├── auth/                                   2 files      161 lines
│       ├── filament/                               5 files      401 lines
│       ├── mail/                                   1 file        14 lines
│       ├── reports/                                3 files      715 lines
│       ├── shops/                                  1 file       298 lines
│       ├── usershop/                               1 file        78 lines
│       └── vendor/                                 2 files      350 lines
├── routes/                                         6 files    2,129 lines
└── tests/                                        190 files   29,681 lines
    ├── Feature/                                  174 files   28,377 lines
    │   ├── Auth/                                   7 files      653 lines
    │   ├── Client/                                 3 files      417 lines
    │   ├── ClientImport/                           2 files      330 lines
    │   ├── Commands/                               1 file       151 lines
    │   ├── Debt/                                   2 files      332 lines
    │   ├── Employee/                               1 file       153 lines
    │   ├── Filament/                               1 file       119 lines
    │   ├── HisobKitob/                             1 file       365 lines
    │   ├── Image/                                  1 file        91 lines
    │   ├── Jobs/                                   6 files    1,219 lines
    │   ├── Kassa/                                  1 file       253 lines
    │   ├── Nakladnoy/                              2 files      290 lines
    │   ├── Notification/                           1 file       138 lines
    │   ├── Notifications/                          2 files      366 lines
    │   ├── Offline/                                1 file        93 lines
    │   ├── OtpService/                             2 files      501 lines
    │   ├── OwnerOrder/                             2 files      260 lines
    │   ├── Printer/                                2 files      392 lines
    │   ├── Product/                                4 files      558 lines
    │   ├── ReferalCode/                            5 files      631 lines
    │   ├── SalesCalc/                              1 file        79 lines
    │   ├── SalesCalcDebt/                          4 files      940 lines
    │   ├── SellerAmallar/                          6 files      712 lines
    │   ├── Shop/                                   6 files      745 lines
    │   ├── ShopPermissions/                        1 file       154 lines
    │   ├── Sms/                                    9 files    1,218 lines
    │   ├── SmsAction/                             12 files    2,435 lines
    │   ├── SmsMailings/                            2 files      247 lines
    │   ├── SocialTask/                             2 files      119 lines
    │   ├── Statistics/                             1 file       251 lines
    │   ├── Stock/                                 11 files    1,495 lines
    │   ├── Subscription/                           4 files      531 lines
    │   ├── Supplier/                               3 files      462 lines
    │   ├── SupplierInvoice/                        4 files      525 lines
    │   ├── SupplierTransaction/                    1 file       189 lines
    │   ├── Tariff/                                 1 file       111 lines
    │   ├── Telegram/                               9 files    1,008 lines
    │   ├── TelegramMailings/                       6 files      704 lines
    │   ├── TransactionConfirmation/                8 files    1,299 lines
    │   ├── TransactionsFeed/                       2 files      443 lines
    │   ├── Ugc/                                    1 file       124 lines
    │   ├── User/                                   2 files      191 lines
    │   ├── UserOrder/                              2 files      293 lines
    │   └── UserOrders/                             2 files      450 lines
    └── Unit/                                      14 files    1,276 lines
        ├── ClientImport/                           2 files      225 lines
        ├── Jobs/                                   1 file       220 lines
        ├── Models/                                 4 files      280 lines
        └── Services/                               1 file       120 lines
```

Generated from [`backend/STRUCTURE.md`](backend/STRUCTURE.md), which goes to full depth. Each count includes everything below that folder.

</details>

**Stack:** Laravel 12.64 · PHP 8.4 · MariaDB · Redis + Horizon · Sanctum ·
Filament 4.2 · PHPUnit 11.5 · Pint · Larastan. 32 production dependencies.

## Mobile — Flutter / Dart 3

```
mobile/lib/
├── constants/     App-wide constants
├── core/          Components, extensions, formatters, handlers,
│                  parsers, storage, utils
├── presantation/  934 files — the feature surface, page-per-directory
├── router/        auto_route configuration
└── service/       Networking, localization (4 locales), printing, platform

mobile/packages/   3 standalone feature packages, 102 files / 16,778 lines
├── pdaftar_shopping_list/   70 files — PUBLISHED IN FULL, see link above
├── pdaftar_sales_calc/      19 files — multi-line sales calculator
└── pdaftar_todo/            13 files — task tracking

mobile/test/               33 test files, 3,671 lines
mobile/integration_test/   2 files
```

<details>
<summary><b>Full mobile folder tree</b> — 4 levels deep, with file and line counts</summary>

```
mobile/
├── integration_test/                               2 files       35 lines
├── lib/                                         1053 files  278,415 lines
│   ├── constants/                                 15 files      986 lines
│   │   └── theme/                                  1 file        34 lines
│   ├── core/                                      26 files    7,298 lines
│   │   ├── components/                             1 file       701 lines
│   │   ├── extensions/                             2 files       15 lines
│   │   ├── formatter/                              1 file        18 lines
│   │   ├── handlers/                              14 files    4,871 lines
│   │   ├── imports/                                1 file        61 lines
│   │   ├── parsers/                                2 files      152 lines
│   │   ├── storage/                                4 files    1,478 lines
│   │   │   ├── get_storage/                        3 files    1,378 lines
│   │   │   └── offline_db/                         1 file       100 lines
│   │   └── utils/                                  1 file         2 lines
│   ├── presantation/                             934 files  209,666 lines
│   │   ├── global_widgets/                        60 files    9,386 lines
│   │   │   ├── app_custom_glassmorphism/           1 file        40 lines
│   │   │   ├── app_drop_down/                      1 file       195 lines
│   │   │   ├── custom_svg/                         1 file        27 lines
│   │   │   ├── dotted_indicator/                   1 file        45 lines
│   │   │   ├── extension/                          2 files      141 lines
│   │   │   ├── grouped_list/                       4 files      802 lines
│   │   │   ├── offline_mode/                       1 file       121 lines
│   │   │   ├── pagination_custom_package/          1 file       103 lines
│   │   │   ├── permission_statuses_sync/           1 file        12 lines
│   │   │   └── shop_list_tile/                     1 file        64 lines
│   │   ├── pages/                                868 files  199,653 lines
│   │   │   ├── ai_support/                        11 files    1,107 lines
│   │   │   ├── applications/                      35 files    6,263 lines
│   │   │   ├── auth/                              51 files    7,382 lines
│   │   │   ├── cash_register/                     52 files   11,176 lines
│   │   │   ├── client_contact/                    35 files    6,496 lines
│   │   │   ├── client_profile/                    66 files   24,748 lines
│   │   │   ├── employees/                         20 files    3,045 lines
│   │   │   ├── faq/                               10 files    1,154 lines
│   │   │   ├── google_map/                         1 file       921 lines
│   │   │   ├── guidance/                           5 files      351 lines
│   │   │   ├── home/                              75 files   20,063 lines
│   │   │   ├── in_app_banner/                     10 files    1,352 lines
│   │   │   ├── instalments/                       14 files    3,627 lines
│   │   │   ├── main/                              20 files    4,988 lines
│   │   │   ├── notification/                      15 files    2,309 lines
│   │   │   ├── offline_actions/                    1 file       219 lines
│   │   │   ├── on_boarding/                        5 files      667 lines
│   │   │   ├── onboarding_quiz/                   15 files    2,465 lines
│   │   │   ├── pin_code/                           9 files    1,933 lines
│   │   │   ├── pre_auth_quiz/                      3 files      588 lines
│   │   │   ├── profile/                           63 files   15,814 lines
│   │   │   ├── quick_transaction/                 11 files    2,411 lines
│   │   │   ├── rentals/                           16 files    4,494 lines
│   │   │   ├── review/                             8 files      571 lines
│   │   │   ├── sales_calc/                         1 file        12 lines
│   │   │   ├── sales_calc_debt/                   14 files    4,274 lines
│   │   │   ├── seller_profile/                    15 files    4,972 lines
│   │   │   ├── shop/                              49 files   11,207 lines
│   │   │   ├── shopping_list/                      1 file     1,079 lines
│   │   │   ├── sklad/                             39 files   10,672 lines
│   │   │   ├── sms_mailings/                      18 files    6,002 lines
│   │   │   ├── social_tasks/                      12 files    1,918 lines
│   │   │   ├── splash/                             4 files      581 lines
│   │   │   ├── statistic/                         44 files   10,376 lines
│   │   │   ├── supplier_catalog/                  12 files    1,271 lines
│   │   │   ├── supplier_profile/                  24 files    7,447 lines
│   │   │   ├── supplier_quick_transaction/        10 files    1,775 lines
│   │   │   ├── telegram_mailings/                 13 files    2,268 lines
│   │   │   ├── todo/                               1 file        12 lines
│   │   │   ├── transaction_confirmation/           9 files    1,579 lines
│   │   │   ├── transactions_feed/                 12 files    1,219 lines
│   │   │   ├── ugc/                               14 files    3,254 lines
│   │   │   ├── user_orders_inbox/                 12 files    1,068 lines
│   │   │   └── voice_mailings/                    13 files    4,523 lines
│   │   └── themes/                                 5 files      507 lines
│   │       └── riverpod/                           4 files      281 lines
│   ├── router/                                     2 files    3,563 lines
│   └── service/                                   72 files   55,369 lines
│       ├── app_lock/                               1 file       220 lines
│       ├── app_rating/                             3 files      282 lines
│       ├── app_update/                             1 file       258 lines
│       ├── appsflyer/                              1 file       144 lines
│       ├── billing/                                2 files      169 lines
│       ├── clarity/                                2 files      175 lines
│       ├── connective_plus/                        2 files      289 lines
│       ├── deep_link/                              3 files      431 lines
│       │   └── handlers/                           2 files      229 lines
│       ├── dev/                                    2 files      187 lines
│       ├── device_info/                            1 file       504 lines
│       ├── firebase/                               1 file        49 lines
│       ├── firebase_analytics/                     1 file        10 lines
│       ├── firebase_messaging/                     2 files      126 lines
│       │   └── data/                               1 file        45 lines
│       ├── google_sign_in/                         1 file       157 lines
│       ├── internet_speed/                         1 file       153 lines
│       ├── local_notification/                     1 file        90 lines
│       ├── localization/                          15 files   46,756 lines
│       │   ├── l10n/                               6 files   45,553 lines
│       │   └── riverpod/                           4 files      318 lines
│       ├── mixpanel/                               3 files      603 lines
│       ├── onboarding/                             2 files      578 lines
│       ├── printer/                               10 files    1,693 lines
│       ├── referral/                               1 file       367 lines
│       ├── remote_config/                          2 files      256 lines
│       ├── telegram/                               3 files      283 lines
│       ├── telegram_oidc/                          1 file       112 lines
│       ├── tracking/                               6 files      884 lines
│       └── widgets/                                2 files      368 lines
├── packages/                                     102 files   16,778 lines
│   ├── pdaftar_sales_calc/                        19 files    4,479 lines
│   │   ├── lib/                                   18 files    4,445 lines
│   │   │   └── src/                               17 files    4,318 lines
│   │   └── test/                                   1 file        34 lines
│   ├── pdaftar_shopping_list/                     70 files   11,236 lines
│   │   ├── lib/                                   69 files   11,189 lines
│   │   │   ├── core/                               1 file         5 lines
│   │   │   └── src/                               67 files   11,000 lines
│   │   └── test/                                   1 file        47 lines
│   └── pdaftar_todo/                              13 files    1,063 lines
│       └── lib/                                   13 files    1,063 lines
│           └── src/                               12 files    1,015 lines
└── test/                                          33 files    3,671 lines
    ├── printer/                                    5 files      433 lines
    ├── sales_calc_debt/                            6 files      685 lines
    ├── seller_profile/                             1 file       167 lines
    ├── service/                                    2 files      192 lines
    │   ├── referral/                               1 file       115 lines
    │   └── sms/                                    1 file        77 lines
    ├── shop_info/                                  3 files      435 lines
    ├── sms_mailings/                               4 files      640 lines
    ├── suppliers/                                  1 file       102 lines
    ├── tracking/                                   1 file        91 lines
    └── transactions_feed/                          5 files      576 lines
```

Generated from [`mobile/STRUCTURE.md`](mobile/STRUCTURE.md), which goes to full depth. Each count includes everything below that folder.

</details>

Feature-first structure under `presantation/`, with the largest features
extracted into standalone packages under `packages/` that carry no dependency on
the host app — see the published shopping-list package for what that boundary
looks like in practice.

Localized into **Uzbek, Russian, Karakalpak and English** (45,544 generated
lines across the base class and four locale files). Ships to both
[the App Store](https://apps.apple.com/uz/app/pdaftar-business-and-finance/id6511237681)
and [Google Play](https://play.google.com/store/apps/details?id=uz.app.pdaftaruz).

## Published in full here

These files are copied unchanged from the production repositories (backend
`main` at `779ad563`, mobile `main` at `c9968ce3`), at the same paths they have there.
The only edit, and the one excerpt, are noted in the table.

| File | Lines | What it is |
| --- | ---: | --- |
| [`backend/app/Services/SMS/SmsPartsCalculatorService.php`](backend/app/Services/SMS/SmsPartsCalculatorService.php) | 183 | GSM 03.38 encoding detection and SMS part counting — described below |
| [`backend/app/Services/SMS/SmsTextNormalizerService.php`](backend/app/Services/SMS/SmsTextNormalizerService.php) | 175 | Folds smart quotes, Uzbek `ʻ` and invisible characters onto GSM 7-bit so a message isn't billed as UCS-2. *Customer and record IDs in comments replaced with neutral wording.* |
| [`backend/app/Services/Client/ClientNameTransliterator.php`](backend/app/Services/Client/ClientNameTransliterator.php) | 90 | Uzbek Cyrillic → Latin for client names, with the positional `е`/`ц` rules |
| [`backend/app/Services/Client/ClientImportColumnMatcher.php`](backend/app/Services/Client/ClientImportColumnMatcher.php) | 162 | Recognises uz / ru / en spreadsheet headers ("Mijoz telefoni", "Имя", "Qarz summasi") during client import |
| [`backend/app/Services/Dashboard/TimePeriodService.php`](backend/app/Services/Dashboard/TimePeriodService.php) | 190 | Daily / weekly / monthly / yearly bucketing for dashboard charts |
| [`backend/app/Services/HeifAuxReferenceSanitizer.php`](backend/app/Services/HeifAuxReferenceSanitizer.php) | 194 | Byte-level HEIF patch that makes iOS 18 photos readable by libheif 1.17 |
| [`backend/app/Http/Controllers/Statistics/ProductStatisticsController.php`](backend/app/Http/Controllers/Statistics/ProductStatisticsController.php) | 317 | The Statistika → Mahsulotlar API: product, daily-sales, sales-report and incoming-goods (kirim) statistics. Every method checks that the caller belongs to the shop and holds `view-product-statistics` |
| [`backend/app/Http/Controllers/Monitoring/EmployeeTransactionFeedController.php`](backend/app/Http/Controllers/Monitoring/EmployeeTransactionFeedController.php) | 73 | The Statistika → Xodimlar API: wages accrued and paid. Checks shop membership and the `view-employees` permission |
| [`backend/routes/mobile_api.statistics-excerpt.php`](backend/routes/mobile_api.statistics-excerpt.php) | 72 | **Excerpt** of `routes/mobile_api.php`: the routes for the two statistics controllers above, inside their real middleware groups. Omitted lines are marked with their production line numbers |
| [`mobile/packages/pdaftar_sales_calc/`](mobile/packages/pdaftar_sales_calc/) | 5,617 | Multi-line sales calculator package — 25 Dart files, including tests |
| [`mobile/packages/pdaftar_todo/`](mobile/packages/pdaftar_todo/) | 1,067 | Task list package — 13 Dart files |
| [`mobile/lib/presantation/pages/profile/`](mobile/lib/presantation/pages/profile/) | 18,585 | The owner's profile and settings screen: account, wallet and SMS balance, referrals, devices, printers, notifications, theme and language — 83 Dart files; 1,115 of the lines are generated (`freezed`) |
| [`mobile/lib/service/localization/l10n/`](mobile/lib/service/localization/l10n/) | — | The app's ARB string files: Uzbek, Russian, English, Karakalpak, Kazakh, Kyrgyz, Tajik, Turkish, Arabic |

The third package, `pdaftar_shopping_list`, is published separately as
[pdaftar-shopping-list](https://github.com/parmonov98/pdaftar-shopping-list).

Everything else stays withheld: the other controllers, authentication, payments,
configuration, migrations and anything that touches customer data.

### The SMS parts calculator

**[`backend/app/Services/SMS/SmsPartsCalculatorService.php`](backend/app/Services/SMS/SmsPartsCalculatorService.php)**

SMS billing depends on knowing how many message *parts* a body splits into
before it is sent, and that depends on which encoding the carrier picks. This
counts parts the way the SMS provider (Eskiz) actually bills them. It was
checked against the provider's own records for 18,603 production messages and
matched every one:

- **Encoding detection** — GSM 7-bit only when every character is ASCII,
  otherwise UCS-2. The provider sends GSM 03.38 letters such as `ü` or `ø` as
  UCS-2, so the calculator does too.
- **Part counting** — GSM 03.38 extension characters (`^ { } [ ] ~ | \`) cost
  two septets each. A single part holds 160 septets; past that, each part holds
  153 (the UDH header takes the difference). UCS-2 is 70 and 67, counted in
  UTF-16 code units, so an emoji outside the BMP costs two.

The UCS-2 case is the one that matters here: customers write in Uzbek and
Russian, and a single Cyrillic character or a `ʻ` in `Toshkent shahri` drops the
whole message to 70 characters per part. Getting it wrong means either
under-billing or surprising the customer.

It was chosen because it is a pure, self-contained algorithm — no models, no
framework coupling, no business rules, no customer data — so it can be read and
judged on its own terms.

## Integrations

Eskiz.uz (SMS) · Click, PayMe, PayUz (payments) · Firebase FCM, OneSignal
(push) · OpenAI, Google Gemini, Anthropic Claude (AI) · Google Document AI
(OCR) · Yandex SpeechKit (voice) · Telegram Bot API

## Licence

Source-available, **not** open source. The published module may be read, not
used, copied, modified, or redistributed. See [LICENSE](LICENSE).

## About

Built by [THEDEVS MCHJ](https://thedevs.uz) — Tashkent, Uzbekistan.

Licensing and verification enquiries: **info@thedevs.uz**
