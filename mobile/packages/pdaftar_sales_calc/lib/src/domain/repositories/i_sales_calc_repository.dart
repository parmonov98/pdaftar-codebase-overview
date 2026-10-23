import '../entities/sales_calc_item.dart';
import '../entities/sales_calc_list.dart';
import '../entities/shop_product.dart';

abstract class ISalesCalcRepository {
  // Lists
  /// [days] > 0 limits the result to lists touched in the last N days
  /// (backend filters by updated_at); null/0 returns all lists.
  Future<List<SalesCalcList>> getLists(int shopId, {int? days});
  Future<SalesCalcList> createList(int shopId, {String? name});
  Future<SalesCalcList> renameList(int shopId, int listId, String name);
  Future<void> deleteList(int shopId, int listId);

  /// Clone an existing list into a frozen snapshot. Used by the
  /// host's "Save as debt" flow: returns the new list id, which
  /// becomes the debt's `sales_calc_list_id` so the receipt can
  /// re-render the line items long after the live list is cleared.
  Future<int> cloneList(int shopId, int listId);

  /// Stamp the client a sale was saved to onto its WORKING list (the
  /// frozen receipt clone is linked via the debt instead). Backs the
  /// client filter in the lists browser.
  Future<void> setListClient(int shopId, int listId, int clientId);

  // Items
  Future<List<SalesCalcItem>> getItems(int shopId, int listId);
  Future<SalesCalcItem> createItem(
    int shopId,
    int listId,
    String expression,
    double result, {
    String? label,
    int? productId,
  });
  Future<SalesCalcItem> updateItem(
    int shopId,
    int id, {
    String? expression,
    double? result,
    int? position,
    String? label,
    int? productId,
  });
  Future<void> deleteItem(int shopId, int id);

  /// [priceTier] (`retail` | `wholesale`) says which price the sale sells
  /// at; omitted leaves the list's tier as it is.
  Future<void> batchSync(int shopId, int listId, List<Map<String, dynamic>> items,
      {String? priceTier});

  // Products — backs the calculator's Nomi autocomplete.
  Future<List<ShopProduct>> searchProducts(int shopId, String query, {int limit});
  Future<ShopProduct> createProduct(
    int shopId, {
    required String name,
    double? price,
    int? currencyId,
  });
}
