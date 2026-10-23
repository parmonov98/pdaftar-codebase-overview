import '../../domain/entities/sales_calc_item.dart';
import '../../domain/entities/sales_calc_list.dart';
import '../../domain/entities/shop_product.dart';
import '../../domain/repositories/i_sales_calc_repository.dart';
import '../datasources/sales_calc_remote_data_source.dart';

class SalesCalcRepositoryImpl implements ISalesCalcRepository {
  final SalesCalcRemoteDataSource _dataSource;

  SalesCalcRepositoryImpl(this._dataSource);

  @override
  Future<List<SalesCalcList>> getLists(int shopId, {int? days}) =>
      _dataSource.getLists(shopId, days: days);

  @override
  Future<SalesCalcList> createList(int shopId, {String? name}) => _dataSource.createList(shopId, name: name);

  @override
  Future<SalesCalcList> renameList(int shopId, int listId, String name) => _dataSource.renameList(shopId, listId, name);

  @override
  Future<void> deleteList(int shopId, int listId) => _dataSource.deleteList(shopId, listId);

  @override
  Future<int> cloneList(int shopId, int listId) => _dataSource.cloneList(shopId, listId);

  @override
  Future<void> setListClient(int shopId, int listId, int clientId) =>
      _dataSource.setListClient(shopId, listId, clientId);

  @override
  Future<List<SalesCalcItem>> getItems(int shopId, int listId) => _dataSource.getItems(shopId, listId);

  @override
  Future<SalesCalcItem> createItem(
    int shopId,
    int listId,
    String expression,
    double result, {
    String? label,
    int? productId,
  }) =>
      _dataSource.createItem(
        shopId,
        listId,
        expression,
        result,
        label: label,
        productId: productId,
      );

  @override
  Future<SalesCalcItem> updateItem(
    int shopId,
    int id, {
    String? expression,
    double? result,
    int? position,
    String? label,
    int? productId,
  }) =>
      _dataSource.updateItem(
        shopId,
        id,
        expression: expression,
        result: result,
        position: position,
        label: label,
        productId: productId,
      );

  @override
  Future<void> deleteItem(int shopId, int id) => _dataSource.deleteItem(shopId, id);

  @override
  Future<void> batchSync(int shopId, int listId, List<Map<String, dynamic>> items,
          {String? priceTier}) =>
      _dataSource.batchSync(shopId, listId, items, priceTier: priceTier);

  @override
  Future<List<ShopProduct>> searchProducts(int shopId, String query, {int limit = 20}) =>
      _dataSource.searchProducts(shopId, query, limit: limit);

  @override
  Future<ShopProduct> createProduct(
    int shopId, {
    required String name,
    double? price,
    int? currencyId,
  }) =>
      _dataSource.createProduct(
        shopId,
        name: name,
        price: price,
        currencyId: currencyId,
      );
}
