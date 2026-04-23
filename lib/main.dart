import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/app.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/services/notification/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

      final settings = ref.read(settingsProvider);
      if (settings.reminderEnabled) {
        debugPrint('[AppLoader] initializing notifications');
        await NotificationService.initialize()
            .timeout(const Duration(seconds: 5));
        await NotificationService.scheduleDailyReminder(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        ).timeout(const Duration(seconds: 5));
        debugPrint('[AppLoader] notifications ready');
      }

      if (mounted) setState(() => _loaded = true);
    } catch (e, st) {
      debugPrint('[AppLoader] FAILED: $e\n$st');
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Startup error',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    child: const Text('Continue anyway'),
                  ),
                ],
              ),
            ),
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
