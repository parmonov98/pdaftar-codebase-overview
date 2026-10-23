// To parse this JSON data, do
//
//     final inviteHistoryResponse = inviteHistoryResponseFromJson(jsonString);

import 'dart:convert';

InviteHistoryResponse inviteHistoryResponseFromJson(String str) => InviteHistoryResponse.fromJson(json.decode(str));

String inviteHistoryResponseToJson(InviteHistoryResponse data) => json.encode(data.toJson());

class InviteHistoryResponse {
  final int? invitedCount;
  final List<Datum>? data;

  InviteHistoryResponse({
    this.invitedCount,
    this.data,
  });

  factory InviteHistoryResponse.fromJson(Map<String, dynamic> json) => InviteHistoryResponse(
    invitedCount: json["invited_count"],
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "invited_count": invitedCount,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  final int? id;
  final int? userId;
  final String? phoneNumber;
  final String? message;
  final String? createdAt;
  final DateTime? updatedAt;

  Datum({
    this.id,
    this.userId,
    this.phoneNumber,
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    userId: json["user_id"],
    phoneNumber: json["phone_number"],
    message: json["message"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "phone_number": phoneNumber,
    "message": message,
    "created_at": createdAt,
    "updated_at": updatedAt?.toIso8601String(),
  };
}