import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _reminderChannelId = 'daily_reminder';
  static const _permissionAskedKey = 'notification_permission_asked';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, true);
    try {
      return await android.requestNotificationsPermission() ?? false;
    } on PlatformException catch (e) {
      debugPrint('[Notification] permission request failed: $e');
      return false;
    }
  }

  /// 권한을 한 번이라도 요청했는지. 시작 시 자동 요청은 이게 false일 때 한 번뿐이다(main.dart) —
  /// OS 설정에서 일부러 끈 사용자에게 매번 다이얼로그를 띄우지 않기 위해서.
  static Future<bool> wasPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionAskedKey) ?? false;
  }

  /// 알림이 실제로 표시될 수 있는지. Android 13+ 권한 미허용과 OS 설정 차단 모두 false.
  /// 확인에 실패하면 true — 모르는 상태로 사용자의 리마인더를 끄지 않는다.
  static Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return true;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      return await android.areNotificationsEnabled() ?? true;
    } on PlatformException catch (e) {
      debugPrint('[Notification] notification state check failed: $e');
      return true;
    }
  }

  /// 매일 지정 시간에 학습 리마인더 예약.
  /// 문구·채널 이름은 예약 시점의 [l10n]으로 고정되므로 UI 언어가 바뀌면 다시 예약해야 한다(app.dart).
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required AppLocalizations l10n,
  }) async {
    await initialize();
    // 매번 다시 읽는다 — 기기 타임존은 여행·설정 변경으로 앱 실행 중에도 바뀐다.
    await _setLocalTimeZone();
    await cancelAll();

    // 채널을 예약 때마다 직접 만든다. 없으면 생성하고, 있으면 이름·설명만 현재 언어로 바뀐다.
    // 표시 시점 channelAction.update는 채널이 없으면 아예 만들지 않아 알림이 버려진다.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          _reminderChannelId,
          l10n.reminderChannelName,
          description: l10n.reminderChannelDescription,
          importance: Importance.high,
        ));

    await _plugin.zonedSchedule(
      0,
      l10n.reminderNotificationTitle,
      l10n.reminderNotificationBody(AppConstants.aiCharacterName),
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          l10n.reminderChannelName,
          channelDescription: l10n.reminderChannelDescription,
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
