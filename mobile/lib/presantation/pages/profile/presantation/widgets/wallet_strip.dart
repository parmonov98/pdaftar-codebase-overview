import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/money_formatter.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/sms_balance_presentation.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// Compact wallet block at the top of the Profile screen.
///
/// Layout:
///
/// ```
/// ┌──────────────┐ ┌──────────────┐
/// │ Hisob   │+│  │ │ Referal │ → │
/// │ 3 986 631   │ │ │ 99+ taklif  │
/// └──────────────┘ └──────────────┘
/// ┌────────────────────────────────┐
/// │ SMS    36 / 36          │+│   │
/// │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓     │
/// └────────────────────────────────┘
/// ```
///
/// Replaces the two stacked full-width cards (`UserBalanceWidget` + the
/// inline SMS card) plus folds the referral entry-point into the same
/// strip so a user can see and act on every wallet-side surface in one
/// glance instead of scrolling through three different blocks.
class WalletStrip extends StatelessWidget {
  const WalletStrip({
    super.key,
    required this.balance,
    required this.smsLeft,
    required this.smsTotal,
    required this.onTopUp,
    required this.onBuySms,
    required this.onSmsHistory,
    required this.onReferral,
    required this.onBalanceHistory,
    this.referralBalance,
    this.tariffName,
    this.smsWarning,
    this.isLoading = false,
  });

  final double? balance;
  final int smsLeft;
  final int smsTotal;
  final String? tariffName;
  final String? smsWarning;

  /// Cash earned through the referral program (UZS). Displayed on the
  /// Referal chip in place of an invitee count — what the user actually
  /// cares about is how much money they've earned.
  final double? referralBalance;
  final VoidCallback onTopUp;
  final VoidCallback onBuySms;
  final VoidCallback onSmsHistory;
  final VoidCallback onReferral;
  final VoidCallback onBalanceHistory;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final balanceStr = balance == null
        ? '—'
        : '${AppMoneyFormatter.longFormatString(balance!.toStringAsFixed(0))} UZS';
    final smsRatio = smsTotal > 0 ? (smsLeft / smsTotal).clamp(0.0, 1.0) : 0.0;
    final smsColor = smsBalanceColor(left: smsLeft, total: smsTotal);
    final referralBalanceStr = referralBalance == null
        ? '—'
        : '${AppMoneyFormatter.longFormatString(referralBalance!.toStringAsFixed(0))} UZS';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ChipCard(
                  label: l10n?.main_balance ?? 'Asosiy hisob',
                  value: balanceStr,
                  subtitle: tariffName,
                  icon: Icons.account_balance_wallet_rounded,
                  // Tapping the body opens the wallet balance history;
                  // the Telegram button opens @pDaftarBot to top up.
                  onTap: onBalanceHistory,
                  trailing: _TelegramTopUpButton(onTap: onTopUp),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ChipCard(
                  label: l10n?.referral_balance ?? 'Referal hisob',
                  value: referralBalanceStr,
                  subtitle: l10n?.refer_and_earn,
                  icon: Icons.card_giftcard_rounded,
                  onTap: onReferral,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 22.sp,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _ChipCard(
            label: 'SMS',
            value: formatRemainingSms(
              smsLeft,
              (count) => l10n?.sms_remaining(count) ?? '$count SMS',
            ),
            subtitle: l10n?.sms_history ?? 'SMS tarixi',
            icon: Icons.message_rounded,
            onTap: onSmsHistory,
            trailing: _ActionPlusButton(onTap: onBuySms),
            progress: smsTotal > 0 ? smsRatio : null,
            valueColor: smsColor,
            progressColor: smsColor,
            warning: smsWarning,
            isWide: true,
          ),
        ],
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.trailing,
    this.subtitle,
    this.progress,
    this.isWide = false,
    this.valueColor,
    this.progressColor,
    this.warning,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget trailing;
  final double? progress;
  final bool isWide;
  final Color? valueColor;
  final Color? progressColor;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: isDark
            ? Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                width: 1,
              )
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: context.palette.accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.85)
                        : Theme.of(context).hintColor,
                    fontFamily: 'Gilroy',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing,
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: isWide ? 18.sp : 16.sp,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ?? Theme.of(context).textTheme.titleLarge?.color,
              fontFamily: 'Gilroy',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10.sp,
                color: Theme.of(context).hintColor,
                fontFamily: 'Gilroy',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (progress != null) ...[
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4.h,
                backgroundColor:
                    Theme.of(context).dividerColor.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(
                  progressColor ?? context.palette.accent,
                ),
              ),
            ),
          ],
          if (warning != null && warning!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              warning!,
              style: TextStyle(
                color: context.isDark ? AppColors.redOnDark : AppColors.red,
                fontSize: 11.sp,
                fontFamily: 'Gilroy',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

/// Bigger gradient + button — large enough to tap as a primary action so
/// the row above no longer needs a duplicate "To'ldirish" quick action.
class _ActionPlusButton extends StatelessWidget {
  const _ActionPlusButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(7.w),
          child: Icon(Icons.add, size: 18.sp, color: AppColors.white),
        ),
      ),
    );
  }
}

/// Telegram-bot button on the balance chip. Wallet top-up lives OUTSIDE the
/// app (App Store / Play compliance — the app must not sell or link to a
/// payment method); tapping opens @pDaftarBot where the owner tops up, the
/// same one-tap link flow as the Kassa FAB. Distinct from `_ActionPlusButton`
/// (still used by the SMS chip) so the "+" affordance stays where in-app
/// purchase is allowed.
class _TelegramTopUpButton extends StatelessWidget {
  const _TelegramTopUpButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF229ED9), // Telegram blue
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(7.w),
          child: Transform.rotate(
            angle: -0.4,
            child:
                Icon(Icons.send_rounded, size: 16.sp, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
