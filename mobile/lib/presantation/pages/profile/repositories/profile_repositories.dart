import 'dart:io';


import '../../../../core/handlers/api_result.dart';
import '../data/sms_history_response.dart';

abstract class ProfileRepository {
  /// [name] is optional: the post-signup phone gate submits a phone and
  /// nothing else, and the backend leaves the stored name untouched when
  /// the field is absent.
  Future<ApiResult<dynamic>> update({
    required int userId,
    String? name,
    required String phoneNumber,
    File? imagePath,
  });


  Future<ApiResult<dynamic>> changePassword(

      {required int userId,
        required String password,
        required String passwordConfirmation,
        required String oldPassword});


  Future<ApiResult<dynamic>> getUserInfo();

  /// GET /api/mobile/seller/my-owner — fetches the OWNER user of the
  /// authenticated seller's currently-attached shop. Surfaced on the
  /// Profil tab when userType=SELLER so the seller sees their boss's
  /// identity (everything else on that page is owner-scoped data).
  /// Owners hit a 404 here — they should keep using getUserInfo().
  Future<ApiResult<dynamic>> getSellerOwner();

  /// POST /api/mobile/seller/leave-shop — the seller leaves one business
  /// they work in (#543). Success data is null.
  Future<ApiResult<dynamic>> leaveShop({required int shopId});

  Future<ApiResult<dynamic>> deleteUser({required int? userID});

  Future<ApiResult<dynamic>> createUserReferral({required String referralCode, required int userID});

  Future<ApiResult<dynamic>> getInvitedUsers();

  Future<ApiResult<dynamic>> getPaidUsers();

  Future<ApiResult<dynamic>> getAppVersion();
  Future<ApiResult<dynamic>> checkAppVersion();

  Future<ApiResult<dynamic>> buySMSTariffOrder({
    required int userID,
    required int smsTariffID,
    required String paySys,
    int? smsCount,
  });

  Future<ApiResult<dynamic>> getSMSTariffs();

  Future<ApiResult<dynamic>> getBalanceHistory();

  /// Referral total only (`users/balance-summary`), without the full,
  /// unpaginated history list. Succeeds with the total as a num.
  Future<ApiResult<dynamic>> getReferralTotal();

  Future<ApiResult<dynamic>> getSMSHistory();

  /// One page of the owner's SMS purchases for a period (Trello #488).
  Future<ApiResult<SmsHistoryResponse>> getSmsPurchases(
      {required int page, int perPage = 20, String? period});

  Future<ApiResult<dynamic>> getMySmsHistory({int? page, int? perPage});

  /// `GET /users/my-sms-usage-summary` — server-side aggregation of how
  /// much SMS limit the user has spent in the current and previous
  /// calendar months.
  Future<ApiResult<dynamic>> getMySmsUsageSummary({String? period});

  Future<ApiResult<dynamic>> sendInviteLink({required String phoneNumber});

  Future<ApiResult<dynamic>> getSmsCountPrice({required int smsQty});


  Future<ApiResult<dynamic>> topUpBalance({
    required int userId,
    required int amount,
    required String paySys
  });


  Future<ApiResult<dynamic>> getWalletBalance();

  Future<ApiResult<dynamic>> getWalletBalanceHistory({int? page});

  Future<ApiResult<dynamic>> getWalletBalanceSummary({required String period});

  // Payment providers
  Future<ApiResult<dynamic>> getPaymentProviders();

  // Phone verification
  Future<ApiResult<dynamic>> verifyPhone({
    required int userId,
    required String otp,
  });

  // Link Google account
  Future<ApiResult<dynamic>> linkGoogleAccount({
    required String firebaseIdToken,
  });

  // Sessions management
  Future<ApiResult<dynamic>> getSessions();

  Future<ApiResult<dynamic>> deleteAllSessions();

  Future<ApiResult<dynamic>> deleteSession({required int sessionId});

  Future<ApiResult<dynamic>> updateNotificationEnabled({required bool enabled});

  /// PATCH /user-settings/daily-reminder-time. `time` must be HH:MM
  /// (server tz). Used by the notification settings page.
  Future<ApiResult<dynamic>> updateDailyReminderTime({required String time});

  /// PATCH /user-settings/morning-greeting-time. `time` must be HH:MM
  /// (server tz).
  Future<ApiResult<dynamic>> updateMorningGreetingTime({required String time});

  /// PATCH /user-settings/show-mahsulot-tab. Per-user toggle for the
  /// mobile Mahsulot bottom-nav tab. Sync changes to MainNotifier so
  /// the bottom bar re-renders immediately.
  Future<ApiResult<dynamic>> updateShowMahsulotTab({required bool enabled});

  /// PATCH /user-settings/show-kassa-tab. Per-user toggle for the Kassa
  /// bottom-nav tab.
  Future<ApiResult<dynamic>> updateShowKassaTab({required bool enabled});

  Future<ApiResult<dynamic>> getUserSettings();
}