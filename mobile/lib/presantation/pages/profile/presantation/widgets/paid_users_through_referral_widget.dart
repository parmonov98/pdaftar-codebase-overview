import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:lottie/lottie.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class PaidUsersThroughReferralWidget extends ConsumerStatefulWidget {
  const PaidUsersThroughReferralWidget({super.key});

  @override
  ConsumerState<PaidUsersThroughReferralWidget> createState() => _PaidUsersThroughReferralWidgetState();
}

class _PaidUsersThroughReferralWidgetState extends ConsumerState<PaidUsersThroughReferralWidget>{


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return state.paidUsersData?.invitedUsers?.isEmpty ?? true
        ? SliverToBoxAdapter(
          child: Column(
            children: [
              Lottie.asset(Assets.noDataLottie, height: 200.sp, repeat: false),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.sp),
                child: AppText("${AppLocalization.getText(context)?.empty_paid_users}",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              50.verticalSpace,
            ],
          ))
        : SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: state.invitedUsersData?.invitedUsers?.length,
            (context, index) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.sp),
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
                          AppText(
                            "${state.paidUsersData?.invitedUsers?[index].name}",
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          4.verticalSpace,
                          AppText(
                            "${state.paidUsersData?.invitedUsers?[index].phoneNumber}".format,
                            fontSize: 14.sp,
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
