import 'package:dio/dio.dart';
import 'package:pdaftaruz/core/handlers/http_service.dart';
import 'package:pdaftaruz/injection.dart';

import 'notification_catalog_models.dart';

/// What a catalog call came back with.
///
/// [unsupported]: an older backend with no such route (404/405) — the page
/// falls back to its pre-#712 layout. [offline]: no network or a timeout.
/// Read from the raw status code: the app's network helper maps 405 to 500.
class NotificationCatalogResult<T> {
  final T? data;
  final bool unsupported;
  final bool offline;
  final String? error;

  const NotificationCatalogResult.ok(this.data)
      : unsupported = false,
        offline = false,
        error = null;
  const NotificationCatalogResult.unsupported()
      : data = null,
        unsupported = true,
        offline = false,
        error = null;
  const NotificationCatalogResult.offline()
      : data = null,
        unsupported = false,
        offline = true,
        error = null;
  const NotificationCatalogResult.failed(this.error)
      : data = null,
        unsupported = false,
        offline = false;

  bool get isOk => !unsupported && !offline && error == null;
}

class NotificationCatalogRepository {
  NotificationCatalogRepository({Dio? client}) : _client = client;

  final Dio? _client;

  /// Last catalog per shop, so going offline shows the last known values.
  static final Map<int, NotificationCatalog> _lastLoaded = {};

  NotificationCatalog? cached(int? shopId) => _lastLoaded[shopId ?? 0];

  Dio get _dio => _client ?? inject<HttpService>().client(requireAuth: true);

  static const _path = 'api/mobile/notification-settings';

  Future<NotificationCatalogResult<NotificationCatalog>> load(
    int? shopId,
  ) async {
    final result = await _call(
      () => _dio.get(
        _path,
        queryParameters: shopId == null ? null : {'shop_id': shopId},
      ),
      NotificationCatalog.fromJson,
    );
    final catalog = result.data;
    if (catalog != null) {
      _lastLoaded[shopId ?? 0] = catalog;
      if (catalog.shop != null) _lastLoaded[catalog.shop!.id] = catalog;
    }
    return result;
  }

  /// Returns the value the server stored.
  Future<NotificationCatalogResult<Object?>> update(
    String key,
    Object value,
    int? shopId,
  ) {
    return _call(
      () => _dio.patch(
        _path,
        data: {
          'key': key,
          'value': value,
          if (shopId != null) 'shop_id': shopId,
        },
      ),
      (data) => data['value'],
    );
  }

  Future<NotificationCatalogResult<T>> _call<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic> data) parse,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is! Map || body['data'] is! Map) {
        return const NotificationCatalogResult.failed(null);
      }
      return NotificationCatalogResult.ok(
        parse(Map<String, dynamic>.from(body['data'] as Map)),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) {
        return const NotificationCatalogResult.unsupported();
      }
      if (e.response == null) {
        return const NotificationCatalogResult.offline();
      }
      final body = e.response?.data;
      final message = body is Map ? body['message']?.toString() : null;
      return NotificationCatalogResult.failed(
        (message == null || message.isEmpty) ? null : message,
      );
    } catch (_) {
      return const NotificationCatalogResult.failed(null);
    }
  }
}
