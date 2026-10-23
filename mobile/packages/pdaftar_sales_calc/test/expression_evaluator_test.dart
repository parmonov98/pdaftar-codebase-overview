import 'package:flutter_test/flutter_test.dart';
import 'package:pdaftar_sales_calc/src/presentation/widgets/expression_evaluator.dart';

void main() {
  group('ExpressionEvaluator', () {
    test('evaluates basic arithmetic with precedence', () {
      expect(ExpressionEvaluator.evaluate('2000'), 2000);
      expect(ExpressionEvaluator.evaluate('2000*3'), 6000);
      expect(ExpressionEvaluator.evaluate('5*2000'), 10000);
      expect(ExpressionEvaluator.evaluate('2000*3+500'), 6500);
      expect(ExpressionEvaluator.evaluate(''), 0);
    });

    test('normalizes × and ÷', () {
      expect(ExpressionEvaluator.evaluate('2000×3'), 6000);
      expect(ExpressionEvaluator.evaluate('6000÷2'), 3000);
    });

    // The "product picked, quantity not typed yet" seed is "<price>*".
    test('trailing operator falls back to the last complete value', () {
      expect(ExpressionEvaluator.evaluate('2000*'), 2000); // 1 unit default
      expect(ExpressionEvaluator.evaluate('2000+'), 2000);
      expect(ExpressionEvaluator.evaluate('2000*-'), 2000);
      expect(ExpressionEvaluator.evaluate('2000×'), 2000);
      // ...and once the quantity is typed, normal math resumes.
      expect(ExpressionEvaluator.evaluate('2000*3'), 6000);
    });

    test('does not mistake a negative operand for a trailing operator', () {
      expect(ExpressionEvaluator.evaluate('2000*-3'), -6000);
      expect(ExpressionEvaluator.evaluate('-2000'), -2000);
    });
  });

  // "Skladdan kamaytirish": the quantity is the factor AFTER '*'
  // (rows read "Narx*Soni"; the autocomplete seeds "<price>*").
  group('ExpressionEvaluator.soldQuantity', () {
    test('price*qty → the second factor', () {
      expect(ExpressionEvaluator.soldQuantity('2000*3'), 3);
      expect(ExpressionEvaluator.soldQuantity('12000*2.5'), 2.5);
      expect(ExpressionEvaluator.soldQuantity('2000×4'), 4);
      expect(ExpressionEvaluator.soldQuantity('2000 * 3'), 3);
    });

    test('bare price (or an unfinished "<price>*" seed) sells one unit', () {
      expect(ExpressionEvaluator.soldQuantity('2000'), 1);
      expect(ExpressionEvaluator.soldQuantity('2000*'), 1);
    });

    test('anything outside the canonical forms yields no quantity', () {
      expect(ExpressionEvaluator.soldQuantity(''), null);
      expect(ExpressionEvaluator.soldQuantity('   '), null);
      expect(ExpressionEvaluator.soldQuantity('2000+500'), null);
      expect(ExpressionEvaluator.soldQuantity('6000/2'), null);
      expect(ExpressionEvaluator.soldQuantity('2000-500'), null);
      expect(ExpressionEvaluator.soldQuantity('2000*-3'), null);
      expect(ExpressionEvaluator.soldQuantity('-2000'), null);
      expect(ExpressionEvaluator.soldQuantity('2000*0'), null);
      expect(ExpressionEvaluator.soldQuantity('0'), null);
    });
  });
}
