// To parse this JSON data, do
//
//     final sendInviteLinkResponse = sendInviteLinkResponseFromJson(jsonString);

import 'dart:convert';

SendInviteLinkResponse sendInviteLinkResponseFromJson(String str) => SendInviteLinkResponse.fromJson(json.decode(str));

String sendInviteLinkResponseToJson(SendInviteLinkResponse data) => json.encode(data.toJson());

class SendInviteLinkResponse {
  final String? message;

  SendInviteLinkResponse({
    this.message,
  });

  factory SendInviteLinkResponse.fromJson(Map<String, dynamic> json) => SendInviteLinkResponse(
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "message": message,
  };
}
