<?php

// EXCERPT of routes/mobile_api.php at backend main 779ad563, not the whole file.
//
// Only the Statistika routes whose controllers are published in this
// repository are kept: Mahsulotlar (ProductStatisticsController) and Xodimlar
// (EmployeeTransactionFeedController). The enclosing groups are kept so the
// middleware chain is visible. Every other route is omitted; each gap is
// marked with the production line numbers it stands for.
//
// The whole file is mounted under the `mobile_api` middleware group with the
// /api/mobile prefix (bootstrap/app.php).

use App\Http\Middleware\SetLocaleMiddleware;
use Illuminate\Support\Facades\Route;

// … the rest of lines 2–191 omitted (other imports and the public routes);
// the two imports above are lines 68–69

Route::middleware(SetLocaleMiddleware::class)->group(function () {

    // … lines 193–270 omitted

    Route::middleware('auth:sanctum')->group(function () {

        // … lines 272–303 omitted

        Route::middleware('saveLocale')->group(function () {

            // … lines 305–1203 omitted

            Route::prefix('monitoring')->middleware(['assign.roles'])->group(function () {
                // … lines 1205–1208 omitted (Hisob-kitob chart and totals)

                // Statistika > Mahsulotlar. Owner-only by default; the
                // controller gates on the opt-in `view-product-statistics`
                // seller permission because this returns the shop's margin.
                Route::get('/{shop}/product-statistics',
                    [\App\Http\Controllers\Statistics\ProductStatisticsController::class, 'index']);

                // Kunlik savdo: per-product sales for one calendar day
                // (?date=Y-m-d, default today) + the day's totals row.
                Route::get('/{shop}/product-statistics/daily',
                    [\App\Http\Controllers\Statistics\ProductStatisticsController::class, 'daily']);
                Route::get('/{shop}/product-statistics/sales',
                    [\App\Http\Controllers\Statistics\ProductStatisticsController::class, 'sales']);
                // Kirim view (Trello #593): incoming goods over a period.
                Route::get('/{shop}/product-statistics/kirims',
                    [\App\Http\Controllers\Statistics\ProductStatisticsController::class, 'kirims']);
                Route::get('/{shop}/product-statistics/filter-options',
                    [\App\Http\Controllers\Statistics\ProductStatisticsController::class, 'filterOptions']);

                // … lines 1226–1238 omitted (client and supplier transaction feeds)

                // Statistika → Xodimlar: wages accrued (kirim) and paid (chiqim).
                Route::get('/{shop}/employee-transactions/history', [\App\Http\Controllers\Monitoring\EmployeeTransactionFeedController::class, 'history']);
                Route::get('/{shop}/employee-transactions/summary', [\App\Http\Controllers\Monitoring\EmployeeTransactionFeedController::class, 'summary']);
            });

            // … further routes omitted

        });

        // … further routes omitted

    });

    // … further routes omitted

});

// … to line 1677, further routes omitted
