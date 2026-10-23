import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

import 'notification_catalog_controller.dart';
import 'notification_catalog_models.dart';
import 'notification_catalog_row_tile.dart';

/// The server-driven groups of Profil → Bildirishnomalar (Trello #712).
///
/// Renders whatever the backend's catalog lists. Link rows whose screen this
/// build doesn't know ([canOpenRoute] false and no switch) are hidden, so a
/// future row never shows up as a dead end.
class NotificationCatalogSection extends StatelessWidget {
  const NotificationCatalogSection({
    super.key,
    required this.controller,
    required this.canOpenRoute,
    required this.onOpenRoute,
    this.onError,
  });

  final NotificationCatalogController controller;
  final bool Function(String route) canOpenRoute;
  final void Function(String route, int? shopId) onOpenRoute;

  /// Shows a refused write; defaults to the app's toast.
  final void Function(String message)? onError;

  bool _visible(NotificationCatalogRow row) =>
      row.kind != 'link' || (row.route != null && canOpenRoute(row.route!));

  Future<void> _save(
    BuildContext context,
    NotificationCatalogRow row,
    Object value,
  ) async {
    final fallback = AppLocalization.getText(context)?.something_went_wrong ??
        'Xatolik yuz berdi';
    final error = await controller.save(row, value);
    if (error != null) {
      final message = error.isEmpty ? fallback : error;
      final show = onError;
      if (show != null) {
        show(message);
      } else {
        AppHelpers.showSnackBarInfo(message: message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l = AppLocalization.getText(context);
    final catalog = controller.catalog;

    if (catalog == null) {
      if (controller.loading || !controller.attempted) {
        return const _CatalogSkeleton();
      }
      return _Notice(
        icon: controller.offline ? Icons.wifi_off : Icons.error_outline,
        text: controller.offline
            ? (l?.no_internet_connection ?? "Internet aloqasi yo'q")
            : (l?.notif_catalog_load_failed ??
                "Bildirishnoma sozlamalarini yuklab bo'lmadi"),
        actionLabel: l?.retry ?? "Qayta urinib ko'rish",
        onAction: controller.load,
      );
    }

    final groups = [
      for (final g in catalog.groups) (g, g.rows.where(_visible).toList()),
    ].where((e) => e.$2.isNotEmpty).toList();
    final editable = !controller.offline && controller.savingKey == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.offline)
          _Notice(
            icon: Icons.wifi_off,
            text: l?.notif_catalog_offline ??
                "Internet yo'q. Oxirgi yuklangan sozlamalar ko'rsatilmoqda.",
            actionLabel: l?.retry ?? "Qayta urinib ko'rish",
            onAction: controller.load,
          )
        else if (controller.loadFailed)
          _Notice(
            icon: Icons.error_outline,
            text: l?.notif_catalog_load_failed ??
                "Bildirishnoma sozlamalarini yuklab bo'lmadi",
            actionLabel: l?.retry ?? "Qayta urinib ko'rish",
            onAction: controller.load,
          ),
        if (catalog.shops.length > 1) _shopSelector(context, catalog),
        if (groups.isEmpty)
          Padding(
            padding: EdgeInsets.all(16.w),
            child: AppText(
              l?.notif_catalog_empty ?? "Hozircha sozlamalar yo'q",
              fontSize: 13.sp,
              color: AppColors.greyColor3,
              textAlign: TextAlign.center,
            ),
          ),
        for (final (group, rows) in groups) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 6.h),
            child: AppText(
              group.title.toUpperCase(),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.greyColor3,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                for (final row in rows)
                  NotificationCatalogRowTile(
                    key: ValueKey('notif-row-${row.key}'),
                    row: row,
                    groupTitle: group.title,
                    enabled: editable,
                    saving: controller.savingKey == row.key,
                    canOpen: row.route != null && canOpenRoute(row.route!),
                    onChanged: (v) => _save(context, row, v),
                    onOpen: () => onOpenRoute(row.route!, catalog.shop?.id),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _shopSelector(BuildContext context, NotificationCatalog catalog) {
    final l = AppLocalization.getText(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Row(
        children: [
          AppText(
            '${l?.notif_catalog_shop ?? "Do'kon"}: ',
            fontSize: 14.sp,
            color: AppColors.greyColor3,
          ),
          Expanded(
            child: DropdownButton<int>(
              key: const ValueKey('notif-shop-selector'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              value: catalog.shop?.id,
              onChanged: controller.loading || controller.savingKey != null
                  ? null
                  : (id) {
                      if (id != null && id != catalog.shop?.id) {
                        controller.selectShop(id);
                      }
                    },
              items: [
                for (final s in catalog.shops)
                  DropdownMenuItem(
                    value: s.id,
                    child: AppText(
                      s.name,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, size: 18.sp, color: context.palette.accent),
          ),
          8.horizontalSpace,
          // Text and action stack, so a long translation or a large font
          // never pushes the button off a 375pt screen.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(text, fontSize: 12.sp),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onAction,
                    child: AppText(actionLabel,
                        fontSize: 12.sp, color: context.palette.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final bar = Theme.of(context).dividerColor.withValues(alpha: 0.4);
    return Padding(
      key: const ValueKey('notif-catalog-skeleton'),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              height: 44,
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: bar,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
        ],
      ),
    );
  }
}
