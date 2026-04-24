import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_theme.dart';
import 'package:eng_friend/features/chat/presentation/screens/chat_screen.dart';
import 'package:eng_friend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/language/app_language.dart';

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

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: KFTheme.light(),
      darkTheme: KFTheme.dark(),
      locale: _resolveLocale(nativeLanguage),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: (isOnboarded || _onboardingDone)
          ? const ChatScreen()
          : OnboardingScreen(
              onComplete: () => setState(() => _onboardingDone = true),
            ),
    );
  }

  /// 사용자의 native language를 UI 로케일로 변환.
  /// 지원하지 않는 언어는 명시적으로 영어로 fallback (사용자 의도 존중).
  Locale _resolveLocale(AppLanguage lang) {
    const supported = {'en', 'ko'}; // 추후 언어 arb 추가 시 여기 확장
    final primary = lang.code.split('-').first;
    if (supported.contains(primary)) {
      return Locale(primary);
    }
    return const Locale('en');
  }
}
