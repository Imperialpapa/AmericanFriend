import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/app.dart';
import 'package:eng_friend/core/constants/ad_constants.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/notification/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  // release logcat에 사용자 발화 전사·오류 원문이 찍히지 않게 한다(tobe.md S-07).
  // debug/profile은 그대로 둔다. 전사 길이만 남기는 로그 래퍼는 후속 작업.
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};
  WidgetsFlutterBinding.ensureInitialized();
  // 개발 기기를 테스트 기기로 등록해 release 빌드에서도 실광고 오클릭을 막는다(tobe P-04).
  final testDeviceIds = AdConstants.testDeviceIds;
  if (testDeviceIds.isNotEmpty) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: testDeviceIds),
    );
  }
  await MobileAds.instance.initialize();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _AppLoader(),
    ),
  );
}

/// 설정을 로드한 후 앱 시작
class _AppLoader extends ConsumerStatefulWidget {
  const _AppLoader();

  @override
  ConsumerState<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends ConsumerState<_AppLoader> {
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      debugPrint('[AppLoader] load start');
      await ref
          .read(settingsProvider.notifier)
          .load()
          .timeout(const Duration(seconds: 5));
      debugPrint('[AppLoader] settings loaded');

      if (mounted) setState(() => _loaded = true);

      // 리마인더 재예약과 서버 공지 동기화는 앱 시작을 막지 않도록 await하지 않는다.
      unawaited(_restoreReminder());
      unawaited(_syncRemoteStatus());
      unawaited(_flushPendingReports());
    } catch (e, st) {
      debugPrint('[AppLoader] FAILED: $e\n$st');
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// 알림 예외가 설정 로드와 같은 try에 있으면 시작 오류 화면으로 번진다(tobe.md L-01).
  /// 리마인더는 부가 기능이라 실패해도 로그만 남긴다.
  Future<void> _restoreReminder() async {
    if (!ref.read(settingsProvider).reminderEnabled) return;
    try {
      // v2.5.0은 알림 권한을 묻지 않아, ON으로 저장된 사용자도 Android 13+에서는 알림이 막혀 있다.
      // 아직 물은 적이 없으면 한 번 묻고, 그래도 꺼져 있으면 토글을 실제 상태(OFF)로 맞춘다.
      // 다시 켜면 설정 화면의 권한 요청·스낵바 흐름을 탄다.
      if (!await NotificationService.areNotificationsEnabled()) {
        final granted = !await NotificationService.wasPermissionRequested() &&
            await NotificationService.requestPermission();
        if (!granted) {
          await NotificationService.cancelAll();
          if (mounted) {
            await ref.read(settingsProvider.notifier).setReminderEnabled(false);
          }
          debugPrint('[AppLoader] notifications blocked, reminder turned off');
          return;
        }
      }
      if (!mounted) return;
      final settings = ref.read(settingsProvider);
      await NotificationService.scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
        // MaterialApp 위라 context로 찾을 수 없다 — 앱과 같은 규칙으로 로케일을 정한다.
        l10n: lookupAppLocalizations(resolveUiLocale(settings.nativeLanguage)),
      ).timeout(const Duration(seconds: 5));
      debugPrint('[AppLoader] reminder scheduled');
    } catch (e) {
      debugPrint('[AppLoader] reminder schedule skipped: $e');
    }
  }

  /// 제공자 모델 셧다운 같은 사고를 앱 릴리스 없이 복구하기 위한 경로 (BUG_HISTORY #9).
  /// 실패해도 조용히 넘어간다 — 상태 확인 실패로 앱을 못 쓰게 되면 본말전도다.
  Future<void> _syncRemoteStatus() async {
    try {
      final status = await ref.read(appStatusProvider.future);
      if (status == null || !mounted) return;
      await ref
          .read(settingsProvider.notifier)
          .applyModelMigrations(status.modelMigrations);
    } catch (e) {
      debugPrint('[AppLoader] status sync skipped: $e');
    }
  }

  /// 지난 실행에서 못 보낸 AI 응답 신고를 다시 보낸다(tobe P-01).
  Future<void> _flushPendingReports() async {
    try {
      await ref.read(reportServiceProvider).flushPending(
            deviceId: ref.read(settingsProvider).freeTierDeviceId,
          );
    } catch (e) {
      debugPrint('[AppLoader] report flush skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(builder: (context) {
              final l = AppLocalizations.of(context);
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(l.startupError,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _loaded = true; // skip load and show app anyway
                        });
                      },
                      child: Text(l.startupContinueAnyway),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    }
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return const EngFriendApp();
  }
}
