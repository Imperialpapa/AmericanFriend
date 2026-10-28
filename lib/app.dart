import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_theme.dart';
import 'package:eng_friend/features/chat/presentation/screens/chat_screen.dart';
import 'package:eng_friend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/services/notification/notification_service.dart';

class EngFriendApp extends ConsumerStatefulWidget {
  const EngFriendApp({super.key});

  @override
  ConsumerState<EngFriendApp> createState() => _EngFriendAppState();
}

class _EngFriendAppState extends ConsumerState<EngFriendApp> {
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    final isOnboarded = ref.watch(onboardingCompleteProvider);
    final nativeLanguage =
        ref.watch(settingsProvider.select((s) => s.nativeLanguage));

    // 예약된 리마인더 문구는 예약 시점 언어로 고정된다 — UI 언어가 바뀌면 새 언어로 다시 예약.
    // 온보딩·설정 등 언어를 바꾸는 경로가 여럿이라 콜백이 아니라 상태에서 파생한다(BUG #10).
    ref.listen<Locale>(
      settingsProvider.select((s) => resolveUiLocale(s.nativeLanguage)),
      (prev, next) {
        final settings = ref.read(settingsProvider);
        if (!settings.reminderEnabled) return;
        unawaited(NotificationService.scheduleDailyReminder(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
          l10n: lookupAppLocalizations(next),
        ).catchError((Object e) {
          debugPrint('[App] reminder reschedule for $next failed: $e');
        }));
      },
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: KFTheme.light(),
      darkTheme: KFTheme.dark(),
      locale: resolveUiLocale(nativeLanguage),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: (isOnboarded || _onboardingDone)
          ? const ChatScreen()
          : OnboardingScreen(
              onComplete: () => setState(() => _onboardingDone = true),
            ),
    );
  }
}

/// 사용자의 native language를 UI 로케일로 변환.
/// 지원하지 않는 언어는 명시적으로 영어로 fallback (사용자 의도 존중).
/// 리마인더처럼 BuildContext 밖에서 문구를 만들 때도 같은 규칙을 쓰도록 공개한다.
Locale resolveUiLocale(AppLanguage lang) {
  const supported = {'en', 'ko'}; // 추후 언어 arb 추가 시 여기 확장
  final primary = lang.code.split('-').first;
  if (supported.contains(primary)) {
    return Locale(primary);
  }
  return const Locale('en');
}
