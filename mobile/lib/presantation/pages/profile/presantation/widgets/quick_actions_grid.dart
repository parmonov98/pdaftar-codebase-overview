import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// 2×2 grid of high-intent shortcuts on the Profile screen.
///
/// Sits between the wallet strip and the settings sections — surfaces the
/// actions users most often dig into the menu for (top up, buy SMS, refer
/// a friend, jump to my businesses) so they're one tap away.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: GridView.builder(
        // Explicit: without it the grid pads itself with MediaQuery's
        // bottom inset, which inside a tab is the whole glass nav (#616) —
        // ~100pt of blank space under the tiles (#619).
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 3.4,
        ),
        itemBuilder: (context, i) => _ActionTile(action: actions[i]),
      ),
    );
  }
}

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: isDark
            ? BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: action.onTap,
        child: Stack(
          children: [
            Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(action.icon,
                    size: 16.sp, color: context.palette.accent),
              ),
              SizedBox(width: 8.w),
              Expanded(
                // scaleDown keeps the label on ONE line: it shrinks to fit
                // instead of wrapping (which left a lone 'lar' under
                // 'Foydalanuvchi') or ellipsising the word away.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    action.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            ],
              ),
            ),
            // Badge floats top-right so the label owns the tile's full
            // width — inline it stole room from an already tight one-line
            // label.
            if (action.badgeCount != null && action.badgeCount! > 0)
              Positioned(
                top: 5.h,
                right: 6.w,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    action.badgeCount! > 99 ? '99+' : '${action.badgeCount}',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
