import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdaftar_sales_calc/pdaftar_sales_calc.dart';
import '../widgets/sale_decimal_input.dart';
import '../widgets/sales_calc_lists_sheet.dart';
import '../widgets/sales_calc_settings_sheet.dart';
import '../sales_calc_palette.dart';

/// Strip the decimal scale a DB column carries but a shop never typed.
///
/// `unit_price` is `decimal:6` and `quantity` `decimal:9`, so the API hands
/// back "6500.000000" and "1.000000000". The zeros are the column's width,
/// not a figure, and printing them reads as false precision (Trello #376).
/// A real fraction is untouched: "2.220000" becomes "2.22".
String trimSalesCalcScale(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (!raw.contains('.')) return raw;
  final trimmed =
      raw.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return trimmed.isEmpty ? '0' : trimmed;
}

String _defaultFormatMoney(Object? value, String? currencyCode) =>
    trimSalesCalcScale(value);

@RoutePage()
class SalesCalcListPage extends StatefulWidget {
  const SalesCalcListPage({
    super.key,
    this.initialClientId,
    this.initialClientName,
    this.initialListId,
    this.startWithNewList = false,
    this.onSaveAsDebt,
    this.onPickClient,
    this.onOpenLinkedDebt,
    this.isSalesToDebtAllowed = true,
    this.onLockedAttempt,
  this.onConfigureProduct,
    this.currencyCodes = const {},
    this.defaultCurrencyId,
    this.formatQuantity = trimSalesCalcScale,
    this.formatMoney = _defaultFormatMoney,
    this.tradeFailureText = 'Saqlanmadi. Qayta urinib ko‘ring.',
    this.tradeFailureMessage,
    this.soldTexts = const SalesCalcSoldTexts(),
    this.stockLockText = 'O‘chirish uchun avval birlikli satrlarni olib tashlang.',
  });

  /// Host-owned capability, shop authorization and unit/currency picker.
  /// Invoked only for inventory-aware lines; null keeps legacy arithmetic.
  final Future<SalesCalcProductChoice> Function(
      BuildContext context,
      int productId,
      String productName,
      SalesCalcItem? current)? onConfigureProduct;
  final Map<int, String> currencyCodes;
  final int? defaultCurrencyId;
  final String tradeFailureText, stockLockText;

  /// Words a failed save from its cause — offline, already sold, a server
  /// error code — instead of the bare [tradeFailureText] (Trello #430).
  /// Null keeps [tradeFailureText] for every failure.
  final String Function(Object? error)? tradeFailureMessage;

  /// Wording for the already-sold chip and the sell-again prompt.
  final SalesCalcSoldTexts soldTexts;


  /// How to render a structured line's quantity and its unit price.
  ///
  /// Both reach us from the API as decimal STRINGS at the column's full
  /// scale — `unit_price` is `decimal:6` and `quantity` `decimal:9` — so a
  /// plain interpolation prints "6 500.000000" and "1.000000000" instead
  /// of "6 500" and "1" (Trello #376). The trailing zeros carry no
  /// information: they are the column's scale, not something the shop
  /// typed.
  ///
  /// The host passes these in rather than this package reimplementing
  /// them, so the calculator and the rest of the app cannot drift into
  /// formatting the same figure two ways.
  ///
  /// The defaults exist only so the package's own `@RoutePage` still
  /// compiles. That bare route is not a real entry point — it has none of
  /// the host callbacks wired up either (see the drawer's comment on
  /// `SalesCalcRouterRoute`), so nothing a user can reach renders with
  /// them.
  final String Function(Object? value) formatQuantity;
  final String Function(Object? value, String? currencyCode) formatMoney;

  /// When set, the calculator opens with a "Client: {name}" pill at
  /// the top so the user knows which client they're ringing up. Tap
  /// the pill to clear the binding without leaving.
  final int? initialClientId;
  final String? initialClientName;

  /// When set, the calculator opens with this specific list selected
  /// in the tabs strip. Used by deep links like the Nakladnoy
  /// receipt's "Sotuv kalkulyatoriga o'tish" CTA so the user lands on
  /// the exact frozen list that was saved to the debt, not whatever
  /// list happened to be active last time the page opened.
  final int? initialListId;

  /// When true the calculator opens on a fresh sale instead of the
  /// last active list: the newest list is reused if still empty,
  /// otherwise a new one is created. Used by the home drawer entry
  /// point. Ignored when [initialListId] is set (deep links win).
  final bool startWithNewList;

  /// Optional host hook. When non-null, the calculator shows a
  /// "Save as debt" action in the app bar; tapping it calls back
  /// with the live `(items, total, clientId)` snapshot. Returning a
  /// non-null int from the callback (the new debt id) means
  /// "saved successfully" — the calculator can keep the items so
  /// the user keeps ringing up.
  final Future<int?> Function(BuildContext ctx, SalesCalcSaveDebtArgs args)?
      onSaveAsDebt;

  /// Optional host hook used to open a client picker when the user
  /// taps the "Mijoz tanlash" placeholder. Returning a non-null
  /// `(id, name)` binds the calculator to that client; null keeps
  /// the unbound state. Without this callback the placeholder is
  /// hidden so the package doesn't expose a non-functional CTA.
  final Future<({int id, String name})?> Function(BuildContext ctx)?
      onPickClient;

  /// Optional host hook used when the user taps the "Linked to debt
  /// #ID" chip. The host owns navigation (client profile, debt
  /// receipt, etc.) — we just pass back the saved debtId + the
  /// client the calc was bound to at save time.
  final void Function(
    BuildContext ctx, {
    required int debtId,
    int? clientId,
    String? clientName,
  })? onOpenLinkedDebt;

  /// Tariff gate: when false, the "Mijoz tanlash" chip and the footer
  /// "Sotuv" save-as-debt button become non-functional — they delegate
  /// to [onLockedAttempt] instead of their normal actions and render
  /// with a lock badge. The calculator + total + copy/save buttons stay
  /// fully functional. Default true so other hosts of this widget
  /// (without a host-side gate) aren't affected.
  final bool isSalesToDebtAllowed;

  /// Called when the user taps a tariff-gated affordance ("Mijoz tanlash"
  /// chip or the footer save-as-debt button) while [isSalesToDebtAllowed]
  /// is false. Hosts typically route to their tariff-upgrade page and
  /// show a snackbar mentioning the qualifying plans.
  final VoidCallback? onLockedAttempt;

  @override
  State<SalesCalcListPage> createState() => _SalesCalcListPageState();
}

/// Snapshot of the calculator's relevant state at "Save as debt"
/// time, passed to the host's [SalesCalcListPage.onSaveAsDebt]
/// callback. Pure data — no Bloc / repository access required.
class SalesCalcProductChoice {
  final bool handled;
  final SalesCalcItem? item;
  const SalesCalcProductChoice.legacy()
      : handled = false,
        item = null;
  const SalesCalcProductChoice.cancelled()
      : handled = true,
        item = null;
  const SalesCalcProductChoice.selected(this.item) : handled = true;
}

/// Host-localized wording for a sheet that is already sold (Trello #432).
class SalesCalcSoldTexts {
  const SalesCalcSoldTexts({
    this.chip = 'Sotuv saqlandi',
    this.againTitle = 'Bu varaq sotilgan',
    this.againBody = _defaultAgainBody,
    this.newSheet = 'Yangi varaq',
    this.sellAgain = 'Yana sotish',
    this.cancel = 'Bekor qilish',
  });

  final String chip, againTitle, newSheet, sellAgain, cancel;

  /// Given the sold sheet's reference ("29.09-#1").
  final String Function(String reference) againBody;

  static String _defaultAgainBody(String reference) =>
      'Bu mahsulotlar allaqachon sotilgan (№$reference). Yana sotsangiz, ikkinchi sotuv yoziladi — birinchisi o‘zgarmaydi.';
}

class SalesCalcSaveDebtArgs {
  const SalesCalcSaveDebtArgs({
    required this.activeListId,
    required this.items,
    required this.total,
    required this.boundClientId,
    required this.boundClientName,
    this.creditTotal,
  });
  final int? activeListId;
  final List<SalesCalcItem> items;
  final double total;
  final int? boundClientId;
  final String? boundClientName;
  final double? creditTotal;
}

class _SalesCalcListPageState extends State<SalesCalcListPage> {
  late final SalesCalcBloc _bloc;
  bool _configuringProduct = false;
  bool _savingAsDebt = false;

  // Track active text field for custom keyboard
  TextEditingController? _activeController;
  FocusNode? _activeFocusNode;
  bool _isKeyboardVisible = false;
  // Focus node for the new-line input
  final FocusNode _newLineFocusNode = FocusNode();
  final TextEditingController _newLineController = TextEditingController();
  double _newLineResult = 0.0;

