import 'package:hyper_local_seller/service/json_parser.dart';

class AppVersionModel {
  bool? success;
  String? message;
  AppVersionData? data;

  AppVersionModel({this.success, this.message, this.data});

  AppVersionModel.fromJson(Map<String, dynamic> json) {
    success = JsonParser.boolValue(json['success']);
    message = JsonParser.string(json['message']);
    data = json['data'] != null ? AppVersionData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class AppVersionData {
  bool? updateAvailable;
  String? updateType;
  String? minSupportedVersion;
  String? latestVersion;
  String? message;
  String? updateUrl;

  AppVersionData({
    this.updateAvailable,
    this.updateType,
    this.minSupportedVersion,
    this.latestVersion,
    this.message,
    this.updateUrl,
  });

  AppVersionData.fromJson(Map<String, dynamic> json) {
    updateAvailable = JsonParser.boolValue(json['update_available']);
    updateType = JsonParser.string(json['update_type']);
    minSupportedVersion = JsonParser.string(json['min_supported_version']);
    latestVersion = JsonParser.string(json['latest_version']);
    message = JsonParser.string(json['message']);
    updateUrl = JsonParser.string(json['update_url']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['update_available'] = updateAvailable;
    data['update_type'] = updateType;
    data['min_supported_version'] = minSupportedVersion;
    data['latest_version'] = latestVersion;
    data['message'] = message;
    data['update_url'] = updateUrl;
    return data;
  }
}
