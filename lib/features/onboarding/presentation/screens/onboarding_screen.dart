import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/settings/presentation/screens/settings_screen.dart';
import 'package:eng_friend/di/service_providers.dart';

const _onboardingCompleteKey = 'onboarding_complete';

/// 온보딩 완료 여부
final onboardingCompleteProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;
  int _selectedLevel = LevelConstants.defaultLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_currentPage) {
            0 => _buildWelcomePage(),
            1 => _buildApiKeyPage(),
            2 => _buildLevelPage(),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    final targetLang = ref.watch(settingsProvider.select((s) => s.targetLanguage));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 50,
          child: Text('A',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Text(
          'Hey! I\'m ${AppConstants.aiCharacterName}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'I\'m your friendly language tutor.\nLet\'s practice ${targetLang.displayName} together!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
                height: 1.6,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'re going to have fun learning\nthrough real conversations!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _currentPage = 1),
            child: const Text('Let\'s Go!'),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('API Key Setup',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'You need an AI API key to start chatting.\nPlease set it up in Settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Set up API Key'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _currentPage = 0),
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => setState(() => _currentPage = 2),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Your Level',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Choose your approximate level.\nIt will adjust automatically as we chat!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 24),

        // 레벨 슬라이더
        Center(
          child: Text(
            'Level $_selectedLevel',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Center(
          child: Text(
            LevelConstants.levelNames[_selectedLevel],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Slider(
          value: _selectedLevel.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: '$_selectedLevel',
          onChanged: (v) => setState(() => _selectedLevel = v.round()),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Beginner', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Native', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),

        const Spacer(),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _currentPage = 1),
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _complete,
              child: const Text('Start Chatting!'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _complete() async {
    // 레벨 저장
    await ref.read(levelProvider.notifier).setLevel(_selectedLevel);

    // 온보딩 완료 표시
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingCompleteKey, true);

    widget.onComplete();
  }
}
