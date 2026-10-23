
import 'dart:convert';
import 'dart:io';


AppVersionResponse appVersionResponseFromJson(String str) =>
    AppVersionResponse.fromJson(json.decode(str));

String appVersionResponseToJson(AppVersionResponse data) =>
    json.encode(data.toJson());

class AppVersionResponse {
  final String? backVersion;
  final bool? updateNeeded;
  final String? message;

  AppVersionResponse({
    this.backVersion,
    this.updateNeeded,
    this.message,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) =>
      AppVersionResponse(
        backVersion: json["back_version"],
        updateNeeded: json["update_needed"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "back_version": backVersion,
        "update_needed": updateNeeded,
        "message": message,
      };
}

class AppVersionModel {
  final String version;
  final String currentVersion;
  final bool canUpdate;
  final String message;

  AppVersionModel({
    required this.version,
    this.currentVersion = '',
    this.message = '',
    this.canUpdate = false,
  });

  static String _platformKey() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'android'; // default
    }
  }

  AppVersionModel copyWith(
      {required String? currentVersion, required bool canUpdate}) {
    return AppVersionModel(
        version: version, canUpdate: canUpdate, currentVersion: currentVersion??version);
  }

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      version: json[_platformKey()] ?? '',
    );
  }
}
