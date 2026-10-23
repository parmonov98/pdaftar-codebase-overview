import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/core/imports/imports.dart';

class CustomProfileLisTileWidget extends StatelessWidget {
  final String? name;
  final String? leadingSvgIcon;
  final int? offlineActionLength;
  final bool isLogOut;
  final double? size;
  final Function? onTap;
  final bool? isNotificationTile;
  final int? notificationCount;
  final bool? isNewLabel;

  const CustomProfileLisTileWidget(
      {required this.name,
      required this.leadingSvgIcon,
      required this.onTap,
      this.offlineActionLength,
        this.size,
      this.isLogOut = false,
      this.isNotificationTile = false,
      this.isNewLabel = false,
      this.notificationCount,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if(isNewLabel == true)
        Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 2),
              decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(topRight: Radius.circular(9))
              ),
          child: AppText("${AppLocalization.getText(context)?.new_label}", fontSize: 10.sp, color: AppColors.white,),
        )),
        GestureDetector(
          onTap: () {
            onTap?.call();
          },
          child: ListTile(
            minTileHeight: 60.h,
            leading: CustomSvgWidgetAsset(
              leadingSvgIcon ?? "",
              size: size ?? 0.035.sh,
              color: isLogOut ? (context.isDark ? AppColors.redOnDark : AppColors.red) :context.palette.textSecondary,
            ),
            title: AppText(
              name ?? "",
              color: isLogOut ? (context.isDark ? AppColors.redOnDark : AppColors.red) : Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.w500,
            ),
            trailing: isLogOut ? const SizedBox.shrink() : (offlineActionLength != 0 && offlineActionLength != null)
                ? CircleAvatar(
              radius: 10.sp,
              backgroundColor: AppColors.errorColor,
              child:  AppText(
                '$offlineActionLength',
                color: AppColors.white,
              ),
            )
                : Row(
              spacing: 10,
              mainAxisSize: MainAxisSize.min,
              children: [
                isNotificationTile ?? false ?
                notificationCount != 0 ?
                Badge.count(
                  textStyle: TextStyle(fontSize: 11.sp),
                  backgroundColor: AppColors.primaryColor,
                  count: notificationCount ?? 0,
                ) : const SizedBox() : const SizedBox(),
                Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
