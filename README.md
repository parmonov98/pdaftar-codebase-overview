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

- Every directory here mirrors a real directory in the production repositories —
  **1,071 of them**, across the backend and the mobile client.
- The **source contents are withheld.** Directories are empty, held open by
  `.gitkeep` files (git cannot track an empty directory).
- Two manifests — **[`backend/STRUCTURE.md`](backend/STRUCTURE.md)** and
  **[`mobile/STRUCTURE.md`](mobile/STRUCTURE.md)** — record, for each directory,
  how many source files and lines it actually contains in production. **895
  directories with real measured counts.**
- **One module is included in full** —
  [`backend/app/Services/SMS/SmsPartsCalculatorService.php`](backend/app/Services/SMS/SmsPartsCalculatorService.php) —
  so the actual code can be judged, not just its shape.
- **A second, larger module is published in full in its own repository:**
  **[pdaftar-shopping-list](https://github.com/parmonov98/pdaftar-shopping-list)** —
  a complete 11,200-line Flutter feature package, the real contents of
  `mobile/packages/pdaftar_shopping_list/` in this tree.

The purpose is to make the scale and architecture of a closed-source commercial
codebase verifiable to reviewers without publishing the codebase itself.

**Nothing here is padded.** The folder trees are faithful copies of the real
ones, and every number below was measured from the production trees, not
estimated. Each manifest includes the command to reproduce its counts.

## The system, in numbers

| | Backend | Mobile | Total |
| --- | ---: | ---: | ---: |
| Source files | 2,253 | 1,190 | **3,443** |
| Lines of source | 250,722 | 298,899 | **549,621** |
| — hand-written | 250,722 | 228,248 | **478,970** |
| — generated (committed codegen) | — | 70,651 | **70,651** |
| Directories | 477 | 594 | **1,071** |
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

Feature-first structure under `presantation/`, with the largest features
extracted into standalone packages under `packages/` that carry no dependency on
the host app — see the published shopping-list package for what that boundary
looks like in practice.

Localized into **Uzbek, Russian, Karakalpak and English** (45,544 generated
lines across the base class and four locale files). Ships to both
[the App Store](https://apps.apple.com/uz/app/pdaftar-business-and-finance/id6511237681)
and [Google Play](https://play.google.com/store/apps/details?id=uz.app.pdaftaruz).

## The module published in full here

**[`backend/app/Services/SMS/SmsPartsCalculatorService.php`](backend/app/Services/SMS/SmsPartsCalculatorService.php)**

SMS billing depends on knowing how many message *parts* a body splits into
before it is sent, and that depends on which encoding the carrier picks. This
implements the GSM 03.38 rules:

- **Encoding detection** — GSM 7-bit (0) → ASCII (1) → UCS-2 (8), in that order
  of preference, testing against the GSM 7-bit charset including the
  escape-sequence extended set.
- **Part counting** — 160 characters for a single GSM 7-bit part but 153 per
  part once concatenated (the UDH header consumes the difference); 70 and 67
  for UCS-2.

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
