// To parse this JSON data, do
//
//     final userInfoResponse = userInfoResponseFromJson(jsonString);

import 'dart:convert';

UserInfoResponse userInfoResponseFromJson(String str) =>
    UserInfoResponse.fromJson(json.decode(str));

String userInfoResponseToJson(UserInfoResponse data) =>
    json.encode(data.toJson());

class UserInfoResponse {
  final String? userType;
  final Data? data;

  UserInfoResponse({
    this.userType,
    this.data,
  });

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) =>
      UserInfoResponse(
        userType: json["user_type"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "user_type": userType,
        "data": data?.toJson(),
      };
}

class Data {
  final int? id;
  final String? name;
  final String? phoneNumber;
  final dynamic image;
  final bool? acceptedTerms;
  final dynamic acceptedTermsAt;
  final bool? acceptedPolicy;
  final dynamic acceptedPolicyAt;
  final bool? isSellerActive; // ✅ Yangi maydon
  final String? ownerPhone; // ✅ Yangi maydon
  final bool? isVerifiedPhone; // ✅ Telefon tasdiqlanganmi
  final bool? googleLinked; // ✅ Google account ulanmagan yoki ulanmaganligi
  final String? googleEmail; // ✅ Google email
  final bool? telegramConnected; // ✅ @pDaftarBot ga ulanganmi
  final Inviter?
      inviter; // User who invited me (nullable; null if not referred)
  final OnboardingQuizStatus? onboardingQuiz;
  /// Mandatory shop-profile completion (Trello SuGPHMgl): non-null for
  /// owners; `required` stays true until the placeholder name is
  /// replaced and category + location are set.
  final ShopSetupStatus? shopSetup;

  Data({
    this.id,
    this.name,
    this.phoneNumber,
    this.image,
    this.acceptedTerms,
    this.acceptedTermsAt,
    this.acceptedPolicy,
    this.acceptedPolicyAt,
    this.isSellerActive,
    this.ownerPhone,
    this.isVerifiedPhone,
    this.googleLinked,
    this.googleEmail,
    this.telegramConnected,
    this.inviter,
    this.onboardingQuiz,
    this.shopSetup,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        name: json["name"],
        phoneNumber: json["phone_number"],
        image: json["image"],
        acceptedTerms: json["accepted_terms"],
        acceptedTermsAt: json["accepted_terms_at"],
        acceptedPolicy: json["accepted_policy"],
        acceptedPolicyAt: json["accepted_policy_at"],
        isSellerActive: json["is_seller_active"],
        ownerPhone: json["owner_phone"], // ✅ JSON'dan o'qiladi
        isVerifiedPhone: json["is_verified_phone"], // ✅ JSON'dan o'qiladi
        googleLinked: json[
            "google_linked"], // ✅ Google account ulanmagan yoki ulanmaganligi
        googleEmail: json["google_email"], // ✅ Google email
        telegramConnected:
            json["telegram_connected"], // ✅ @pDaftarBot ga ulanganmi
        inviter:
            json["inviter"] == null ? null : Inviter.fromJson(json["inviter"]),
        onboardingQuiz: json["onboarding_quiz"] == null
            ? null
            : OnboardingQuizStatus.fromJson(json["onboarding_quiz"]),
        shopSetup: json["shop_setup"] == null
            ? null
            : ShopSetupStatus.fromJson(json["shop_setup"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "phone_number": phoneNumber,
        "image": image,
        "accepted_terms": acceptedTerms,
        "accepted_terms_at": acceptedTermsAt,
        "accepted_policy": acceptedPolicy,
        "accepted_policy_at": acceptedPolicyAt,
        "is_seller_active": isSellerActive,
        "owner_phone": ownerPhone, // ✅ JSON'ga yoziladi
        "is_verified_phone": isVerifiedPhone, // ✅ JSON'ga yoziladi
        "google_linked": googleLinked, // ✅ JSON'ga yoziladi
        "google_email": googleEmail, // ✅ JSON'ga yoziladi
        "telegram_connected": telegramConnected, // ✅ JSON'ga yoziladi
        "inviter": inviter?.toJson(),
        "onboarding_quiz": onboardingQuiz?.toJson(),
        "shop_setup": shopSetup?.toJson(),
      };
}

/// Drives the post-auth router decision: send the user to the onboarding quiz
/// or straight to the home screen. `shouldShowQuiz=true` means the user has
/// not yet completed a real (non-backfill) quiz answer.
class OnboardingQuizStatus {
  final int? quizAnswerId;
  final String? completedAt;
  final bool? shouldShowQuiz;
  final bool isExistingUser;

  OnboardingQuizStatus({
    this.quizAnswerId,
    this.completedAt,
    this.shouldShowQuiz,
    this.isExistingUser = false,
  });

  factory OnboardingQuizStatus.fromJson(Map<String, dynamic> json) =>
      OnboardingQuizStatus(
        quizAnswerId: json["quiz_answer_id"],
        completedAt: json["completed_at"],
        shouldShowQuiz: json["should_show_quiz"],
        isExistingUser: json["is_existing_user"] == true,
      );

  Map<String, dynamic> toJson() => {
        "quiz_answer_id": quizAnswerId,
        "completed_at": completedAt,
        "should_show_quiz": shouldShowQuiz,
        "is_existing_user": isExistingUser,
      };
}

/// Inviter payload returned by the backend `UserResource`.
/// Populated when the current user was referred by someone; null otherwise.
class Inviter {
  final int? id;
  final String? name;
  final String? phoneNumber;
  final String? businessName;

  Inviter({this.id, this.name, this.phoneNumber, this.businessName});

  factory Inviter.fromJson(Map<String, dynamic> json) => Inviter(
        id: json["id"],
        name: json["name"],
        phoneNumber: json["phone_number"],
        businessName: json["businessName"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "phone_number": phoneNumber,
        "businessName": businessName,
      };
}


/// users/info `shop_setup` — completeness of the owner's first shop.
class ShopSetupStatus {
  final bool? required_;
  final int? shopId;
  final String? name;
  final bool? isDefaultName;
  final int? businessCategoryId;
  final String? address;
  final int? currencyId;

  ShopSetupStatus({
    this.required_,
    this.shopId,
    this.name,
    this.isDefaultName,
    this.businessCategoryId,
    this.address,
    this.currencyId,
  });

  factory ShopSetupStatus.fromJson(Map<String, dynamic> json) =>
      ShopSetupStatus(
        required_: json["required"] as bool?,
        shopId: json["shop_id"] as int?,
        name: json["name"] as String?,
        isDefaultName: json["is_default_name"] as bool?,
        businessCategoryId: json["business_category_id"] as int?,
        address: json["address"] as String?,
        currencyId: json["currency_id"] as int?,
      );

  Map<String, dynamic> toJson() => {
        "required": required_,
        "shop_id": shopId,
        "name": name,
        "is_default_name": isDefaultName,
        "business_category_id": businessCategoryId,
        "address": address,
        "currency_id": currencyId,
      };
}
