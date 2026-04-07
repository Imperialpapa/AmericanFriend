import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/app.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/services/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await ref.read(settingsProvider.notifier).load();

    // 알림이 활성화되어 있으면 스케줄 복원
    final settings = ref.read(settingsProvider);
    if (settings.reminderEnabled) {
      await NotificationService.initialize();
      await NotificationService.scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      );
    }

    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
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