  // New-line product autocomplete state.
  final TextEditingController _newLineLabelController = TextEditingController();
  final FocusNode _newLineLabelFocusNode = FocusNode();
  String? _newLinePickedLabel;
  int? _newLinePickedProductId;
  // Duplicate-name guard for the new-line Nomi field: set while the
  // typed/picked name already labels another row in the active list.
  // Blocks _submitNewLine and paints the field's red border.
  bool _newLineLabelDuplicate = false;
  // Sentinel id used by the bloc's product-search state to mark
  // "the new-line row is the active autocomplete target". Real items
  // have positive backend ids or negative local ids — 0 is unused.
  static const int _newLineSearchId = 0;

  /// Dark-mode colours (#649); light values pass through untouched.
  SalesCalcPalette get _p => SalesCalcPalette.of(context);

  // Track line focus nodes for existing items
  final Map<int, FocusNode> _lineFocusNodes = {};
  final Map<int, TextEditingController> _lineControllers = {};
  final Map<int, TextEditingController> _labelControllers = {};

  final ScrollController _scrollController = ScrollController();

  /// Live binding to the host-supplied client. Null means "no client"
  /// — the host's onSaveAsDebt callback can prompt for one.
  int? _boundClientId;
  String? _boundClientName;

  /// The most recent sale of each sheet, with the client snapshot taken
  /// at sale time so the chip can hand it back to the host's
  /// onOpenLinkedDebt even if the bound client changes later.
  ///
  /// Kept per sheet and persisted through the host (Trello #432): the
  /// sheet stays editable after a sale, so the mark is what tells a second
  /// "Sotuv" on it apart from a first one — also after the app restarts.
  Map<int, SalesCalcSoldMark> _soldMarks = {};

  /// This device's mark or the server's, whichever sale is newer — the
  /// server's covers a sheet sold from another phone or the web.
  SalesCalcSoldMark? get _activeSoldMark {
    final listId = _bloc.state.activeListId;
    if (listId == null) return null;
    final local = _soldMarks[listId];
    final remote = _bloc.state.lists
        .where((l) => l.id == listId)
        .map((l) => l.lastSale)
        .firstOrNull;
    if (local == null) return remote;
    if (remote == null) return local;
    return remote.debtId > local.debtId ? remote : local;
  }

  @override
  void initState() {
    super.initState();
    _boundClientId = widget.initialClientId;
    _boundClientName = widget.initialClientName;
    _soldMarks = SalesCalcPackage.readSoldMarks();
    _bloc = SalesCalcBloc(
      repository: SalesCalcPackage.repository,
      shopId: SalesCalcPackage.shopId,
      defaultCurrencyId: widget.defaultCurrencyId,
    );
    _bloc.add(LoadSalesCalcLists(
      // Deep links (initialListId) take precedence — the SelectList
      // dispatched below would immediately leave the new list anyway.
      startWithNewList: widget.startWithNewList && widget.initialListId == null,
    ));

    // Deep-link entry: a host opened us with a specific list ID
    // (e.g. the Nakladnoy receipt's "Sotuv kalkulyatoriga o'tish"
    // CTA points at the frozen list saved to the debt). Wait for
    // the bloc's lists fetch to finish, then dispatch SelectList so
    // we land on that exact list instead of the most-recent default.
    // No-op when the id isn't in the loaded set — the SelectList
    // handler triggers an items fetch anyway, so even a frozen list
    // that isn't in the working-list tabs will populate.
    if (widget.initialListId != null) {
      _bloc.stream
          .firstWhere((s) => s.lists.isNotEmpty || s.activeListId != null)
          .then((_) {
        if (!mounted) return;
        if (_bloc.state.activeListId == widget.initialListId) return;
        _bloc.add(SelectList(listId: widget.initialListId!));
      });
    }

    _newLineFocusNode.addListener(_onNewLineFocusChange);
    _newLineLabelFocusNode.addListener(_onNewLineLabelFocusChange);

    // First-load focus: once the bloc resolves an activeListId (initial
    // LoadSalesCalcLists), land the cursor on the new-line Mahsulot
    // input so the user can start typing immediately. Uses the same
    // helper as `_startNewList` so the same race-free check applies
    // here too — if the bloc has ALREADY emitted a non-null
    // activeListId by the time we get here (sync seed), we schedule
    // the focus directly instead of waiting for a future emission
    // that will never come.
    _scheduleFocusAfterListSwitch(priorListId: null);
  }

