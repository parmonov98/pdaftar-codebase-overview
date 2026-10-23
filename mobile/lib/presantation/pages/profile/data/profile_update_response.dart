class ProfileUpdateResponse {
  bool? success;
  String? message;
  bool? requiresVerification;
  Data? data;

  ProfileUpdateResponse({
    this.success,
    this.message,
    this.requiresVerification,
    this.data,
  });

  ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    requiresVerification = json['requires_verification'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['requires_verification'] = requiresVerification;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  bool? success;

  Data({this.success});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    return data;
  }
}
