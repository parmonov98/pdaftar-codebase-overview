// To parse this JSON data, do
//
//     final getSmsCountPriceResponse = getSmsCountPriceResponseFromJson(jsonString);

import 'dart:convert';

GetSmsCountPriceResponse getSmsCountPriceResponseFromJson(String str) => GetSmsCountPriceResponse.fromJson(json.decode(str));

String getSmsCountPriceResponseToJson(GetSmsCountPriceResponse data) => json.encode(data.toJson());

class GetSmsCountPriceResponse {
  final Tariff? tariff;
  final int? totalPrice;

  GetSmsCountPriceResponse({
    this.tariff,
    this.totalPrice,
  });

  factory GetSmsCountPriceResponse.fromJson(Map<String, dynamic> json) => GetSmsCountPriceResponse(
    tariff: json["tariff"] == null ? null : Tariff.fromJson(json["tariff"]),
    totalPrice: json["total_price"],
  );

  Map<String, dynamic> toJson() => {
    "tariff": tariff?.toJson(),
    "total_price": totalPrice,
  };
}

class Tariff {
  final int? id;
  final String? name;
  final int? price;
  final int? count;
  final int? ownerTariffId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tariff({
    this.id,
    this.name,
    this.price,
    this.count,
    this.ownerTariffId,
    this.createdAt,
    this.updatedAt,
  });

  factory Tariff.fromJson(Map<String, dynamic> json) => Tariff(
    id: json["id"],
    name: json["name"],
    price: json["price"],
    count: json["count"],
    ownerTariffId: json["owner_tariff_id"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "price": price,
    "count": count,
    "owner_tariff_id": ownerTariffId,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}