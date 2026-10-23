import 'package:equatable/equatable.dart';
import '../../../domain/entities/sales_calc_item.dart';
import '../../../domain/entities/sales_calc_list.dart';
import '../../../domain/entities/shop_product.dart';

enum SalesCalcStatus { initial, loading, loaded, error }

class SalesCalcState extends Equatable {
  final SalesCalcStatus status;
  final List<SalesCalcList> lists;
  final int? activeListId;
  final List<SalesCalcItem> items;
  final bool showLabels;

  /// "Skladdan kamaytirish": when true, product-linked rows sync with an
  /// explicit sold quantity so selling the list writes stock movements.
  /// Free-text rows have no product link and are skipped silently.
  final bool deductStock;
  final String? errorMessage;

  /// Product autocomplete state. `productSearchLineId` identifies which
  /// row's Nomi field triggered the latest search — the line widget
  /// shows suggestions only when the value matches its own item id, so
  /// two lines being edited never share a dropdown.
  final List<ShopProduct> productSuggestions;
  final String productSearchQuery;
  final bool isSearchingProducts;
  final int? productSearchLineId;

  const SalesCalcState({
    this.status = SalesCalcStatus.initial,
    this.lists = const [],
    this.activeListId,
    this.items = const [],
    this.showLabels = false,
    this.deductStock = true,
    this.errorMessage,
    this.productSuggestions = const [],
    this.productSearchQuery = '',
    this.isSearchingProducts = false,
    this.productSearchLineId,
  });

  bool get hasStructuredItems =>
      items.any((item) => item.productUnitId != null);
  Map<int?, double> get totalsByCurrency {
    final totals = <int?, double>{};
    for (final item in items) {
      totals.update(item.currencyId, (value) => value + item.result,
          ifAbsent: () => item.result);
    }
    return totals;
  }

  bool get hasMixedCurrencies => totalsByCurrency.length > 1;
  double get total => hasMixedCurrencies
      ? 0
      : items.fold(0.0, (sum, item) => sum + item.result);

  SalesCalcState copyWith({
    SalesCalcStatus? status,
    List<SalesCalcList>? lists,
    int? activeListId,
    List<SalesCalcItem>? items,
    bool? showLabels,
    bool? deductStock,
    String? errorMessage,
    List<ShopProduct>? productSuggestions,
    String? productSearchQuery,
    bool? isSearchingProducts,
    int? productSearchLineId,
    bool clearProductSearchLineId = false,
  }) {
    return SalesCalcState(
      status: status ?? this.status,
      lists: lists ?? this.lists,
      activeListId: activeListId ?? this.activeListId,
      items: items ?? this.items,
      showLabels: showLabels ?? this.showLabels,
      deductStock: deductStock ?? this.deductStock,
      errorMessage: errorMessage,
      productSuggestions: productSuggestions ?? this.productSuggestions,
      productSearchQuery: productSearchQuery ?? this.productSearchQuery,
      isSearchingProducts: isSearchingProducts ?? this.isSearchingProducts,
      productSearchLineId: clearProductSearchLineId
          ? null
          : (productSearchLineId ?? this.productSearchLineId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        lists,
        activeListId,
        items,
        showLabels,
        deductStock,
        errorMessage,
        productSuggestions,
        productSearchQuery,
        isSearchingProducts,
        productSearchLineId,
      ];
}
