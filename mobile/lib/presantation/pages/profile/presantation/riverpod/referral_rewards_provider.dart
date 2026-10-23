import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/referral_rewards_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/repositories/referral_rewards_repository.dart';

final referralRewardsRepositoryProvider = Provider<ReferralRewardsRepository>(
    (ref) => const ReferralRewardsRepository());

final referralRewardsProvider =
    StateNotifierProvider<ReferralRewardsNotifier, ReferralRewardsState>(
  (ref) => ReferralRewardsNotifier(ref.read(referralRewardsRepositoryProvider)),
);

class ReferralRewardsState {
  final bool isLoading;
  final ReferralRewardsResponse data;

  /// Reward id whose choice is being sent; blocks a second tap.
  final int? choosingId;

  const ReferralRewardsState({
    this.isLoading = false,
    this.data = const ReferralRewardsResponse(),
    this.choosingId,
  });

  ReferralRewardsState copyWith({
    bool? isLoading,
    ReferralRewardsResponse? data,
    int? choosingId,
    bool clearChoosing = false,
  }) =>
      ReferralRewardsState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        choosingId: clearChoosing ? null : (choosingId ?? this.choosingId),
      );
}

/// Outcome of a choice, for the caller's snackbar.
class ReferralRewardChoiceResult {
  final bool ok;
  final String? errorMessage;

  const ReferralRewardChoiceResult({required this.ok, this.errorMessage});
}

class ReferralRewardsNotifier extends StateNotifier<ReferralRewardsState> {
  ReferralRewardsNotifier(this._repository)
      : super(const ReferralRewardsState());

  final ReferralRewardsRepository _repository;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final result = await _repository.getRewards();
    if (!mounted) return;
    result.when(
      success: (data) => state = state.copyWith(isLoading: false, data: data),
      // Keep what is on screen; the section stays quiet on a failed refresh.
      failure: (_, __, ___) => state = state.copyWith(isLoading: false),
    );
  }

  Future<ReferralRewardChoiceResult> choose({
    required int rewardId,
    required String choice,
  }) async {
    if (state.choosingId != null) {
      return const ReferralRewardChoiceResult(ok: false);
    }
    state = state.copyWith(choosingId: rewardId);
    final result = await _repository.choose(rewardId: rewardId, choice: choice);
    if (!mounted) return const ReferralRewardChoiceResult(ok: false);
    state = state.copyWith(clearChoosing: true);

    return result.when(
      success: (_) {
        load();
        return const ReferralRewardChoiceResult(ok: true);
      },
      failure: (error, statusCode, data) {
        load();
        return ReferralRewardChoiceResult(
          ok: false,
          errorMessage: data is String && data.isNotEmpty ? data : null,
        );
      },
    );
  }
}
