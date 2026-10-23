library pdaftar_sales_calc;

import 'package:dio/dio.dart';
import 'package:pdaftar_sales_calc/src/data/datasources/sales_calc_remote_data_source.dart';
import 'package:pdaftar_sales_calc/src/data/repositories/sales_calc_repository_impl.dart';
import 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_item.dart';
import 'package:pdaftar_sales_calc/src/domain/repositories/i_sales_calc_repository.dart';
import 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_sold_marks.dart';

export 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_item.dart';
export 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_list.dart';
export 'package:pdaftar_sales_calc/src/domain/entities/shop_product.dart';
export 'package:pdaftar_sales_calc/src/domain/repositories/i_sales_calc_repository.dart';
export 'package:pdaftar_sales_calc/src/data/models/sales_calc_item_model.dart';
export 'package:pdaftar_sales_calc/src/presentation/blocs/sales_calc_bloc/sales_calc_bloc.dart';
export 'package:pdaftar_sales_calc/src/presentation/blocs/sales_calc_bloc/sales_calc_event.dart';
export 'package:pdaftar_sales_calc/src/presentation/blocs/sales_calc_bloc/sales_calc_state.dart';
export 'package:pdaftar_sales_calc/src/presentation/pages/sales_calc_list_page.dart';
export 'package:pdaftar_sales_calc/src/domain/entities/sales_calc_sold_marks.dart';
export 'package:pdaftar_sales_calc/src/presentation/widgets/sales_calc_line_widget.dart';
export 'package:pdaftar_sales_calc/src/presentation/widgets/expression_evaluator.dart';
export 'package:pdaftar_sales_calc/src/presentation/widgets/calc_keyboard.dart';
export 'package:pdaftar_sales_calc/src/presentation/sales_calc_router.dart';
export 'package:pdaftar_sales_calc/src/presentation/sales_calc_router.gm.dart';

typedef SalesCalcAnalyticsCallback = void Function(String event, [Map<String, dynamic>? props]);

/// Callback for reading/writing user preferences.
typedef SalesCalcPrefReader = bool Function(String key, {bool defaultValue});
typedef SalesCalcPrefWriter = void Function(String key, bool value);
typedef SalesCalcIntPrefReader = int Function(String key, {int defaultValue});
typedef SalesCalcIntPrefWriter = void Function(String key, int value);
typedef SalesCalcStringPrefReader = String? Function(String key);
typedef SalesCalcStringPrefWriter = void Function(String key, String value);

class SalesCalcPackage {
  /// Pref key + default for the tab-strip window: only lists touched in
  /// the last N days are fetched. 0 = no limit ("Hammasi").
  static const String listDaysPrefKey = 'sales_calc_list_days';
  static const int defaultListDays = 30;

  static late final ISalesCalcRepository _repository;
  static late int Function() _shopIdProvider;
  static SalesCalcAnalyticsCallback? _onAnalyticsEvent;
  static SalesCalcPrefReader? _prefReader;
  static SalesCalcPrefWriter? _prefWriter;
  static SalesCalcIntPrefReader? _intPrefReader;
  static SalesCalcIntPrefWriter? _intPrefWriter;
  static SalesCalcStringPrefReader? _stringPrefReader;
  static SalesCalcStringPrefWriter? _stringPrefWriter;

  static void init({
    required Dio dio,
    required int Function() shopIdProvider,
    SalesCalcAnalyticsCallback? onAnalyticsEvent,
    SalesCalcPrefReader? prefReader,
    SalesCalcPrefWriter? prefWriter,
    SalesCalcIntPrefReader? intPrefReader,
    SalesCalcIntPrefWriter? intPrefWriter,
    SalesCalcStringPrefReader? stringPrefReader,
    SalesCalcStringPrefWriter? stringPrefWriter,
  }) {
    final remoteDataSource = SalesCalcRemoteDataSourceImpl(dio);
    _repository = SalesCalcRepositoryImpl(remoteDataSource);
    _shopIdProvider = shopIdProvider;
    _onAnalyticsEvent = onAnalyticsEvent;
    _prefReader = prefReader;
    _prefWriter = prefWriter;
    _intPrefReader = intPrefReader;
    _intPrefWriter = intPrefWriter;
    _stringPrefReader = stringPrefReader;
    _stringPrefWriter = stringPrefWriter;
  }

  static int get shopId => _shopIdProvider();
  static ISalesCalcRepository get repository => _repository;

  static void trackEvent(String event, [Map<String, dynamic>? props]) {
    _onAnalyticsEvent?.call(event, props);
  }

  static bool readPref(String key, {bool defaultValue = false}) {
    return _prefReader?.call(key, defaultValue: defaultValue) ?? defaultValue;
  }

  static void writePref(String key, bool value) {
    _prefWriter?.call(key, value);
  }

  static int readIntPref(String key, {int defaultValue = 0}) {
    return _intPrefReader?.call(key, defaultValue: defaultValue) ??
        defaultValue;
  }

  static void writeIntPref(String key, int value) {
    _intPrefWriter?.call(key, value);
  }

  /// Sheets already sold, by sheet id (Trello #432). Without a host
  /// string pref these live only as long as the page.
  static Map<int, SalesCalcSoldMark> readSoldMarks() {
    try {
      return SalesCalcSoldMarks.decode(
          _stringPrefReader?.call(SalesCalcSoldMarks.prefKey));
    } catch (_) {
      return {};
    }
  }

  static void writeSoldMarks(Map<int, SalesCalcSoldMark> marks) {
    try {
      _stringPrefWriter?.call(
          SalesCalcSoldMarks.prefKey, SalesCalcSoldMarks.encode(marks));
    } catch (_) {}
  }

  /// Current tab-strip window in days (0 = all lists).
  static int get listDays =>
      readIntPref(listDaysPrefKey, defaultValue: defaultListDays);

  static set listDays(int days) => writeIntPref(listDaysPrefKey, days);

  /// Serialize calculator items into a one-line-per-item description
  /// suitable for a Debt's `description` column. Receipt page falls
  /// back to this string when a debt has no FK link to a frozen list
  /// (legacy or external paths).
  ///
  /// Format:
  ///   `<label or "Item N">: <expression> = <result>`
  /// Numbers are formatted with thousand grouping and up to 2
  /// decimals; trailing `.00` is dropped.
  static String formatItemsAsDescription(List<SalesCalcItem> items) {
    String fmtNum(double v) {
      if (v == v.roundToDouble()) {
        return v.toInt().toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            );
      }
      final fixed = v.toStringAsFixed(2);
      // Strip trailing zero and decimal point if applicable.
      return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final lines = <String>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final label = (it.label != null && it.label!.trim().isNotEmpty)
          ? it.label!.trim()
          : 'Item ${i + 1}';
      lines.add('$label: ${it.expression} = ${fmtNum(it.result)}');
    }
    return lines.join('\n');
  }
}
