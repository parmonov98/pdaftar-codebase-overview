import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pdaftaruz/constants/app_api_error_helper.dart';
import 'package:pdaftaruz/core/handlers/api_result.dart';
import 'package:pdaftaruz/core/handlers/network_exception.dart';
import 'package:pdaftaruz/core/handlers/http_service.dart';
import 'package:pdaftaruz/injection.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/referral_rewards_response.dart';

/// Referral purchase rewards (Trello #544). Kept apart from
/// ProfileRepositories so its fakes don't have to grow two methods.
class ReferralRewardsRepository {
  const ReferralRewardsRepository();

  Future<ApiResult<ReferralRewardsResponse>> getRewards() async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get('api/mobile/users/referral-rewards');
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ApiResult.success(data: ReferralRewardsResponse.fromJson(body));
    } on DioException catch (e) {
      debugPrint('==> get referral rewards failure: $e');
      // A backend without the endpoint answers 404/405: no rewards to show.
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        return const ApiResult.success(data: ReferralRewardsResponse());
      }
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    } catch (e) {
      debugPrint('==> get referral rewards failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// [choice] is 'extend' or 'balance'. On failure `data` carries the
  /// backend's message for the snackbar.
  Future<ApiResult<String?>> choose({
    required int rewardId,
    required String choice,
  }) async {
    try {
      final client = inject<HttpService>().client(requireAuth: true);
      await client.post(
        'api/mobile/users/referral-rewards/$rewardId/choose',
        data: {'choice': choice},
      );
      return const ApiResult.success(data: null);
    } on DioException catch (e) {
      debugPrint('==> choose referral reward failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
        data: AppApiErrorHelper.message(e.response?.data),
      );
    } catch (e) {
      debugPrint('==> choose referral reward failure: $e');
      return ApiResult.failure(
        error: NetworkExceptions.getDioException(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
