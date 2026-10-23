// To parse this JSON data, do
//
//     final checkReferralCodeResponse = checkReferralCodeResponseFromJson(jsonString);

import 'dart:convert';

CreateUserReferralResponse checkReferralCodeResponseFromJson(String str) => CreateUserReferralResponse.fromJson(json.decode(str));

String checkReferralCodeResponseToJson(CreateUserReferralResponse data) => json.encode(data.toJson());

class CreateUserReferralResponse {
  final bool? success;
  final String? message;
  final String? referalCode;
  final Benefits? benefits;

  CreateUserReferralResponse({
    this.success,
    this.message,
    this.referalCode,
    this.benefits,
  });

  factory CreateUserReferralResponse.fromJson(Map<String, dynamic> json) => CreateUserReferralResponse(
    success: json["success"],
    message: json["message"],
    referalCode: json["referal_code"],
    benefits: json["benefits"] == null ? null : Benefits.fromJson(json["benefits"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "referal_code": referalCode,
    "benefits": benefits?.toJson(),
  };
}

class Benefits {
  final String? signupBonus;
  final String? paymentBonus;

  Benefits({
    this.signupBonus,
    this.paymentBonus,
  });

  factory Benefits.fromJson(Map<String, dynamic> json) => Benefits(
    signupBonus: json["signup_bonus"],
    paymentBonus: json["payment_bonus"],
  );

  Map<String, dynamic> toJson() => {
    "signup_bonus": signupBonus,
    "payment_bonus": paymentBonus,
  };
}
