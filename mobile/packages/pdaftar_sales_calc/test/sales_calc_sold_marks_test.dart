import 'package:flutter_test/flutter_test.dart';
import 'package:pdaftar_sales_calc/pdaftar_sales_calc.dart';

/// Trello #432: a sold sheet stays marked, also across restarts.
void main() {
  const mark = SalesCalcSoldMark(
      debtId: 2032827, reference: '29.09-#1', clientId: 7, clientName: 'Marat');

  test('marks survive an encode/decode round trip', () {
    final decoded = SalesCalcSoldMarks.decode(
        SalesCalcSoldMarks.encode({14218: mark}));
    expect(decoded.keys, [14218]);
    expect(decoded[14218]!.debtId, 2032827);
    expect(decoded[14218]!.reference, '29.09-#1');
    expect(decoded[14218]!.clientName, 'Marat');
  });

  test('a broken or empty pref reads as no marks', () {
    expect(SalesCalcSoldMarks.decode(null), isEmpty);
    expect(SalesCalcSoldMarks.decode('not json'), isEmpty);
    expect(SalesCalcSoldMarks.decode('{"x":{"debt_id":"no"}}'), isEmpty);
  });

  test('re-selling a sheet moves it to the newest slot; oldest drop past the cap', () {
    var marks = <int, SalesCalcSoldMark>{};
    for (var i = 0; i < SalesCalcSoldMarks.maxEntries + 5; i++) {
      marks = SalesCalcSoldMarks.put(marks, i, mark);
    }
    marks = SalesCalcSoldMarks.put(marks, 10, mark);
    final kept = SalesCalcSoldMarks.decode(SalesCalcSoldMarks.encode(marks));
    expect(kept.length, SalesCalcSoldMarks.maxEntries);
    expect(kept.keys.last, 10);
    expect(kept.containsKey(0), isFalse);
  });

  test("the server's last_sale reads as a mark; null reads as none", () {
    final mark = SalesCalcSoldMark.fromJson({
      'debt_id': 1974201,
      'reference': '29.09-#1',
      'client_id': 435023,
      'client_name': 'Marat',
      'sold_at': '2026-09-29T14:55:20+05:00',
    });
    expect(mark!.debtId, 1974201);
    expect(mark.reference, '29.09-#1');
    expect(mark.clientName, 'Marat');
    expect(SalesCalcSoldMark.fromJson(null), isNull);
  });
}
