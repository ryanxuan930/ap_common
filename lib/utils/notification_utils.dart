import 'dart:io';

import 'package:ap_common/models/course_notify_data.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

export 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationUtils {
  static const ANDROID_RESOURCE_NAME = '@drawable/ic_stat_name';

  // Notification ID
  static const int BUS = 100;
  static const int COURSE = 101;
  static const int FCM = 200;

  static get isSupport =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static InitializationSettings get settings {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(ANDROID_RESOURCE_NAME);
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    return InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );
  }

  //For taiwan week order
  static Day getDay(int weekIndex) {
    if (weekIndex == 6)
      return Day.sunday;
    else
      return Day(weekIndex + 2);
  }

  static Time parseTime(String text, {beforeMinutes = 0}) {
    var formatter = DateFormat('HH:mm', 'zh');
    DateTime dateTime = formatter.parse(text).add(
          Duration(minutes: -beforeMinutes),
        );
    return Time(dateTime.hour, dateTime.minute);
  }

  static DateTime getNextWeekdayDateTime(Day day, Time time) {
    var now = DateTime.now();
    var dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );
    int diffDay = 7 - (now.weekday - day.value + 1);
    if (now.weekday + 1 == day.value && now.isBefore(dateTime)) diffDay = 0;
    return dateTime.add(
      Duration(days: diffDay),
    );
  }

  static Future<void> show({
    required int id,
    required String androidChannelId,
    required String androidChannelDescription,
    required String title,
    required String content,
    bool enableVibration = true,
    String androidResourceIcon = ANDROID_RESOURCE_NAME,
    InitializationSettings? settings,
    VoidCallback? onSelectNotification,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelDescription,
        androidChannelDescription,
        icon: androidResourceIcon,
        importance: Importance.max,
        enableVibration: enableVibration,
        styleInformation: BigTextStyleInformation(content),
      ),
      iOS: IOSNotificationDetails(presentAlert: true),
      macOS: MacOSNotificationDetails(presentAlert: true),
    );
    flutterLocalNotificationsPlugin.initialize(
      settings ?? NotificationUtils.settings,
      onSelectNotification: (text) async => onSelectNotification?.call(),
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      content,
      platformChannelSpecifics,
      payload: content,
    );
  }

  static Future<void> scheduleCourseNotify({
    required BuildContext context,
    required CourseNotify courseNotify,
    required Day day,
    bool enableVibration = true,
    int beforeMinutes = 10,
    String? androidResourceIcon = ANDROID_RESOURCE_NAME,
    InitializationSettings? settings,
    VoidCallback? onSelectNotification,
  }) async {
    final ap = ApLocalizations.of(context);
    String content = sprintf(ap.courseNotifyContent, [
      courseNotify.title,
      courseNotify.location == null || courseNotify.location!.isEmpty
          ? ap.courseNotifyUnknown
          : courseNotify.location
    ]);
    final time =
        parseTime(courseNotify.startTime, beforeMinutes: beforeMinutes);
    await scheduleWeeklyNotify(
      id: courseNotify.id,
      title: ap.courseNotify,
      content: content,
      day: getDay(courseNotify.weekdayIndex),
      time: time,
      androidChannelId: '$COURSE',
      androidChannelDescription: ap.courseNotify,
      settings: settings,
      onSelectNotification: onSelectNotification,
    );
  }

  static Future<void> scheduleWeeklyNotify({
    required int id,
    required String androidChannelId,
    required String androidChannelDescription,
    required Day day,
    required Time time,
    required String title,
    required String content,
    String androidResourceIcon = ANDROID_RESOURCE_NAME,
    InitializationSettings? settings,
    VoidCallback? onSelectNotification,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelDescription,
        androidChannelDescription,
        icon: androidResourceIcon,
        importance: Importance.max,
        enableVibration: false,
        styleInformation: BigTextStyleInformation(content),
      ),
      iOS: IOSNotificationDetails(presentAlert: true),
      macOS: MacOSNotificationDetails(presentAlert: true),
    );
    tz.initializeTimeZones();
    var scheduleDateTime = tz.TZDateTime.from(
      getNextWeekdayDateTime(day, time),
      tz.local,
    );
    flutterLocalNotificationsPlugin.initialize(
      settings ?? NotificationUtils.settings,
      onSelectNotification: (text) async => onSelectNotification?.call(),
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      scheduleDateTime,
      platformChannelSpecifics,
      payload: content,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> schedule({
    required int id,
    required String androidChannelId,
    required String androidChannelDescription,
    required DateTime dateTime,
    required String title,
    required String content,
    String androidResourceIcon = ANDROID_RESOURCE_NAME,
    InitializationSettings? settings,
    VoidCallback? onSelectNotification,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelDescription,
        androidChannelDescription,
        icon: androidResourceIcon,
        importance: Importance.max,
        enableVibration: false,
        styleInformation: BigTextStyleInformation(content),
      ),
      iOS: IOSNotificationDetails(presentAlert: true),
      macOS: MacOSNotificationDetails(presentAlert: true),
    );
    tz.initializeTimeZones();
    var scheduleDateTime = tz.TZDateTime.from(
      dateTime,
      tz.local,
    );
    flutterLocalNotificationsPlugin.initialize(
      settings ?? NotificationUtils.settings,
      onSelectNotification: (text) async => onSelectNotification?.call(),
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      scheduleDateTime,
      platformChannelSpecifics,
      payload: content,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<bool?> requestPermissions({
    bool sound = true,
    bool alert = true,
    bool badge = true,
  }) async {
    if (!kIsWeb && Platform.isIOS)
      return await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: sound,
            badge: badge,
            sound: sound,
          );
    else if (!kIsWeb && Platform.isMacOS)
      return await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: sound,
            badge: badge,
            sound: sound,
          );
    else
      return null;
  }

  static Future<void> cancelCourseNotify({
    required int id,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotificationList() async {
    return await FlutterLocalNotificationsPlugin()
        .pendingNotificationRequests();
  }

  static Future<void> cancelAll() async {
    await FlutterLocalNotificationsPlugin().cancelAll();
  }
}
