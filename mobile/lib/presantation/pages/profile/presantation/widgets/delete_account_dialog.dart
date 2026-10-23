import 'dart:math';

import 'package:flutter/services.dart';

import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// Two-step account deletion (#538). "Ha" no longer deletes: the dialog
/// turns into "type this code" with a fresh random 4-digit code, and only
/// the matching code calls [onConfirmed]. A wrong code stays in the dialog
/// with an inline error.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.onConfirmed,
    this.codeGenerator,
  });

  /// Called once the typed code matches. The dialog is already closed.
  final VoidCallback onConfirmed;

  /// Tests pin the code; production draws a new one each time.
  final String Function()? codeGenerator;

  static Future<void> show(BuildContext context,
      {required VoidCallback onConfirmed}) {
    return showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DeleteAccountDialog(onConfirmed: onConfirmed),
    );
  }

  static String randomCode() =>
      (1000 + Random.secure().nextInt(9000)).toString();

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();
  String? _code;
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _askForCode() => setState(() {
        _code = (widget.codeGenerator ?? DeleteAccountDialog.randomCode)();
        _controller.clear();
        _wrong = false;
      });

  void _submit() {
    if (_controller.text.trim() != _code) {
      setState(() => _wrong = true);
      return;
    }
    Navigator.of(context).pop();
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final code = _code;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: CustomSvgWidgetAsset(
        size: 70.sp,
        context.isDark
            ? Assets.questionIconDarkSvg
            : Assets.questionIconSvg,
        blendMode: BlendMode.dst,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              code == null
                  ? (l10n?.wanna_delete_account ??
                      "Akkauntizni o'chirmoqchimisiz?")
                  : (l10n?.delete_account_enter_code(code) ??
                      "Akkauntni o'chirish uchun shu kodni kiriting: $code"),
              textAlign: TextAlign.center,
              fontSize: 16.sp,
              maxLines: 6,
            ),
            5.h.verticalSpace,
            if (code == null)
              AppText(
                l10n?.delete_account ?? '',
                maxLines: 15,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w500,
              )
            else
              TextField(
                key: const ValueKey('delete_account_code_field'),
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (_wrong) setState(() => _wrong = false);
                },
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                    fontSize: 20.sp,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  errorText: _wrong
                      ? (l10n?.delete_account_code_wrong ??
                          "Kod noto'g'ri. Qaytadan kiriting")
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            10.h.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _button(
                  context,
                  label: l10n?.no ?? "Yo'q",
                  filled: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                _button(
                  context,
                  key: const ValueKey('delete_account_confirm'),
                  label: code == null
                      ? (l10n?.yes ?? 'Ha')
                      : (l10n?.delete ?? "O'chirish"),
                  filled: true,
                  onPressed: code == null ? _askForCode : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context,
      {Key? key,
      required String label,
      required bool filled,
      required VoidCallback onPressed}) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        maximumSize: Size(120.sp, 40.sp),
        minimumSize: Size(120.sp, 40.sp),
        backgroundColor:
            filled ? AppColors.red : Theme.of(context).tabBarTheme.labelColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        side: filled ? null : BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: AppText(
        label,
        color: filled
            ? AppColors.white
            : Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }
}
