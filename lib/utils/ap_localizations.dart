import 'package:ap_common/resources/ap_icon.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../l10n/l10n.dart';

export 'package:ap_common/models/ap_support_language.dart';
export 'package:ap_common/l10n/l10n.dart';
export 'package:intl/intl.dart';

extension ApExtension on ApLocalizations {
  String get dateTimeLocale {
    if (Intl.defaultLocale!.contains('TW'))
      return 'zh-TW';
    else
      return 'en-US';
  }

  String get locale {
    if (Intl.defaultLocale!.contains('TW'))
      return 'zh-TW';
    else
      return 'en-US';
  }

  String get iconText {
    switch (ApIcon.code) {
      case ApIcon.FILLED:
        return filled;
      case ApIcon.OUTLINED:
      default:
        return outlined;
    }
  }

  List<String> get weekdaysCourse => [
        mon,
        tue,
        wed,
        thu,
        fri,
        sat,
        sun,
      ];

  List<String> get weekdays => [
        sunday,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
      ];
}

extension DioErrorI18nExtension on DioError {
  String? get i18nMessage {
    switch (type) {
      case DioErrorType.other:
        return ApLocalizations.current.noInternet;
      case DioErrorType.connectTimeout:
      case DioErrorType.receiveTimeout:
      case DioErrorType.sendTimeout:
        return ApLocalizations.current.timeoutMessage;
      case DioErrorType.response:
        if (response!.data is Map<String, dynamic>)
          return response!.data['description'] ?? message;
        else
          return message;
      case DioErrorType.cancel:
      default:
        return null;
    }
  }

  bool get isJsonResponse {
    return (type == DioErrorType.response &&
        response!.data is Map<String, dynamic>);
  }

  String? get falconMessage {
    // Define in falcon description
    return isJsonResponse ? response!.data['description'] ?? message : null;
  }
}
