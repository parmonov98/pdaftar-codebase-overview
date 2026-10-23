
import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/printer/printer_model_detector.dart';

const _kPurple = Color(0xFF7C3AED);

/// [_kPurple] is too dark for text, icons and outlines on the dark theme
/// (about 3:1); fills keep it (#649).
Color _purpleInk(BuildContext context) =>
    context.isDark ? context.palette.accent : _kPurple;

/// Edit one printer: the shop's own label for it, and the paper it is loaded
/// with.
///
/// Both belong to the PRINTER, not the phone. Cheap thermal printers all
/// advertise the same Bluetooth name — this shop has two called "Printer001"
/// — so without a rename the list is genuinely unusable. And a shop with an
/// 80mm till printer and a 58mm portable needs each to remember its own roll,
/// otherwise selecting one applies the other's width and the receipt wraps.
class PrinterEditSheet extends StatefulWidget {
  /// Bluetooth broadcast name, shown as the placeholder when unnamed.
  final String bluetoothName;

  /// The shop's stored label, if it has one.
  final String? currentName;

  /// '58mm' or '80mm'.
  final String currentPaper;

  /// The shop's stored brand/model, if already known.
  final String? currentBrand;
  final String? currentModel;

  /// Called with the edited values; returns true when the save succeeded.
  final Future<bool> Function(
    String? name,
    String paper,
    String? brand,
    String? model,
  ) onSave;

  const PrinterEditSheet({
    super.key,
    required this.bluetoothName,
    required this.currentPaper,
    required this.onSave,
    this.currentName,
    this.currentBrand,
    this.currentModel,
  });

  @override
  State<PrinterEditSheet> createState() => _PrinterEditSheetState();
}

class _PrinterEditSheetState extends State<PrinterEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late String _paper;
  bool _saving = false;

  /// True when we worked the model out from the Bluetooth name rather than
  /// the shop typing it. Detected models are shown read-only: re-asking for
  /// something we already know is friction, and the point of asking at all is
  /// only to fill the gaps.
  bool _autoDetected = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName ?? '');
    _paper = widget.currentPaper == '80mm' ? '80mm' : '58mm';

    // Prefer what the shop already stored; otherwise try to read the model out
    // of the Bluetooth name, and only fall back to asking.
    final detected = PrinterModelDetector.detect(widget.bluetoothName);
    final brand = widget.currentBrand ?? detected?.brand;
    final model = widget.currentModel ?? detected?.model;
    _autoDetected = widget.currentModel == null && detected != null;

    _brandCtrl = TextEditingController(text: brand ?? '');
    _modelCtrl = TextEditingController(text: model ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final typed = _nameCtrl.text.trim();
    // Empty means "no custom label" — fall back to the Bluetooth name rather
    // than storing a blank that would render as an unlabelled row.
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();

    final ok = await widget.onSave(
      typed.isEmpty ? null : typed,
      _paper,
      brand.isEmpty ? null : brand,
      model.isEmpty ? null : model,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) AppNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalization.getText(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        // Lift above the keyboard — the name field is the first thing tapped.
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            l?.printer_edit_title ?? 'Printerni tahrirlash',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          4.h.verticalSpace,
          AppText(
            widget.bluetoothName,
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
          16.h.verticalSpace,
          AppText(l?.printer_edit_name ?? 'Nomi',
              fontSize: 13, fontWeight: FontWeight.w500),
          6.h.verticalSpace,
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            maxLength: 40,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: widget.bluetoothName,
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          16.h.verticalSpace,
          // Brand + model. Shown as a confirmed line when we recognised the
          // printer, and as inputs only when we could not — asking a shop to
          // retype something the app already knows is pure friction, and a
          // blank is what makes the public list useless.
          if (_autoDetected)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18.sp, color: _purpleInk(context)),
                  10.w.horizontalSpace,
                  Expanded(
                    child: AppText(
                      '${_brandCtrl.text} ${_modelCtrl.text}'.trim(),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _autoDetected = false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: AppText(
                      l?.edit ?? 'Tahrirlash',
                      fontSize: 12,
                      color: _purpleInk(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            AppText(l?.printer_edit_brand ?? 'Brend',
                fontSize: 13, fontWeight: FontWeight.w500),
            6.h.verticalSpace,
            _textField(_brandCtrl, 'Xprinter'),
            12.h.verticalSpace,
            AppText(l?.printer_edit_model ?? 'Model',
                fontSize: 13, fontWeight: FontWeight.w500),
            6.h.verticalSpace,
            _textField(_modelCtrl, 'XP-58'),
            6.h.verticalSpace,
            AppText(
              l?.printer_edit_model_hint ??
                  "Ixtiyoriy. Boshqa do'konlar qaysi printer ishlashini "
                      "bilishi uchun yordam beradi.",
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ],
          16.h.verticalSpace,
          AppText(l?.printer_settings_paper ?? "Qog'oz eni",
              fontSize: 13, fontWeight: FontWeight.w500),
          8.h.verticalSpace,
          Row(
            children: [
              _paperChip('58mm', l?.receipt_paper_58mm ?? '58mm'),
              8.w.horizontalSpace,
              _paperChip('80mm', l?.receipt_paper_80mm ?? '80mm'),
            ],
          ),
          20.h.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : AppText(
                      l?.save ?? 'Saqlash',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController c, String hint) => TextField(
        controller: c,
        textInputAction: TextInputAction.next,
        maxLength: 40,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          filled: true,
          fillColor: Theme.of(context).cardColor,
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      );

  Widget _paperChip(String value, String label) {
    final selected = _paper == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: _saving ? null : () => setState(() => _paper = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected ? _kPurple.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? _purpleInk(context)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.7),
            ),
          ),
          child: Center(
            child: AppText(
              label,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _purpleInk(context) : null,
            ),
          ),
        ),
      ),
    );
  }
}
