import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdaftar_sales_calc/pdaftar_sales_calc.dart';

class SalesCalcBloc extends Bloc<SalesCalcEvent, SalesCalcState> {
  final ISalesCalcRepository _repository;
  final int shopId;
  final int? defaultCurrencyId;
  int _localIdCounter = -1; // Negative IDs for local-only items
  bool _isDirty = false; // Track if local changes need syncing

  /// Why the last sync failed, for the host to word the error (Trello #430).
  /// Null after a successful sync.
  Object? lastSyncError;

  bool get isDirty => _isDirty;

  static const _showLabelsKey = 'sales_calc_show_labels';
  static const _deductStockKey = 'sales_calc_deduct_stock';
  int _productSearchSeq = 0;

  // ─── Offline product catalog ────────────────────────────────
  // The autocomplete filters this in-memory list instead of hitting
  // the backend on every keystroke. Fetched once (first search or
  // page load), refreshed after the TTL so products created by other
  // devices / list saves eventually appear.
  List<ShopProduct>? _productCatalog;
  DateTime? _productCatalogFetchedAt;
  Future<List<ShopProduct>>? _catalogInflight;
  static const _catalogTtl = Duration(minutes: 5);
  static const _catalogFetchLimit = 500;

  Future<List<ShopProduct>> _getProductCatalog() {
    final fetchedAt = _productCatalogFetchedAt;
    final fresh = _productCatalog != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _catalogTtl;
    if (fresh) return Future.value(_productCatalog!);
    return _catalogInflight ??= _repository
        .searchProducts(shopId, '', limit: _catalogFetchLimit)
        .then((list) {
      _productCatalog = list;
      _productCatalogFetchedAt = DateTime.now();
      return list;
    }).whenComplete(() => _catalogInflight = null);
  }

  SalesCalcBloc(
      {required ISalesCalcRepository repository,
      required this.shopId,
      this.defaultCurrencyId})
      : _repository = repository,
        super(SalesCalcState(
          // Nomi column is shown by default. Users who explicitly hid it
          // via the settings toggle keep their choice (the pref reader
          // returns the persisted value). New users get the labels-on
          // experience the product flow now expects.
          showLabels: SalesCalcPackage.readPref(
            _showLabelsKey,
            defaultValue: true,
          ),
          // "Skladdan kamaytirish" defaults ON (Trello #439). It was OFF so
          // existing sales wrote no stock movements until the user opted in —
          // and most never found the switch: since 13 Sep 32% of sold rows
          // linked to a product deducted nothing, 47 shops never deducted at
          // all, and users reported "sold from the calculator, stock didn't
          // go down". Only users who never touched it change: an explicit OFF
          // is stored and still wins. Products that were never inventoried
          // stay untouched either way (StockService::isTracked).
          deductStock: SalesCalcPackage.readPref(
            _deductStockKey,
            defaultValue: true,
          ),
        )) {
    on<LoadSalesCalcLists>(_onLoadLists);
    on<CreateNewList>(_onCreateList);
    on<SelectList>(_onSelectList);
    on<RenameList>(_onRenameList);
    on<DeleteList>(_onDeleteList);
    on<ToggleShowLabels>(_onToggleLabels);
    on<ToggleDeductStock>(_onToggleDeductStock);
    on<SyncToBackend>(_onSync);
    on<LoadSalesCalcItems>(_onLoadItems);
    on<CreateSalesCalcItem>(_onCreateItem);
    on<UpdateSalesCalcItem>(_onUpdateItem);
    on<DeleteSalesCalcItem>(_onDeleteItem);
    on<UpdateItemLabel>(_onUpdateLabel);
    on<UpdateLocalExpression>(_onUpdateLocal);
    on<UpdateItemProduct>(_onUpdateProduct);
    on<SetStructuredProductLine>(_onStructuredProduct);
    on<SearchProducts>(_onSearchProducts);
    on<BrowseProducts>(_onBrowseProducts);
    on<ClearProductSuggestions>(_onClearSuggestions);
  }