  /// Schedules `_focusNewLine()` to fire after the bloc has settled on
  /// a list other than [priorListId]. Pass `priorListId: null` from
  /// `initState` to wait for the very first non-null activeListId.
  ///
  /// Why this exists: the old code called
  /// `_bloc.stream.firstWhere(...).then(...)` directly. `firstWhere`
  /// only listens to *future* emissions, so if the bloc's
  /// `CreateNewList` handler had already emitted the new state by the
  /// time the subscriber attached, the callback would never fire and
  /// the keyboard never popped — the exact symptom users hit when
  /// tapping the "+" tab. We now check the current state first and
  /// only fall through to the stream subscription when the id hasn't
  /// flipped yet.
  void _scheduleFocusAfterListSwitch({required int? priorListId}) {
    void schedule() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNewLine();
      });
    }
    final current = _bloc.state.activeListId;
    if (current != null && current != priorListId) {
      schedule();
      return;
    }
    _bloc.stream
        .firstWhere(
          (s) => s.activeListId != null && s.activeListId != priorListId,
        )
        .then((_) {
      if (!mounted) return;
      schedule();
    });
  }

  @override
  void dispose() {
    // Sync to backend before closing
    _bloc.syncBeforeExit();

    _browseTimer?.cancel();
    _newLineFocusNode.removeListener(_onNewLineFocusChange);
    _newLineFocusNode.dispose();
    _newLineController.dispose();
    _newLineLabelFocusNode.removeListener(_onNewLineLabelFocusChange);
    _newLineLabelFocusNode.dispose();
    _newLineLabelController.dispose();
    _scrollController.dispose();
    for (final fn in _lineFocusNodes.values) {
      fn.dispose();
    }
    for (final c in _lineControllers.values) {
      c.dispose();
    }
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    _bloc.close();
    super.dispose();
  }

  /// Browse-suggestions timer: fires 1s after the Nomi field gains
  /// focus while empty, offering the catalog (names only) proactively.
  Timer? _browseTimer;

  void _onNewLineLabelFocusChange() {
    if (_newLineLabelFocusNode.hasFocus) {
      if (_newLineLabelController.text.trim().isEmpty) {
        _browseTimer?.cancel();
        _browseTimer = Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          // Only fire when the field is STILL focused and STILL empty —
          // a keystroke in the meantime owns the suggestions instead.
          if (!_newLineLabelFocusNode.hasFocus) return;
          if (_newLineLabelController.text.trim().isNotEmpty) return;
          _bloc.add(const BrowseProducts(lineId: _newLineSearchId));
        });
      }
    } else {
      _browseTimer?.cancel();
      // Tap-away with nothing typed: dismiss a lingering browse list.
      // Small delay so a tap ON a suggestion (which unfocuses nothing,
      // but ordering is platform-touchy) still lands its pick first.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || _newLineLabelFocusNode.hasFocus) return;
        if (_bloc.state.productSearchLineId == _newLineSearchId &&
            _bloc.state.productSearchQuery.isEmpty &&
            _bloc.state.productSuggestions.isNotEmpty) {
          _bloc.add(const ClearProductSuggestions());
        }
      });
    }
  }

  void _onNewLineFocusChange() {
    if (_newLineFocusNode.hasFocus) {
      _setActiveField(_newLineController, _newLineFocusNode);
    } else {
      _checkHideKeyboard();
    }
  }

  FocusNode _getFocusNode(int id) {
    return _lineFocusNodes.putIfAbsent(id, () {
      final fn = FocusNode();
      fn.addListener(() {
        if (fn.hasFocus) {
          final ctrl = _lineControllers[id];
          if (ctrl != null) _setActiveField(ctrl, fn);
        } else {
          _checkHideKeyboard();
        }
      });
      return fn;
    });
  }

  TextEditingController _getController(int id, String initialText) {
    return _lineControllers.putIfAbsent(id, () => TextEditingController(text: initialText));
  }

  TextEditingController _getLabelController(int id, String? initialText) {
    return _labelControllers.putIfAbsent(id, () => TextEditingController(text: initialText ?? ''));
  }

  /// Hand focus to an expression field programmatically (submit/pick
  /// flows, not taps). Deferred one tick so it runs AFTER the framework's
  /// own unfocus-on-submit, and places the caret at the end explicitly —
  /// a readOnly field focused without a gesture has no valid selection,
  /// so the cursor would stay invisible even though typing works.
  void _handOffToExpression(
      TextEditingController controller, FocusNode focusNode) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      focusNode.requestFocus();
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
      _setActiveField(controller, focusNode);
    });
  }

  void _setActiveField(TextEditingController controller, FocusNode focusNode) {
    setState(() {
      _activeController = controller;
      _activeFocusNode = focusNode;
      _isKeyboardVisible = true;
    });
    // Hide system keyboard
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _checkHideKeyboard() {
    // Delayed check - if no field gained focus, hide keyboard
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      bool anyFocused = _newLineFocusNode.hasFocus;
      if (!anyFocused) {
        for (final fn in _lineFocusNodes.values) {
          if (fn.hasFocus) {
            anyFocused = true;
            break;
          }
        }
      }
      if (!anyFocused) {
        setState(() => _isKeyboardVisible = false);
      }
    });
  }

  void _onKeyboardKey(String key) {
    final ctrl = _activeController;
    if (ctrl == null) return;

    if (key == '.') {
      final updated = insertSaleDecimal(ctrl.value);
      if (updated == ctrl.value) return;
      ctrl.value = updated;
      _onActiveExpressionChanged(updated.text);
      return;
    }

    final text = ctrl.text;
    final selection = ctrl.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    // One row = one operation, and that operation is multiplication
    // (narx*soni) — Trello #153. Chained expressions (2*3000+500) break
    // the qty×price parse when the list is saved as a sale/debt, so the
    // other operators never reach the row (their keys are also greyed in
    // CalcKeyboard) and a second '*' — or one before any number — is
    // swallowed here.
    if (key == '+' || key == '-' || key == '/') return;
    if (key == '*') {
      final candidate = text.replaceRange(start, end, key);
      if (candidate.startsWith('*') ||
          candidate.split('*').length - 1 > 1) {
        return;
      }
    }

    final newText = text.replaceRange(start, end, key);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + key.length),
    );

    // Trigger onChange for the active line
    _onActiveExpressionChanged(newText);
  }

  void _onKeyboardBackspace() {
    final ctrl = _activeController;
    if (ctrl == null) return;

    final text = ctrl.text;
    final selection = ctrl.selection;
    if (!selection.isValid || (selection.start == 0 && selection.end == 0)) return;

    final start = selection.start;
    final end = selection.end;

    if (start == end && start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
      _onActiveExpressionChanged(newText);
    } else if (start != end) {
      final newText = text.replaceRange(start, end, '');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
      _onActiveExpressionChanged(newText);
    }
  }

  void _onKeyboardClear() {
    final ctrl = _activeController;
    if (ctrl == null) return;
    ctrl.clear();
    _onActiveExpressionChanged('');
  }

  /// Delegate the client pick to the host. The host's bottom sheet
  /// owns the search UX; on return we just store the binding so the
  /// "Save as debt" flow has a client to attach to.
  Future<void> _promptPickClient() async {
    final cb = widget.onPickClient;
    if (cb == null) return;
    final picked = await cb(context);
    if (!mounted || picked == null) return;
    setState(() {
      _boundClientId = picked.id;
      _boundClientName = picked.name;
    });
  }

  /// Land focus on whichever new-line field makes sense:
  ///   - Mahsulot (Nomi) when labels are visible — that's the entry
  ///     point for the autocomplete-driven workflow.
  ///   - Expression otherwise.
  void _focusNewLine() {
    if (_bloc.state.showLabels) {
      // Hand-off to the system-keyboard Mahsulot field: drop the custom
      // keypad explicitly. Relying on the expression node's focus-loss
      // listener is racy — when the node already lost focus during
      // keypad typing, no event fires and both keyboards end up
      // stacked on screen.
      setState(() => _isKeyboardVisible = false);
      if (_newLineLabelFocusNode.hasFocus) {
        // The node kept logical focus across the list swap while the
        // platform tore down both the keyboard AND the IME connection.
        // requestFocus() is a no-op on a focused node, and
        // TextInput.show is ignored without a live connection — the
        // only reliable revive is a full unfocus → refocus cycle,
        // which makes the TextField open a fresh IME connection.
        _newLineLabelFocusNode.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _newLineLabelFocusNode.requestFocus();
        });
      } else {
        _newLineLabelFocusNode.requestFocus();
      }
    } else {
      _newLineFocusNode.requestFocus();
      _setActiveField(_newLineController, _newLineFocusNode);
    }
  }

  String _normLabel(String s) => s.trim().toLowerCase();

  /// True when [label] already names another row in the active list
  /// (case- and whitespace-insensitive). Pass [beforeIndex] to scan
  /// only the rows ABOVE a given row so just the LATER occurrence of
  /// a pair gets flagged — the first keeps its normal styling.
  bool _isDuplicateLabel(String label, {int? beforeIndex}) {
    final norm = _normLabel(label);
    if (norm.isEmpty) return false;
    final items = _bloc.state.items;
    final end = beforeIndex == null
        ? items.length
        : (beforeIndex < items.length ? beforeIndex : items.length);
    for (var i = 0; i < end; i++) {
      if (_normLabel(items[i].label ?? '') == norm) return true;
    }
    return false;
  }

  /// Drop products that already label a row from the autocomplete, so a
  /// duplicate can never be picked in the first place.
  ///
  /// The commit-time `_isDuplicateLabel` guard stays as a backstop for
  /// hand-typed names, but it only ever covered the new-line paths — the
  /// existing-row pick had no check at all, so a product could be dropped
  /// onto a committed row and silently duplicate it. Filtering the source
  /// list closes both paths at once.
  ///
  /// [lineId] is the row being edited, if any. A row must not block
  /// itself: re-picking the product a row already carries is not a
  /// duplicate, and hiding it would make the row's own product vanish
  /// from its suggestions.
  List<ShopProduct> _suggestionsExcludingTaken(
    List<ShopProduct> suggestions, {
    int? lineId,
  }) {
    final taken = <String>{};
    for (final item in _bloc.state.items) {
      if (lineId != null && item.id == lineId) continue;
      if (item.productUnitId != null && widget.onConfigureProduct != null) {
        continue;
      }
      final norm = _normLabel(item.label ?? '');
      if (norm.isNotEmpty) taken.add(norm);
    }
    if (taken.isEmpty) return suggestions;

    return suggestions
        .where((p) => !taken.contains(_normLabel(p.name)))
        .toList();
  }

  /// Outline for a Nomi cell — red when it holds a duplicate name,
  /// transparent otherwise. Always returns a decoration (never null):
  /// Container only mounts a DecoratedBox when decoration != null, so
  /// toggling null ↔ decoration would change the element-tree shape,
  /// remount the TextField inside and kill its IME connection — the
  /// keyboard visibly closed mid-typing the moment the border appeared.
  BoxDecoration _labelCellDecoration(bool duplicate) => BoxDecoration(
        border: Border.all(
          color: duplicate ? Colors.red : Colors.transparent,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(6.r),
      );

  void _onKeyboardSubmit() {
    if (_activeController == _newLineController) {
      _submitNewLine();
    } else {
      // Save current line and move to new line
      _activeFocusNode?.unfocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        _focusNewLine();
        _scrollToBottom();
      });
    }
  }

  void _submitNewLine() {
    final expression = _newLineController.text.trim();
    if (expression.isNotEmpty) {
      final result = ExpressionEvaluator.evaluate(expression);
      // Prefer the picked product label; fall back to whatever the
      // user typed in the new-line Nomi field (the resolve-or-create
      // path on the backend turns it into a Product on save).
      final typedLabel = _newLineLabelController.text.trim();
      final label = (_newLinePickedLabel?.isNotEmpty ?? false)
          ? _newLinePickedLabel
          : (typedLabel.isEmpty ? null : typedLabel);
      // Duplicate names are not allowed within one list — block the
      // commit, paint the Nomi field red and put the cursor back so
      // the user fixes the name instead of silently doubling a row.
      if (label != null && _isDuplicateLabel(label)) {
        setState(() => _newLineLabelDuplicate = true);
        _focusNewLine();
        return;
      }
      _bloc.add(CreateSalesCalcItem(
        expression: expression,
        result: result,
        label: label,
        productId: _newLinePickedProductId,
      ));
      _newLineController.clear();
      _newLineLabelController.clear();
      _newLinePickedLabel = null;
      _newLinePickedProductId = null;
      _bloc.add(const ClearProductSuggestions());
      setState(() {
        _newLineResult = 0.0;
        _newLineLabelDuplicate = false;
      });
      // Keep focus on new line for continuous entry — land on the
      // Mahsulot field so the next product can be picked first.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _focusNewLine();
          _scrollToBottom();
        }
      });
    }
  }

  void _onActiveExpressionChanged(String value) {
    // Update local result for the new line
    if (_activeController == _newLineController) {
      setState(() => _newLineResult = ExpressionEvaluator.evaluate(value));
      return;
    }
    // Existing lines can NOT handle their own result via the widget: the
    // Ifoda field is readOnly and driven by this custom keypad, which
    // mutates the controller programmatically — and a programmatic write
    // never fires TextField.onChanged. Without dispatching here the bloc
    // keeps the stale expression, and the row rebinds the controller from
    // it on unfocus, silently reverting the user's edit.
    final id = _activeLineId;
    if (id == null) return;
    _bloc.add(UpdateLocalExpression(
      id: id,
      expression: value,
      result: ExpressionEvaluator.evaluate(value),
    ));
  }

  /// The list-item id whose expression field the custom keypad is
  /// currently editing, or null for the new-line row / no active field.
  int? get _activeLineId {
    final ctrl = _activeController;
    if (ctrl == null || ctrl == _newLineController) return null;
    for (final entry in _lineControllers.entries) {
      if (entry.value == ctrl) return entry.key;
    }
    return null;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewList() {
    final priorListId = _bloc.state.activeListId;
    _bloc.add(const CreateNewList());
    // Clean up local controllers/focus nodes
    for (final c in _lineControllers.values) {
      c.dispose();
    }
    for (final fn in _lineFocusNodes.values) {
      fn.dispose();
    }
    _lineControllers.clear();
    for (final c in _labelControllers.values) { c.dispose(); }
    _labelControllers.clear();
    _lineFocusNodes.clear();
    _newLineController.clear();
    _newLineLabelController.clear();
    _newLinePickedLabel = null;
    _newLinePickedProductId = null;
    setState(() {
      _newLineResult = 0.0;
      _newLineLabelDuplicate = false;
    });
    // Schedule keyboard focus on the new list's Mahsulot row. The
    // helper handles both timing cases — if `CreateNewList` already
    // emitted synchronously, we don't wait for a phantom future
    // emission that would never arrive.
    _scheduleFocusAfterListSwitch(priorListId: priorListId);
  }

  /// Switch the calculator to [listId]: dispose per-row controllers,
  /// drop the previous list's local state and debt linkage, select the
  /// list in the bloc and land the cursor on the new Mahsulot row.
  /// Shared by the horizontal tab strip and the vertical lists sheet.
  void _switchToList(int listId) {
    if (listId == _bloc.state.activeListId) return;
    final priorListId = _bloc.state.activeListId;
    for (final c in _lineControllers.values) {
      c.dispose();
    }
    for (final fn in _lineFocusNodes.values) {
      fn.dispose();
    }
    _lineControllers.clear();
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    _labelControllers.clear();
    _lineFocusNodes.clear();
    _newLineController.clear();
    setState(() {
      _newLineResult = 0.0;
    });
    _bloc.add(SelectList(listId: listId));
    _scheduleFocusAfterListSwitch(priorListId: priorListId);
  }

  /// Vertical browser for the sales lists with date-range / sort /
  /// client filters — see [SalesCalcListsSheet]. Tap opens the list,
  /// long-press shows the same rename/clone/delete options as the
  /// horizontal strip.
  void _showListsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: _bloc,
        child: SalesCalcListsSheet(
          formatNumber: _formatNumber,
          onPick: (listId) {
            Navigator.of(ctx).pop();
            _switchToList(listId);
          },
          onLongPressList: (list) {
            Navigator.of(ctx).pop();
            _showListOptions(context, list);
          },
        ),
      ),
    );
  }

  void _showListOptions(BuildContext context, SalesCalcList list) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: _p.accent(const Color(0xFF7C3AED)), size: 22.sp),
              title: const Text('Nomini o\'zgartirish'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, list);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red, size: 22.sp),
              title: const Text("O'chirish"),
              onTap: () {
                Navigator.pop(ctx);
                _bloc.add(DeleteList(listId: list.id));
              },
            ),
            ListTile(
              leading: Icon(Icons.close, size: 22.sp),
              title: const Text('Bekor'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, SalesCalcList list) {
    final controller = TextEditingController(text: list.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nomini o\'zgartirish'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Yangi nom...'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _bloc.add(RenameList(listId: list.id, name: value.trim()));
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _bloc.add(RenameList(listId: list.id, name: name));
                Navigator.pop(ctx);
              }
            },
            child: Text('Saqlash', style: TextStyle(color: _p.accent(const Color(0xFF7C3AED)))),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Sozlamalar — content extracted to [SalesCalcSettingsSheet] (this
  /// file was already far past its size budget). The sheet reads and
  /// mutates settings through the bloc handed down here.
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: _bloc,
        child: SalesCalcSettingsSheet(stockLockText: widget.stockLockText),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _p.raised(Colors.grey.shade100),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(8.sp),
          child: Icon(icon, size: 20.sp, color: _p.textSecondary(Colors.grey.shade700)),
        ),
      ),
    );
  }

  /// Primary "Sotuv" / save-as-debt CTA placed at the right edge of the
  /// footer (next to the `Jami:` total). Disabled when the cart is empty.
  /// When the tariff gate is OFF the button keeps its position but
  /// renders with a lock icon and routes the tap to [onLockedAttempt]
  /// instead of the save action — keeps the upsell discoverable.
  Widget _buildSaveAsDebtButton(SalesCalcState state) {
    final cartHasItems = state.items.any((item) => item.result > 0);
    final locked = !widget.isSalesToDebtAllowed;
    // Locked state intentionally stays tappable so the user gets the
    // upsell; the cart-empty disabled state still gates on items.
    final enabled = !_savingAsDebt && (locked || cartHasItems);
    return ElevatedButton.icon(
      onPressed: enabled
          ? () {
              if (locked) {
                widget.onLockedAttempt?.call();
                return;
              }
              _saveAsDebt(state);
            }
          : null,
      icon: Icon(
        locked ? Icons.lock_outline : Icons.point_of_sale_rounded,
        size: 18.sp,
      ),
      label: const Text('Sotuv'),
      style: ElevatedButton.styleFrom(
        backgroundColor: locked
            ? Colors.grey.shade500
            : const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        disabledBackgroundColor: _p.raised(Colors.grey.shade300),
        padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 8.sp),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    );
  }

  /// Extracted save flow so both the footer button and any future
  /// call-sites can trigger it consistently. Moved out of the old
  /// AppBar IconButton inline closure verbatim — same client-snapshot
  /// pattern, same bloc-sync-before-host-call ordering.
  Future<void> _saveAsDebt(SalesCalcState state) async {
    final cb = widget.onSaveAsDebt;
    if (cb == null || _savingAsDebt) return;
    final soldMark = _activeSoldMark;
    if (soldMark != null) {
      final choice = await _askSellAgain(soldMark);
      if (!mounted) return;
      if (choice == _SellAgainChoice.newSheet) {
        _startNewList();
        return;
      }
      if (choice != _SellAgainChoice.sellAgain) return;
    }
    setState(() => _savingAsDebt = true);
    try {
    // Card #132 chose "warn" over silent loss: with the toggle ON,
    // free-text rows carry no product link and will NOT decrement
    // stock — surface that before the sale instead of hiding it.
    if (_bloc.state.deductStock) {
      final filled = state.items.where((i) => i.expression.trim().isNotEmpty);
      final unlinked = filled.where((i) => i.productId == null).length;
      // Only a MIXED sale needs the warning (Trello #439): with the toggle
      // now on by default, an all-free-text sale — nothing to deduct — asked
      // on every tap.
      final linked = filled.length - unlinked;
      if (unlinked > 0 && linked > 0) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Skladdan kamaytirish'),
            content: Text(
                "$unlinked ta qator mahsulotga bog'lanmagan — ular skladdan kamaymaydi. Davom etasizmi?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Bekor qilish'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Davom etish'),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
    }
    // "Skladdan kamaytirish" writes stock movements from the CLONE the
    // host makes right after this call — force the pre-save sync while
    // the toggle is ON so the server rows carry fresh quantities even
    // when the list was loaded clean (synced earlier without them).
    // With the toggle OFF this stays the old dirty-only sync.
    final synced = await _bloc.syncBeforeExit(force: _bloc.state.deductStock || state.hasStructuredItems);
    if (!mounted) return;
    if (!synced) {
      // The inline banner already says exactly this — don't stack a
      // snackbar with the same text under it.
      if (_bloc.state.errorMessage != 'sync_failed') {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_failureText(_bloc.lastSyncError))));
      }
      return;
    }
    var submittedItems = _bloc.state.items;
    if (state.hasStructuredItems) {
      try {
        submittedItems = await SalesCalcPackage.repository
            .getItems(SalesCalcPackage.shopId, state.activeListId!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_failureText(e))));
        }
        return;
      }
      if (!mounted) return;
    }
    // Snapshot the client at submit time — the host may navigate
    // away (receipt route) before returning, and the user could
    // change _boundClientId in the meantime. Stable snapshot keeps
    // the linked-debt chip honest.
    final submittedClientId = _boundClientId;
    final submittedClientName = _boundClientName;
    final debtId = await cb(
      context,
      SalesCalcSaveDebtArgs(
        activeListId: state.activeListId,
        items: submittedItems,
        total: state.total,
        boundClientId: submittedClientId,
        boundClientName: submittedClientName,
      ),
    );
    if (!mounted || debtId == null) return;
    final soldListId = state.activeListId;
    if (soldListId != null) {
      final reference = state.lists
              .where((l) => l.id == soldListId)
              .map((l) => l.name)
              .firstOrNull ??
          '#$debtId';
      setState(() {
        _soldMarks = SalesCalcSoldMarks.put(
          _soldMarks,
          soldListId,
          SalesCalcSoldMark(
            debtId: debtId,
            reference: reference,
            clientId: submittedClientId,
            clientName: submittedClientName,
          ),
        );
      });
      SalesCalcPackage.writeSoldMarks(_soldMarks);
    }
    } finally {
      if (mounted) setState(() => _savingAsDebt = false);
    }
  }

  void _copyToClipboard(SalesCalcState state) {
    final buffer = StringBuffer();
    for (var i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      if (item.expression.trim().isEmpty) continue;
      final labelPart = (state.showLabels && item.label != null && item.label!.isNotEmpty)
          ? '${item.label}: '
          : '';
      buffer.writeln('$labelPart${item.productUnitId != null ? '${widget.formatQuantity(item.enteredQuantity ?? item.quantity)} ${item.unitNameSnapshot ?? ''} × ${widget.formatMoney(item.unitPrice, widget.currencyCodes[item.currencyId])}' : item.expression} = ${_formatNumber(item.result, item.currencyId)}${item.currencyId == null ? '' : ' ${widget.currencyCodes[item.currencyId] ?? item.currencyId}'}');
    }
    buffer.writeln('───────────');
    buffer.writeln('Jami: ${_displayTotal(state)}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nusxalandi'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Every money figure on this screen goes through the host's formatter.
  ///
  /// This used to be a local `NumberFormat('#,###')`, so a row could show
  /// "1 Dona × 6 500 UZS" as its subtitle and "6,500 UZS" as its result —
  /// the same amount, two separators, one row (Trello #376/#377).
  String _formatNumber(double value, [int? currencyId]) => widget.formatMoney(
      value,
      widget.currencyCodes[currencyId ?? widget.defaultCurrencyId]);

  Future<_SellAgainChoice?> _askSellAgain(SalesCalcSoldMark mark) {
    final t = widget.soldTexts;
    return showDialog<_SellAgainChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.againTitle),
        content: Text(t.againBody(mark.reference)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_SellAgainChoice.sellAgain),
            child: Text(t.sellAgain),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_SellAgainChoice.newSheet),
            child: Text(t.newSheet),
          ),
        ],
      ),
    );
  }

  String _failureText(Object? error) =>
      widget.tradeFailureMessage?.call(error) ?? widget.tradeFailureText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _bloc.syncBeforeExit();
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
        backgroundColor: _p.page(Colors.white),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 46,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20.sp, color: _p.text(Colors.black87)),
            onPressed: () async {
              await _bloc.syncBeforeExit();
              if (!context.mounted) return;
              // Two entry points need different pop targets:
              //   - Drawer flow: this page lives inside SalesCalcRouterPage's
              //     inner AutoRouter; popping locally would leave the inner
              //     router empty (blank screen). Walk up to the parent so
              //     the whole router page closes.
              //   - FAB flow (SalesCalcWithClientRoute): this page is the
              //     route at the top of the root router — there is no
              //     parent, pop locally.
              final parent = context.router.parent();
              if (parent != null) {
                final popped = await parent.maybePop();
                if (popped) return;
                if (!context.mounted) return;
              }
              final popped = await context.router.maybePop();
              if (popped) return;
              if (!context.mounted) return;
              await Navigator.of(context, rootNavigator: true).maybePop();
            },
          ),
          title: Text(
            'Sotuv Kalkulyator',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: _p.text(Colors.black87),
            ),
          ),
          actions: [
            // The "Save as debt" / Sotuv action that used to live here
            // moved to the footer row next to the `Jami:` total — the
            // visual flow "build → see total → save" reads better
            // when the CTA sits right beside the number. See
            // `_buildSaveAsDebtButton` invoked in the footer below.
            // Manual sync: flush local edits, re-pull lists + items and
            // refresh the offline product catalog (otherwise products
            // added on web/another device wait out the 5-min TTL).
            IconButton(
              tooltip: 'Yangilash',
              icon: Icon(Icons.sync, size: 20.sp, color: _p.textSecondary(Colors.grey.shade600)),
              onPressed: () =>
                  _bloc.add(const LoadSalesCalcLists(refresh: true)),
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 20.sp, color: _p.textSecondary(Colors.grey.shade600)),
              onPressed: _showSettings,
            ),
            IconButton(
              icon: Icon(Icons.add, size: 22.sp, color: _p.accent(const Color(0xFF7C3AED))),
              onPressed: _startNewList,
            ),
          ],
        ),
        // SafeArea(top:false): with Android 15+ edge-to-edge the body
        // extends behind the system navigation bar, and the footer row
        // (copy / save / Sotuv / Jami) plus the custom calc keyboard were
        // buried under it. The AppBar already handles the top inset.
        body: SafeArea(
          top: false,
          child: BlocBuilder<SalesCalcBloc, SalesCalcState>(
          builder: (context, state) {
            if (state.status == SalesCalcStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == SalesCalcStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Xatolik yuz berdi', style: TextStyle(fontSize: 16.sp)),
                    SizedBox(height: 8.sp),
                    ElevatedButton(
                      onPressed: () => _bloc.add(const LoadSalesCalcItems()),
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                if (state.errorMessage == 'sync_failed')
                  Padding(padding: const EdgeInsets.all(12),
                    child: Text(widget.tradeFailureText, style: const TextStyle(color: Colors.red))),
                // Client binding pill. Bound: name + clear (X). Unbound:
                // "Mijoz tanlash" placeholder that delegates to the host
                // via onPickClient — the package itself doesn't ship a
                // client picker, so we hide the placeholder when the
                // host didn't wire one up.
                if (_boundClientId != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.sp, 6.sp, 12.sp, 0),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _boundClientId = null;
                        _boundClientName = null;
                      }),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.sp, vertical: 6.sp),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 14.sp,
                                color: _p.accent(const Color(0xFF7C3AED))),
                            SizedBox(width: 6.sp),
                            Text(
                              _boundClientName ?? '#$_boundClientId',
                              style: TextStyle(
                                color: _p.accent(const Color(0xFF7C3AED)),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.sp),
                            Icon(Icons.close, size: 12.sp,
                                color: _p.accent(const Color(0xFF7C3AED))),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (widget.onPickClient != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.sp, 6.sp, 12.sp, 0),
                    child: GestureDetector(
                      // Tariff-gated: locked users route to the upgrade
                      // page via `onLockedAttempt` so they can't quietly
                      // pick a client and then hit the same gate later
                      // when they try to save. The chip stays visible
                      // (with a lock icon swap) so the upsell remains
                      // discoverable.
                      onTap: widget.isSalesToDebtAllowed
                          ? _promptPickClient
                          : (widget.onLockedAttempt ?? () {}),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.sp, vertical: 6.sp),
                        decoration: BoxDecoration(
                          color: widget.isSalesToDebtAllowed
                              ? _p.raised(Colors.grey.shade100)
                              : _p.border(Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
                              style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isSalesToDebtAllowed
                                  ? Icons.person_add_alt_1
                                  : Icons.lock_outline,
                              size: 14.sp,
                              color: widget.isSalesToDebtAllowed
                                  ? _p.accent(const Color(0xFF7C3AED))
                                  : _p.textSecondary(Colors.grey.shade600),
                            ),
                            SizedBox(width: 6.sp),
                            Text(
                              'Mijoz tanlash',
                              style: TextStyle(
                                color: widget.isSalesToDebtAllowed
                                    ? _p.accent(const Color(0xFF7C3AED))
                                    : _p.textSecondary(Colors.grey.shade700),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // "Saqlangan qarz" chip — appears after Save-as-Debt
                // succeeds on this list. Tap delegates to the host
                // (typically opens the client profile + debt receipt).
                if (_activeSoldMark case final sold?)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.sp, 6.sp, 12.sp, 0),
                    child: GestureDetector(
                      onTap: () {
                        final cb = widget.onOpenLinkedDebt;
                        if (cb == null) return;
                        cb(
                          context,
                          debtId: sold.debtId,
                          clientId: sold.clientId,
                          clientName: sold.clientName,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.sp, vertical: 6.sp),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 14.sp,
                                color: _p.success(const Color(0xFF059669))),
                            SizedBox(width: 6.sp),
                            Text(
                              sold.clientName != null
                                  ? '${widget.soldTexts.chip}: ${sold.clientName!} · №${sold.reference}'
                                  : '${widget.soldTexts.chip} · №${sold.reference}',
                              style: TextStyle(
                                color: _p.success(const Color(0xFF059669)),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.sp),
                            Icon(Icons.chevron_right,
                                size: 14.sp,
                                color: _p.success(const Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ),
                  ),
                // List tabs
                if (state.lists.length > 1)
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _p.border(Colors.grey.shade200))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8.sp),
                      itemCount: state.lists.length,
                      itemBuilder: (context, index) {
                        final list = state.lists[index];
                        final isActive = list.id == state.activeListId;
                        return GestureDetector(
                          onTap: () => _switchToList(list.id),
                          onLongPress: () => _showListOptions(context, list),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.sp),
                            margin: EdgeInsets.only(right: 4.sp),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isActive ? _p.accent(const Color(0xFF7C3AED)) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              list.name ?? '#${index + 1}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? _p.accent(const Color(0xFF7C3AED)) : _p.textSecondary(Colors.grey.shade600),
                              ),
                            ),
                          ),
                        );
                      },
                          ),
                        ),
                        // Vertical list browser — the horizontal strip
                        // hides everything past a few tabs; this opens
                        // the same lists stacked vertically with their
                        // totals so an old sale is one tap away.
                        InkWell(
                          onTap: _showListsSheet,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.sp),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: _p.border(Colors.grey.shade200)),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.view_agenda_outlined,
                              size: 18.sp,
                              color: _p.textSecondary(Colors.grey.shade600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Column header
                Container(
                  width: double.infinity,
                  // horizontal 8.sp matches the row containers exactly —
                  // 12.sp shifted every header label 4.sp off its column.
                  padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
                  decoration: BoxDecoration(
                    color: _p.surface(const Color(0xFFF8F7FC)),
                    border: Border(bottom: BorderSide(color: _p.border(Colors.grey.shade300))),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 28.sp, child: Text('#', style: TextStyle(fontSize: 12.sp, color: Colors.blue, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                      _columnDivider(16),
                      if (state.showLabels) ...[
                        Expanded(child: Padding(padding: EdgeInsets.only(left: 4.sp), child: Text('Nomi', style: TextStyle(fontSize: 12.sp, color: Colors.blue, fontWeight: FontWeight.w600)))),
                        _columnDivider(16),
                      ],
                      // Width 140.sp matches the Ifoda input column —
                      // widened from 110.sp so expressions like
                      // "1000*5000" fit without the input scrolling /
                      // visually jumping mid-typing. Right padding 8.sp
                      // mirrors the input's contentPadding so the header
                      // text ends on the same edge as the typed value.
                      SizedBox(width: 110.sp, child: Padding(padding: EdgeInsets.only(right: 8.sp), child: Text('Narxi*soni', style: TextStyle(fontSize: 12.sp, color: Colors.blue, fontWeight: FontWeight.w600), textAlign: TextAlign.end))),
                      _columnDivider(16),
                      SizedBox(width: 100.sp, child: Text('Natija', style: TextStyle(fontSize: 12.sp, color: Colors.blue, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Tap empty area → hide keyboard
                      FocusScope.of(context).unfocus();
                      setState(() => _isKeyboardVisible = false);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          // New line row
                          return _buildNewLineRow();
                        }
                        final item = state.items[index];
                        return _buildItemRow(item, index);
                      },
                    ),
                  ),
                ),
                // Product autocomplete suggestions render inline under
                // the active row (see _buildItemRow / _buildNewLineRow)
                // so they read as a dropdown attached to what the user
                // is typing — not a strip floating above the footer.
                // Total bar with actions
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
                  decoration: BoxDecoration(
                    color: _p.surface(Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Copy button
                      _buildActionIcon(
                        icon: Icons.copy,
                        tooltip: 'Nusxalash',
                        onTap: () => _copyToClipboard(state),
                      ),
                      SizedBox(width: 8.sp),
                      // Save button
                      _buildActionIcon(
                        icon: Icons.save,
                        tooltip: 'Saqlash',
                        onTap: () {
                          _bloc.add(const SyncToBackend());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saqlandi'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      // ─── "Sotuv" save-as-debt CTA ─────────────────
                      // Sits beside Copy/Save so the action cluster
                      // (utility icons + the primary save-as-debt CTA)
                      // reads as one toolbar on the left. Stays hidden
                      // when the host didn't wire `onSaveAsDebt`. When
                      // the user's tariff doesn't allow client linking
                      // we still render the button (discoverability) but
                      // swap the icon for a lock and route the tap to
                      // the upgrade page via `onLockedAttempt`.
                      if (widget.onSaveAsDebt != null) ...[
                        SizedBox(width: 8.sp),
                        _buildSaveAsDebtButton(state),
                      ],
                      // Trello #377: the gap and the total now share the
                      // leftover room (Spacer flex 1 vs Flexible flex 3)
                      // instead of the gap taking all of it, so the figure
                      // sits further left and a two-currency total has
                      // somewhere to expand. The smaller type keeps it on
                      // one line more often.
                      const Spacer(),
                      Text(
                        'Jami:',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: _p.textSecondary(Colors.grey.shade600)),
                      ),
                      SizedBox(width: 6.sp),
                      Flexible(
                              flex: 3,
                              child: Text(
                        _displayTotal(state),
                            maxLines: 3,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: _p.accent(const Color(0xFF7C3AED)),
                        ),
                      )),
                    ],
                  ),
                ),
                // Custom keyboard
                if (_isKeyboardVisible)
                  CalcKeyboard(
                    onKeyPressed: _onKeyboardKey,
                    onBackspace: _onKeyboardBackspace,
                    onSubmit: _onKeyboardSubmit,
                    onClear: _onKeyboardClear,
                  ),
              ],
            );
          },
          ),
        ),
      ),
      ),
    );
  }

  /// The footer total, formatted the same way as the lines above it.
  ///
  /// It used to go through [_formatNumber] (a local `#,###`), which put a
  /// comma in the total while every line rendered by the host's formatter
  /// used a space — two separators for the same money on one screen.
  String _displayTotal(SalesCalcState state) => !state.hasStructuredItems
      ? widget.formatMoney(
          state.total, widget.currencyCodes[widget.defaultCurrencyId])
      : state.totalsByCurrency.entries
          .map((entry) =>
              '${widget.formatMoney(entry.value, widget.currencyCodes[entry.key])} ${widget.currencyCodes[entry.key] ?? entry.key ?? "?"}')
          .join(' / ');

  Future<bool> _configureProduct(
      int productId, String name, SalesCalcItem? current) async {
    final callback = widget.onConfigureProduct;
    if (callback == null ||
        (!_bloc.state.deductStock && current?.productUnitId == null)) {
      return false;
    }
    if (_configuringProduct) return true;
    _configuringProduct = true;
    FocusScope.of(context).unfocus();
    setState(() => _isKeyboardVisible = false);
    try {
      final choice = await callback(context, productId, name, current);
      if (!mounted || !choice.handled) return choice.handled;
      if (choice.item != null) {
        _bloc.add(SetStructuredProductLine(
            item: choice.item!, replacingId: current?.id));
        _bloc.add(const ClearProductSuggestions());
        if (current == null) {
          _newLineController.clear();
          _newLineLabelController.clear();
          _newLinePickedLabel = null;
          _newLinePickedProductId = null;
          setState(() {
            _newLineResult = 0;
            _newLineLabelDuplicate = false;
          });
        }
      }
      return true;
    } finally {
      _configuringProduct = false;
    }
  }

  Widget _buildItemRow(SalesCalcItem item, int index) {
    if (item.productUnitId != null) {
      final code =
          widget.currencyCodes[item.currencyId] ?? item.currencyId.toString();
      return ListTile(
          key: ValueKey(item.id),
          title: Text(item.label ?? ''),
          subtitle: Text(
              '${widget.formatQuantity(item.enteredQuantity ?? item.quantity)} ${item.unitNameSnapshot ?? ""} × ${widget.formatMoney(item.unitPrice, code)} $code'),
          onTap: widget.onConfigureProduct == null
              ? null
              : () =>
                  _configureProduct(item.productId!, item.label ?? '', item),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${_formatNumber(item.result, item.currencyId)} $code'),
            IconButton(
                onPressed: () => _bloc.add(DeleteSalesCalcItem(id: item.id)),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.delete_outline)),
          ]));
    }
    final focusNode = _getFocusNode(item.id);
    final controller = _getController(item.id, item.expression);
    final labelController = _getLabelController(item.id, item.label);
    final showLabels = _bloc.state.showLabels;

    // Update controller text if it changed from server (and not focused)
    if (!focusNode.hasFocus && controller.text != item.expression) {
      controller.text = item.expression;
    }

    final state = _bloc.state;
    final showSuggestionsHere = state.showLabels &&
        state.productSearchLineId == item.id &&
        state.productSuggestions.isNotEmpty;

    final row = Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _bloc.add(DeleteSalesCalcItem(id: item.id));
        _lineFocusNodes.remove(item.id)?.dispose();
        _lineControllers.remove(item.id)?.dispose();
        _labelControllers.remove(item.id)?.dispose();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.sp),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: focusNode.hasFocus ? _p.accentTint(const Color(0xFFF3F0FF)) : _p.page(Colors.white),
          border: Border(bottom: BorderSide(color: _p.border(Colors.grey.shade200))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.sp,
              child: Text(
                '${index + 1}',
                style: TextStyle(fontSize: 13.sp, color: Colors.blue, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            _columnDivider(26),
            // Label column (optional) — also drives the product search
            // for the autocomplete strip rendered above the total bar.
            // Now flex-sized: long product names ("koka kola 1.5L")
            // were getting truncated against an 80.sp wall while the
            // Ifoda column had headroom for short expressions. Swap:
            // Nomi gets the flexible remainder, Ifoda is pinned to a
            // fixed 110.sp matching the header.
            if (showLabels)
              Expanded(
                child: Container(
                  // Later occurrence of a duplicated name gets the red
                  // border (the first keeps normal styling) — recomputed
                  // live on every bloc emission, so it appears/clears as
                  // labels are edited anywhere in the list.
                  decoration: _labelCellDecoration(_isDuplicateLabel(
                      item.label ?? '',
                      beforeIndex: index)),
                  child: TextField(
                  controller: labelController,
                  onTap: () {
                    // Text field → system keyboard; hide the custom
                    // keypad so the two never stack.
                    if (_isKeyboardVisible) {
                      setState(() => _isKeyboardVisible = false);
                    }
                    // Re-fire search using the current text so the
                    // suggestions strip shows up the moment the user
                    // taps back into the field.
                    _bloc.add(SearchProducts(
                      query: labelController.text,
                      lineId: item.id,
                    ));
                  },
                  onChanged: (value) {
                    _bloc.add(UpdateItemLabel(id: item.id, label: value));
                    // Picking an existing product is now the user's
                    // intent — drop any prior product link until they
                    // pick a new suggestion. The backend's
                    // resolve-or-create handles the unmatched case on
                    // save.
                    if (item.productId != null) {
                      _bloc.add(UpdateItemProduct(id: item.id, label: value));
                    }
                    _bloc.add(SearchProducts(query: value, lineId: item.id));
                  },
                  style: TextStyle(fontSize: 12.sp, color: _p.text(Colors.grey.shade700)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: _p.isDark ? false : null,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
                    hintText: "Nomi",
                    hintStyle: TextStyle(fontSize: 11.sp, color: _p.textSecondary(Colors.grey.shade400)),
                  ),
                  // Tap Done/Next on the system keyboard → hand off to
                  // the Ifoda field's custom numeric keyboard. Without
                  // this the system keyboard just dismissed and the
                  // user had to manually tap the Ifoda cell to bring
                  // up the in-app keypad. Both the system "Next" arrow
                  // and the explicit onSubmitted handler are needed:
                  // the action only changes the keyboard label, the
                  // handler does the actual focus + keyboard swap via
                  // `_setActiveField` (which is what gates the custom
                  // numeric pad).
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      _handOffToExpression(controller, focusNode),
                  ),
                ),
              ),
            if (showLabels) _columnDivider(26),
            SizedBox(
              width: 110.sp,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: true, // Use custom keyboard
                showCursor: true,
                onTap: () => _setActiveField(controller, focusNode),
                onChanged: (value) {
                  final result = ExpressionEvaluator.evaluate(value);
                  _bloc.add(UpdateLocalExpression(id: item.id, expression: value, result: result));
                },
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                // Right-align so the column LOOKS the same regardless
                // of expression length — "10" and "1000*5000" both sit
                // at the same right edge instead of left-anchored text
                // visually "growing" rightward and making the cursor
                // jump as the user types. Matches the result column to
                // its right (also TextAlign.end) for a clean column.
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: _p.isDark ? false : null,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  hintText: "Narx*Soni...",
                  hintStyle: TextStyle(fontSize: 14.sp, color: _p.textSecondary(Colors.grey.shade400)),
                ),
              ),
            ),
            _columnDivider(26),
            SizedBox(
              width: 100.sp,
              child: Text(
                _formatNumber(item.result),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: item.result < 0 ? Colors.red : _p.text(Colors.black87),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );

    // Always wrap in a Column so the Element tree stays stable when
    // suggestions toggle on/off — otherwise Flutter would unmount the
    // row's TextField and the user would lose focus mid-typing (e.g.
    // when they backspace the last character and the suggestions
    // disappear).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (showSuggestionsHere) _buildProductSuggestions(state),
      ],
    );
  }

  /// Thin vertical rule between table columns — used in the header and
  /// in every row so the boundaries read as one continuous gridline.
  Widget _columnDivider(double height) => Container(
        width: 1,
        height: height.sp,
        color: _p.border(Colors.grey.shade300),
      );

  Widget _buildProductSuggestions(SalesCalcState state) {
    final lineId = state.productSearchLineId!;
    // Never offer a product that already labels a row. The new-line row
    // uses a sentinel id that matches no item, so everything already in
    // the list is excluded for it — which is what we want.
    final suggestions = _suggestionsExcludingTaken(
      state.productSuggestions,
      lineId: lineId,
    );
    // Everything matching is already in the list: drop the dropdown
    // rather than render an empty bordered box.
    if (suggestions.isEmpty) return const SizedBox.shrink();
    // Browse mode (empty query = proactive catalog offer on focus):
    // show NAMES ONLY — the Ifoda/Natija preview cells stay hidden
    // until the user picks or types.
    final browseMode = state.productSearchQuery.isEmpty;
    // Cap visible height so the dropdown never pushes the footer
    // off-screen; the inner ListView scrolls when there are more
    // matches than fit. ~44.sp per row × 5 rows = roughly 220.sp.
    final maxHeight = 220.sp;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _p.surface(Colors.white),
        border: Border(
          top: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
          bottom: BorderSide(color: _p.border(Colors.grey.shade200)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: _p.border(Colors.grey.shade100),
        ),
        itemBuilder: (context, i) {
          final p = suggestions[i];
          // Mirror the column layout of the item rows above: Nomi |
          // Ifoda (110.sp) | Natija (100.sp). Preview exactly what tapping
          // inserts — only the unit price, no auto-filled quantity.
          final fill = _expressionFromProduct(p);
          final ifoda = fill?.expression;
          final natija = fill?.result;
          return InkWell(
            onTap: () => _onPickProduct(lineId, p),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 10.sp),
              child: Row(
                children: [
                  SizedBox(width: 28.sp),
                  Expanded(
                    child: Text(
                      p.name,
                      style: TextStyle(fontSize: 13.sp, color: _p.text(Colors.grey.shade800)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!browseMode) ...[
                    SizedBox(
                      width: 110.sp,
                      child: Text(
                        (ifoda != null && ifoda.isNotEmpty) ? ifoda : '',
                        style: TextStyle(fontSize: 13.sp, color: _p.textSecondary(Colors.grey.shade600)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 100.sp,
                      child: Text(
                        natija != null ? _formatNumber(natija) : '',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _p.accent(const Color(0xFF7C3AED)),
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Resolve what the autocomplete should drop into the Ifoda field.
  /// Inserts ONLY the unit price — never a quantity. It used to restore the
  /// product's last full expression (e.g. `200*100`), which auto-filled the
  /// previous quantity; the cashier now types the quantity themselves.
  ({String expression, double result})? _expressionFromProduct(
    ShopProduct product,
  ) {
    final price = product.price;
    if (price != null && price > 0) {
      return (expression: price.toStringAsFixed(0), result: price);
    }
    // No catalog price (e.g. a product only ever used inside a calc list):
    // fall back to the last expression ONLY when it's a bare price scalar with
    // no quantity math, so we still never auto-fill a quantity.
    final lastExp = product.lastExpression?.trim();
    if (lastExp != null &&
        lastExp.isNotEmpty &&
        !RegExp(r'[*x×/+\-]').hasMatch(lastExp)) {
      final result = product.lastResult ?? ExpressionEvaluator.evaluate(lastExp);
      return (expression: lastExp, result: result);
    }
    return null;
  }

  void _onPickProduct(int lineId, ShopProduct product) async {
    final current = lineId == _newLineSearchId
        ? null
        : _bloc.state.items.where((item) => item.id == lineId).firstOrNull;
    if (await _configureProduct(product.id, product.name, current)) return;
    if (!mounted) return;
    final fill = _expressionFromProduct(product);

    // New-line row uses a sentinel id; picked values live on this
    // widget's state until the user submits the line.
    if (lineId == _newLineSearchId) {
      // The picked product already labels a row in this list —
      // duplicates are not allowed, so reject the pick: show the name
      // with the red border and keep the cursor in Nomi for a fix.
      if (_isDuplicateLabel(product.name)) {
        _newLineLabelController.text = product.name;
        _newLinePickedLabel = null;
        _newLinePickedProductId = null;
        setState(() => _newLineLabelDuplicate = true);
        _bloc.add(const ClearProductSuggestions());
        _focusNewLine();
        return;
      }
      if (_newLineLabelDuplicate) {
        setState(() => _newLineLabelDuplicate = false);
      }
      _newLineLabelController.text = product.name;
      _newLinePickedLabel = product.name;
      _newLinePickedProductId = product.id;
      if (_newLineController.text.trim().isEmpty && fill != null) {
        // Seed "<price>*" and drop the cursor after the operator so the cashier
        // types only the quantity. Result stays at the unit price until they do
        // (evaluator ignores the trailing operator).
        _newLineController.text = '${fill.expression}*';
        setState(() => _newLineResult = fill.result);
      }
      _bloc.add(const ClearProductSuggestions());
      // Move focus to expression so the user can immediately edit.
      _handOffToExpression(_newLineController, _newLineFocusNode);
      return;
    }

    final item = _bloc.state.items.firstWhere(
      (it) => it.id == lineId,
      orElse: () => SalesCalcItem(
        id: lineId,
        expression: '',
        result: 0,
        position: 0,
      ),
    );

    // Update the visible label controller so the field reflects the
    // chosen product immediately (the bloc state is the source of
    // truth, but the field's TextEditingController has its own buffer).
    final lblCtrl = _labelControllers[lineId];
    if (lblCtrl != null && lblCtrl.text != product.name) {
      lblCtrl.text = product.name;
    }

    _bloc.add(UpdateItemLabel(id: lineId, label: product.name));
    _bloc.add(UpdateItemProduct(
      id: lineId,
      productId: product.id,
      label: product.name,
    ));

    // Auto-fill the expression with the product's last-used math ONLY
    // when the line has no expression yet — never overwrite user input.
    final isExpressionEmpty = item.expression.trim().isEmpty;
    if (isExpressionEmpty && fill != null) {
      // Seed "<price>*" and drop the cursor after the operator so the cashier
      // types only the quantity (see _handOffToExpression below). Result stays
      // at the unit price until they do (evaluator ignores the trailing op).
      final seeded = '${fill.expression}*';
      final expCtrl = _lineControllers[lineId];
      if (expCtrl != null) {
        expCtrl.text = seeded;
      }
      _bloc.add(UpdateLocalExpression(
        id: lineId,
        expression: seeded,
        result: fill.result,
      ));
    }

    _bloc.add(const ClearProductSuggestions());

    // Hand focus to this row's expression field so the user can type
    // the math immediately — mirrors the new-line pick behavior above.
    final rowExprCtrl = _lineControllers[lineId];
    if (rowExprCtrl != null) {
      _handOffToExpression(rowExprCtrl, _getFocusNode(lineId));
    }
  }

  Widget _buildNewLineRow() {
    final showLabels = _bloc.state.showLabels;
    final state = _bloc.state;
    final showSuggestionsHere = state.showLabels &&
        state.productSearchLineId == _newLineSearchId &&
        state.productSuggestions.isNotEmpty;
    final row = GestureDetector(
      onTap: () {
        // When labels are shown, prefer landing the user in the Nomi
        // field so they pick a product first. Falls back to the
        // expression field when labels are off.
        if (showLabels) {
          _newLineLabelFocusNode.requestFocus();
        } else {
          _newLineFocusNode.requestFocus();
          _setActiveField(_newLineController, _newLineFocusNode);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: _p.accentTint(const Color(0xFFF3F0FF)),
          border: Border(bottom: BorderSide(color: _p.border(Colors.grey.shade200))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.sp,
              child: Icon(Icons.add, size: 16.sp, color: _p.accent(const Color(0xFF7C3AED))),
            ),
            _columnDivider(26),
            // New-line Nomi field with autocomplete. System keyboard
            // is fine here — labels are short text, not arithmetic.
            // Column widths mirror the item rows (Nomi = remainder,
            // Ifoda = fixed 110.sp) so the new-line row aligns to
            // both the header and the existing rows above it.
            if (showLabels)
              Expanded(
                child: Container(
                  decoration: _labelCellDecoration(_newLineLabelDuplicate),
                  child: TextField(
                  controller: _newLineLabelController,
                  focusNode: _newLineLabelFocusNode,
                  onTap: () {
                    // Text field → system keyboard; never leave the
                    // custom keypad stacked underneath it.
                    if (_isKeyboardVisible) {
                      setState(() => _isKeyboardVisible = false);
                    }
                    _bloc.add(SearchProducts(
                      query: _newLineLabelController.text,
                      lineId: _newLineSearchId,
                    ));
                  },
                  onChanged: (value) {
                    // Typing owns the suggestions — cancel the pending
                    // browse offer so it can't replace typed results.
                    _browseTimer?.cancel();
                    // User edited after picking — drop the FK link;
                    // backend's resolve-or-create will re-link on save.
                    if (_newLinePickedProductId != null) {
                      _newLinePickedProductId = null;
                      _newLinePickedLabel = null;
                    }
                    // Live duplicate check — red border appears/clears
                    // as the user types, not only on a blocked submit.
                    final dup = _isDuplicateLabel(value);
                    if (dup != _newLineLabelDuplicate) {
                      setState(() => _newLineLabelDuplicate = dup);
                    }
                    _bloc.add(SearchProducts(
                      query: value,
                      lineId: _newLineSearchId,
                    ));
                  },
                  // Done on the system keyboard hands off to the
                  // expression field's custom keypad — same flow as the
                  // item rows, so "type name → ✓ → type math" never
                  // needs a manual tap on the Narx*Soni cell.
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      _handOffToExpression(_newLineController, _newLineFocusNode),
                  style: TextStyle(fontSize: 13.sp, color: _p.text(Colors.grey.shade800)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: _p.isDark ? false : null,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
                    hintText: "Mahsulot",
                    hintStyle: TextStyle(fontSize: 12.sp, color: _p.accent(const Color(0xFF7C3AED)).withValues(alpha: 0.7)),
                  ),
                  ),
                ),
              ),
            if (showLabels) _columnDivider(26),
            SizedBox(
              width: 110.sp,
              child: TextField(
                controller: _newLineController,
                focusNode: _newLineFocusNode,
                readOnly: true,
                showCursor: true,
                onTap: () => _setActiveField(_newLineController, _newLineFocusNode),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                // Right-aligned to match the existing-row input above —
                // see comment there for the rationale.
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: _p.isDark ? false : null,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  hintText: showLabels ? "Narx*Soni" : "Yangi qator...",
                  hintStyle: TextStyle(fontSize: 14.sp, color: _p.textSecondary(Colors.grey.shade400)),
                ),
              ),
            ),
            _columnDivider(26),
            // Always present (empty when 0) so the expression column
            // keeps the same right edge as the item rows and the
            // header — hiding it let the field drift under "Natija".
            SizedBox(
              width: 100.sp,
              child: Text(
                _newLineResult != 0.0 ? _formatNumber(_newLineResult) : '',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _p.textSecondary(Colors.black54)),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );

    // See note in _buildItemRow — always wrap in a Column so the
    // Element tree is stable across suggestion show/hide transitions.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (showSuggestionsHere) _buildProductSuggestions(state),
      ],
    );
  }

}

enum _SellAgainChoice { newSheet, sellAgain }
