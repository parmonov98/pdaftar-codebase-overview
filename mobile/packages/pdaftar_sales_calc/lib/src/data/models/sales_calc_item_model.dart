import '../../domain/entities/sales_calc_item.dart';

class SalesCalcItemModel extends SalesCalcItem {
  const SalesCalcItemModel({
    required super.id,
    required super.expression,
    super.label,
    required super.result,
    required super.position,
    super.productId,
    super.productUnitId,
    super.unitId,
    super.unitVersion,
    super.currencyId,
    super.unitNameSnapshot,
    super.baseUnitId,
    super.conversionNumerator,
    super.conversionDenominator,
    super.quantity,
    super.enteredQuantity,
    super.baseQuantity,
    super.unitPrice,
    super.createdById,
    super.createdAt,
    super.updatedAt,
  });

  factory SalesCalcItemModel.fromJson(Map<String, dynamic> json) {
    return SalesCalcItemModel(
      id: json['id'] as int? ?? 0,
      expression: json['expression']?.toString() ?? '',
      label: json['label']?.toString(),
      result: double.tryParse(json['result']?.toString() ?? '') ?? 0.0,
      position: json['position'] as int? ?? 0,
      productId: (json['product_id'] as num?)?.toInt(),
      productUnitId: (json['product_unit_id'] as num?)?.toInt(),
      unitId: (json['unit_id'] as num?)?.toInt(),
      unitVersion: (json['unit_version'] as num?)?.toInt(),
      currencyId: (json['currency_id'] as num?)?.toInt(),
      unitNameSnapshot: json['unit_name_snapshot']?.toString(),
      baseUnitId: (json['base_unit_id'] as num?)?.toInt(),
      conversionNumerator: json['conversion_numerator']?.toString(),
      conversionDenominator: json['conversion_denominator']?.toString(),
      quantity: json['quantity']?.toString(),
      enteredQuantity: json['entered_quantity']?.toString(),
      baseQuantity: json['base_quantity']?.toString(),
      unitPrice: json['unit_price']?.toString(),
      createdById: json['created_by_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'expression': expression,
        'label': label,
        'result': result,
        'position': position,
        'product_id': productId,
        'product_unit_id': productUnitId,
        'unit_id': unitId,
        'unit_version': unitVersion,
        'currency_id': currencyId,
        'unit_name_snapshot': unitNameSnapshot,
        'base_unit_id': baseUnitId,
        'conversion_numerator': conversionNumerator,
        'conversion_denominator': conversionDenominator,
        'quantity': quantity,
        'entered_quantity': enteredQuantity,
        'base_quantity': baseQuantity,
        'unit_price': unitPrice,
        'created_by_id': createdById,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  SalesCalcItem toEntity() => SalesCalcItem(
        id: id,
        expression: expression,
        label: label,
        result: result,
        position: position,
        productId: productId,
        productUnitId: productUnitId,
        unitId: unitId,
        unitVersion: unitVersion,
        currencyId: currencyId,
        unitNameSnapshot: unitNameSnapshot,
        baseUnitId: baseUnitId,
        conversionNumerator: conversionNumerator,
        conversionDenominator: conversionDenominator,
        quantity: quantity,
        enteredQuantity: enteredQuantity,
        baseQuantity: baseQuantity,
        unitPrice: unitPrice,
        createdById: createdById,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
