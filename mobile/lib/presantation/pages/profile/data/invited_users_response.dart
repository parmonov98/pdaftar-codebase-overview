// To parse this JSON data, do
//
//     final invitedUsersResponse = invitedUsersResponseFromJson(jsonString);

import 'dart:convert';

InvitedUsersResponse invitedUsersResponseFromJson(String str) => InvitedUsersResponse.fromJson(json.decode(str));

String invitedUsersResponseToJson(InvitedUsersResponse data) => json.encode(data.toJson());

class InvitedUsersResponse {
  final String? referalCode;
  final int? invitedCount;
  final List<InvitedUser>? invitedUsers;

  InvitedUsersResponse({
    this.referalCode,
    this.invitedCount,
    this.invitedUsers,
  });

  factory InvitedUsersResponse.fromJson(Map<String, dynamic> json) => InvitedUsersResponse(
    referalCode: json["referal_code"],
    invitedCount: json["invited_count"],
    invitedUsers: json["invited_users"] == null ? [] : List<InvitedUser>.from(json["invited_users"]!.map((x) => InvitedUser.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "referal_code": referalCode,
    "invited_count": invitedCount,
    "invited_users": invitedUsers == null ? [] : List<dynamic>.from(invitedUsers!.map((x) => x.toJson())),
  };
}

class InvitedUser {
  final int? id;
  final String? name;
  final String? phoneNumber;
  final bool? isRegistered;

  InvitedUser({
    this.id,
    this.name,
    this.phoneNumber,
    this.isRegistered,
  });

  factory InvitedUser.fromJson(Map<String, dynamic> json) => InvitedUser(
    id: json["id"],
    name: json["name"],
    phoneNumber: json["phone_number"],
    isRegistered: json["is_registered"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone_number": phoneNumber,
    "is_registered": isRegistered,
  };
}
