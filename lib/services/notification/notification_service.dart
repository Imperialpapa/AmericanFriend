import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // MainActivity.kt의 채널. iOS에는 없어서 MissingPluginException → UTC로 떨어진다.
  static const _timezoneChannel =
      MethodChannel('com.engfriend.eng_friend/timezone');

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  /// 알림 권한 요청. Android 13+는 시스템 다이얼로그를 띄우고,
  /// 12 이하는 앱 알림이 켜져 있는지만 돌려준다. iOS는 initialize에서 이미 요청한다.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      return await android.requestNotificationsPermission() ?? false;
    } on PlatformException catch (e) {
      debugPrint('[Notification] permission request failed: $e');
      return false;
    }
  }

  /// 매일 지정 시간에 학습 리마인더 예약
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();
    // 매번 다시 읽는다 — 기기 타임존은 여행·설정 변경으로 앱 실행 중에도 바뀐다.
    await _setLocalTimeZone();
    await cancelAll();

    await _plugin.zonedSchedule(
      0,
      'Time to practice!',
      "You haven't talked to Alex today. Keep your streak going!",
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily language practice reminder',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 리마인더 취소
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// tz.local 기본값은 UTC라, 설정하지 않으면 20:00 예약이 KST 05:00에 울린다.
  static Future<void> _setLocalTimeZone() async {
    try {
      final id = await _timezoneChannel.invokeMethod<String>('getLocalTimezone');
      if (id == null || id.isEmpty) throw StateError('empty timezone id');
      tz.setLocalLocation(tz.getLocation(id));
    } catch (e) {
      // 채널이 없거나(iOS) tz DB에 없는 ID(예: 'GMT+09:00')면 UTC로 둔다 — 예약 시각이 어긋나므로 남긴다.
      debugPrint('[Notification] local timezone unavailable, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