  @override
  Future<void> close() {
    // Invalidate stale in-flight search results.
    _productSearchSeq++;
    return super.close();
  }

  // ─── Lists ───

  Future<void> _onLoadLists(
      LoadSalesCalcLists event, Emitter<SalesCalcState> emit) async {
    emit(state.copyWith(status: SalesCalcStatus.loading));
    if (event.refresh) {
      // Manual sync: never lose local rows — push unsynced edits up
      // before re-pulling, then invalidate the catalog so products
      // created elsewhere (web, another device, a list save) appear.
      if (_isDirty && state.activeListId != null) {
        if (!await _syncCurrentList()) {
          emit(state.copyWith(
              status: SalesCalcStatus.loaded, errorMessage: 'sync_failed'));
          return;
        }
      }
      _productCatalog = null;
      _productCatalogFetchedAt = null;
    }
    // Warm the offline autocomplete catalog in the background so the
    // very first keystroke already filters locally. Errors are
    // swallowed — the first search retries the fetch itself.
    unawaited(_getProductCatalog().catchError((_) => const <ShopProduct>[]));
    try {
      // Tab-strip window: only lists touched in the last N days (user
      // setting, 0 = all). Keeps the strip from growing forever.
      final lists = await _repository.getLists(
        shopId,
        days: SalesCalcPackage.listDays,
      );
      if (lists.isEmpty) {
        final newList = await _repository.createList(shopId);
        emit(state.copyWith(
          status: SalesCalcStatus.loaded,
          lists: [newList],
          activeListId: newList.id,
        ));
      } else if (event.startWithNewList && lists.first.itemsCount > 0) {
        // Drawer entry: the newest list already holds a sale, so a
        // fresh one is created. (When the newest list is still empty
        // it's reused below — repeated drawer opens shouldn't pile up
        // blank lists.)
        final newList = await _repository.createList(shopId);
        emit(state.copyWith(
          status: SalesCalcStatus.loaded,
          lists: [newList, ...lists],
          activeListId: newList.id,
          items: [],
        ));
      } else {
        // Fall back to the newest list when nothing was active OR the
        // previously-active list fell outside the days window (e.g.
        // after tightening the setting) — keeping a hidden id active
        // would desync the tab strip from the items below it.
        final prior = state.activeListId;
        final activeId = event.startWithNewList
            ? lists.first.id
            : ((prior != null && lists.any((l) => l.id == prior))
                ? prior
                : lists.first.id);
        emit(state.copyWith(
          status: SalesCalcStatus.loaded,
          lists: lists,
          activeListId: activeId,
        ));
        add(const LoadSalesCalcItems(isRefresh: true));
      }
    } catch (e) {
      emit(state.copyWith(
          status: SalesCalcStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateList(
      CreateNewList event, Emitter<SalesCalcState> emit) async {
    // Sync current list before switching
    if (_isDirty && state.activeListId != null) {
      if (!await _syncCurrentList()) {
        emit(state.copyWith(errorMessage: 'sync_failed'));
        return;
      }
    }

    try {
      final newList = await _repository.createList(shopId, name: event.name);
      final updatedLists = [newList, ...state.lists];
      emit(state.copyWith(
        lists: updatedLists,
        activeListId: newList.id,
        items: [],
      ));
      _isDirty = false;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSelectList(
      SelectList event, Emitter<SalesCalcState> emit) async {
    // Sync current list before switching
    if (_isDirty && state.activeListId != null) {
      if (!await _syncCurrentList()) {
        emit(state.copyWith(errorMessage: 'sync_failed'));
        return;
      }
    }

    emit(state.copyWith(activeListId: event.listId, items: []));
    _isDirty = false;
    add(const LoadSalesCalcItems(isRefresh: true));
  }

  Future<void> _onRenameList(
      RenameList event, Emitter<SalesCalcState> emit) async {
    try {
      final updated =
          await _repository.renameList(shopId, event.listId, event.name);
      final updatedLists = state.lists.map((l) {
        if (l.id == event.listId) return updated;
        return l;
      }).toList();
      emit(state.copyWith(lists: updatedLists));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteList(
      DeleteList event, Emitter<SalesCalcState> emit) async {
    try {
      await _repository.deleteList(shopId, event.listId);
      final updatedLists =
          state.lists.where((l) => l.id != event.listId).toList();
      final newActiveId =
          updatedLists.isNotEmpty ? updatedLists.first.id : null;
      emit(state
          .copyWith(lists: updatedLists, activeListId: newActiveId, items: []));
      _isDirty = false;
      if (newActiveId != null) {
        add(const LoadSalesCalcItems(isRefresh: true));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  // ─── Settings ───

  void _onToggleLabels(ToggleShowLabels event, Emitter<SalesCalcState> emit) {
    final newValue = !state.showLabels;
    emit(state.copyWith(showLabels: newValue));
    SalesCalcPackage.writePref(_showLabelsKey, newValue);
  }

  void _onToggleDeductStock(
    ToggleDeductStock event,
    Emitter<SalesCalcState> emit,
  ) {
    if (state.hasStructuredItems) {
      // Structured quantity is required by the server. Never erase a frozen
      // tuple merely to implement the legacy no-stock switch.
      return;
    }
    final newValue = !state.deductStock;
    emit(state.copyWith(deductStock: newValue));
    SalesCalcPackage.writePref(_deductStockKey, newValue);
    // The toggle changes what the sync payload carries (quantity per
    // linked row vs none), and batchSync is a full-list replace on the
    // backend — so force the next sync to rewrite the rows. Flipping
    // OFF then selling must NOT reuse quantities stored by an earlier
    // ON-sync, and flipping ON must backfill them.
    _isDirty = true;
  }

  // ─── Sync ───

  Future<void> _onSync(
      SyncToBackend event, Emitter<SalesCalcState> emit) async {
    if (!_isDirty || state.activeListId == null) return;
    await _syncCurrentList();
  }

  Future<bool> _syncCurrentList() async {
    final syncingItems = state.items;
    final listId = state.activeListId;
    if (listId == null) {
      _isDirty = false;
      return true;
    }

    try {
      lastSyncError = null;
      final itemsData = state.items
          .where((item) => item.expression.trim().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((entry) {
        final item = entry.value;
        // "Skladdan kamaytirish": an explicit sold quantity rides along
        // for product-LINKED rows only. The backend stores it on the
        // row, the save-as-debt clone freezes it, and debt creation
        // turns product_id+quantity lines into `sale` stock movements.
        // Free-text rows have no product link → no quantity → skipped
        // silently. With the toggle OFF nothing is sent, and since
        // batchSync fully replaces the list's rows, an OFF-sync also
        // clears quantities left by an earlier ON-sync.
        final quantity = state.deductStock && item.productId != null
            ? ExpressionEvaluator.soldQuantity(item.expression)
            : null;
        return {
          'expression': item.expression,
          'label': item.label,
          'result': item.result,
          'position': entry.key,
          if (item.productId != null) 'product_id': item.productId,
          if (item.productUnitId != null) ...{
            'product_unit_id': item.productUnitId,
            'unit_version': item.unitVersion,
            'currency_id': item.currencyId,
            'quantity': item.enteredQuantity ?? item.quantity,
            'unit_price': item.unitPrice,
          } else ...{
            if (quantity != null) 'quantity': quantity,
            if (state.hasStructuredItems &&
                (item.currencyId ?? defaultCurrencyId) != null)
              'currency_id': item.currencyId ?? defaultCurrencyId,
          },
        };
      }).toList();

      {
        await _repository.batchSync(shopId, listId, itemsData);
        // batchSync is where the backend's resolve-or-create turns
        // typed labels into Products — the offline catalog is stale
        // the moment it returns. Re-warm it in the background so the
        // just-created products autocomplete on the next list
        // (covers new-list, tab-switch, and manual sync paths alike).
        _productCatalog = null;
        _productCatalogFetchedAt = null;
        unawaited(
            _getProductCatalog().catchError((_) => const <ShopProduct>[]));
      }
      _isDirty = !identical(syncingItems, state.items);
      debugPrint('SalesCalc: synced ${itemsData.length} items to backend');
      return !_isDirty;
    } catch (e) {
      debugPrint('SalesCalc: sync failed: $e');
      lastSyncError = e;
      return false;
    }
  }

  /// Call this from the page's dispose to ensure data is saved.
  ///
  /// [force] syncs even when nothing is locally dirty. The save-as-debt
  /// path passes it while "Skladdan kamaytirish" is ON: stock movements
  /// are written from the CLONE the host makes right after this call, so
  /// the server rows must carry fresh quantities even when the list was
  /// loaded clean (e.g. synced earlier by an older build with no
  /// quantities).
  Future<bool> syncBeforeExit({bool force = false}) async {
    if ((_isDirty || force) && state.activeListId != null) {
      return _syncCurrentList();
    }
    return true;
  }

  // ─── Items (all LOCAL) ───

  Future<void> _onLoadItems(
      LoadSalesCalcItems event, Emitter<SalesCalcState> emit) async {
    final listId = state.activeListId;
    if (listId == null) return;

    try {
      final received = await _repository.getItems(shopId, listId);
      final items = received
          .map((item) => item.currencyId == null &&
                  item.productUnitId == null &&
                  defaultCurrencyId != null
              ? item.copyWith(currencyId: defaultCurrencyId)
              : item)
          .toList();
      emit(state.copyWith(status: SalesCalcStatus.loaded, items: items));
      _isDirty = false;
    } catch (e) {
      emit(state.copyWith(
          status: SalesCalcStatus.error, errorMessage: e.toString()));
    }
  }

  void _onCreateItem(CreateSalesCalcItem event, Emitter<SalesCalcState> emit) {
    final newItem = SalesCalcItem(
      id: _localIdCounter--,
      expression: event.expression,
      result: event.result,
      position: state.items.length,
      label: event.label,
      productId: event.productId,
      currencyId: defaultCurrencyId,
    );
    emit(state.copyWith(items: [...state.items, newItem]));
    _isDirty = true;
  }

  void _onUpdateItem(UpdateSalesCalcItem event, Emitter<SalesCalcState> emit) {
    final updatedItems = state.items.map((item) {
      if (item.id == event.id && item.productUnitId == null) {
        return item.copyWith(
          expression: event.expression ?? item.expression,
          result: event.result ?? item.result,
          position: event.position ?? item.position,
        );
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
    _isDirty = true;
  }

  void _onDeleteItem(DeleteSalesCalcItem event, Emitter<SalesCalcState> emit) {
    final updatedItems =
        state.items.where((item) => item.id != event.id).toList();
    emit(state.copyWith(items: updatedItems));
    _isDirty = true;
  }

  void _onUpdateLabel(UpdateItemLabel event, Emitter<SalesCalcState> emit) {
    final updatedItems = state.items.map((item) {
      if (item.id == event.id) {
        return item.copyWith(label: event.label);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
    _isDirty = true;
  }

  void _onUpdateLocal(
      UpdateLocalExpression event, Emitter<SalesCalcState> emit) {
    final updatedItems = state.items.map((item) {
      if (item.id == event.id && item.productUnitId == null) {
        return item.copyWith(
            expression: event.expression, result: event.result);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
    _isDirty = true;
  }

  void _onUpdateProduct(UpdateItemProduct event, Emitter<SalesCalcState> emit) {
    final updatedItems = state.items.map((item) {
      if (item.id == event.id && item.productUnitId == null) {
        return item.copyWith(
          productId: event.productId,
          label: event.label ?? item.label,
        );
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
    _isDirty = true;
  }

  void _onStructuredProduct(
      SetStructuredProductLine event, Emitter<SalesCalcState> emit) {
    if (!state.deductStock && !state.hasStructuredItems) return;
    final source = event.item;
    if (source.productId == null ||
        source.productUnitId == null ||
        source.currencyId == null ||
        source.unitVersion == null ||
        source.quantity == null ||
        source.unitPrice == null) {
      return;
    }
    final existing =
        state.items.where((item) => item.id == event.replacingId).firstOrNull;
    final item = source.copyWith(
        id: existing?.id ?? _localIdCounter--,
        position: existing?.position ?? state.items.length);
    emit(state.copyWith(
        items: existing == null
            ? [...state.items, item]
            : state.items
                .map((old) => old.id == existing.id ? item : old)
                .toList()));
    _isDirty = true;
  }

  // ─── Product autocomplete ──────────────────────────────────

  /// Offline product search: filters the cached catalog in memory, so
  /// suggestions are instant and typing never spams the backend. The
  /// only network hit is the catalog fetch itself (first search after
  /// load or TTL expiry). The monotonic sequence still guards against
  /// a slow catalog fetch finishing after a newer query.
  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<SalesCalcState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        productSuggestions: const [],
        productSearchQuery: '',
        isSearchingProducts: false,
        clearProductSearchLineId: true,
      ));
      return;
    }

    emit(state.copyWith(
      productSearchQuery: query,
      isSearchingProducts: true,
      productSearchLineId: event.lineId,
    ));

    final mySeq = ++_productSearchSeq;
    List<ShopProduct> catalog;
    try {
      catalog = await _getProductCatalog();
    } catch (_) {
      catalog = const [];
    }
    if (mySeq != _productSearchSeq) return; // stale
    if (state.productSearchQuery != query) return;
    if (emit.isDone) return;

    // Prefix matches first, then substring matches — capped like the
    // old backend search.
    final q = query.toLowerCase();
    final prefix = <ShopProduct>[];
    final substr = <ShopProduct>[];
    for (final p in catalog) {
      final name = p.name.toLowerCase();
      if (name.startsWith(q)) {
        prefix.add(p);
      } else if (name.contains(q)) {
        substr.add(p);
      }
    }
    final results = [...prefix, ...substr].take(20).toList();

    emit(state.copyWith(
      productSuggestions: results,
      isSearchingProducts: false,
    ));
  }

  /// Browse mode: the Nomi field is focused but empty — offer the
  /// catalog proactively (names only in the UI; productSearchQuery
  /// stays empty, which is what flags browse rendering). Picking one
  /// routes through the same _onPickProduct flow as typed search.
  Future<void> _onBrowseProducts(
    BrowseProducts event,
    Emitter<SalesCalcState> emit,
  ) async {
    final mySeq = ++_productSearchSeq;
    List<ShopProduct> catalog;
    try {
      catalog = await _getProductCatalog();
    } catch (_) {
      catalog = const [];
    }
    if (mySeq != _productSearchSeq) return; // a typed search superseded us
    if (emit.isDone) return;
    if (catalog.isEmpty) return;

    emit(state.copyWith(
      productSuggestions: catalog.take(20).toList(),
      productSearchQuery: '',
      isSearchingProducts: false,
      productSearchLineId: event.lineId,
    ));
  }

  void _onClearSuggestions(
    ClearProductSuggestions event,
    Emitter<SalesCalcState> emit,
  ) {
    // Invalidate any in-flight catalog-backed search.
    _productSearchSeq++;
    emit(state.copyWith(
      productSuggestions: const [],
      productSearchQuery: '',
      isSearchingProducts: false,
      clearProductSearchLineId: true,
    ));
  }
}
