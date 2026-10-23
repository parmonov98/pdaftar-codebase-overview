import 'package:flutter_test/flutter_test.dart';
import 'package:pdaftar_sales_calc/src/presentation/pages/sales_calc_list_page.dart';

/// Trello #376 — the calculator printed a line as
/// "1.000000000 Dona × 6500.000000 UZS".
///
/// Those zeros are the width of the DB column (`quantity` is decimal:9,
/// `unit_price` decimal:6), not a figure anyone typed. The rule worth
/// pinning is the boundary: strip what the column added, keep what the
/// shop entered.
void main() {
  group('trimSalesCalcScale', () {
    test('drops the column scale from a whole number', () {
      expect(trimSalesCalcScale('6500.000000'), '6500');
      expect(trimSalesCalcScale('1.000000000'), '1');
    });

    test('keeps a fraction the shop actually entered', () {
      expect(trimSalesCalcScale('2.220000'), '2.22');
      expect(trimSalesCalcScale('0.500000'), '0.5');
    });

    test('leaves an already-clean value alone', () {
      expect(trimSalesCalcScale('6500'), '6500');
      expect(trimSalesCalcScale('2.22'), '2.22');
    });

    test('a value that is all scale still reads as zero, not empty', () {
      expect(trimSalesCalcScale('0.000000'), '0');
    });

    test('null and blank do not crash the row', () {
      expect(trimSalesCalcScale(null), '');
      expect(trimSalesCalcScale('  '), '');
    });
  });
}
