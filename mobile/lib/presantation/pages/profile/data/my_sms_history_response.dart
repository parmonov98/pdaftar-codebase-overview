import 'dart:convert';

MySmsHistoryResponse mySmsHistoryResponseFromJson(String str) =>
    MySmsHistoryResponse.fromJson(json.decode(str));

String mySmsHistoryResponseToJson(MySmsHistoryResponse data) =>
    json.encode(data.toJson());

class MySmsHistoryResponse {
  final bool? success;
  final List<MySmsHistoryItem>? data;
  final MySmsHistoryPagination? pagination;

  MySmsHistoryResponse({
    this.success,
    this.data,
    this.pagination,
  });

  factory MySmsHistoryResponse.fromJson(Map<String, dynamic> json) =>
      MySmsHistoryResponse(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<MySmsHistoryItem>.from(
                json["data"].map((x) => MySmsHistoryItem.fromJson(x))),
        pagination: json["pagination"] == null
            ? null
            : MySmsHistoryPagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "pagination": pagination?.toJson(),
      };
}

class MySmsHistoryItem {
  final int? id;
  final String? text;
  final String? phoneNumber;
  final String? status;
  final String? sentAt;
  final String? deliveredAt;
  final int? templateId;
  final int? shopId;
  final String? shopName;
  final int? clientId;
  final String? clientName;
  final int? smsLimitSpent;
  final int? calculatedSmsParts;
  final int? providerSmsParts;
  final String? createdAt;
  final String? updatedAt;

  MySmsHistoryItem({
    this.id,
    this.text,
    this.phoneNumber,
    this.status,
    this.sentAt,
    this.deliveredAt,
    this.templateId,
    this.shopId,
    this.shopName,
    this.clientId,
    this.clientName,
    this.smsLimitSpent,
    this.calculatedSmsParts,
    this.providerSmsParts,
    this.createdAt,
    this.updatedAt,
  });

  factory MySmsHistoryItem.fromJson(Map<String, dynamic> json) =>
      MySmsHistoryItem(
        id: json["id"],
        text: json["text"],
        phoneNumber: json["phone_number"],
        status: json["status"],
        sentAt: json["sent_at"],
        deliveredAt: json["delivered_at"],
        templateId: json["template_id"],
        shopId: json["shop_id"],
        shopName: json["shop_name"],
        clientId: json["client_id"],
        clientName: json["client_name"],
        smsLimitSpent: json["sms_limit_spent"],
        calculatedSmsParts: json["calculated_sms_parts"],
        providerSmsParts: json["provider_sms_parts"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "text": text,
        "phone_number": phoneNumber,
        "status": status,
        "sent_at": sentAt,
        "delivered_at": deliveredAt,
        "template_id": templateId,
        "shop_id": shopId,
        "shop_name": shopName,
        "client_id": clientId,
        "client_name": clientName,
        "sms_limit_spent": smsLimitSpent,
        "calculated_sms_parts": calculatedSmsParts,
        "provider_sms_parts": providerSmsParts,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}

class MySmsHistoryPagination {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  MySmsHistoryPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  factory MySmsHistoryPagination.fromJson(Map<String, dynamic> json) =>
      MySmsHistoryPagination(
        currentPage: json["current_page"],
        lastPage: json["last_page"],
        perPage: json["per_page"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
      };
}

