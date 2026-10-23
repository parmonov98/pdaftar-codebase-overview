import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/money_formatter.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/referral_rewards_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/riverpod/referral_rewards_provider.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// The inviter's choice for one referral purchase reward (Trello #544):
/// extend their tariff, or take money on the referral balance.
///
/// Resolves to the granted choice ('extend' / 'balance'), or null when the
/// sheet was dismissed. Errors stay inside the sheet so a toast never
/// competes with it; the caller announces success and refreshes balances.
class ReferralRewardChoiceSheet extends ConsumerStatefulWidget {
  final ReferralReward reward;

  const ReferralRewardChoiceSheet({super.key, required this.reward});

  static Future<String?> open(
      BuildContext context, ReferralReward reward) async {
    final result = await AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: ReferralRewardChoiceSheet(reward: reward),
    );
    return result is String ? result : null;
  }

  @override
  ConsumerState<ReferralRewardChoiceSheet> createState() =>
      _ReferralRewardChoiceSheetState();
}

class _ReferralRewardChoiceSheetState
    extends ConsumerState<ReferralRewardChoiceSheet> {
  static const _extend = 'extend';
  static const _balance = 'balance';

  // Balance is the safe default: it is what happens if the choice lapses.
  String _choice = _balance;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final options = widget.reward.options;
    final choosing = ref.watch(referralRewardsProvider
        .select((s) => s.choosingId == widget.reward.id));
    final tariff = options?.extendTariffName ?? '';
    final days = options?.extendDays ?? 0;
    final amount = AppMoneyFormatter.longFormatDouble(
        (options?.balanceAmount ?? 0).toDouble());

    final extendSubtitle = options?.isUpgrade == true
        ? (l10n?.referral_reward_option_upgrade(days, tariff) ??
            '$tariff $days')
        : (l10n?.referral_reward_option_extend_days(days, tariff) ??
            '+$days $tariff');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              l10n?.referral_reward_sheet_title ?? '',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            12.verticalSpace,
            _OptionTile(
              title: l10n?.referral_reward_option_extend ?? '',
              subtitle: extendSubtitle,
              icon: Icons.event_repeat_rounded,
              selected: _choice == _extend,
              onTap: choosing ? null : () => setState(() => _choice = _extend),
            ),
            10.verticalSpace,
            _OptionTile(
              title: l10n?.referral_reward_option_balance ?? '',
              subtitle: l10n?.referral_reward_option_balance_amount(amount) ??
                  '+$amount UZS',
              icon: Icons.account_balance_wallet_outlined,
              selected: _choice == _balance,
              onTap: choosing ? null : () => setState(() => _choice = _balance),
            ),
            if (_error != null) ...[
              10.verticalSpace,
              AppText(
                _error!,
                fontSize: 13.sp,
                maxLines: 3,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
            16.verticalSpace,
            CustomButtonWidget(
              title: l10n?.referral_reward_confirm ?? '',
              isLoading: choosing,
              onTap: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (ref.read(referralRewardsProvider).choosingId != null) return;
    final fallbackError =
        AppLocalization.getText(context)?.something_went_wrong ?? '';
    final choice = _choice;
    setState(() => _error = null);

    final result = await ref
        .read(referralRewardsProvider.notifier)
        .choose(rewardId: widget.reward.id, choice: choice);
    if (!mounted) return;

    if (!result.ok) {
      setState(() => _error = result.errorMessage ?? fallbackError);
      return;
    }
    Navigator.of(context).pop(choice);
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(14.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: selected
                ? primary.withValues(alpha: 0.08)
                : Theme.of(context).cardColor,
            border: Border.all(
              color: selected ? primary : Theme.of(context).dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 26.sp),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(title,
                        fontSize: 15.sp, fontWeight: FontWeight.w600),
                    4.verticalSpace,
                    AppText(subtitle, fontSize: 13.sp, maxLines: 2),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? primary : Theme.of(context).disabledColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
