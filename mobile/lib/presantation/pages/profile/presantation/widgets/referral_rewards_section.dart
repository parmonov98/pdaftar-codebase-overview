import 'package:intl/intl.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/money_formatter.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/riverpod/provider/home_provider.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/referral_rewards_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/riverpod/referral_rewards_provider.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/referral_reward_choice_sheet.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// Rewards for friends' paid purchases, on the referral page (Trello #544).
/// Renders nothing until there is something to show, so inviters without
/// rewards (and backends without the feature) see the page as before.
class ReferralRewardsSection extends ConsumerWidget {
  /// Runs after a reward is granted with the success message. Defaults to
  /// a toast plus refreshing the referral balance and, for an extension,
  /// the tariff; tests replace it.
  final void Function(WidgetRef ref, String choice, String message)? onGranted;

  const ReferralRewardsSection({super.key, this.onGranted});

  static void announceAndRefresh(WidgetRef ref, String choice, String message) {
    AppHelpers.showSnackBarSuccess(message: message);
    ref.read(profileProvider.notifier).getBalanceHistory(isRefresh: true);
    if (choice == 'extend') {
      ref.read(homeProvider(0).notifier).checkOwnerTariffs(forceRefresh: true);
    }
  }

  Future<void> _choose(
      BuildContext context, WidgetRef ref, ReferralReward reward) async {
    final l10n = AppLocalization.getText(context);
    final options = reward.options;
    // Built before the sheet opens: the success toast shows after it closes.
    final extendMessage =
        l10n?.referral_reward_granted_extension(options?.extendDays ?? 0) ?? '';
    final balanceMessage = l10n?.referral_reward_granted_balance(
            AppMoneyFormatter.longFormatDouble(
                (options?.balanceAmount ?? 0).toDouble())) ??
        '';

    final choice = await ReferralRewardChoiceSheet.open(context, reward);
    if (choice == null) return;

    (onGranted ?? announceAndRefresh)(
        ref, choice, choice == 'extend' ? extendMessage : balanceMessage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(referralRewardsProvider.select((s) => s.data));
    if (data.pending.isEmpty &&
        data.history.isEmpty &&
        data.thisMonthCount == 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalization.getText(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            l10n?.referral_rewards_title ?? '',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          if (data.thisMonthCount > 0) ...[
            2.verticalSpace,
            AppText(
              l10n?.referral_reward_this_month(data.thisMonthCount) ?? '',
              fontSize: 12.sp,
              maxLines: 2,
              color: Theme.of(context).hintColor,
            ),
          ],
          8.verticalSpace,
          for (final reward in data.pending) ...[
            _PendingRewardCard(
              reward: reward,
              onChoose: () => _choose(context, ref, reward),
            ),
            8.verticalSpace,
          ],
          for (final reward in data.history.take(5))
            _HistoryRow(reward: reward),
        ],
      ),
    );
  }
}

class _PendingRewardCard extends StatelessWidget {
  final ReferralReward reward;
  final VoidCallback onChoose;

  const _PendingRewardCard({required this.reward, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final primary = Theme.of(context).primaryColor;
    final name = reward.friendName?.trim().isNotEmpty == true
        ? reward.friendName!.trim()
        : (l10n?.referral_reward_friend_fallback ?? '');
    final deadline = reward.autoResolveAt == null
        ? null
        : DateFormat('dd.MM.yyyy').format(reward.autoResolveAt!.toLocal());

    return Container(
      padding: EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                  color: context.palette.accent, size: 24.sp),
              10.horizontalSpace,
              Expanded(
                child: AppText(
                  l10n?.referral_reward_pending_title(
                          name, reward.friendTariffName ?? '') ??
                      name,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          if (deadline != null) ...[
            6.verticalSpace,
            AppText(
              l10n?.referral_reward_deadline(deadline) ?? '',
              fontSize: 12.sp,
              maxLines: 3,
              color: Theme.of(context).hintColor,
            ),
          ],
          10.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: reward.options == null ? null : onChoose,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(44.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: AppText(
                l10n?.referral_reward_choose ?? '',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ReferralReward reward;

  const _HistoryRow({required this.reward});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final name = reward.friendName?.trim().isNotEmpty == true
        ? reward.friendName!.trim()
        : (l10n?.referral_reward_friend_fallback ?? '');
    final isExtension = reward.status == ReferralReward.statusGrantedExtension;
    final text = isExtension
        ? l10n?.referral_reward_history_extension(name, reward.grantedDays ?? 0)
        : l10n?.referral_reward_history_balance(
            name,
            AppMoneyFormatter.longFormatDouble(
                (reward.grantedAmount ?? 0).toDouble()));

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            isExtension
                ? Icons.event_available_rounded
                : Icons.account_balance_wallet_outlined,
            size: 18.sp,
            color: AppColors.green,
          ),
          8.horizontalSpace,
          Expanded(child: AppText(text ?? '', fontSize: 13.sp, maxLines: 2)),
        ],
      ),
    );
  }
}
