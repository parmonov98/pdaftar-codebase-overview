import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// One tappable row inside a [SettingsSection].
///
/// Renders a leading SVG (square), a title, an optional notification badge,
/// an optional "Yangi" tag, and a chevron. Use [destructive] for the sign-out
/// row (renders title + leading icon in red).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    required this.iconAsset,
    this.onTap,
    this.notificationCount,
    this.isNew = false,
    this.destructive = false,
    this.trailing,
    this.subtitle,
  });

  final String title;

  /// A quiet second line under [title].
  final String? subtitle;
  final String iconAsset;
  final VoidCallback? onTap;
  final int? notificationCount;
  final bool isNew;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final iconBgColor = destructive
        ? AppColors.red.withValues(alpha: 0.10)
        : AppColors.primaryColor.withValues(alpha: 0.08);
    final iconColor =
        destructive ? AppColors.red : context.palette.accent;
    final titleColor = destructive
        ? AppColors.red
        : Theme.of(context).textTheme.titleLarge?.color;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: CustomSvgWidgetAsset(
                  iconAsset,
                  size: 20.w,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                      fontFamily: 'Gilroy',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).hintColor,
                        fontFamily: 'Gilroy',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isNew) _NewBadge(),
            if (notificationCount != null && notificationCount! > 0) ...[
              SizedBox(width: 6.w),
              _CountBadge(count: notificationCount!),
            ],
            if (trailing != null) ...[
              SizedBox(width: 6.w),
              trailing!,
            ] else if (!destructive) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 22.sp,
                color: Theme.of(context).hintColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Yangi',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }
}
