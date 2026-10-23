import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/constants/app_owner_status.dart';
import 'package:pdaftaruz/core/imports/imports.dart';

class ProfileSettingsFiveSection extends StatefulWidget {
  final int? notificationCount;
  final int? newsCount;
  final int? businessCount;
  const ProfileSettingsFiveSection({
    this.notificationCount,
    this.newsCount,
    this.businessCount,
    super.key});

  @override
  State<ProfileSettingsFiveSection> createState() =>
      _ProfileSettingsFiveSectionState();
}

class _ProfileSettingsFiveSectionState
    extends State<ProfileSettingsFiveSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0.sp),
          child: AppText(
            "${AppLocalization.getText(context)?.profile_nav}",
            color: context.palette.textSecondary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CustomProfileLisTileWidget(
                name: "${AppLocalization.getText(context)?.profile_settings}",
                leadingSvgIcon: Assets.profileIconSvg,
                onTap: () {
                  AppNavigator.push(const ProfileSettingsRoute());
                }),

            AppOwnerStatus.status(LocalStorage.instance.getUserType()) ?
            CustomProfileLisTileWidget(
                name: "${AppLocalization.getText(context)?.my_business}",
                leadingSvgIcon: Assets.businessSvg,
                notificationCount: widget.businessCount,
                isNotificationTile: true,
                onTap: () {
                  AppNavigator.push(BusinessControlRoute());
                }) : const SizedBox.shrink(),

            CustomProfileLisTileWidget(
                notificationCount: widget.notificationCount,
                name: AppLocalization.getText(context)?.notification,
                isNotificationTile: true,
                leadingSvgIcon: Assets.notificationIconSvg,
                onTap: () {
                  // Navigate to the Notifications tab (index 0)
                  AppNavigator.push(NotificationRoute(initialTabIndex: 0));
                }),

            CustomProfileLisTileWidget(
                notificationCount: widget.newsCount,
                name: AppLocalization.getText(context)?.news,
                isNotificationTile: true,
                leadingSvgIcon: Assets.infoSvg,
                onTap: () {
                  // Navigate to the News tab (index 1)
                  AppNavigator.push(NotificationRoute(initialTabIndex: 1));
                }),

            // CustomProfileLisTileWidget(
            //     name: "Ilovani baholash",
            //     leadingSvgIcon: Assets.infoSvg,
            //     onTap: () {
            //       if (context.mounted) {
            //         ReviewService.showReviewDialog(context);
            //       }
            //     }),

            // CustomProfileLisTileWidget(
            //     name: AppLocalization.getText(context)?.balance_history ?? "",
            //     leadingSvgIcon: Assets.dollarIconSvg,
            //     onTap: () {
            //       AppNavigator.push(BalanceHistoryRoute());
            //     }),

          ]),
        ),
      ],
    );
  }
}
