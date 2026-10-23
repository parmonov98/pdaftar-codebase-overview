import 'dart:convert';

SmsHistoryResponse smsOrdersResponseFromJson(String str) =>
    SmsHistoryResponse.fromJson(json.decode(str));

String smsOrdersResponseToJson(SmsHistoryResponse data) =>
    json.encode(data.toJson());

class SmsHistoryResponse {
  final List<SmsOrder>? smsOrders;

  /// SMS bought in the requested period (Trello #488); 0 on an old server.
  final int totalSms;
  final int currentPage;
  final int lastPage;

  SmsHistoryResponse({
    this.smsOrders,
    this.totalSms = 0,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  factory SmsHistoryResponse.fromJson(Map<String, dynamic> json) =>
      SmsHistoryResponse(
        smsOrders: json["sms_orders"] == null
            ? []
            : List<SmsOrder>.from(
            json["sms_orders"].map((x) => SmsOrder.fromJson(x))),
        totalSms: (json["total_sms"] as num?)?.toInt() ?? 0,
        currentPage:
            (json["pagination"]?["current_page"] as num?)?.toInt() ?? 1,
        lastPage: (json["pagination"]?["last_page"] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
    "sms_orders": smsOrders == null
        ? []
        : List<dynamic>.from(smsOrders!.map((x) => x.toJson())),
  };
}

class SmsOrder {
  final int? id;
  final int? price;
  final int? smsCount;
  final DateTime? createdAt;

  /// `included` (free with a tariff), `combo` (bought with a tariff) or
  /// `purchase` (bought on its own).
  final String? source;
  final String? tariffName;

  SmsOrder({
    this.id,
    this.price,
    this.smsCount,
    this.createdAt,
    this.source,
    this.tariffName,
  });

  factory SmsOrder.fromJson(Map<String, dynamic> json) => SmsOrder(
    id: json["id"],
    price: (json["price"] as num?)?.toInt(),
    smsCount: (json["sms_count"] as num?)?.toInt(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    source: json["source"]?.toString(),
    tariffName: json["tariff_name"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "price": price,
    "sms_count": smsCount,
    "created_at": createdAt?.toIso8601String(),
  };
}
