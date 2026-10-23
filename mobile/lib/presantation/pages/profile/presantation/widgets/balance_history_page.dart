import 'package:pdaftaruz/constants/app_date_formatter.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:lottie/lottie.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class BalanceHistoryPage extends ConsumerStatefulWidget {
  const BalanceHistoryPage({super.key});

  @override
  ConsumerState<BalanceHistoryPage> createState() => _BalanceHistoryPageState();
}

class _BalanceHistoryPageState extends ConsumerState<BalanceHistoryPage> {

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    ref.read(profileProvider.notifier);

    return state.balanceHistory?.invitedCount?.isNotEmpty ?? false || state.balanceHistory != null
        ? SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: state.balanceHistory?.invitedCount?.length,
              (context, index) {
                final item = state.balanceHistory?.invitedCount?[index];
                // Categorize by the AMOUNT SIGN — the source of truth
                // for "deposit vs spend." `type` is informational only
                // (the catalog includes referral_bonus, ugc_reward,
                // business_clients_report_export, sms_purchase,
                // owner_subscription_purchase, etc.) and the prior
                // substring-match-on-description heuristic happened to
                // work only when the word "bonus" appeared in the text.
                // Positive amount → deposit (Bonus / green / +).
                // Negative amount → spend  (Harajat / red / -).
                final rawAmount = item?.amount ?? '';
                final parsedAmount = double.tryParse(rawAmount) ?? 0;
                final isBonus = parsedAmount > 0;
                // Re-format the unsigned figure so rendering can prefix
                // the sign consistently without double-negatives.
                final unsignedAmount = rawAmount.startsWith('-')
                    ? rawAmount.substring(1)
                    : rawAmount;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.sp),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.sp,
                                      vertical: 4.sp,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isBonus 
                                          ? AppColors.green.withValues(alpha: 0.1)
                                          : AppColors.errorColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: AppText(
                                      isBonus ? "${AppLocalization.getText(context)?.bonus}" : "${AppLocalization.getText(context)?.spent}",
                                      fontSize: 12.sp,
                                      color: isBonus ? (context.isDark ? AppColors.greenOnDark : AppColors.green) : (context.isDark ? AppColors.redOnDark : AppColors.errorColor),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 8.sp),
                                  // Wrap in Flexible so the date can
                                  // ellipsis instead of pushing the row
                                  // off-screen when the user picks the
                                  // larger font-size preset.
                                  Flexible(
                                    child: AppText(
                                      AppDateFormatter.format(
                                          item?.createdAt, context),
                                      fontSize: 12.sp,
                                      color: Colors.grey,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (item?.description != null && item!.description!.isNotEmpty) ...[
                                4.verticalSpace,
                                AppText(
                                  "${item.description}",
                                  maxLines: 3,
                                  fontSize: 11.sp,
                                  color: context.isDark
                                      ? context.palette.accent
                                      : AppColors.primaryColorShade600,
                                ),
                              ],
                            ],
                          ),
                        ),
                        16.horizontalSpace,
                        AppText(
                          isBonus
                              ? '+$unsignedAmount UZS'
                              : '-$unsignedAmount UZS',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: isBonus ? AppColors.green : AppColors.errorColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                0.1.sh.verticalSpace,
                Lottie.asset(Assets.noDataLottie, height: 200.sp, repeat: false),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.sp),
                  child: AppText(
                    "${AppLocalization.getText(context)?.empty_balance_history}",
                    maxLines: 5,
                    textAlign: TextAlign.center,
                    fontSize: 14.sp,
                  ),
                )
              ],
            ),
          );
  }
}
