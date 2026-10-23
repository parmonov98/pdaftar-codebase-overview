/// Rewards an inviter earns when an invited friend buys a paid tariff with
/// real money (Trello #544). Backend: GET api/mobile/users/referral-rewards.
class ReferralRewardsResponse {
  final bool enabled;
  final int thisMonthCount;
  final List<ReferralReward> pending;
  final List<ReferralReward> history;

  const ReferralRewardsResponse({
    this.enabled = false,
    this.thisMonthCount = 0,
    this.pending = const [],
    this.history = const [],
  });

  factory ReferralRewardsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return ReferralRewardsResponse(
      enabled: data['enabled'] == true,
      thisMonthCount: _toInt(data['this_month_count']),
      pending: _list(data['pending']),
      history: _list(data['history']),
    );
  }

  static List<ReferralReward> _list(dynamic raw) => raw is List
      ? raw
          .whereType<Map<String, dynamic>>()
          .map(ReferralReward.fromJson)
          .toList()
      : const [];
}

class ReferralReward {
  static const statusPending = 'pending_choice';
  static const statusGrantedExtension = 'granted_extension';
  static const statusGrantedBalance = 'granted_balance';

  final int id;
  final String status;
  final String? friendName;
  final String? friendTariffName;
  final int valueUzs;
  final DateTime? autoResolveAt;
  final int? grantedDays;
  final int? grantedAmount;
  final DateTime? resolvedAt;
  final ReferralRewardOptions? options;

  const ReferralReward({
    required this.id,
    required this.status,
    this.friendName,
    this.friendTariffName,
    this.valueUzs = 0,
    this.autoResolveAt,
    this.grantedDays,
    this.grantedAmount,
    this.resolvedAt,
    this.options,
  });

  bool get isPending => status == statusPending;

  factory ReferralReward.fromJson(Map<String, dynamic> json) => ReferralReward(
        id: _toInt(json['id']),
        status: '${json['status'] ?? ''}',
        friendName: json['friend_name'] as String?,
        friendTariffName: json['friend_tariff_name'] as String?,
        valueUzs: _toInt(json['value_uzs']),
        autoResolveAt: DateTime.tryParse('${json['auto_resolve_at'] ?? ''}'),
        grantedDays:
            json['granted_days'] == null ? null : _toInt(json['granted_days']),
        grantedAmount: json['granted_amount'] == null
            ? null
            : _toInt(json['granted_amount']),
        resolvedAt: DateTime.tryParse('${json['resolved_at'] ?? ''}'),
        options: json['options'] is Map<String, dynamic>
            ? ReferralRewardOptions.fromJson(
                json['options'] as Map<String, dynamic>)
            : null,
      );
}

/// What each choice would give right now, computed by the backend.
class ReferralRewardOptions {
  /// 'upgrade' when the inviter is on the free tariff (they get the friend's
  /// tariff for [extendDays] days), 'extend' when their own tariff is
  /// extended by [extendDays] days.
  final String extendMode;
  final int extendDays;
  final String? extendTariffName;
  final int balanceAmount;

  const ReferralRewardOptions({
    required this.extendMode,
    required this.extendDays,
    this.extendTariffName,
    required this.balanceAmount,
  });

  bool get isUpgrade => extendMode == 'upgrade';

  factory ReferralRewardOptions.fromJson(Map<String, dynamic> json) {
    final extend = json['extend'] is Map ? json['extend'] as Map : const {};
    final balance = json['balance'] is Map ? json['balance'] as Map : const {};
    return ReferralRewardOptions(
      extendMode: '${extend['mode'] ?? 'extend'}',
      extendDays: _toInt(extend['days']),
      extendTariffName: extend['tariff_name'] as String?,
      balanceAmount: _toInt(balance['amount']),
    );
  }
}

int _toInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? 0;
