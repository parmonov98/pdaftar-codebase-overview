import 'package:equatable/equatable.dart';

/// Shop product surfaced by the calculator's Nomi autocomplete.
///
/// `lastExpression` / `lastResult` carry the most recent calc-item that
/// linked to this product — the autocomplete uses them to restore the
/// ORIGINAL math (e.g. `200*100`) when the user picks a suggestion,
/// instead of inserting just the price scalar. They're nullable for
/// products that were created via the explicit POST endpoint (no
/// prior sale yet).
class ShopProduct extends Equatable {
  final int id;
  final String name;
  final double? price;
  final int? currencyId;
  final String? code;
  final String? lastExpression;
  final double? lastResult;

  const ShopProduct({
    required this.id,
    required this.name,
    this.price,
    this.currencyId,
    this.code,
    this.lastExpression,
    this.lastResult,
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic raw) {
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw);
      return null;
    }

    return ShopProduct(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      price: toDouble(json['price']),
      currencyId: (json['currency_id'] as num?)?.toInt(),
      code: json['code'] as String?,
      lastExpression: json['last_expression'] as String?,
      lastResult: toDouble(json['last_result']),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, price, currencyId, code, lastExpression, lastResult];
}
