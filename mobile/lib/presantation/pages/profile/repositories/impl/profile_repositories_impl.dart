import 'package:dio/dio.dart';
import 'package:pdaftaruz/core/handlers/api_result.dart';
import 'package:pdaftaruz/presantation/pages/applications/data/make_payment_response.dart';
import 'package:pdaftaruz/presantation/pages/applications/data/sms_tariffs_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/app_version_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/balance_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/create_user_referral_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/invited_users_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/payment_providers_response.dart';

import 'package:pdaftaruz/presantation/pages/profile/data/profile_update_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/seller_owner_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/send_invite_link_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_count_price_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/my_sms_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_usage_summary_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/wallet_balance_summary_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sessions_response.dart';

import '../../../../../constants/app_api_error_helper.dart';
import '../../../../../core/handlers/http_service.dart';
import '../../../../../core/imports/imports.dart';
import '../../../../../core/parsers/data_parser.dart';
import '../../../../../injection.dart';
import '../../../home/presantation/widgets/wallet_balance_response.dart';
import '../../data/user_info_response.dart';

class ProfileRepositoryImpl extends ProfileRepository {
  @override
  Future<ApiResult<dynamic>> update(
      {required int userId,
      String? name,
      File? imagePath,
      required String phoneNumber}) async {
    String fileName = imagePath?.path.split('/').last ?? "";
    // Send only what the caller actually has. An empty `name` was being
    // posted from the phone gate and failed the server's required rule;
    // a null `image` was going out as an empty multipart part, which the
    // `image` rule then rejected as not-an-image. Omitting both leaves
    // the stored values untouched.
    final formData = FormData.fromMap({
      if (name != null && name.trim().isNotEmpty) "name": name,
      "phone_number": phoneNumber,
      if (imagePath != null)
        "image": await MultipartFile.fromFile(imagePath.path,
            filename: fileName),
      "_method": "PUT"
    });
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.post('api/mobile/users/$userId', data: formData);
      return ApiResult.success(
        data: ProfileUpdateResponse.fromJson(response.data),
      );
    } on DioException catch (e) {
      debugPrint('==> profile update failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> profile update failure: $e');

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  // Start-up and an account switch ask for users/info from about five
  // places at once (main page, quiz gate, Home, the home refresh, the
  // Telegram gate); seen as 5 requests per switch on the emulator (#542).
  // Callers of the same session share one request, and a successful answer
  // is reused for a moment. Keyed by token, so another account never gets
  // this one's answer.
  static Future<ApiResult<dynamic>>? _userInfoInflight;
  static String? _userInfoToken;
  static DateTime? _userInfoAt;
  static ApiResult<dynamic>? _userInfoLast;
  static const _userInfoReuse = Duration(seconds: 2);

  /// Drops the reused answer, so the next call asks the server. An
  /// in-flight request is still shared.
  static void forgetUserInfo() {
    _userInfoLast = null;
    _userInfoAt = null;
  }

  @override
  Future<ApiResult<dynamic>> getUserInfo() {
    final token = LocalStorage.instance.getToken();
    if (_userInfoToken == token) {
      final inflight = _userInfoInflight;
      if (inflight != null) return inflight;
      final at = _userInfoAt;
      final last = _userInfoLast;
      if (at != null &&
          last != null &&
          DateTime.now().difference(at) < _userInfoReuse) {
        return Future.value(last);
      }
    }
    _userInfoToken = token;
    _userInfoLast = null;
    final request = _fetchUserInfo();
    _userInfoInflight = request;
    request.then((result) {
      if (!identical(_userInfoInflight, request)) return;
      _userInfoInflight = null;
      result.whenOrNull(success: (_) {
        _userInfoLast = result;
        _userInfoAt = DateTime.now();
      });
    });
    return request;
  }

  Future<ApiResult<dynamic>> _fetchUserInfo() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get(
        'api/mobile/users/info',
      );

      return await DataParser.parseResponse<UserInfoResponse>(
          response.data, UserInfoResponse.fromJson);
    } on DioException catch (e) {
      debugPrint('==> user info failure: $e');

      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: await DataParser.safeFromJson<UserInfoResponse>(
            e.response?.data, UserInfoResponse.fromJson),
      );
    } catch (e) {
      debugPrint('==> user info failure: $e');
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> leaveShop({required int shopId}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      await client.post('api/mobile/seller/leave-shop',
          data: {'shop_id': shopId});
      return const ApiResult.success(data: null);
    } on DioException catch (e) {
      debugPrint('==> leave shop failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> leave shop failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> getSellerOwner() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      // The selected shop's owner — a seller may work for several (#543).
      final shopId = LocalStorage.instance.getSelectedShopId();
      final response = await client.get(
        'api/mobile/seller/my-owner',
        queryParameters: shopId > 0 ? {'shop_id': shopId} : null,
      );
      return ApiResult.success(
        data: SellerOwnerResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map)),
      );
    } on DioException catch (e) {
      debugPrint('==> seller owner fetch failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    } catch (e) {
      debugPrint('==> seller owner fetch failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> changePassword(
      {required int userId,
      required String password,
      required String passwordConfirmation,
      required String oldPassword}) async {
    // TODO: implement update
    final data = <String, String>{
      "password": password,
      "password_confirmation": passwordConfirmation,
      "old_password": oldPassword
    };

    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client
          .post('api/mobile/users/$userId/change_password', data: data);

      return await DataParser.parseResponse(
          response.data, ProfileUpdateResponse.fromJson);
    } on DioException catch (e) {
      debugPrint('==> Change password OWNER failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> Change password  OWNER failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> deleteUser({required int? userID}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.delete('api/mobile/users/${userID ?? 0}/delete');

      return await DataParser.parseResponse(
          response.data, ProfileUpdateResponse.fromJson);
    } on DioException catch (e) {
      debugPrint('==> Delete user failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data ?? {}),
      );
    } catch (e) {
      debugPrint('==> Delete user failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> buySMSTariffOrder({
    required int userID,
    required int smsTariffID,
    required String paySys,
    int? smsCount,
  }) async {
    final data = <String, dynamic>{
      "user_id": userID,
      "sms_tariff_id": smsTariffID,
      "paysys": paySys,
      "selected_sms_count": smsCount
    };

    try {
      final client = inject<HttpService>().client(requireAuth: true);
      debugPrint('Data sent to sms/store-order: $data');
      final response =
          await client.post("api/mobile/sms/store-order", data: data);

      return await DataParser.parseResponse<MakePaymentResponse>(
          response.data, MakePaymentResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> Buy SMS tariff failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    } catch (e) {
      debugPrint("==> Buy SMS tariff failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> getSMSTariffs() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get('api/mobile/sms/get-tariffs');
      return await DataParser.parseResponse<SmsTariffsResponse>(
          response.data, SmsTariffsResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get SMS tariffs failure: $e");

      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: await DataParser.safeFromJson<SmsTariffsResponse>(
            e.response?.data, SmsTariffsResponse.fromJson),
      );
    } catch (e) {
      debugPrint("==> get SMS tariffs failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult> getSmsCountPrice({required int smsQty}) async {
    final data = <String, dynamic>{"selected_sms_count": smsQty};
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.post('api/mobile/sms/get-sms/by-count', data: data);
      return await DataParser.parseResponse<GetSmsCountPriceResponse>(
          response.data, GetSmsCountPriceResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get calculated sms price failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: await DataParser.safeFromJson<GetSmsCountPriceResponse>(
            e.response?.data, GetSmsCountPriceResponse.fromJson),
      );
    } catch (e) {
      debugPrint("==> get calculated sms price failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> createUserReferral({
    required String referralCode,
    required int userID,
  }) async {
    final data = <String, dynamic>{
      "referal_code": referralCode,
      "user_id": userID
    };

    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.post('api/mobile/users/create-referal', data: data);

      return await DataParser.parseResponse(
          response.data, CreateUserReferralResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> Create user referral code: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> Create User referral code: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> getInvitedUsers() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/users/invited-users");
      return await DataParser.parseResponse(
          response.data, InvitedUsersResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get invited users from referral code failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e),
          data: AppApiErrorHelper.message(e.response?.data));
    } catch (e) {
      debugPrint("==> get invited users from referral code failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getPaidUsers() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/users/paid-invited-users");
      return await DataParser.parseResponse(
          response.data, InvitedUsersResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get paid users from referral code failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e),
          data: AppApiErrorHelper.message(e.response?.data));
    } catch (e) {
      debugPrint("==> get paid users from referral code failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getReferralTotal() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/users/balance-summary");
      final total = response.data is Map ? response.data['total_balance'] : null;
      return ApiResult.success(
          data: total is num ? total : num.tryParse('$total') ?? 0);
    } on DioException catch (e) {
      // The raw code, not getDioStatus(): that maps 405 to 500, and 405 is
      // how a backend without this endpoint answers — the caller's cue to
      // fall back to balance-history.
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode:
              e.response?.statusCode ?? NetworkExceptions.getDioStatus(e));
    } catch (e) {
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getBalanceHistory() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/users/balance-history");
      return await DataParser.parseResponse(
          response.data, ReferralBonusResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get referral bonus failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e),
          data: AppApiErrorHelper.message(e.response?.data));
    } catch (e) {
      debugPrint("==> get referral bonus failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getSMSHistory() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/sms/purchase-history");
      return await DataParser.parseResponse(
          response.data, SmsHistoryResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get SMS history failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> get SMS history failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<SmsHistoryResponse>> getSmsPurchases(
      {required int page, int perPage = 20, String? period}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/sms/purchase-history",
          queryParameters: {
            'page': page,
            'per_page': perPage,
            if (period != null) 'period': period,
          });
      return ApiResult.success(
          data: SmsHistoryResponse.fromJson(
              Map<String, dynamic>.from(response.data as Map)));
    } on DioException catch (e) {
      debugPrint("==> get SMS purchases failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    } catch (e) {
      debugPrint("==> get SMS purchases failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getMySmsHistory({int? page, int? perPage}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final queryParams = <String, dynamic>{
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      };
      final response = await client.get(
        "api/mobile/users/my-sms-history",
        queryParameters: queryParams,
      );
      return await DataParser.parseResponse(
          response.data, MySmsHistoryResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get my SMS history failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> get my SMS history failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getMySmsUsageSummary({String? period}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get(
        "api/mobile/users/my-sms-usage-summary",
        queryParameters: period == null ? null : {"period": period},
      );
      return await DataParser.parseResponse(
          response.data, SmsUsageSummaryResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get my SMS usage summary failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> get my SMS usage summary failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> sendInviteLink(
      {required String phoneNumber}) async {
    try {
      final data = <String, String>{"phone_number": "+998$phoneNumber"};

      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.post("api/mobile/users/send-ivite-link", data: data);
      return await DataParser.parseResponse(
          response.data, SendInviteLinkResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> send invite link failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> send invite link failure: $e");

      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> topUpBalance(
      {required int userId,
      required int amount,
      required String paySys}) async {
    final data = <String, dynamic>{
      "user_id": userId,
      "amount": amount,
      "paysys": paySys,
    };
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.post("api/mobile/wallet-orders/store", data: data);

      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint("==> top up balance failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e),
          data: AppApiErrorHelper.message(e.response?.data));
    } catch (e) {
      debugPrint("==> top up balance failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getAppVersion() async {
    final data = <String, String>{"version": "1.2.0"};
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.post("api/mobile/version", data: data);

      return await DataParser.parseResponse(
          response.data, AppVersionResponse.fromJson);
    } on DioException catch (e) {
      debugPrint("==> get app version failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e),
          data: AppApiErrorHelper.message(e.response?.data));
    } catch (e) {
      debugPrint("==> get app version failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> checkAppVersion() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get("api/mobile/app-version");

      return await DataParser.parseResponse(
          response.data, AppVersionModel.fromJson);
    } on DioException catch (e) {
      debugPrint("==> check app version failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e),
          data: AppApiErrorHelper.message(e.response?.data));
    } catch (e) {
      debugPrint("==> check app version failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getWalletBalance() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response =
          await client.get("api/mobile/users/wallet-balance-history");

      return ApiResult.success(
          data: WalletBalanceResponse.fromJson(response.data));
    } on DioException catch (e) {
      debugPrint("==> get wallet balance failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> get wallet balance failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getWalletBalanceHistory({int? page}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final pageParam = page != null ? "?page=$page" : "";
      final response =
          await client.get("api/mobile/users/wallet-balance-history$pageParam");

      return ApiResult.success(
          data: WalletBalanceResponse.fromJson(response.data));
    } on DioException catch (e) {
      debugPrint("==> get wallet balance history failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> get wallet balance history failure: $e");
      return ApiResult.failure(
          error: NetworkExceptions.getDioException(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> getWalletBalanceSummary({
    required String period,
  }) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get(
        "api/mobile/users/wallet-balance-summary",
        queryParameters: {"period": period},
      );
      return ApiResult.success(
        data: WalletBalanceSummaryResponse.fromJson(response.data),
      );
    } on DioException catch (e) {
      debugPrint("==> get wallet balance summary failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint("==> get wallet balance summary failure: $e");
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> getPaymentProviders() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get('api/mobile/payment-providers');
      return ApiResult.success(
        data: PaymentProvidersResponse.fromJson(response.data),
      );
    } on DioException catch (e) {
      debugPrint('==> get payment providers failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> get payment providers failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> verifyPhone({
    required int userId,
    required String otp,
  }) async {
    final data = <String, String>{
      "otp": otp,
    };

    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.post(
        'api/mobile/users/$userId/verify-phone',
        data: data,
      );

      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> verify phone failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> verify phone failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> linkGoogleAccount({
    required String firebaseIdToken,
  }) async {
    final data = <String, String>{
      "firebase_id_token": firebaseIdToken,
    };

    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.post(
        'api/mobile/users/link-google',
        data: data,
      );

      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> link google account failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> link google account failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> getSessions() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get('api/mobile/sessions');

      return await DataParser.parseResponse(
          response.data, SessionsResponse.fromJson);
    } on DioException catch (e) {
      debugPrint('==> get sessions failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: await DataParser.safeFromJson<SessionsResponse>(
            e.response?.data, SessionsResponse.fromJson),
      );
    } catch (e) {
      debugPrint('==> get sessions failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> deleteAllSessions() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.delete('api/mobile/sessions');

      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> delete all sessions failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> delete all sessions failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> deleteSession({required int sessionId}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.delete('api/mobile/sessions/$sessionId');

      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> delete session failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> delete session failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateNotificationEnabled({required bool enabled}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.patch(
        'api/mobile/user-settings/notification-enabled',
        data: {'notification_enabled': enabled},
      );
      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> updateNotificationEnabled failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> updateNotificationEnabled failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateDailyReminderTime({required String time}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.patch(
        'api/mobile/user-settings/daily-reminder-time',
        data: {'daily_reminder_time': time},
      );
      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> updateDailyReminderTime failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> updateDailyReminderTime failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateMorningGreetingTime({required String time}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.patch(
        'api/mobile/user-settings/morning-greeting-time',
        data: {'morning_greeting_time': time},
      );
      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> updateMorningGreetingTime failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> updateMorningGreetingTime failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateShowMahsulotTab({required bool enabled}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.patch(
        'api/mobile/user-settings/show-mahsulot-tab',
        data: {'show_mahsulot_tab': enabled},
      );
      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> updateShowMahsulotTab failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> updateShowMahsulotTab failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateShowKassaTab({required bool enabled}) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.patch(
        'api/mobile/user-settings/show-kassa-tab',
        data: {'show_kassa_tab': enabled},
      );
      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> updateShowKassaTab failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> updateShowKassaTab failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> getUserSettings() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get('api/mobile/user-settings');
      return ApiResult.success(data: response.data);
    } on DioException catch (e) {
      debugPrint('==> getUserSettings failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> getUserSettings failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
