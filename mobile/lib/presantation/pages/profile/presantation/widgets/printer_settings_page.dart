import 'package:app_settings/app_settings.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/shop/shop_info/presantation/riverpod/provider/shop_info_provider.dart';
import 'package:pdaftaruz/presantation/pages/sales_calc_debt/data/receipt_models.dart';
import 'package:pdaftaruz/service/printer/receipt_escpos_builder.dart';
import 'package:pdaftaruz/service/printer/receipt_pdf_builder.dart';
import 'package:pdaftaruz/service/printer/receipt_raster_builder.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/printer_edit_sheet.dart';
import 'package:pdaftaruz/service/printer/shop_printer_api.dart';
import 'package:printing/printing.dart';
import 'package:pdaftaruz/service/printer/test_receipt_escpos_builder.dart';
import 'package:pdaftaruz/service/printer/test_receipt_sample.dart';
import 'package:pdaftaruz/service/printer/thermal_printer_service.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/printer_device_filter_toggle.dart';
import 'package:pdaftaruz/service/printer/printer_device_filter.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

const _kPurple = Color(0xFF7C3AED);

/// [_kPurple] is too dark for text, icons and outlines on the dark theme
/// (about 3:1); fills keep it (#649).
Color _purpleInk(BuildContext context) =>
    context.isDark ? context.palette.accent : _kPurple;

