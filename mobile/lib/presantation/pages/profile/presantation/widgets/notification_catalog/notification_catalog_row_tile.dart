import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/localization/l10n/app_localizations.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

import 'notification_catalog_models.dart';

/// One catalog row: a switch, a time, or a link to a detail screen.
class NotificationCatalogRowTile extends StatelessWidget {
  const NotificationCatalogRowTile({
    super.key,
    required this.row,
    required this.groupTitle,
    required this.enabled,
    required this.saving,
    required this.canOpen,
    required this.onChanged,
    required this.onOpen,
  });

  final NotificationCatalogRow row;
  final String groupTitle;

  /// False while offline or while another row is saving.
  final bool enabled;
  final bool saving;

  /// Whether this build knows the row's detail screen.
  final bool canOpen;
  final ValueChanged<Object> onChanged;
  final VoidCallback onOpen;

  String? _subtitle(AppLocalizations? l) {
    switch (row.lockedReason) {
      case 'owner_only':
        return l?.notif_catalog_owner_only ??
            "Faqat do'kon egasi o'zgartira oladi";
      case 'mandatory':
        return row.description ?? l?.notif_catalog_mandatory ?? 'Doim yoqiq';
    }
    return row.description;
  }

  Future<void> _pickTime(BuildContext context) async {
    final raw = row.value is String ? row.value as String : '';
    final parts = raw.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 20,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    onChanged('$hh:$mm');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalization.getText(context);
    final subtitle = _subtitle(l);
    final interactive = enabled && row.editable;
    final on = row.value == true;

    Widget? trailing;
    if (saving) {
      trailing = SizedBox(
        width: 22.w,
        height: 22.w,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(context.palette.accent),
        ),
      );
    } else if (row.kind == 'toggle') {
      trailing = Transform.scale(
        scale: 0.85,
        child: Switch.adaptive(
          value: on,
          onChanged: interactive ? (v) => onChanged(v) : null,
          activeThumbColor: Theme.of(context).primaryColor,
        ),
      );
    } else if (row.kind == 'time') {
      trailing = AppText(
        row.value is String ? row.value as String : '--:--',
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: interactive ? context.palette.accent : AppColors.greyColor3,
      );
    }

    final showChevron = canOpen && row.route != null;
    final VoidCallback? onTap = row.kind == 'time'
        ? (interactive ? () => _pickTime(context) : null)
        : (showChevron ? onOpen : null);

    final state = row.kind == 'toggle'
        ? (on
            ? (l?.notif_catalog_state_on ?? 'yoqiq')
            : (l?.notif_catalog_state_off ?? "o'chiq"))
        : null;

    return Semantics(
      label: [groupTitle, row.title, if (state != null) state].join(', '),
      excludeSemantics: row.kind != 'toggle',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        row.title,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      if (subtitle != null) ...[
                        2.verticalSpace,
                        AppText(
                          subtitle,
                          fontSize: 12.sp,
                          color: context.isDark
                              ? context.palette.textSecondary
                              : AppColors.greyColor3,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[8.horizontalSpace, trailing],
                if (showChevron)
                  Icon(
                    Icons.chevron_right,
                    size: 20.sp,
                    color: AppColors.greyColor3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
