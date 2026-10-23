import 'dart:convert';

/// A calculator sheet that has already been sold (Trello #432).
///
/// Selling clones the sheet into a frozen copy and books the sale on that
/// copy; the sheet itself stays editable so the next customer can reuse
/// it. Nothing on the server links the two, so without this mark a second
/// "Sotuv" on the same sheet — after the receipt, or after reopening the
/// app — silently booked the same goods again.
class SalesCalcSoldMark {
  const SalesCalcSoldMark({
    required this.debtId,
    required this.reference,
    this.clientId,
    this.clientName,
  });

  final int debtId;

  /// The sheet's name at sale time ("29.09-#1") — the same "No" the
  /// nakladnoy prints, unlike the raw debt id.
  final String reference;
  final int? clientId;
  final String? clientName;

  Map<String, dynamic> toJson() => {
        'debt_id': debtId,
        'reference': reference,
        if (clientId != null) 'client_id': clientId,
        if (clientName != null) 'client_name': clientName,
      };

  static SalesCalcSoldMark? fromJson(Object? json) {
    if (json is! Map) return null;
    final debtId = json['debt_id'];
    if (debtId is! int) return null;
    return SalesCalcSoldMark(
      debtId: debtId,
      reference: json['reference']?.toString() ?? '#$debtId',
      clientId: json['client_id'] is int ? json['client_id'] as int : null,
      clientName: json['client_name']?.toString(),
    );
  }
}

/// Sold marks keyed by sheet id, stored as one JSON string pref.
class SalesCalcSoldMarks {
  SalesCalcSoldMarks._();

  static const String prefKey = 'sales_calc_sold_marks';

  /// Oldest marks are dropped past this — a sheet sold hundreds of sales
  /// ago is not the one about to be sold twice.
  static const int maxEntries = 200;

  static Map<int, SalesCalcSoldMark> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final marks = <int, SalesCalcSoldMark>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString());
        final mark = SalesCalcSoldMark.fromJson(value);
        if (id != null && mark != null) marks[id] = mark;
      });
      return marks;
    } catch (_) {
      return {};
    }
  }

  static String encode(Map<int, SalesCalcSoldMark> marks) {
    var entries = marks.entries.toList();
    if (entries.length > maxEntries) {
      entries = entries.sublist(entries.length - maxEntries);
    }
    return jsonEncode({
      for (final e in entries) '${e.key}': e.value.toJson(),
    });
  }

  /// [marks] with [listId] set to [mark], moved to the newest position.
  static Map<int, SalesCalcSoldMark> put(
      Map<int, SalesCalcSoldMark> marks, int listId, SalesCalcSoldMark mark) {
    return {
      for (final e in marks.entries)
        if (e.key != listId) e.key: e.value,
      listId: mark,
    };
  }
}
