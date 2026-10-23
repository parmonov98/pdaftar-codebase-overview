import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/printer/referral_stand_pdf_builder.dart';
import 'package:printing/printing.dart';

class ReferralStandButton extends StatefulWidget {
  final String? ownedReferalCode;
  final Future<void> Function(String code)? sharePdf;

  const ReferralStandButton({super.key, this.ownedReferalCode, this.sharePdf});

  @override
  State<ReferralStandButton> createState() => _ReferralStandButtonState();
}

class _ReferralStandButtonState extends State<ReferralStandButton> {
  bool _preparing = false;

  bool get _hasValidCode {
    try {
      ReferralStandPdfBuilder.qrPayload(widget.ownedReferalCode ?? '');
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<void> _download() async {
    if (_preparing || !_hasValidCode) return;
    setState(() => _preparing = true);
    final l10n = AppLocalization.getText(context);
    try {
      if (widget.sharePdf != null) {
        await widget.sharePdf!(widget.ownedReferalCode!);
      } else {
        final doc = await ReferralStandPdfBuilder.build(
          ownedReferalCode: widget.ownedReferalCode!,
          title: l10n?.referral_stand_title ??
              'Hisob-kitobingizni pDaftarda yuriting',
          cta: l10n?.referral_stand_cta ??
              'Ilovani yuklab olish uchun skanerlang',
        );
        final bytes = await doc.save();
        if (!mounted) return;
        await Printing.sharePdf(
            bytes: bytes, filename: 'pdaftar-reklama-stend.pdf');
      }
    } catch (_) {
      if (mounted) {
        AppHelpers.showSnackBarError(
            errorMessage:
                l10n?.referral_stand_failed ?? "PDF tayyorlab bo'lmadi");
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: !_hasValidCode || _preparing ? null : _download,
        icon: _preparing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined),
        label: Text(AppLocalization.getText(context)?.referral_stand_download ??
            'Reklama stendini yuklab olish'),
      );
}
