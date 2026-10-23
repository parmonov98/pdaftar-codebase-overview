class PaymentProvidersResponse {
  final bool success;
  final List<PaymentProvider> data;
  final String? message;

  PaymentProvidersResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory PaymentProvidersResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProvidersResponse(
      success: json['success'] == true,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => PaymentProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}

class PaymentProvider {
  final int id;
  final String name;
  final String code;
  final String? displayName;
  final String? logoUrl;
  final bool isEnabled;
  final bool isDefault;

  PaymentProvider({
    required this.id,
    required this.name,
    required this.code,
    this.displayName,
    this.logoUrl,
    required this.isEnabled,
    required this.isDefault,
  });

  factory PaymentProvider.fromJson(Map<String, dynamic> json) {
    return PaymentProvider(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      displayName: json['display_name'] as String?,
      logoUrl: json['logo_url'] as String?,
      isEnabled: (json['is_enabled'] ?? false) as bool,
      isDefault: (json['is_default'] ?? false) as bool,
    );
  }
}
