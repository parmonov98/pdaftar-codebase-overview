<?php

declare(strict_types=1);

namespace App\Http\Controllers\Statistics;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\Product;
use App\Models\Shop;
use App\Models\Supplier;
use App\Services\Shop\ShopPermissionChecker;
use App\Services\Statistics\KirimStatisticsService;
use App\Services\Statistics\ProductSalesReportService;
use App\Services\Statistics\ProductStatisticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/**
 * Statistika > Mahsulotlar.
 *
 * Owner-only by default. `view-product-statistics` is an opt-in seller
 * permission because this endpoint returns the shop's margin — the very
 * thing `seller_can_set_selling_price` exists to keep from a seller. It
 * must not become the back door to it.
 */
class ProductStatisticsController extends Controller {
    public function __construct(
        private readonly ProductStatisticsService $statistics,
        private readonly ProductSalesReportService $salesReport,
        private readonly ShopPermissionChecker $permissions,
        private readonly KirimStatisticsService $kirims,
    ) {}

    public function index(Request $request, Shop $shop): JsonResponse {
        $shop->shopUsers()->where('user_id', $request->user()->id)->firstOrFail();

        if (! $this->permissions->allows($request->user(), $shop, 'view-product-statistics')) {
            abort(403, "You do not have the 'view-product-statistics' permission for this shop");
        }

        $validated = $request->validate([
            // Mirrors the other Statistika tabs: one currency at a time,
            // chosen by the picker at the top of the screen.
            'currency_id' => 'sometimes|integer|exists:currencies,id',
            'basis' => 'sometimes|in:selling,cost',
            'dead_days' => 'sometimes|integer|min:1|max:365',
            'supplier_id' => 'sometimes|nullable|integer',
            'product_id' => 'sometimes|nullable|integer',
            'client_id' => ['sometimes', 'nullable', 'integer', Rule::exists('clients', 'id')->where('shop_id', $shop->id)->whereNull('deleted_at')],
            // The sales window (Trello #389): the period the app's Savdo
            // card shows now scopes every sales-derived block too. Absent =
            // the trailing dead_days window, as before, so old builds keep
            // the numbers they had.
            'start_date' => 'sometimes|date_format:Y-m-d',
            'end_date' => 'sometimes|date_format:Y-m-d|after_or_equal:start_date',
        ]);

        $from = isset($validated['start_date']) ? Carbon::parse($validated['start_date']) : null;
        $to = isset($validated['end_date']) ? Carbon::parse($validated['end_date']) : $from;

        $data = $this->statistics->forShop(
            $shop,
            (int) ($validated['currency_id'] ?? $shop->currency_id ?? 1),
            $validated['basis'] ?? ProductStatisticsService::BASIS_SELLING,
            (int) ($validated['dead_days'] ?? ProductStatisticsService::DEFAULT_DEAD_DAYS),
            isset($validated['supplier_id']) ? (int) $validated['supplier_id'] : null,
            isset($validated['product_id']) ? (int) $validated['product_id'] : null,
            isset($validated['client_id']) ? (int) $validated['client_id'] : null,
            $from,
            $to,
        );

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    /**
     * Kunlik savdo: per-product sales for one calendar day plus the day's
     * totals. Same membership check and the same `view-product-statistics`
     * gate as index() — this returns revenue, which is exactly what that
     * permission exists to withhold from sellers.
     */
    public function daily(Request $request, Shop $shop): JsonResponse {
        $shop->shopUsers()->where('user_id', $request->user()->id)->firstOrFail();

        if (! $this->permissions->allows($request->user(), $shop, 'view-product-statistics')) {
            abort(403, "You do not have the 'view-product-statistics' permission for this shop");
        }

        $validated = $request->validate([
            // `date` is the single-day form every released build sends and
            // keeps working untouched. `start_date`/`end_date` is the range
            // the picker added in Trello #385 — both optional, so an old
            // build, a new build on "Bugun", and a new build on "Bu oy" all
            // reach the same method.
            'date' => 'sometimes|date_format:Y-m-d',
            'start_date' => 'sometimes|date_format:Y-m-d',
            'end_date' => 'sometimes|date_format:Y-m-d',
            'currency_id' => 'sometimes|integer|exists:currencies,id',
            'supplier_id' => 'sometimes|nullable|integer',
            'product_id' => 'sometimes|nullable|integer',
            'client_id' => ['sometimes', 'nullable', 'integer', Rule::exists('clients', 'id')->where('shop_id', $shop->id)->whereNull('deleted_at')],
        ]);

        // A lone `end_date` is not a range — without a start it would read
        // as "everything up to here", which no picker can produce and which
        // would scan the whole ledger. Fall back to the single-day form.
        $start = $validated['start_date'] ?? $validated['date'] ?? null;
        $end = isset($validated['start_date']) ? ($validated['end_date'] ?? null) : null;

        $data = $this->statistics->dailySales(
            $shop,
            (int) ($validated['currency_id'] ?? $shop->currency_id ?? 1),
            $start !== null ? Carbon::parse($start) : Carbon::today(),
            isset($validated['supplier_id']) ? (int) $validated['supplier_id'] : null,
            isset($validated['product_id']) ? (int) $validated['product_id'] : null,
            isset($validated['client_id']) ? (int) $validated['client_id'] : null,
            $end !== null ? Carbon::parse($end) : null,
        );

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    /**
     * Kirim (Trello #593): what came in over a period — totals, per product,
     * top suppliers and the latest kirims. Same membership check and gate as
     * daily(): it carries purchase costs, i.e. half of the shop's margin.
     */
    public function kirims(Request $request, Shop $shop): JsonResponse {
        $shop->shopUsers()->where('user_id', $request->user()->id)->firstOrFail();

        if (! $this->permissions->allows($request->user(), $shop, 'view-product-statistics')) {
            abort(403, "You do not have the 'view-product-statistics' permission for this shop");
        }

        $validated = $request->validate([
            'start_date' => 'sometimes|date_format:Y-m-d',
            'end_date' => 'sometimes|date_format:Y-m-d',
            'currency_id' => 'required|integer|exists:currencies,id',
            'supplier_id' => 'sometimes|nullable|integer',
            'product_id' => 'sometimes|nullable|integer',
            // Clamped, not rejected: the cap is a server limit, not input error.
            'history_limit' => 'sometimes|integer',
        ]);

        // As daily(): a lone end_date is not a range; no start means today.
        $start = isset($validated['start_date']) ? Carbon::parse($validated['start_date']) : Carbon::today();
        $end = isset($validated['start_date'], $validated['end_date']) ? Carbon::parse($validated['end_date']) : null;

        return response()->json([
            'success' => true,
            'data' => $this->kirims->forShop(
                $shop,
                (int) $validated['currency_id'],
                $start,
                $end,
                isset($validated['supplier_id']) ? (int) $validated['supplier_id'] : null,
                isset($validated['product_id']) ? (int) $validated['product_id'] : null,
                (int) ($validated['history_limit'] ?? KirimStatisticsService::DEFAULT_HISTORY_LIMIT),
            ),
        ]);
    }

    public function sales(Request $request, Shop $shop): JsonResponse {
        $shop->shopUsers()->where('user_id', $request->user()->id)->firstOrFail();

        if (! $this->permissions->allows($request->user(), $shop, 'view-product-statistics')) {
            abort(403, "You do not have the 'view-product-statistics' permission for this shop");
        }

        $validated = $request->validate([
            'currency_id' => 'sometimes|integer|exists:currencies,id',
            'start_date' => 'sometimes|date_format:Y-m-d',
            'end_date' => 'sometimes|date_format:Y-m-d|after_or_equal:start_date',
            'client_id' => [
                'sometimes',
                'nullable',
                'integer',
                Rule::exists('clients', 'id')->where('shop_id', $shop->id),
            ],
            'limit' => 'sometimes|integer|min:1|max:50',
            'payment_method' => 'sometimes|string|in:cash,card,terminal,bank_account,credit,other,unknown',
            'include_summary' => 'sometimes|boolean',
            // Any currency code, lower-cased, or "mixed" (Trello #468).
            'currency_option' => ['sometimes', 'string', Rule::in(
                \Illuminate\Support\Facades\DB::table('currencies')->pluck('code')
                    ->map(fn ($code) => strtolower((string) $code))->push('mixed')->all()
            )],
            'page' => 'sometimes|integer|min:1',
            'per_page' => 'sometimes|integer|min:1|max:100',
        ]);

        $endDate = isset($validated['end_date']) ? Carbon::parse($validated['end_date']) : Carbon::today();
        $startDate = isset($validated['start_date'])
            ? Carbon::parse($validated['start_date'])
            : $endDate->copy()->subDays(29);

        if (($validated['currency_option'] ?? null) === 'mixed') {
            return response()->json(['success' => true, 'data' => $this->salesReport->mixedForShop(
                $shop, $startDate, $endDate, isset($validated['client_id']) ? (int) $validated['client_id'] : null,
                (int) ($validated['page'] ?? 1), (int) ($validated['per_page'] ?? 20), $validated['payment_method'] ?? null, (bool) ($validated['include_summary'] ?? true))]);
        }
        if (isset($validated['currency_option'])) {
            $validated['currency_id'] = \Illuminate\Support\Facades\DB::table('currencies')->where('code', strtoupper($validated['currency_option']))->value('id');
            abort_unless($validated['currency_id'], 422, 'Currency unavailable');
        }

        return response()->json([
            'success' => true,
            'data' => $this->salesReport->forShop(
                $shop,
                (int) ($validated['currency_id'] ?? $shop->currency_id ?? 1),
                $startDate,
                $endDate,
                isset($validated['client_id']) ? (int) $validated['client_id'] : null,
                (int) ($validated['limit'] ?? 20),
                $validated['payment_method'] ?? null,
                false,
                (int) ($validated['page'] ?? 1),
                isset($validated['per_page']) ? (int) $validated['per_page'] : null,
                (bool) ($validated['include_summary'] ?? true),
            ),
        ]);
    }

    public function filterOptions(Request $request, Shop $shop): JsonResponse {
        $shop->shopUsers()->where('user_id', $request->user()->id)->firstOrFail();
        if (! $this->permissions->allows($request->user(), $shop, 'view-product-statistics')) {
            abort(403, "You do not have the 'view-product-statistics' permission for this shop");
        }

        $validated = $request->validate([
            'type' => 'required|in:supplier,product,client',
            'search' => 'sometimes|nullable|string|max:120',
            'currency_id' => 'sometimes|integer|exists:currencies,id',
            'supplier_id' => 'sometimes|nullable|integer',
            'limit' => 'sometimes|integer|min:1|max:50',
            // Additive (Trello #593): `source=kirim` lists who/what actually
            // appears in kirims, for the Kirim view. Absent = unchanged.
            'source' => 'sometimes|nullable|in:kirim',
        ]);
        $currencyId = (int) ($validated['currency_id'] ?? $shop->currency_id ?? 1);
        $search = trim((string) ($validated['search'] ?? ''));
        $limit = (int) ($validated['limit'] ?? 20);

        if (($validated['source'] ?? null) === 'kirim' && $validated['type'] !== 'client') {
            $options = $validated['type'] === 'supplier'
                ? $this->kirims->supplierOptions($shop, $currencyId, $search, $limit)
                : $this->kirims->productOptions($shop, $currencyId, isset($validated['supplier_id']) ? (int) $validated['supplier_id'] : null, $search, $limit);

            return response()->json([
                'success' => true,
                'data' => $options['items'],
                'meta' => ['has_more' => $options['has_more'], 'limit' => $limit],
            ]);
        }

        if ($validated['type'] === 'client') {
            $query = Client::query()->realClients()->where('shop_id', $shop->id)
                ->when($search !== '', fn ($query) => $query->where('name', 'like', "%{$search}%"));
            $columns = ['id', 'name'];
        } elseif ($validated['type'] === 'supplier') {
            $query = Supplier::query()
                ->where('suppliers.shop_id', $shop->id)
                ->whereExists(fn ($query) => $query
                    ->selectRaw('1')
                    ->from('products')
                    ->whereColumn('products.supplier_id', 'suppliers.id')
                    ->where('products.shop_id', $shop->id)
                    ->where('products.currency_id', $currencyId)
                    ->whereNull('products.deleted_at'))
                ->when($search !== '', fn ($query) => $query->where('name', 'like', "%{$search}%"))
                // Trello #671: the supplier the shop last dealt with comes
                // first; suppliers with no transaction yet go last, by name.
                ->select(['suppliers.id', 'suppliers.name'])
                ->selectSub(fn ($query) => $query
                    ->from('supplier_transactions')
                    ->selectRaw('MAX(supplier_transactions.created_at)')
                    ->whereColumn('supplier_transactions.supplier_id', 'suppliers.id')
                    ->where('supplier_transactions.shop_id', $shop->id)
                    ->whereNull('supplier_transactions.deleted_at'), 'last_transaction_at')
                ->orderByRaw('last_transaction_at IS NULL')
                ->orderByDesc('last_transaction_at');
            $columns = ['id', 'name'];
        } else {
            $query = Product::query()
                ->where('shop_id', $shop->id)
                ->where('currency_id', $currencyId)
                ->when(isset($validated['supplier_id']), fn ($query) => $query->where('supplier_id', $validated['supplier_id']))
                ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search) {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('title', 'like', "%{$search}%")
                        ->orWhere('code', 'like', "%{$search}%");
                }));
            $columns = ['id', 'name', 'title'];
        }

        $items = $query->orderBy('name')->orderBy('id')->limit($limit + 1)->get($columns);

        return response()->json([
            'success' => true,
            'data' => $items->take($limit)->map(fn ($item) => [
                'id' => (int) $item->id,
                'name' => (string) ($item instanceof Product ? ($item->title ?: $item->name) : $item->name),
            ])->values(),
            'meta' => ['has_more' => $items->count() > $limit, 'limit' => $limit],
        ]);
    }
}
