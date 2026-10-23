import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/presantation/pages/home/data/owner_sub_check_response.dart'
    as owner_sub;

/// One-time notice for an owner whose trial tariff normally comes with a
/// monthly SMS package (Distribyutor: 2000) — Trello #694.
///
/// The trial deliberately does not hand that package out, so the SMS card
/// shows only the free SMS the owner already had (25 on Bepul). Without a
/// word about it the owner reads the small number as a bug. The sheet puts
/// the SMS they DO have up front and says plainly why the package is not
/// there yet. Shown once per trial row (see LocalStorage), from the profile
/// page the trial flow returns to.
class TrialSmsNoticeSheet extends StatelessWidget {
  const TrialSmsNoticeSheet({
    super.key,
    required this.smsLeft,
    required this.withheldSms,
    required this.tariffName,
  });

  final int smsLeft;
  final int withheldSms;
  final String tariffName;

  /// Opens the sheet when [sub] is a trial that withholds an SMS package
  /// and this trial has not shown it yet. Marks it shown BEFORE opening,
  /// so a rebuild while the sheet is up cannot stack a second one.
  static Future<void> maybeShow(
    BuildContext context,
    owner_sub.Data? sub,
  ) async {
    final id = sub?.id;
    if (sub == null || id == null) return;
    if (sub.isTrial != true || sub.trialWithheldSmsCount <= 0) return;
    if (LocalStorage.instance.isTrialSmsNoticeShown(id)) return;
    LocalStorage.instance.setTrialSmsNoticeShown(id);

    await AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: TrialSmsNoticeSheet(
        smsLeft: (sub.smsCount ?? 0) - (sub.usedSms ?? 0),
        withheldSms: sub.trialWithheldSmsCount,
        tariffName: sub.tariff?.name ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final primary = context.palette.accent;
    final left = smsLeft < 0 ? 0 : smsLeft;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sms_rounded, size: 32.sp, color: primary),
            ),
          ),
          14.h.verticalSpace,
          AppText(
            l10n?.trial_sms_notice_title ?? 'Sinov muddatidagi SMS',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          12.h.verticalSpace,
          // The SMS the owner can use right now — the point of the sheet.
          Semantics(
            liveRegion: true,
            child: AppText(
              l10n?.trial_sms_notice_free_count(left) ??
                  'Sizda $left ta bepul SMS bor',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: primary,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          10.h.verticalSpace,
          AppText(
            l10n?.trial_sms_notice_body(tariffName, withheldSms) ??
                "Bu bepul sinov muddati bo'lgani uchun $tariffName "
                    'tarifidagi $withheldSms ta SMS berilmadi. Ular tarifni '
                    "sotib olganingizdan keyin qo'shiladi.",
            fontSize: 14,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
          20.h.verticalSpace,
          CustomButtonWidget(
            title: l10n?.guide_understood ?? 'Tushunarli',
            isLoading: false,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
