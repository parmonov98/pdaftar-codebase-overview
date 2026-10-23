import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/core/imports/imports.dart';

class AppCardWidget extends StatelessWidget {
  final String? title;
  final String? leadingIconSvg;
  final String? name;
  final bool isDoubleSection;
  final bool isTripleSection;
  final bool isNotificationTile;
  final int? notificationCount;
  final String? secondLeadingIcon;
  final String? secondName;
  final String? thirdLeadingIcon;
  final String? thirdName;
  final bool isLogOut;
  final bool? isNewLabel;
  final bool? isThirdNewLabel;
  final Function()? onTap;
  final Function()? onSecondaryTap;
  final Function()? onTertiaryTap;

  const AppCardWidget({
    super.key,
    required this.title,
    required this.leadingIconSvg,
    required this.name,
    this.isDoubleSection = false,
    this.isTripleSection = false,
    this.isNotificationTile = false,
    this.notificationCount,
    this.secondLeadingIcon,
    this.secondName,
    this.thirdLeadingIcon,
    this.thirdName,
    this.isLogOut = false,
    this.isNewLabel = false,
    this.isThirdNewLabel = false,
    this.onTap,
    this.onSecondaryTap,
    this.onTertiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isLogOut
            ? 12.h.verticalSpace
            : Padding(
                padding: EdgeInsets.all(8.0.sp),
                child: AppText(title ?? "", color: context.palette.textSecondary,),
              ),
        Container(
          decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
          alignment: Alignment.center,
          height: isTripleSection ? 186.h : (isDoubleSection ? 128.h : 70.h),
          child: isTripleSection
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomProfileLisTileWidget(
                        name: name,
                        leadingSvgIcon: leadingIconSvg,
                        isNewLabel: isNewLabel,
                        onTap: onTap),
                    CustomProfileLisTileWidget(
                        name: secondName,
                        leadingSvgIcon: secondLeadingIcon,
                        onTap: onSecondaryTap),
                    CustomProfileLisTileWidget(
                        name: thirdName,
                        leadingSvgIcon: thirdLeadingIcon,
                        isNewLabel: isThirdNewLabel,
                        onTap: onTertiaryTap),
                  ],
                )
              : isDoubleSection
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomProfileLisTileWidget(
                            name: name,
                            leadingSvgIcon: leadingIconSvg,
                            onTap: onTap),
                        CustomProfileLisTileWidget(
                            name: secondName,
                            leadingSvgIcon: secondLeadingIcon,
                            onTap: onSecondaryTap)
                      ],
                    )
                  : CustomProfileLisTileWidget(
                      isNewLabel: isNewLabel,
                      notificationCount: notificationCount,
                      name: name,
                      leadingSvgIcon: leadingIconSvg,
                      onTap: onTap,
                      isLogOut: isLogOut,
                    ),
        ),
      ],
    );
  }
}
