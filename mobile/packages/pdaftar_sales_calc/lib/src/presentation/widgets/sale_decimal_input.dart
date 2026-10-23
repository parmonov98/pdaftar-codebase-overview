import 'package:flutter/services.dart';

/// Insert a decimal separator at the caret, allowing one per operand.
/// Check the resulting text so replacing an existing separator still works.
TextEditingValue insertSaleDecimal(TextEditingValue value) {
  final selection = value.selection;
  final start = selection.isValid ? selection.start : value.text.length;
  final end = selection.isValid ? selection.end : value.text.length;
  final candidate = value.text.replaceRange(start, end, '.');
  if (candidate
      .split('*')
      .any((operand) => '.'.allMatches(operand).length > 1)) {
    return value;
  }
  return TextEditingValue(
    text: candidate,
    selection: TextSelection.collapsed(offset: start + 1),
  );
}
