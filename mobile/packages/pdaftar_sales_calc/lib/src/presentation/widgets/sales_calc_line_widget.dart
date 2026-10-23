import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sales_calc_item.dart';
import '../sales_calc_palette.dart';
import 'expression_evaluator.dart';

class SalesCalcLineWidget extends StatefulWidget {
  final SalesCalcItem? item;
  final int lineNumber;
  final bool isNewLine;
  final ValueChanged<SalesCalcItem>? onChanged;
  final ValueChanged<String>? onNewLineSubmitted;
  final VoidCallback? onDelete;
  final FocusNode? focusNode;
  final VoidCallback? onEditStructured;
  final String? currencyCode;

  const SalesCalcLineWidget({
    super.key,
    this.item,
    required this.lineNumber,
    this.isNewLine = false,
    this.onChanged,
    this.onNewLineSubmitted,
    this.onDelete,
    this.focusNode,
    this.onEditStructured,
    this.currencyCode,
  });

  @override
  State<SalesCalcLineWidget> createState() => _SalesCalcLineWidgetState();
}

class _SalesCalcLineWidgetState extends State<SalesCalcLineWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  double _localResult = 0.0;
  String? _lastSavedExpression;

  static final _formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item?.expression ?? '');
    _focusNode = widget.focusNode ?? FocusNode();
    _localResult = widget.item?.result ?? 0.0;
    _lastSavedExpression = widget.item?.expression;

    _focusNode.addListener(_onFocusChange);
    // Listen to controller changes so both system-keyboard typing AND
    // programmatic writes (the page's custom calc keyboard sets
    // `controller.value = ...` directly, which does NOT fire
    // TextField.onChanged) keep the local result in sync.
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SalesCalcLineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item?.expression != oldWidget.item?.expression && !_focusNode.hasFocus) {
      _controller.text = widget.item?.expression ?? '';
      _localResult = widget.item?.result ?? 0.0;
      _lastSavedExpression = widget.item?.expression;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onControllerChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final newResult = ExpressionEvaluator.evaluate(_controller.text);
    if (newResult != _localResult) {
      setState(() => _localResult = newResult);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.item != null) {
      final currentExpression = _controller.text.trim();
      if (currentExpression != _lastSavedExpression && currentExpression.isNotEmpty) {
        _lastSavedExpression = currentExpression;
        widget.onChanged?.call(widget.item!.copyWith(
          expression: currentExpression,
          result: _localResult,
        ));
      }
    }
  }

  void _onExpressionChanged(String value) {
    setState(() {
      _localResult = ExpressionEvaluator.evaluate(value);
    });
  }

  String _formatResult(double value) {
    if (value == 0.0) return '0';
    if (value == value.truncateToDouble()) {
      return _formatter.format(value.toInt());
    }
    return _formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item?.productUnitId != null) {
      final currency = widget.currencyCode ?? item!.currencyId.toString();
      return ListTile(title: Text(item!.label ?? ''),
        subtitle: Text('${item.enteredQuantity ?? item.quantity} ${item.unitNameSnapshot ?? ""} × ${item.unitPrice} $currency'),
        onTap: widget.onEditStructured,
        trailing: IconButton(onPressed: widget.onDelete,
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          icon: const Icon(Icons.delete_outline)));
    }
    if (widget.isNewLine) {
      return _buildNewLineRow(context);
    }
    return _buildItemRow(context);
  }

  Widget _buildItemRow(BuildContext context) {
    final p = SalesCalcPalette.of(context);
    return Dismissible(
      key: ValueKey(widget.item!.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.sp),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: p.page(Colors.white),
          border: Border(bottom: BorderSide(color: p.border(Colors.grey.shade200))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.sp,
              child: Text(
                '${widget.lineNumber}',
                style: TextStyle(fontSize: 13.sp, color: Colors.blue, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onExpressionChanged,
                onSubmitted: (_) {
                  // Move focus or create new line handled by parent
                },
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: p.isDark ? false : null,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  hintText: "Narx*Soni",
                  hintStyle: TextStyle(fontSize: 14.sp, color: p.textSecondary(Colors.grey.shade400)),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-*/. ]')),
                ],
              ),
            ),
            SizedBox(
              width: 120.sp,
              child: Text(
                _formatResult(_localResult),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: _localResult < 0 ? Colors.red : p.text(Colors.black87),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewLineRow(BuildContext context) {
    final p = SalesCalcPalette.of(context);
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: p.accentTint(const Color(0xFFF3F0FF)),
          border: Border(bottom: BorderSide(color: p.border(Colors.grey.shade200))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.sp,
              child: Icon(Icons.add, size: 16.sp, color: p.accent(const Color(0xFF7C3AED))),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onExpressionChanged,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    widget.onNewLineSubmitted?.call(value.trim());
                    _controller.clear();
                    setState(() => _localResult = 0.0);
                  }
                },
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: p.isDark ? false : null,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  hintText: "Yangi qator...",
                  hintStyle: TextStyle(fontSize: 14.sp, color: p.textSecondary(Colors.grey.shade400)),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-*/. ]')),
                ],
              ),
            ),
            if (_localResult != 0.0)
              SizedBox(
                width: 120.sp,
                child: Text(
                  _formatResult(_localResult),
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: p.textSecondary(Colors.black54)),
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
