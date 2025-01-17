import 'dart:convert';

import 'package:ap_common/config/ap_constants.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

enum PermissionLevel { user, editor, admin }

class AnnouncementLoginData {
  AnnouncementLoginData({
    this.key,
  });

  String? key;

  AnnouncementLoginData copyWith({
    String? key,
  }) =>
      AnnouncementLoginData(
        key: key ?? this.key,
      );

  factory AnnouncementLoginData.fromRawJson(String str) =>
      AnnouncementLoginData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AnnouncementLoginData.fromJson(Map<String, dynamic> json) =>
      AnnouncementLoginData(
        key: json["key"] == null ? null : json["key"],
      );

  Map<String, dynamic> toJson() => {
        "key": key == null ? null : key,
      };

  Map<String, dynamic> get decodedToken => JwtDecoder.decode(key!);

  bool get isExpired => JwtDecoder.isExpired(key!);

  PermissionLevel get level =>
      PermissionLevel.values[decodedToken['user']['permission_level']];

  String? get loginType => decodedToken['user']['login_type'];

  String? get username => decodedToken['user']['username'];

  void save() {
    Preferences.setStringSecurity(
      '${ApConstants.PACKAGE_NAME}'
      '.announcement_login_data',
      this.toRawJson(),
    );
  }

  static AnnouncementLoginData? load() {
    String? rawString = Preferences.getStringSecurity(
      '${ApConstants.PACKAGE_NAME}'
          '.announcement_login_data',
      '',
    );
    if (rawString == '')
      return null;
    else
      return AnnouncementLoginData.fromRawJson(rawString!);
  }
}
