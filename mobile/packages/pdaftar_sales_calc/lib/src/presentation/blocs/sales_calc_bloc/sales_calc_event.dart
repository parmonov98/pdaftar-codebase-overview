import '../../../domain/entities/sales_calc_item.dart';
import 'package:equatable/equatable.dart';

abstract class SalesCalcEvent extends Equatable {
  const SalesCalcEvent();
  @override
  List<Object?> get props => [];
}

// ─── List events ───

class LoadSalesCalcLists extends SalesCalcEvent {
  /// When true (the app-bar sync button): flushes unsynced local edits
  /// first, then drops the cached product catalog so lists AND
  /// autocomplete products are re-fetched from the backend.
  final bool refresh;

  /// When true (drawer entry point): land on a fresh sale instead of
  /// the last active list. The newest list is reused if it's still
  /// empty (so repeated open/close doesn't pile up blanks); otherwise
  /// a new list is created and selected.
  final bool startWithNewList;

  const LoadSalesCalcLists(
      {this.refresh = false, this.startWithNewList = false});
}

class CreateNewList extends SalesCalcEvent {
  final String? name;
  const CreateNewList({this.name});
  @override
  List<Object?> get props => [name];
}

class SelectList extends SalesCalcEvent {
  final int listId;
  const SelectList({required this.listId});
  @override
  List<Object?> get props => [listId];
}

class RenameList extends SalesCalcEvent {
  final int listId;
  final String name;
  const RenameList({required this.listId, required this.name});
  @override
  List<Object?> get props => [listId, name];
}

class DeleteList extends SalesCalcEvent {
  final int listId;
  const DeleteList({required this.listId});
  @override
  List<Object?> get props => [listId];
}

// ─── Settings ───

class ToggleShowLabels extends SalesCalcEvent {
  const ToggleShowLabels();
}

/// "Skladdan kamaytirish" — when ON, synced rows that are linked to a
/// ShopProduct carry an explicit sold quantity, which the backend turns
/// into `sale` stock movements when the list is sold (saved as a debt).
class ToggleDeductStock extends SalesCalcEvent {
  const ToggleDeductStock();
}

// ─── Sync ───

class SyncToBackend extends SalesCalcEvent {
  const SyncToBackend();
}

// ─── Item events ───

class LoadSalesCalcItems extends SalesCalcEvent {
  final bool isRefresh;
  const LoadSalesCalcItems({this.isRefresh = false});
  @override
  List<Object?> get props => [isRefresh];
}

class CreateSalesCalcItem extends SalesCalcEvent {
  final String expression;
  final double result;
  final String? label;
  final int? productId;
  const CreateSalesCalcItem({
    required this.expression,
    required this.result,
    this.label,
    this.productId,
  });
  @override
  List<Object?> get props => [expression, result, label, productId];
}

class UpdateSalesCalcItem extends SalesCalcEvent {
  final int id;
  final String? expression;
  final double? result;
  final int? position;
  const UpdateSalesCalcItem(
      {required this.id, this.expression, this.result, this.position});
  @override
  List<Object?> get props => [id, expression, result, position];
}

class DeleteSalesCalcItem extends SalesCalcEvent {
  final int id;
  const DeleteSalesCalcItem({required this.id});
  @override
  List<Object?> get props => [id];
}

class UpdateItemLabel extends SalesCalcEvent {
  final int id;
  final String label;
  const UpdateItemLabel({required this.id, required this.label});
  @override
  List<Object?> get props => [id, label];
}

class UpdateLocalExpression extends SalesCalcEvent {
  final int id;
  final String expression;
  final double result;
  const UpdateLocalExpression(
      {required this.id, required this.expression, required this.result});
  @override
  List<Object?> get props => [id, expression, result];
}

/// Pick or unlink a product for an existing line item.
class UpdateItemProduct extends SalesCalcEvent {
  final int id;
  final int? productId;
  final String? label;
  const UpdateItemProduct({required this.id, this.productId, this.label});
  @override
  List<Object?> get props => [id, productId, label];
}

// ─── Product autocomplete ───

/// Proactive "browse" suggestions: shown ~1s after the Nomi field is
/// focused while still empty. Lists catalog products by NAME ONLY (the
/// UI hides the Ifoda/Natija cells when productSearchQuery is empty).
class BrowseProducts extends SalesCalcEvent {
  final int? lineId;
  const BrowseProducts({this.lineId});
}

class SearchProducts extends SalesCalcEvent {
  final String query;
  final int? lineId;
  const SearchProducts({required this.query, this.lineId});
  @override
  List<Object?> get props => [query, lineId];
}

class ClearProductSuggestions extends SalesCalcEvent {
  const ClearProductSuggestions();
}

/// Replaces an entire structured tuple atomically; quantity changes cannot
/// accidentally retain a price from another currency or unit.
class SetStructuredProductLine extends SalesCalcEvent {
  final SalesCalcItem item;
  final int? replacingId;
  const SetStructuredProductLine({required this.item, this.replacingId});
  @override
  List<Object?> get props => [item, replacingId];
}
