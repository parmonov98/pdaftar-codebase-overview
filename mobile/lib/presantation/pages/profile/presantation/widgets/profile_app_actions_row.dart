import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/riverpod/provider/home_provider.dart';
import 'package:pdaftaruz/presantation/pages/review/services/review_service.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// Baholash / Ilovani ulashish as two equal tiles inside the Profil list,
/// right before the settings sections.
///
/// These used to float over the page as a ★ and a share FAB, and whatever
/// rested under them could not be tapped — the "Foydalanuvchilar" label under
/// ★ (#591). In the list they cover nothing. AI yordamchi was a third tile
/// here until it went back to being the app-wide floating bubble (#619).
class ProfileAppActionsRow extends ConsumerWidget {
  const ProfileAppActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.getText(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      // Equal heights when one label wraps to two lines (ru, tg, large text).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AppActionTile(
                key: const Key('profile_rate_tile'),
                label: l10n?.rate_app_button ?? 'Baholash',
                icon: Icon(Icons.star_rate_rounded,
                    size: 20.sp, color: context.palette.accent),
                onTap: () => ReviewService.showReviewDialog(context),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _AppActionTile(
                key: const Key('profile_share_tile'),
                label: l10n?.share_app ?? 'Ilovani ulashish',
                icon: Icon(Icons.share_rounded,
                    size: 18.sp, color: context.palette.accent),
                onTap: () => _shareApp(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareApp(BuildContext context, WidgetRef ref) {
    // Personalize the download URL with the user's referral code so installs
    // from this share credit them on the referral leaderboard. Falls back to
    // the plain URL when the code isn't loaded yet (e.g. fresh launch before
    // checkOwnerTariffs has resolved).
    final ownedCode = ref
        .read(homeProvider(0))
        .ownerTariffsCheck
        ?.data
        ?.owner
        ?.ownedReferalCode;
    // utm_source=app_share splits this channel from the per-client invite
    // button (utm_source=client_invite) in attribution reports.
    final personalizedUrl = (ownedCode != null && ownedCode.isNotEmpty)
        ? 'pDaftar.uz/down?ref=$ownedCode&utm_source=app_share'
        : 'pDaftar.uz/down?utm_source=app_share';
    final base = AppLocalization.getText(context)?.share_app_text ??
        "pDaftar ilovasini biznes boshqarishda ishlatmoqdaman. Siz ham sinab ko'ring.\n\nyuklash uchun pDaftar.uz/down kiring.";
    AppSharing.share(text: base.replaceAll('pDaftar.uz/down', personalizedUrl));
  }
}

/// One tile: tinted icon over a centred label, styled like the
/// Mening bizneslarim / Foydalanuvchilar tiles above it (QuickActionsGrid).
class _AppActionTile extends StatelessWidget {
  const _AppActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: isDark
              ? BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                  width: 1,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: icon,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
