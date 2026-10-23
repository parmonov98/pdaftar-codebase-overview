/// Self-contained arithmetic expression evaluator.
/// Supports +, -, *, / with correct operator precedence.
class ExpressionEvaluator {
  ExpressionEvaluator._();

  /// Evaluate a string expression like "2500 * 2000" and return the numeric result.
  /// Returns 0.0 for empty, invalid, or division-by-zero expressions.
  static double evaluate(String input) {
    var cleaned = input.replaceAll(' ', '').replaceAll('\u00D7', '*').replaceAll('\u00F7', '/');
    // A trailing operator means the expression is mid-entry \u2014 evaluate the last
    // complete part instead of returning 0. This lets a seeded "<price>*"
    // (product picked, quantity not typed yet) show the unit price, and makes a
    // line submitted without a quantity fall back to 1 unit.
    cleaned = cleaned.replaceAll(RegExp(r'[+\-*/]+$'), '');
    if (cleaned.isEmpty) return 0.0;

    try {
      final tokens = _tokenize(cleaned);
      if (tokens.isEmpty) return 0.0;
      return _evaluate(tokens);
    } catch (_) {
      return 0.0;
    }
  }

  /// Extract the sold quantity from a row expression for the stock ledger
  /// ("Skladdan kamaytirish").
  ///
  /// The calculator's row contract is a single multiplication with the
  /// price FIRST — the column header reads "Narx*Soni" and the product
  /// autocomplete seeds "<price>*" for the cashier to finish with the
  /// quantity — so the factor AFTER '*' is the quantity. A bare number
  /// (or the "<price>*" seed submitted as-is) is one unit, the same
  /// reading the backend's nakladnoy gives such lines. Anything outside
  /// those canonical forms (legacy +/- chains, unparsable factors,
  /// qty <= 0) returns null: no movement beats a guessed one.
  static double? soldQuantity(String input) {
    var cleaned = input
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');
    // Trailing operator = mid-entry seed ("2000*") → quantity not typed,
    // sold as a single unit. Mirrors evaluate()'s fallback.
    cleaned = cleaned.replaceAll(RegExp(r'[+\-*/]+$'), '');
    if (cleaned.isEmpty) return null;
    // Only the "price" and "price*qty" forms carry a trustworthy
    // quantity; +, -, / anywhere means this is freeform math.
    if (RegExp(r'[+/\-]').hasMatch(cleaned)) return null;
    final parts = cleaned.split('*');
    if (parts.length == 1) {
      final price = double.tryParse(parts[0]);
      if (price == null || price <= 0) return null;
      return 1.0;
    }
    if (parts.length != 2) return null;
    final qty = double.tryParse(parts[1]);
    if (qty == null || qty <= 0) return null;
    return qty;
  }

  static List<dynamic> _tokenize(String input) {
    final tokens = <dynamic>[];
    var numBuffer = StringBuffer();

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (c == '+' || c == '-' || c == '*' || c == '/') {
        if (numBuffer.isNotEmpty) {
          final num = double.tryParse(numBuffer.toString());
          if (num == null) return [];
          tokens.add(num);
          numBuffer.clear();
        } else if (c == '-' && (tokens.isEmpty || tokens.last is String)) {
          // Negative number
          numBuffer.write(c);
          continue;
        }
        tokens.add(c);
      } else if (c == '.' || (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57)) {
        numBuffer.write(c);
      }
    }
    if (numBuffer.isNotEmpty) {
      final num = double.tryParse(numBuffer.toString());
      if (num == null) return [];
      tokens.add(num);
    }

    return tokens;
  }

  static double _evaluate(List<dynamic> tokens) {
    // First pass: handle * and /
    var i = 0;
    while (i < tokens.length) {
      if (tokens[i] is String && (tokens[i] == '*' || tokens[i] == '/')) {
        final left = tokens[i - 1] as double;
        final right = tokens[i + 1] as double;
        double result;
        if (tokens[i] == '*') {
          result = left * right;
        } else {
          if (right == 0) return 0.0;
          result = left / right;
        }
        tokens.replaceRange(i - 1, i + 2, [result]);
        continue;
      }
      i++;
    }

    // Second pass: handle + and -
    var result = tokens[0] as double;
    i = 1;
    while (i < tokens.length - 1) {
      final op = tokens[i] as String;
      final right = tokens[i + 1] as double;
      if (op == '+') {
        result += right;
      } else if (op == '-') {
        result -= right;
      }
      i += 2;
    }

    return result;
  }
}
