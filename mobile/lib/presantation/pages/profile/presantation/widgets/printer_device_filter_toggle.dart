import 'package:pdaftaruz/core/imports/imports.dart';

/// "Show all Bluetooth devices" / "Show printers only" under a printer list
/// (Trello #463). The pickers list only printer-type devices by default; this
/// is the way back to the rest for a printer that does not announce itself
/// as one. Renders nothing when the filter hides nothing.
class PrinterDeviceFilterToggle extends StatelessWidget {
  const PrinterDeviceFilterToggle({
    super.key,
    required this.showAll,
    required this.hiddenCount,
    required this.onChanged,
    this.enabled = true,
  });

  final bool showAll;

  /// Devices the printers-only view leaves out.
  final int hiddenCount;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  static const _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    if (hiddenCount == 0) return const SizedBox.shrink();
    final l = AppLocalization.getText(context);
    final label = showAll
        ? (l?.printer_show_only_printers ?? "Faqat printerlarni ko'rsatish")
        : '${l?.printer_show_all_devices ?? "Barcha Bluetooth qurilmalarni ko'rsatish"} ($hiddenCount)';
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled ? () => onChanged(!showAll) : null,
        // Icon lines up with the radio icons of the list above.
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
        ),
        icon: Icon(
          showAll ? Icons.print_outlined : Icons.bluetooth_searching,
          color: _purple,
          size: 18.sp,
        ),
        label: AppText(label,
            fontSize: 13, color: _purple, fontWeight: FontWeight.w600),
      ),
    );
  }
}
