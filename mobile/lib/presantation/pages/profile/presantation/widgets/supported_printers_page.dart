
import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/printer/printer_compatibility_api.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';

const _kPurple = Color(0xFF7C3AED);

/// [_kPurple] is too dark for text, icons and outlines on the dark theme
/// (about 3:1); fills keep it (#649).
Color _purpleInk(BuildContext context) =>
    context.isDark ? context.palette.accent : _kPurple;

/// Which printers work with pdaftar, on the phone the user is holding.
///
/// This is a buying guide, so it is deliberately careful about what it claims.
/// Entries carry the hardware each status was proven on, and models nobody has
/// tested are shown as exactly that rather than being hidden — absence reads
/// as "does not work", which is a stronger claim than we can make and would
/// steer a shop away from hardware that may be fine.
@RoutePage()
class SupportedPrintersPage extends StatefulWidget {
  const SupportedPrintersPage({super.key});

  @override
  State<SupportedPrintersPage> createState() => _SupportedPrintersPageState();
}

class _SupportedPrintersPageState extends State<SupportedPrintersPage> {
  PrinterCompatibilityResult _result =
      const PrinterCompatibilityResult(models: []);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await PrinterCompatibilityApi.fetch();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalization.getText(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: AppText(
          l?.supported_printers_title ?? 'Qo\'llab-quvvatlanadigan printerlar',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
        systemOverlayStyle: AppStatusBarThemes.changeDefaultThemeStatusBar(),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                children: [
                  _platformCard(l),
                  20.h.verticalSpace,
                  if (_result.models.isEmpty)
                    _emptyState(l)
                  else ...[
                    AppText(
                      l?.supported_printers_models ?? 'Tekshirilgan modellar',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    10.h.verticalSpace,
                    ..._result.models.map(_modelCard),
                  ],
                  16.h.verticalSpace,
                  AppText(
                    l?.supported_printers_footer ??
                        "Ro'yxatda yo'q printer ham ishlashi mumkin — "
                            "ESC/POS Bluetooth printerlar odatda mos keladi.",
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  /// What THIS phone can do, before any model is considered. A shop on iPhone
  /// and a shop on Android are asking different questions.
  Widget _platformCard(dynamic l) {
    final cap = _result.capability;
    final os = Platform.isIOS ? 'iPhone' : 'Android';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(os, fontSize: 15, fontWeight: FontWeight.w700),
          10.h.verticalSpace,
          _capRow(
            l?.supported_printers_thermal ?? 'Bluetooth chek printer',
            cap?.thermalBluetooth ?? true,
            cap?.transport,
          ),
          6.h.verticalSpace,
          _capRow(
            l?.supported_printers_a4 ?? 'A4 (tizim orqali)',
            cap?.systemPrint ?? true,
            Platform.isIOS ? 'AirPrint' : 'Mopria / USB',
          ),
        ],
      ),
    );
  }

  Widget _capRow(String label, bool ok, String? detail) => Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18.sp,
            color: ok ? Colors.green.shade600 : AppColors.red,
          ),
          10.w.horizontalSpace,
          Expanded(
            child: AppText(label, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (detail != null && detail.isNotEmpty)
            AppText(detail,
                fontSize: 11, color: Theme.of(context).hintColor),
        ],
      );

  Widget _modelCard(PrinterCompatibilityModel m) {
    final l = AppLocalization.getText(context);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: m.isSupported
              ? Colors.green.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  '${m.brand} ${m.model}'.trim(),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _statusChip(m, l),
            ],
          ),
          8.h.verticalSpace,
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              ...m.paperSizes.map((p) => _tag(p)),
              ...m.connectionTypes.map((c) => _tag(c)),
            ],
          ),
          if (m.note != null && m.note!.isNotEmpty) ...[
            8.h.verticalSpace,
            AppText(m.note!,
                fontSize: 12, color: Theme.of(context).hintColor),
          ],
          // Provenance. A tick with no evidence behind it is how this feature
          // was wrong once already.
          if (m.isSupported && (m.verifiedOn?.isNotEmpty ?? false)) ...[
            6.h.verticalSpace,
            AppText(
              '${l?.supported_printers_verified_on ?? "Tekshirilgan"}: ${m.verifiedOn}',
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(PrinterCompatibilityModel m, dynamic l) {
    final (String text, Color colour) = switch (m.status) {
      'supported' => (l?.supported_printers_works ?? 'Ishlaydi', Colors.green.shade600),
      'unsupported' => (l?.supported_printers_no ?? 'Ishlamaydi', AppColors.red),
      // Neither a promise nor a warning — nobody has tried it.
      _ => (l?.supported_printers_untested ?? 'Tekshirilmagan', Colors.orange.shade700),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: AppText(text, fontSize: 11, fontWeight: FontWeight.w600, color: colour),
    );
  }

  Widget _tag(String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: _kPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: AppText(text, fontSize: 11, color: _purpleInk(context)),
      );

  Widget _emptyState(dynamic l) => Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: AppText(
          l?.supported_printers_empty ??
              "Ro'yxatni yuklab bo'lmadi. Internetni tekshirib, qayta urining.",
          fontSize: 13,
          color: Theme.of(context).hintColor,
          textAlign: TextAlign.center,
        ),
      );
}