/// Printer settings: pick the thermal printer and paper width this device
/// should use, and print a sample receipt to prove it works.
///
/// Why this exists separately from [ThermalPrintSheet]: until now the only way
/// to reach a printer was from a finished receipt, so setting a shop up meant
/// making a real sale first. That is a bad first-run experience and it made
/// diagnosing a printer ("is it the pairing, the paper width, or the
/// codepage?") impossible without creating junk data.
///
/// The choice is stored per DEVICE, not per shop. A shop can have a till
/// printer and a courier's portable one, and the correct printer is a property
/// of the phone in your hand — unlike paper size, which the print sheet also
/// syncs to the shop so the web app agrees.
@RoutePage()
class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() =>
      _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  List<BluetoothInfo> _devices = const [];
  String? _selectedMac;
  String? _selectedName;
  String _paper = '58mm';
  bool _loading = true;
  bool _printing = false;
  bool _bluetoothOn = true;

  // Printer-type devices only, unless the user asks for all (Trello #463).
  List<BluetoothInfo> _allDevices = const [];
  Map<String, int> _deviceClasses = const {};
  bool _showAllDevices = false;

  List<BluetoothInfo> _filteredDevices({bool? showAll}) =>
      PrinterDeviceFilter.visible(
        _allDevices,
        _deviceClasses,
        showAll: showAll ?? _showAllDevices,
        // Only the selected printer bypasses the filter; remembered shop
        // printers must pass it too (Trello #721).
        keep: {if (_selectedMac != null) _selectedMac!},
      );

  int get _hiddenDeviceCount =>
      _allDevices.length - _filteredDevices(showAll: false).length;

  /// printer identifier -> what the shop remembers (label + paper).
  Map<String, ShopPrinterInfo> _printers = const {};

  @override
  void initState() {
    super.initState();
    _selectedMac = LocalStorage.instance.getThermalPrinterAddress();
    _selectedName = LocalStorage.instance.getThermalPrinterName();
    // Same precedence as the print sheet: explicit local pick -> shop
    // default -> thermal width fallback. Reading only the thermal width
    // (58/80) silently dropped an A4 shop default on the floor.
    _paper = LocalStorage.instance.getReceiptPaperSize() ??
        _shopDefaultPaper() ??
        '${LocalStorage.instance.getThermalPaperWidthMm()}mm';
    _loadDevices();

    // updateShop() builds its payload by falling back to state.shopInfo for
    // the fields the API requires (name, address, category...). Opened cold —
    // straight from Profil after a fresh start — that state is empty, so the
    // request went up with an empty name, 422'd, and the notifier surfaced its
    // own error snackbar with a null message: the literal "null" banner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopId = LocalStorage.instance.getSelectedShopId();
      if (shopId == 0) return;
      if (ref.read(shopInfoProvider(shopId)).shopInfo?.data?.id != null) return;
      ref.read(shopInfoProvider(shopId).notifier).getShopInfo(shopId: shopId);
    });
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    await ThermalPrinterService.ensurePermissions();
    final on = await ThermalPrinterService.isBluetoothOn();
    final devices = await ThermalPrinterService.pairedDevices();
    final classes = await PrinterDeviceFilter.majorClasses();
    final remembered =
        await ShopPrinterApi.fetch(LocalStorage.instance.getSelectedShopId());
    if (!mounted) return;
    setState(() {
      _bluetoothOn = on;
      _allDevices = devices;
      _deviceClasses = classes;
      if (remembered.isNotEmpty) _printers = remembered;
      _devices = _filteredDevices();

      // Adopt the selected printer's remembered width. Without this the page
      // shows whatever width was last used on THIS phone, which is wrong the
      // moment a shop owns two printers with different rolls.
      final mac = _selectedMac;
      final forSelected = mac == null ? null : remembered[mac]?.paperSize;
      if (forSelected != null && _paper != forSelected) {
        _paper = forSelected;
        LocalStorage.instance.setReceiptPaperSize(forSelected);
        LocalStorage.instance
            .setThermalPaperWidthMm(forSelected == '80mm' ? 80 : 58);
      }
      // Keep the saved printer selected even if it is out of range right now —
      // dropping the selection because the printer is merely switched off
      // would silently lose the user's setup.
      _loading = false;
    });
  }

  Future<void> _select(BluetoothInfo d) async {
    final remembered = _printers[d.macAdress]?.paperSize;

    setState(() {
      _selectedMac = d.macAdress;
      _selectedName = d.name;
      // Switching printer switches paper. A till printer on 80mm and a
      // portable on 58mm must not inherit each other's width.
      if (remembered != null) _paper = remembered;
    });

    await LocalStorage.instance.setThermalPrinter(d.macAdress, d.name);

    if (remembered != null) {
      await LocalStorage.instance.setReceiptPaperSize(remembered);
      await LocalStorage.instance
          .setThermalPaperWidthMm(remembered == '80mm' ? 80 : 58);
    } else {
      // First time we see this printer: record the width currently shown so
      // the next phone does not have to guess.
      await _rememberPaperForSelectedPrinter(_paper);
    }
  }

  /// Persist the width against the CHOSEN printer, not the phone.
  ///
  /// Best-effort on purpose: the local pick is already saved by the caller, so
  /// a failure here degrades to the old per-device behaviour rather than
  /// blocking the user from printing.
  Future<void> _rememberPaperForSelectedPrinter(String paper) async {
    final mac = _selectedMac;
    if (mac == null || paper == 'A4') return;
    // A non-printer picked via "show all" stays a local pick only; saving it
    // would list it as a printer on every phone of the shop (Trello #721).
    // Editing it explicitly (label sheet) still saves.
    if (!PrinterDeviceFilter.isPrinterMac(mac, _allDevices, _deviceClasses)) {
      return;
    }

    setState(() => _printers = {
          ..._printers,
          mac: ShopPrinterInfo(
            identifier: mac,
            name: _printers[mac]?.name,
            paperSize: paper,
          ),
        });

    await ShopPrinterApi.save(
      shopId: LocalStorage.instance.getSelectedShopId(),
      identifier: mac,
      name: _selectedName,
      paperSize: paper,
    );
  }

  /// What to call a printer in the list: the shop's own label if it has one,
  /// otherwise the Bluetooth broadcast name. Two printers here both advertise
  /// as "Printer001", which is exactly why the label exists.
  String _labelFor(BluetoothInfo d) {
    final stored = _printers[d.macAdress]?.name;
    if (stored != null && stored.trim().isNotEmpty) return stored;

    return d.name.isEmpty ? d.macAdress : d.name;
  }

  Future<void> _editPrinter(BluetoothInfo d) async {
    final l = AppLocalization.getText(context);
    final existing = _printers[d.macAdress];

    await AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: PrinterEditSheet(
        bluetoothName: d.name.isEmpty ? d.macAdress : d.name,
        currentName: existing?.name,
        currentBrand: existing?.brand,
        currentModel: existing?.model,
        currentPaper: existing?.paperSize ?? (_isThermal ? _paper : '58mm'),
        onSave: (name, paper, brand, model) async {
          final ok = await ShopPrinterApi.save(
            shopId: LocalStorage.instance.getSelectedShopId(),
            identifier: d.macAdress,
            name: name,
            brand: brand,
            model: model,
            // Only Bluetooth is drivable today; recording it explicitly means
            // a future transport shows up as a change rather than an
            // assumption baked into old rows.
            connectionType: 'bluetooth',
            paperSize: paper,
          );

          if (!mounted) return ok;

          if (!ok) {
            _snack(l?.error_occurred ?? 'Xatolik yuz berdi');
            return false;
          }

          setState(() {
            _printers = {
              ..._printers,
              d.macAdress: ShopPrinterInfo(
                identifier: d.macAdress,
                name: name,
                brand: brand,
                model: model,
                paperSize: paper,
              ),
            };
            // Editing the printer you are currently using should move the
            // page's paper with it, otherwise the chips disagree with the row.
            if (_selectedMac == d.macAdress) {
              _paper = paper;
              _selectedName = name;
            }
          });

          if (_selectedMac == d.macAdress) {
            await LocalStorage.instance.setReceiptPaperSize(paper);
            await LocalStorage.instance
                .setThermalPaperWidthMm(paper == '80mm' ? 80 : 58);
          }

          _snack(l?.printer_saved ?? 'Saqlandi', ok: true);
          return true;
        },
      ),
    );
  }

  String? _shopDefaultPaper() {
    final shopId = LocalStorage.instance.getSelectedShopId();
    if (shopId == 0) return null;

    return ref.read(shopInfoProvider(shopId)).shopInfo?.data?.defaultPaperSize;
  }

  bool get _isThermal => _paper == '58mm' || _paper == '80mm';

  int get _widthMm => _paper == '80mm' ? 80 : 58;

  Future<void> _setPaper(String paper) async {
    setState(() {
      _paper = paper;

      // If the chosen width hides the printer that was selected, do not leave
      // it selected behind the filter — a test print would silently go to a
      // printer the user can no longer see. Prefer another matching one.
      final mac = _selectedMac;
      final storedForSelected = mac == null ? null : _printers[mac]?.paperSize;
      if (paper != 'A4' &&
          storedForSelected != null &&
          storedForSelected != paper) {
        final replacement = _devices
            .where((d) => (_printers[d.macAdress]?.paperSize ?? paper) == paper)
            .map((d) => d.macAdress)
            .firstOrNull;
        _selectedMac = replacement;
        _selectedName = replacement == null ? null : _printers[replacement]?.name;
      }
    });
    await LocalStorage.instance.setReceiptPaperSize(paper);
    if (paper != 'A4') {
      await LocalStorage.instance.setThermalPaperWidthMm(_widthMm);
      await _rememberPaperForSelectedPrinter(paper);
    }
    await _syncShopDefault(paper);
  }

  /// Fire-and-forget shop sync, mirroring ThermalPrintSheet so the web app and
  /// the user's other devices agree. Without it this page and the print sheet
  /// would quietly hold different defaults.
  Future<void> _syncShopDefault(String size) async {
    final shopId = LocalStorage.instance.getSelectedShopId();
    if (shopId == 0) return;

    final shop = ref.read(shopInfoProvider(shopId)).shopInfo?.data;
    if (shop?.defaultPaperSize == size) return;

    // Belt and braces: if shop info still is not loaded, skip the sync rather
    // than send a payload with an empty name. The local pick is already saved,
    // and a paper-size preference is not worth an error banner over.
    if (shop?.id == null || (shop?.name ?? '').isEmpty) return;

    try {
      await ref.read(shopInfoProvider(shopId).notifier).updateShop(
            context: context,
            shopId: shopId,
            defaultPaperSize: size,
          );
    } catch (_) {
      // Silent — the local pick is already saved.
    }
  }

  Future<void> _testPrint() async {
    if (_printing) return;
    final l = AppLocalization.getText(context);

    if (!_isThermal) {
      await _testPrintA4(l);
      return;
    }

    final mac = _selectedMac;
    if (mac == null) {
      _snack(l?.printer_settings_pick_first ?? 'Avval printerni tanlang');
      return;
    }

    setState(() => _printing = true);
    try {
      final title = l?.printer_test_title ?? 'TEST CHEK';
      final widthLabel = l?.printer_settings_paper ?? "Qog'oz eni";
      // A picture receipt, like a real sale prints; the text-mode test is
      // only the fallback if the picture cannot be drawn.
      List<int> bytes;
      try {
        bytes = await ReceiptRasterBuilder.build(
          TestReceiptSample.build(
            title: title,
            widthLabel: widthLabel,
            widthMm: _widthMm,
            now: DateTime.now(),
          ),
          _widthMm,
          _receiptTexts(l),
        );
      } catch (e) {
        debugPrint('ReceiptRasterBuilder failed, printing text test: $e');
        bytes = await TestReceiptEscposBuilder.build(
          _widthMm,
          TestReceiptTexts(
            title: title,
            explanation: l?.printer_test_explanation ??
                'Agar bu chek to\'g\'ri chiqsa, printer tayyor.',
            itemName: l?.receipt_items_header_name ?? 'Nomi',
            itemPrice: l?.receipt_items_header_price ?? 'Narx',
            total: l?.receipt_total ?? 'Jami',
            widthLabel: widthLabel,
          ),
        );
      }

      final err = await ThermalPrinterService.printBytes(mac: mac, bytes: bytes);
      if (!mounted) return;

      if (err == null) {
        _snack(l?.printer_test_sent ?? 'Test chek yuborildi', ok: true);
      } else {
        _snack(_errText(l, err));
      }
    } catch (e, st) {
      debugPrint('Test print failed: $e\n$st');
      if (mounted) _snack(_errText(l, 'unknown'));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  /// A4 test goes through the OS print dialog, using the SAME PDF builder a
  /// real receipt uses — a test that renders differently from the real thing
  /// proves nothing.
  Future<void> _testPrintA4(dynamic l) async {
    setState(() => _printing = true);
    try {
      final doc = await ReceiptPdfBuilder.build(
        _sampleReceipt(l),
        _receiptTexts(l),
        cutHint: l?.receipt_print_cut_here ?? 'cut along this line',
      );
      final ok = await Printing.layoutPdf(
        name: 'pdaftar-test-receipt',
        onLayout: (format) async => doc.save(),
      );
      if (!mounted) return;
      // `false` means the user dismissed the dialog — not a failure.
      if (ok) _snack(l?.printer_test_sent ?? 'Test chek yuborildi', ok: true);
    } catch (e, st) {
      debugPrint('A4 test print failed: $e\n$st');
      if (mounted) _snack(_errText(l, 'unknown'));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  ReceiptData _sampleReceipt(dynamic l) {
    final shopId = LocalStorage.instance.getSelectedShopId();
    final shop = ref.read(shopInfoProvider(shopId)).shopInfo?.data;

    return ReceiptData(
      debtId: 0,
      amount: 1073000,
      currencyCode: 'UZS',
      createdAt: DateTime.now(),
      clientBalanceBefore: 0,
      clientBalanceAfter: -1073000,
      shop: ReceiptShop(
        id: shopId,
        name: shop?.name ?? 'pDaftar',
        phone: shop?.phoneNumber,
      ),
      client: ReceiptClient(id: 0, name: l?.printer_test_title ?? 'TEST CHEK'),
      creator: ReceiptCreator(id: 0, name: shop?.name ?? 'pDaftar'),
      items: const [
        // Same sample lines as the thermal test: an Uzbek Latin apostrophe and
        // a Cyrillic word, so a font/encoding fault shows up here too.
        // 7-figure on purpose — see TestReceiptEscposBuilder: a total that
        // fits comfortably would not exercise the double-width guard.
        ReceiptItem(id: 1, label: "Go'sht", expression: '10*100800', result: 1008000),
        ReceiptItem(id: 2, label: 'Сут', expression: '2*25000', result: 50000),
        ReceiptItem(id: 3, label: 'Non', expression: '10*1500', result: 15000),
      ],
    );
  }

  ReceiptPrintTexts _receiptTexts(dynamic l) => ReceiptPrintTexts(
        numberLabel: l?.receipt_number ?? 'No',
        dateLabel: l?.receipt_date ?? 'Sana',
        clientLabel: l?.receipt_client ?? 'Mijoz',
        phoneLabel: l?.receipt_phone ?? 'Telefon',
        itemName: l?.receipt_items_header_name ?? 'Nomi',
        itemPrice: l?.receipt_items_header_price ?? 'Narx',
        total: l?.receipt_total ?? 'Jami',
        paidAmount: l?.receipt_paid_amount ?? "To'langan summa",
        paymentLabels: {
          'cash': l?.cash ?? 'Naqd',
          'card': l?.card ?? 'Karta',
          'transfer': l?.transfer ?? "O'tkazma",
          'mixed': l?.receipt_payment_mixed ?? 'Aralash',
        },
        balanceBefore: l?.receipt_balance_before ?? 'Avvalgi balans',
        balanceAfter: l?.receipt_balance_after ?? 'Yangi balans',
        seller: l?.receipt_seller ?? 'Sotuvchi',
        discount: l?.sale_discount ?? 'Chegirma',
      );

  String _errText(dynamic l, String key) {
    switch (key) {
      case 'bt_off':
        return l?.receipt_print_bt_off ?? 'Bluetooth o\'chirilgan';
      case 'connect_failed':
        return l?.receipt_print_connect_failed ?? 'Printerga ulanib bo\'lmadi';
      case 'write_failed':
        return l?.receipt_print_failed ?? 'Chekni yuborib bo\'lmadi';
      default:
        return l?.error_occurred ?? 'Xatolik yuz berdi';
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (ok) {
      AppHelpers.showSnackBarSuccess(message: msg);
    } else {
      AppHelpers.showSnackBarError(errorMessage: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalization.getText(context);

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: AppText(
            l?.printer_settings_title ?? 'Printer sozlamalari',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          centerTitle: true,
          systemOverlayStyle: AppStatusBarThemes.changeDefaultThemeStatusBar(),
          actions: [
            IconButton(
              onPressed: _loading ? null : _loadDevices,
              icon: const Icon(Icons.refresh),
              tooltip: l?.receipt_print_refresh ?? 'Yangilash',
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
          children: [
            // Bluetooth state is irrelevant to A4 (that goes over AirPrint /
            // Mopria), so warning about it there is just noise.
            if (_isThermal && !_bluetoothOn) _bluetoothOffBanner(l),

            // "Which printer should I buy / is mine supported?" merged in
            // here from the separate Yordam entry, so everything about
            // printers lives on one page.
            Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: ListTile(
                leading: Icon(Icons.print_outlined,
                    color: context.palette.accent, size: 22.sp),
                title: AppText(
                  l?.supported_printers_title ??
                      "Qo'llab-quvvatlanadigan printerlar",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
                trailing: Icon(Icons.chevron_right, size: 20.sp),
                onTap: () => AppNavigator.push(const SupportedPrintersRoute()),
              ),
            ),
            _sectionTitle(l?.printer_settings_paper ?? "Qog'oz eni"),
            8.h.verticalSpace,
            Row(
              children: [
                _paperChip('A4', l?.receipt_paper_a4 ?? 'A4'),
                8.w.horizontalSpace,
                _paperChip('80mm', l?.receipt_paper_80mm ?? '80mm'),
                8.w.horizontalSpace,
                _paperChip('58mm', l?.receipt_paper_58mm ?? '58mm'),
              ],
            ),
            // A4 goes through the OS print dialog (AirPrint / Mopria / a
            // CUPS-shared laser), so there is no Bluetooth printer to choose
            // and nothing to pair. Showing the picker anyway would imply the
            // A4 job goes to the thermal printer, which it never does.
            if (_isThermal) ...[
              20.h.verticalSpace,
              _sectionTitle(l?.printer_settings_device ?? 'Printer'),
              8.h.verticalSpace,
              _deviceList(l),
              12.h.verticalSpace,
            ] else ...[
              16.h.verticalSpace,
              _a4Note(l),
            ],
            // Pairing is Android-only on purpose. iOS cannot reach Bluetooth
            // Classic (SPP) printers at all without MFi certification -- see
            // the note on ThermalPrintSheet -- so offering an iPhone owner a
            // "connect a printer" button would send them to a Settings screen
            // where the printer can never appear. Explain instead.
            // Pairing is offered on BOTH platforms. An earlier build hid this
            // on iOS and told iPhone users these printers could not work --
            // that was wrong (they expose BLE, and print_bluetooth_thermal
            // drives BLE on iOS), and it stopped people using hardware they
            // already owned.
            if (_isThermal) _pairButton(l),
            24.h.verticalSpace,
            _testButton(l),
            // Only the Bluetooth path needs a footnote here; for A4 the same
            // sentence already sits in the card above the button, and printing
            // it twice just looks like a rendering bug.
            if (_isThermal) ...[
              12.h.verticalSpace,
              AppText(
                l?.printer_settings_hint ??
                    "Printer telefonning Bluetooth sozlamalarida ulangan bo'lishi kerak.",
                fontSize: 12,
                color: Theme.of(context).hintColor,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
    );
  }

  Widget _bluetoothOffBanner(dynamic l) => Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: context.isDark ? AppColors.redOnDark : AppColors.red),
            12.w.horizontalSpace,
            Expanded(
              child: AppText(
                l?.receipt_print_bt_off ?? "Bluetooth o'chirilgan",
                fontSize: 13,
                color: context.isDark ? AppColors.redOnDark : AppColors.red,
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text) =>
      AppText(text, fontSize: 14, fontWeight: FontWeight.w600);

  Widget _paperChip(String value, String label) {
    final selected = _paper == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: _printing ? null : () => _setPaper(value),
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

  /// Printers that can actually take the currently selected roll.
  ///
  /// A printer loaded with 58mm must not be offered while 80mm is selected --
  /// sending an 80mm layout to a 58mm roll is precisely what wrapped the total
  /// into "1,073,0" / "00 UZS" on the first real receipt.
  ///
  /// Printers with no stored width are always shown: they have simply never
  /// been edited, and hiding a brand-new printer would leave the user with an
  /// empty list and nothing to act on.
  List<BluetoothInfo> get _matchingDevices {
    if (!_isThermal) return _devices;

    return _devices.where((d) {
      final stored = _printers[d.macAdress]?.paperSize;
      return stored == null || stored == _paper;
    }).toList();
  }

  /// Printers hidden purely because their roll differs from the selection.
  int get _hiddenByWidth => _devices.length - _matchingDevices.length;

  Widget _deviceList(dynamic l) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final devices = _matchingDevices;

    if (devices.isEmpty) {
      return Column(
        children: [
          // Distinguish "no printers paired" from "your printers are all a
          // different width" — otherwise selecting 80mm looks like the app
          // lost the printer.
          if (_hiddenByWidth > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: AppText(
                l?.printer_none_for_width ??
                    "Bu qog'oz eni uchun printer yo'q. Boshqa enini tanlang "
                        'yoki printerni tahrirlang.',
                fontSize: 13,
                color: Theme.of(context).hintColor,
                textAlign: TextAlign.center,
              ),
            ),
          // A saved printer that isn't in the paired list right now is almost
          // always just switched off or out of range. Showing it (greyed) beats
          // an empty list, which reads as "your setup is gone".
          if (_selectedName != null && _selectedName!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Icon(Icons.print_disabled,
                      size: 18.sp, color: Theme.of(context).hintColor),
                  8.w.horizontalSpace,
                  Expanded(
                    child: AppText(
                      _selectedName!,
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: AppText(
              l?.receipt_print_no_printers ??
                  "Ulangan printer topilmadi. Printerni telefon Bluetooth sozlamalarida ulang.",
              fontSize: 13,
              color: Theme.of(context).hintColor,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton.icon(
            onPressed: _loadDevices,
            icon: Icon(Icons.refresh, color: _purpleInk(context)),
            label: AppText(
              l?.receipt_print_refresh ?? 'Yangilash',
              color: _purpleInk(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ...devices.map((d) {
          final selected = d.macAdress == _selectedMac;
          return InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: _printing ? null : () => _select(d),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? _purpleInk(context) : Theme.of(context).hintColor,
                    size: 20.sp,
                  ),
                  12.w.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          _labelFor(d),
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        // Each printer shows the roll IT is loaded with, so a
                        // shop with an 80mm till and a 58mm portable can see
                        // both at a glance instead of trusting one global chip.
                        if (_printers[d.macAdress] != null)
                          AppText(
                            _printers[d.macAdress]!.paperSize,
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _printing ? null : () => _editPrinter(d),
                    icon: Icon(Icons.edit_outlined,
                        size: 18.sp, color: _purpleInk(context)),
                    tooltip: l?.printer_edit_title ?? 'Printerni tahrirlash',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(8.w),
                  ),
                ],
              ),
            ),
          );
        }),
        PrinterDeviceFilterToggle(
          showAll: _showAllDevices,
          hiddenCount: _hiddenDeviceCount,
          enabled: !_printing,
          onChanged: (v) => setState(() {
            _showAllDevices = v;
            _devices = _filteredDevices();
          }),
        ),
        if (_hiddenByWidth > 0)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: AppText(
              l?.printer_hidden_by_width ??
                  "Boshqa qog'oz eniga sozlangan printerlar ko'rsatilmadi.",
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _loadDevices,
            icon: Icon(Icons.refresh, color: _purpleInk(context), size: 18),
            label: AppText(
              l?.receipt_print_refresh ?? 'Yangilash',
              color: _purpleInk(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _a4Note(dynamic l) => Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
          ),
        ),
        child: AppText(
          l?.receipt_print_a4_hint ??
              'A4 tizim chop etish oynasi orqali chiqariladi.',
          fontSize: 12,
          color: Theme.of(context).hintColor,
          textAlign: TextAlign.center,
        ),
      );

  Widget _pairButton(dynamic l) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => AppSettings.openAppSettings(
            type: AppSettingsType.bluetooth,
          ),
          icon: Icon(Icons.bluetooth_searching, color: _purpleInk(context)),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 13.h),
            side: BorderSide(color: _purpleInk(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          label: AppText(
            l?.printer_pair_new ?? 'Yangi printer ulash',
            color: _purpleInk(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );

  Widget _testButton(dynamic l) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _printing ? null : _testPrint,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPurple,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: _printing
              ? SizedBox(
                  height: 20.h,
                  width: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : AppText(
                  l?.printer_test_button ?? 'Test chek chiqarish',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
        ),
      );
}
