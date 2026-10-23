class WalletBalanceSummaryResponse {
  final String? period;
  final double totalSpent;
  final List<WalletBalanceSummaryFeature> byFeature;

  const WalletBalanceSummaryResponse({
    this.period,
    this.totalSpent = 0,
    this.byFeature = const [],
  });

  factory WalletBalanceSummaryResponse.fromJson(Map<String, dynamic> json) {
    return WalletBalanceSummaryResponse(
      period: json['period'] as String?,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      byFeature: (json['by_feature'] as List<dynamic>?)
              ?.map((e) => WalletBalanceSummaryFeature.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class WalletBalanceSummaryFeature {
  final String? featureType;
  final double total;

  const WalletBalanceSummaryFeature({this.featureType, this.total = 0});

  factory WalletBalanceSummaryFeature.fromJson(Map<String, dynamic> json) {
    return WalletBalanceSummaryFeature(
      featureType: json['feature_type'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}
