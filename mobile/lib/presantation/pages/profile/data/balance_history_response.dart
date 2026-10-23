// To parse this JSON data, do
//
//     final referralBonusResponse = referralBonusResponseFromJson(jsonString);

import 'dart:convert';

ReferralBonusResponse referralBonusResponseFromJson(String str) => ReferralBonusResponse.fromJson(json.decode(str));

String referralBonusResponseToJson(ReferralBonusResponse data) => json.encode(data.toJson());

class ReferralBonusResponse {
  final int? totalBalance;
  final List<InvitedCount>? invitedCount;

  ReferralBonusResponse({
    this.totalBalance,
    this.invitedCount,
  });

  factory ReferralBonusResponse.fromJson(Map<String, dynamic> json) => ReferralBonusResponse(
    totalBalance: json["total_balance"],
    invitedCount: json["invited_count"] == null ? [] : List<InvitedCount>.from(json["invited_count"]!.map((x) => InvitedCount.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "total_balance": totalBalance,
    "invited_count": invitedCount == null ? [] : List<dynamic>.from(invitedCount!.map((x) => x.toJson())),
  };
}

class InvitedCount {
  final int? id;
  final int? userId;
  final String? amount;
  final String? type;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvitedCount({
    this.id,
    this.userId,
    this.amount,
    this.type,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory InvitedCount.fromJson(Map<String, dynamic> json) => InvitedCount(
    id: json["id"],
    userId: json["user_id"],
    amount: json["amount"],
    type: json["type"],
    description: json["description"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "amount": amount,
    "type": type,
    "description": description,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
