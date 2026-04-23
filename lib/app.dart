import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_theme.dart';
import 'package:eng_friend/features/chat/presentation/screens/chat_screen.dart';
import 'package:eng_friend/features/onboarding/presentation/screens/onboarding_screen.dart';

class EngFriendApp extends ConsumerStatefulWidget {
  const EngFriendApp({super.key});

  @override
  ConsumerState<EngFriendApp> createState() => _EngFriendAppState();
}

class _EngFriendAppState extends ConsumerState<EngFriendApp> {
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _onboardingDone = false; // will be set from provider in build
  }

  @override
  Widget build(BuildContext context) {
    final isOnboarded = ref.watch(onboardingCompleteProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: KFTheme.light(),
      darkTheme: KFTheme.dark(),
      home: (isOnboarded || _onboardingDone)
          ? const ChatScreen()
          : OnboardingScreen(
              onComplete: () => setState(() => _onboardingDone = true),
            ),
    );
  }
}
