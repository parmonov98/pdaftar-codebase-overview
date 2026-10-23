<?php

namespace App\Http\Controllers\Monitoring;

use App\Http\Controllers\Controller;
use App\Http\Requests\Monitoring\TransactionsHistoryRequest;
use App\Http\Requests\Monitoring\TransactionsSummaryRequest;
use App\Http\Resources\Monitoring\EmployeeTransactionFeedItemResource;
use App\Models\Shop;
use App\Services\Monitoring\EmployeeTransactionFeedService;
use App\Services\Shop\ShopPermissionChecker;
use App\Traits\CheckUserShopTrait;
use Illuminate\Http\JsonResponse;

/**
 * Statistika → Xodimlar. Wages are the most private numbers in the shop, so
 * on top of shop membership a seller needs `view-employees` — the same gate
 * the per-employee screens use (WebEmployeeTransactionController).
 */
class EmployeeTransactionFeedController extends Controller {
    use CheckUserShopTrait;

    public function __construct(private readonly EmployeeTransactionFeedService $service) {}

    /**
     * Same condition, status and body as MonitoringController::getSumDebitAndCredit(),
     * so a client that already handles that endpoint's error needs no new branch.
     */
    private function currencyNotFound(): JsonResponse {
        return response()->json([
            'success' => false,
            'message' => 'Currency not found. Please set a default currency for the shop or specify a currency_id.',
        ], 400);
    }

    public function history(TransactionsHistoryRequest $request, Shop $shop): JsonResponse {
        $this->checkUserShop($shop->id);
        abort_unless(app(ShopPermissionChecker::class)->allows(request()->user(), $shop, 'view-employees'), 403);

        $currencyId = $this->service->resolveCurrencyId($shop, $request->integer('currency_id') ?: null);
        if ($currencyId === null) {
            return $this->currencyNotFound();
        }

        $paginator = $this->service->history(
            $shop,
            $request->filled('direction') ? $request->string('direction')->toString() : null,
            $currencyId,
            $request->string('start_date')->toString(),
            $request->string('end_date')->toString(),
            $request->integer('per_page') ?: 20,
        );

        return EmployeeTransactionFeedItemResource::collection($paginator)->response();
    }

    public function summary(TransactionsSummaryRequest $request, Shop $shop): JsonResponse {
        $this->checkUserShop($shop->id);
        abort_unless(app(ShopPermissionChecker::class)->allows(request()->user(), $shop, 'view-employees'), 403);

        $currencyId = $this->service->resolveCurrencyId($shop, $request->integer('currency_id') ?: null);
        if ($currencyId === null) {
            return $this->currencyNotFound();
        }

        return response()->json($this->service->summary(
            $shop,
            $currencyId,
            $request->string('start_date')->toString(),
            $request->string('end_date')->toString(),
        ));
    }
}
