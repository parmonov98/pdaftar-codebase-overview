// To parse this JSON data, do
//
//     final sessionsResponse = sessionsResponseFromJson(jsonString);

import 'dart:convert';

SessionsResponse sessionsResponseFromJson(String str) =>
    SessionsResponse.fromJson(json.decode(str));

String sessionsResponseToJson(SessionsResponse data) =>
    json.encode(data.toJson());

class SessionsResponse {
  final String? userType;
  final List<SessionData>? data;

  SessionsResponse({
    this.userType,
    this.data,
  });

  factory SessionsResponse.fromJson(Map<String, dynamic> json) =>
      SessionsResponse(
        userType: json["user_type"],
        data: json["data"] == null
            ? []
            : List<SessionData>.from(
                json["data"]!.map((x) => SessionData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "user_type": userType,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class SessionData {
  final int? id;
  final String? name;
  final String? deviceName;
  final String? deviceType;
  final String? platform;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final bool? isCurrent;
  final String? ipAddress;

  SessionData({
    this.id,
    this.name,
    this.deviceName,
    this.deviceType,
    this.platform,
    this.lastUsedAt,
    this.createdAt,
    this.isCurrent,
    this.ipAddress,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        id: json["id"],
        name: json["name"],
        deviceName: json["device_name"],
        deviceType: json["device_type"],
        platform: json["platform"],
        lastUsedAt: json["last_used_at"] == null
            ? null
            : DateTime.parse(json["last_used_at"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        isCurrent: json["is_current"],
        ipAddress: json["ip_address"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "device_name": deviceName,
        "device_type": deviceType,
        "platform": platform,
        "last_used_at": lastUsedAt?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
        "is_current": isCurrent,
        "ip_address": ipAddress,
      };
}
