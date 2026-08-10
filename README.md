# pDaftar — Backend Structural Overview

**The directory architecture of the [pDaftar](https://pdaftar.uz) backend: a Laravel 12 / PHP 8.4 platform serving bookkeeping, debt tracking, inventory, SMS and payments to small businesses across Uzbekistan.**

[![Laravel](https://img.shields.io/badge/Laravel-12-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.4-777BB4?logo=php&logoColor=white)](https://php.net)
[![Filament](https://img.shields.io/badge/Filament-4.2-FDAE4B)](https://filamentphp.com)
[![License](https://img.shields.io/badge/license-source--available-red)](LICENSE)

---

## What this repository is — read this first

This is **not** the pDaftar backend source. It is a **structural overview** of it.

- Every directory here mirrors a real directory in the production backend.
- The **source contents are withheld.** Directories are empty, held open by
  `.gitkeep` files (git cannot track an empty directory).
- **[`STRUCTURE.md`](STRUCTURE.md)** records, for each of those directories, how
  many PHP files and lines it actually contains in production — 416 directories
  with real measured counts.
- **One module is included in full** — see [below](#the-one-module-published-in-full) —
  so the actual code and its quality can be judged, not just its shape.

The purpose is to make the scale and architecture of a closed-source commercial
codebase verifiable to reviewers without publishing the codebase itself. Nothing
here is padded: the folder tree is a faithful copy of the real one, and every
number in `STRUCTURE.md` was measured from the production tree, not estimated.

The companion repository
**[pdaftar-shopping-list](https://github.com/parmonov98/pdaftar-shopping-list)**
publishes one complete Flutter feature module from the mobile client in full
source, for the same purpose.

## The codebase this describes

| Metric | Count |
| --- | ---: |
| First-party PHP files | **2,253** |
| First-party lines of PHP | **250,722** |
| Directories | **477** |
| Eloquent models | **142** |
| Service classes | **131** |
| HTTP controllers | **193** |
| Queue jobs | **99** |
| Console commands | **69** |
| Database migrations | **547** |
| Filament admin classes | **235** |
| Test files | **190** |
| Lines of test code | **29,681** |

Excludes `vendor/` and all framework code. Per-directory breakdown in
[`STRUCTURE.md`](STRUCTURE.md).

## Architecture

```
app/
├── Ai/            AI agents (OpenAI, Gemini, Claude) for expense parsing
├── Casts/         Eloquent attribute casts
├── Console/       69 artisan commands (schedulers, backfills, reports)
├── Constants/     Domain enums — Payment, Plan, OwnerTariff, Order, Ugc, …
├── Contracts/     Interfaces, incl. currency-exchange providers
├── DTO/           Typed transfer objects per aggregate
├── Exceptions/    Domain exception hierarchy
├── Filament/      235 classes — the admin panel (resources, pages, exports)
├── Http/          193 controllers, split Mobile/ · Web/ · Auth/,
│                  + form requests, API resources, middleware
├── Jobs/          99 queued jobs — SMS dispatch, payments, exports, reports
├── Models/        142 Eloquent models
├── Notifications/ Mail, database and push notification classes
├── Observers/     Model lifecycle hooks
├── Policies/      Authorization policies
├── Repositories/  Data-access layer over Eloquent
├── Services/      131 services — the business-logic layer
├── Task/          Scheduled task definitions
├── Telegram/      Telegram bot handlers (multiple bots)
├── Traits/        Shared model behaviour
└── UseCases/      55 feature-scoped use cases

database/migrations/   547 migrations
tests/Unit · Feature   190 test files, 29,681 lines
routes/                mobile_api.php (1,285 lines) · web_api.php (606)
                       · web.php · api.php · console.php · channels.php
```

Controllers are thin; business logic lives in `Services/` and `UseCases/`.
Validation is via form requests, response shaping via API resources, and
anything slow (SMS, payments, exports, report generation) goes through a queued
job on Redis + Horizon.

## The one module published in full

**[`app/Services/SMS/SmsPartsCalculatorService.php`](app/Services/SMS/SmsPartsCalculatorService.php)**

SMS billing depends on knowing how many message *parts* a body will be split
into before it is sent, and that depends on which encoding the carrier will
pick. This service implements the GSM 03.38 rules:

- **Encoding detection** — GSM 7-bit (0) → ASCII (1) → UCS-2 (8), in that
  order of preference, by testing the message against the GSM 7-bit charset
  including the escape-sequence extended set.
- **Part counting** — 160 chars for a single GSM 7-bit part but 153 per part
  once concatenated (the UDH header consumes the difference); 70 and 67 for
  UCS-2.

The UCS-2 case is the one that matters in practice here: pDaftar's customers
write in Uzbek and Russian, and a single Cyrillic character or a `ʻ` in
`Toshkent shahri` drops the whole message to 70 characters per part. Getting
this wrong means either under-billing or surprising the customer.

It was chosen for publication because it is a pure, self-contained algorithm —
no models, no framework coupling, no business rules, no customer data — so it
can be read and judged on its own terms.

## Stack

Laravel 12.64 · PHP 8.4 · MariaDB · Redis + Laravel Horizon · Laravel Sanctum ·
Filament 4.2 · PHPUnit 11.5 · Laravel Pint · Larastan

32 production dependencies, 10 development dependencies.

**Integrations:** Eskiz.uz (SMS) · Click, PayMe, PayUz (payments) ·
Firebase FCM, OneSignal (push) · OpenAI, Google Gemini, Anthropic Claude (AI) ·
Google Document AI (OCR) · Yandex SpeechKit (voice) · Telegram Bot API

## Licence

Source-available, **not** open source. The published module may be read, not
used, copied, modified, or redistributed. See [LICENSE](LICENSE).

## About

Built by [THEDEVS MCHJ](https://thedevs.uz) — Tashkent, Uzbekistan.

pDaftar is available on
[the App Store](https://apps.apple.com/uz/app/pdaftar-business-and-finance/id6511237681)
and [Google Play](https://play.google.com/store/apps/details?id=uz.app.pdaftaruz).

Licensing and verification enquiries: **info@thedevs.uz**
