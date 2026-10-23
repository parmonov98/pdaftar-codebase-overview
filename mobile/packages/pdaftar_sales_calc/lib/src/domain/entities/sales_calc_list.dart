import 'package:equatable/equatable.dart';
import 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_sold_marks.dart';

class SalesCalcList extends Equatable {
  final int id;
  final String? name;
  final int itemsCount;
  final double total;

  /// Client the sale was saved to (stamped by the save-as-debt flow);
  /// null for lists that were never sold. Drives the lists browser's
  /// client filter.
  final int? clientId;
  final String? clientName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Newest live sale booked from this sheet, as the server knows it
  /// (Trello #432) — lets a second device warn before selling it again.
  /// Null when never sold, or when the backend predates the field.
  final SalesCalcSoldMark? lastSale;

  const SalesCalcList({
    required this.id,
    this.name,
    this.itemsCount = 0,
    this.total = 0.0,
    this.clientId,
    this.clientName,
    this.createdAt,
    this.updatedAt,
    this.lastSale,
  });

  @override
  List<Object?> get props =>
      [
        id,
        name,
        itemsCount,
        total,
        clientId,
        clientName,
        createdAt,
        updatedAt,
        lastSale?.debtId,
      ];
}
