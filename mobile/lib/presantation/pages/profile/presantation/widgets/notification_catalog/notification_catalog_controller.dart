import 'package:flutter/foundation.dart';

import 'notification_catalog_models.dart';
import 'notification_catalog_repository.dart';

/// State of the Bildirishnomalar catalog section (Trello #712).
class NotificationCatalogController extends ChangeNotifier {
  NotificationCatalogController({
    required NotificationCatalogRepository repository,
    int? initialShopId,
  })  : _repository = repository,
        _shopId = initialShopId;

  final NotificationCatalogRepository _repository;
  int? _shopId;

  NotificationCatalog? catalog;
  bool loading = false;

  /// Older backend without the endpoint: the page shows its old layout.
  bool unsupported = false;

  /// Last load hit no network; [catalog] (if any) is the last known one and
  /// every control is read-only until a reload succeeds.
  bool offline = false;
  bool loadFailed = false;

  /// False until the first load finished: the section shows its skeleton,
  /// not an error, before anything was asked.
  bool attempted = false;
  String? savingKey;
  bool _disposed = false;

  int? get shopId => catalog?.shop?.id ?? _shopId;

  Future<void> load({int? shopId}) async {
    if (loading) return;
    if (shopId != null) _shopId = shopId;
    loading = true;
    loadFailed = false;
    _notify();

    final result = await _repository.load(_shopId);
    if (_disposed) return;

    loading = false;
    attempted = true;
    unsupported = result.unsupported;
    offline = result.offline;
    if (result.data != null) {
      catalog = result.data;
      offline = false;
    } else {
      catalog ??= _repository.cached(_shopId);
      loadFailed = !result.unsupported && !result.offline;
    }
    _notify();
  }

  Future<void> selectShop(int id) => load(shopId: id);

  /// Optimistic write; rolls back and returns the error text (or '' for a
  /// generic failure) when the server refuses. Null on success.
  Future<String?> save(NotificationCatalogRow row, Object value) async {
    final current = catalog;
    if (current == null || savingKey != null || offline) return null;
    final previous = row.value;
    savingKey = row.key;
    catalog = current.withValue(row.key, value);
    _notify();

    final result = await _repository.update(
      row.key,
      value,
      row.isShopScoped ? current.shop?.id : null,
    );
    if (_disposed) return null;

    savingKey = null;
    if (result.isOk) {
      catalog = catalog?.withValue(row.key, result.data ?? value);
      _notify();
      return null;
    }
    catalog = catalog?.withValue(row.key, previous);
    if (result.offline) offline = true;
    _notify();
    return result.error ?? '';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
