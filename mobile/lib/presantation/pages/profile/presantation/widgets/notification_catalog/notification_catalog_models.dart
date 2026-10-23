/// Trello #712: the server-driven "Bildirishnomalar" catalog.
///
/// The backend decides which groups and rows exist, their labels (already in
/// the app's language), current values and whether they can be changed, so a
/// push type can be added or switched off without an app release. Parsing is
/// tolerant: a row of a kind this build doesn't know is dropped, never shown
/// broken.
class NotificationCatalogRow {
  const NotificationCatalogRow({
    required this.key,
    required this.kind,
    required this.title,
    this.channel = 'push',
    this.scope = 'account',
    this.description,
    this.value,
    this.editable = false,
    this.lockedReason,
    this.route,
  });

  static const kinds = {'toggle', 'time', 'link', 'info'};

  final String key;
  final String kind;
  final String channel;
  final String scope;
  final String title;
  final String? description;

  /// bool for `toggle`, "HH:MM" for `time`, null for `link`/`info`.
  final Object? value;
  final bool editable;

  /// `mandatory` (always on) or `owner_only` (seller sees it read-only).
  final String? lockedReason;
  final String? route;

  bool get isShopScoped => scope == 'shop';

  static NotificationCatalogRow? tryParse(Object? json) {
    if (json is! Map) return null;
    final key = json['key'];
    final kind = json['kind'];
    final title = json['title'];
    if (key is! String || kind is! String || title is! String) return null;
    if (!kinds.contains(kind)) return null;
    final description = json['description'];
    final route = json['route'];
    final locked = json['locked_reason'];
    return NotificationCatalogRow(
      key: key,
      kind: kind,
      title: title,
      channel: json['channel']?.toString() ?? 'push',
      scope: json['scope']?.toString() ?? 'account',
      description:
          description is String && description.isNotEmpty ? description : null,
      value: json['value'],
      editable: json['editable'] == true,
      lockedReason: locked is String ? locked : null,
      route: route is String && route.isNotEmpty ? route : null,
    );
  }

  NotificationCatalogRow copyWith({Object? value}) => NotificationCatalogRow(
        key: key,
        kind: kind,
        title: title,
        channel: channel,
        scope: scope,
        description: description,
        value: value,
        editable: editable,
        lockedReason: lockedReason,
        route: route,
      );
}

class NotificationCatalogGroup {
  const NotificationCatalogGroup({
    required this.key,
    required this.title,
    required this.rows,
  });

  final String key;
  final String title;
  final List<NotificationCatalogRow> rows;
}

class NotificationCatalogShop {
  const NotificationCatalogShop({required this.id, required this.name});

  final int id;
  final String name;
}

class NotificationCatalog {
  const NotificationCatalog({
    required this.groups,
    this.shop,
    this.shops = const [],
    this.canEditShop = false,
  });

  final NotificationCatalogShop? shop;
  final List<NotificationCatalogShop> shops;
  final bool canEditShop;
  final List<NotificationCatalogGroup> groups;

  bool get isEmpty => groups.every((g) => g.rows.isEmpty);

  static NotificationCatalogShop? _shop(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! num) return null;
    return NotificationCatalogShop(
      id: id.toInt(),
      name: name?.toString() ?? '',
    );
  }

  factory NotificationCatalog.fromJson(Map<String, dynamic> json) {
    final groups = <NotificationCatalogGroup>[];
    final rawGroups = json['groups'];
    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is! Map || g['key'] is! String) continue;
        final items = g['items'];
        final rows = items is List
            ? items
                .map(NotificationCatalogRow.tryParse)
                .whereType<NotificationCatalogRow>()
                .toList()
            : <NotificationCatalogRow>[];
        if (rows.isEmpty) continue;
        groups.add(
          NotificationCatalogGroup(
            key: g['key'] as String,
            title: g['title']?.toString() ?? '',
            rows: rows,
          ),
        );
      }
    }
    final shops = json['shops'];
    return NotificationCatalog(
      shop: _shop(json['shop']),
      shops: shops is List
          ? shops.map(_shop).whereType<NotificationCatalogShop>().toList()
          : const [],
      canEditShop: json['can_edit_shop'] == true,
      groups: groups,
    );
  }

  NotificationCatalog withValue(String key, Object? value) =>
      NotificationCatalog(
        shop: shop,
        shops: shops,
        canEditShop: canEditShop,
        groups: [
          for (final g in groups)
            NotificationCatalogGroup(
              key: g.key,
              title: g.title,
              rows: [
                for (final r in g.rows)
                  r.key == key ? r.copyWith(value: value) : r,
              ],
            ),
        ],
      );
}
