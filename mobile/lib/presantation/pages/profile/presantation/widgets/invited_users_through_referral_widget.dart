import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:lottie/lottie.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class InvitedUsersThroughReferralWidget extends ConsumerStatefulWidget {
  const InvitedUsersThroughReferralWidget({super.key});

  @override
  ConsumerState<InvitedUsersThroughReferralWidget> createState() => _InvitedUsersThroughReferralWidgetState();
}

class _InvitedUsersThroughReferralWidgetState extends ConsumerState<InvitedUsersThroughReferralWidget> {

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final invitedUsers = state.invitedUsersData?.invitedUsers;

    return
      invitedUsers?.isEmpty ?? true
          ? SliverToBoxAdapter(
          child: Column(
            children: [
              //50.verticalSpace,
              Lottie.asset(Assets.noDataLottie, height: 200.sp, repeat: false),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.sp),
                child: AppText("${AppLocalization.getText(context)?.empty_invited_users}",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              50.verticalSpace,
            ],
          ))
          : SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: invitedUsers?.length,
          (context, index) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 6.sp, horizontal: 16.sp),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_outline,
                      color: context.palette.accent,
                      size: 24.sp,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppText(
                                "${invitedUsers?[index].name}",
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 4.sp),
                              decoration: BoxDecoration(
                                color: invitedUsers?[index].isRegistered ?? true ?  AppColors.successColor : Theme.of(context).disabledColor,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: AppText(
                                invitedUsers?[index].isRegistered ?? true ? "${AppLocalization.getText(context)?.registered}" : "${AppLocalization.getText(context)?.waiting}",
                                fontSize: 10.sp,
                                color: invitedUsers?[index].isRegistered ?? true ? AppColors.white : AppColors.errorColor,
                              ),
                            ),
                          ],
                        ),
                        4.verticalSpace,
                        AppText(
                          "${state.invitedUsersData?.invitedUsers?[index].phoneNumber}".format,
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
  }
}
