import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/app_shimmer_widget.dart';
import 'package:pdaftaruz/presantation/global_widgets/money_formatter.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_top_up_bottom_sheet.dart';

class UserBalanceWidget extends ConsumerWidget {
  final double? balance;
  final bool isLoading;

  const UserBalanceWidget({
    super.key,
    this.balance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    return CustomShimmerEffect(
      isLoading: isLoading,
      child: InkWell(
        onTap: () {
          AppNavigator.push(const WalletBalanceHistoryRoute());
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6938EF),
                Color(0xFF9747FF),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      AppLocalization.getText(context)?.main_balance ?? "Asosiy Balans",
                      fontSize: 14.w,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    4.verticalSpace,
                    AppText(
                      '${AppMoneyFormatter.longFormatDouble(state.walletBalance?.totalWalletBalance ?? 0)} UZS',
                      fontSize: 18.w,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              
              // Top Up Button
              if(LocalStorage.instance.getUserType() == "OWNER")
                GestureDetector(
              onTap: () async {
                await ProfileTopUpBottomSheet.open(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: AppColors.primaryColor,
                      size: 16.sp,
                    ),
                    4.horizontalSpace,
                    AppText(
                      AppLocalization.getText(context)?.top_up ?? "Пополнить",
                      fontSize: 12.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

} 