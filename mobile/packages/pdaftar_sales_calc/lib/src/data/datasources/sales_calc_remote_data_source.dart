import 'package:dio/dio.dart';
import 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_sold_marks.dart';
import '../../domain/entities/sales_calc_list.dart';
import '../../domain/entities/shop_product.dart';
import '../models/sales_calc_item_model.dart';

abstract class SalesCalcRemoteDataSource {
  // Lists
  Future<List<SalesCalcList>> getLists(int shopId, {int? days});
  Future<void> setListClient(int shopId, int listId, int clientId);
  Future<SalesCalcList> createList(int shopId, {String? name});
  Future<SalesCalcList> renameList(int shopId, int listId, String name);
  Future<void> deleteList(int shopId, int listId);
  Future<int> cloneList(int shopId, int listId);

  // Items
  Future<List<SalesCalcItemModel>> getItems(int shopId, int listId);
  Future<SalesCalcItemModel> createItem(
    int shopId,
    int listId,
    String expression,
    double result, {
    String? label,
    int? productId,
  });
  Future<SalesCalcItemModel> updateItem(
    int shopId,
    int itemId, {
    String? expression,
    double? result,
    int? position,
    String? label,
    int? productId,
  });
  Future<void> deleteItem(int shopId, int itemId);
  Future<void> batchSync(int shopId, int listId, List<Map<String, dynamic>> items,
      {String? priceTier});

  // Products (for the Nomi autocomplete)
  Future<List<ShopProduct>> searchProducts(int shopId, String query, {int limit});
  Future<ShopProduct> createProduct(
    int shopId, {
    required String name,
    double? price,
    int? currencyId,
  });
}

class SalesCalcRemoteDataSourceImpl implements SalesCalcRemoteDataSource {
  final Dio _dio;

  SalesCalcRemoteDataSourceImpl(this._dio);

  String _listsPath(int shopId) => '/api/mobile/shops/$shopId/sales-calc-lists';
  String _itemsPath(int shopId) => '/api/mobile/shops/$shopId/sales-calc-items';
  String _productsPath(int shopId) => '/api/mobile/shops/$shopId/products';

  @override
  Future<List<SalesCalcList>> getLists(int shopId, {int? days}) async {
    final response = await _dio.get(
      _listsPath(shopId),
      // days > 0 → backend returns only lists touched in the last N
      // days; omitted → all lists (legacy behavior, "Hammasi").
      queryParameters: (days != null && days > 0) ? {'days': days} : null,
    );
    final data = response.data['data'] as List? ?? [];
    return data.map((json) => _parseList(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<SalesCalcList> createList(int shopId, {String? name}) async {
    final response = await _dio.post(_listsPath(shopId), data: {'name': name});
    return _parseList(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<SalesCalcList> renameList(int shopId, int listId, String name) async {
    final response = await _dio.put('${_listsPath(shopId)}/$listId', data: {'name': name});
    return _parseList(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteList(int shopId, int listId) async {
    await _dio.delete('${_listsPath(shopId)}/$listId');
  }

  @override
  Future<void> setListClient(int shopId, int listId, int clientId) async {
    await _dio.put('${_listsPath(shopId)}/$listId', data: {'client_id': clientId});
  }

  @override
  Future<int> cloneList(int shopId, int listId) async {
    final response = await _dio.post('${_listsPath(shopId)}/$listId/clone');
    final data = response.data['data'] as Map<String, dynamic>?;
    final id = data?['id'] as int?;
    if (id == null) {
      throw StateError('Clone response missing data.id');
    }
    return id;
  }

  SalesCalcList _parseList(Map<String, dynamic> json) {
    return SalesCalcList(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString(),
      itemsCount: json['items_count'] as int? ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      clientId: json['client_id'] as int?,
      clientName: json['client_name']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      lastSale: SalesCalcSoldMark.fromJson(json['last_sale']),
    );
  }

  @override
  Future<List<SalesCalcItemModel>> getItems(int shopId, int listId) async {
    final response = await _dio.get('${_listsPath(shopId)}/$listId/items');
    final data = response.data['data'] as List? ?? [];
    return data.map((json) => SalesCalcItemModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<SalesCalcItemModel> createItem(
    int shopId,
    int listId,
    String expression,
    double result, {
    String? label,
    int? productId,
  }) async {
    final response = await _dio.post(
      '${_listsPath(shopId)}/$listId/items',
      data: {
        'expression': expression,
        'result': result,
        if (label != null) 'label': label,
        if (productId != null) 'product_id': productId,
      },
    );
    return SalesCalcItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<SalesCalcItemModel> updateItem(
    int shopId,
    int itemId, {
    String? expression,
    double? result,
    int? position,
    String? label,
    int? productId,
  }) async {
    final data = <String, dynamic>{};
    if (expression != null) data['expression'] = expression;
    if (result != null) data['result'] = result;
    if (position != null) data['position'] = position;
    if (label != null) data['label'] = label;
    if (productId != null) data['product_id'] = productId;

    final response = await _dio.put('${_itemsPath(shopId)}/$itemId', data: data);
    return SalesCalcItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteItem(int shopId, int itemId) async {
    await _dio.delete('${_itemsPath(shopId)}/$itemId');
  }

  @override
  Future<void> batchSync(int shopId, int listId, List<Map<String, dynamic>> items,
      {String? priceTier}) async {
    await _dio.put(
      '${_listsPath(shopId)}/$listId/items/batch',
      // This build sends structured unit rows back with their unit fields,
      // so a structured row missing from `items` was deleted on purpose —
      // tells the backend not to answer 409 for it.
      data: {
        'items': items,
        'structured_units_aware': true,
        // Chakana / Ulgurji (Trello #459). Absent keeps the list's tier.
        if (priceTier != null) 'price_tier': priceTier,
      },
    );
  }

  @override
  Future<List<ShopProduct>> searchProducts(
    int shopId,
    String query, {
    int limit = 20,
  }) async {
    final response = await _dio.get(
      _productsPath(shopId),
      queryParameters: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        'limit': limit,
      },
    );
    final data = response.data['data'] as List? ?? [];
    return data
        .whereType<Map>()
        .map((e) => ShopProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<ShopProduct> createProduct(
    int shopId, {
    required String name,
    double? price,
    int? currencyId,
  }) async {
    final response = await _dio.post(
      _productsPath(shopId),
      data: {
        'name': name,
        if (price != null) 'price': price,
        if (currencyId != null) 'currency_id': currencyId,
      },
    );
    return ShopProduct.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
