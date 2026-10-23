import 'package:equatable/equatable.dart';

class SalesCalcItem extends Equatable {
  final int id;
  final String expression;
  final String? label;
  final double result;
  final int position;
  final int? productId;
  final int? productUnitId;
  final int? unitId;
  final int? unitVersion;
  final int? currencyId;
  final String? unitNameSnapshot;
  final int? baseUnitId;
  final String? conversionNumerator;
  final String? conversionDenominator;
  final String? quantity;
  final String? enteredQuantity;
  final String? baseQuantity;
  final String? unitPrice;
  final int? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SalesCalcItem({
    required this.id,
    required this.expression,
    this.label,
    required this.result,
    required this.position,
    this.productId,
    this.productUnitId,
    this.unitId,
    this.unitVersion,
    this.currencyId,
    this.unitNameSnapshot,
    this.baseUnitId,
    this.conversionNumerator,
    this.conversionDenominator,
    this.quantity,
    this.enteredQuantity,
    this.baseQuantity,
    this.unitPrice,
    this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  SalesCalcItem copyWith({
    int? id,
    String? expression,
    String? label,
    double? result,
    int? position,
    int? productId,
    int? productUnitId,
    int? unitId,
    int? unitVersion,
    int? currencyId,
    String? unitNameSnapshot,
    int? baseUnitId,
    String? conversionNumerator,
    String? conversionDenominator,
    String? quantity,
    String? enteredQuantity,
    String? baseQuantity,
    String? unitPrice,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesCalcItem(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      label: label ?? this.label,
      result: result ?? this.result,
      position: position ?? this.position,
      productId: productId ?? this.productId,
      productUnitId: productUnitId ?? this.productUnitId,
      unitId: unitId ?? this.unitId,
      unitVersion: unitVersion ?? this.unitVersion,
      currencyId: currencyId ?? this.currencyId,
      unitNameSnapshot: unitNameSnapshot ?? this.unitNameSnapshot,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      conversionNumerator: conversionNumerator ?? this.conversionNumerator,
      conversionDenominator:
          conversionDenominator ?? this.conversionDenominator,
      quantity: quantity ?? this.quantity,
      enteredQuantity: enteredQuantity ?? this.enteredQuantity,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        expression,
        label,
        result,
        position,
        productId,
        productUnitId,
        unitId,
        unitVersion,
        currencyId,
        unitNameSnapshot,
        baseUnitId,
        conversionNumerator,
        conversionDenominator,
        quantity,
        enteredQuantity,
        baseQuantity,
        unitPrice,
        createdById,
        createdAt,
        updatedAt,
      ];
}
