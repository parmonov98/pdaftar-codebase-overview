import 'dart:convert';

/// Wraps the response from `GET /api/mobile/users/my-sms-usage-summary`.
///
/// Both buckets (`current_month` and `previous_month`) are computed
/// server-side from `sms_jobs` so the UI doesn't have to depend on
/// pagination state to know how much SMS limit a user has burned in a
/// given calendar month.
SmsUsageSummaryResponse smsUsageSummaryResponseFromJson(String str) =>
    SmsUsageSummaryResponse.fromJson(json.decode(str));

class SmsUsageSummaryResponse {
  final bool? success;
  final SmsUsageSummaryData? data;

  SmsUsageSummaryResponse({this.success, this.data});

  factory SmsUsageSummaryResponse.fromJson(Map<String, dynamic> json) =>
      SmsUsageSummaryResponse(
        success: json['success'],
        data: json['data'] == null
            ? null
            : SmsUsageSummaryData.fromJson(
                Map<String, dynamic>.from(json['data'])),
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data?.toJson(),
      };
}

class SmsUsageSummaryData {
  final SmsUsageBucket? currentMonth;
  final SmsUsageBucket? previousMonth;

  /// Single-bucket totals returned when the request was made with a
  /// `period` query parameter (current_month, previous_month, this_year,
  /// all_time). Mutually exclusive with [currentMonth]/[previousMonth].
  final SmsUsageBucket? bucket;

  /// Echoes back the `period` value the caller supplied so the UI can
  /// confirm which chip the totals correspond to.
  final String? period;

  SmsUsageSummaryData({
    this.currentMonth,
    this.previousMonth,
    this.bucket,
    this.period,
  });

  factory SmsUsageSummaryData.fromJson(Map<String, dynamic> json) {
    // When `period` is present the response collapses to a flat bucket;
    // otherwise it has the legacy current/previous shape.
    if (json.containsKey('period')) {
      return SmsUsageSummaryData(
        bucket: SmsUsageBucket.fromJson(Map<String, dynamic>.from(json)),
        period: json['period'] as String?,
      );
    }
    return SmsUsageSummaryData(
      currentMonth: json['current_month'] == null
          ? null
          : SmsUsageBucket.fromJson(
              Map<String, dynamic>.from(json['current_month'])),
      previousMonth: json['previous_month'] == null
          ? null
          : SmsUsageBucket.fromJson(
              Map<String, dynamic>.from(json['previous_month'])),
    );
  }

  Map<String, dynamic> toJson() => {
        if (period != null) 'period': period,
        if (bucket != null) ...bucket!.toJson(),
        if (currentMonth != null) 'current_month': currentMonth?.toJson(),
        if (previousMonth != null) 'previous_month': previousMonth?.toJson(),
      };
}

class SmsUsageBucket {
  /// Sum of SMS parts billed against the user's limit for this bucket.
  final int? totalSms;

  /// Number of `sms_jobs` rows that contributed to [totalSms].
  final int? totalJobs;

  /// Calendar year of the bucket — useful when rendering localized
  /// month names so the client doesn't need to derive them.
  final int? year;

  /// Calendar month of the bucket (1–12).
  final int? month;

  SmsUsageBucket({this.totalSms, this.totalJobs, this.year, this.month});

  factory SmsUsageBucket.fromJson(Map<String, dynamic> json) => SmsUsageBucket(
        totalSms: json['total_sms'],
        totalJobs: json['total_jobs'],
        year: json['year'],
        month: json['month'],
      );

  Map<String, dynamic> toJson() => {
        'total_sms': totalSms,
        'total_jobs': totalJobs,
        'year': year,
        'month': month,
      };
}
