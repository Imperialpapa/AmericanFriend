import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/core/widgets/banner_ad_widget.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/language/app_language.dart';

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
  late AppLanguage _nativeLanguage;
  late AppLanguage _targetLanguage;
  AiProviderType _onboardingProvider = AiProviderType.gemini;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 기기 시스템 언어로 모국어 기본값 설정
    final systemLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _nativeLanguage = AppLanguage.fromSystemLocale(systemLocale);
    // 대상 언어 기본값: 모국어가 영어면 한국어, 아니면 영어
    _targetLanguage = _nativeLanguage == AppLanguage.englishUS ||
            _nativeLanguage == AppLanguage.englishUK
        ? AppLanguage.korean
        : AppLanguage.englishUS;
    _apiKeyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: switch (_currentPage) {
                  0 => _buildWelcomePage(),
                  1 => _buildLanguagePage(),
                  2 => _buildApiKeyPage(),
                  3 => _buildLevelPage(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
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
          'I\'m your friendly language tutor.\nLet\'s practice together!',
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

  Widget _buildLanguagePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text('Language Setup',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Choose your native language and the language you want to learn.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 24),

        // 모국어 (기기 설정 기반 자동 감지)
        Text('Your native language',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Detected from your device settings',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppLanguage>(
          initialValue: _nativeLanguage,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.translate),
          ),
          items: AppLanguage.values
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang.label),
                  ))
              .toList(),
          onChanged: (lang) {
            if (lang != null) setState(() => _nativeLanguage = lang);
          },
        ),

        const SizedBox(height: 24),

        // 대상 언어 선택
        Text('Language to learn',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppLanguage>(
          initialValue: _targetLanguage,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
          ),
          items: AppLanguage.values
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang.label),
                  ))
              .toList(),
          onChanged: (lang) {
            if (lang != null) setState(() => _targetLanguage = lang);
          },
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
              onPressed: () async {
                if (_nativeLanguage == _targetLanguage) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your native language and the language to learn must be different.',
                      ),
                    ),
                  );
                  return;
                }
                final notifier = ref.read(settingsProvider.notifier);
                await notifier.setNativeLanguage(_nativeLanguage);
                await notifier.setTargetLanguage(_targetLanguage);
                setState(() => _currentPage = 2);
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiKeyPage() {
    final keyUrl = _onboardingProvider == AiProviderType.gemini
        ? 'https://aistudio.google.com/apikey'
        : 'https://console.groq.com/keys';
    final hasKey = _apiKeyController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Get Your Free API Key',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Both providers offer free tiers — no credit card needed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 20),

          // 프로바이더 선택
          SegmentedButton<AiProviderType>(
            segments: const [
              ButtonSegment(
                value: AiProviderType.gemini,
                label: Text('Gemini'),
                icon: Icon(Icons.auto_awesome),
              ),
              ButtonSegment(
                value: AiProviderType.groq,
                label: Text('Groq'),
                icon: Icon(Icons.bolt),
              ),
            ],
            selected: {_onboardingProvider},
            onSelectionChanged: (s) =>
                setState(() => _onboardingProvider = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _onboardingProvider == AiProviderType.gemini
                ? 'Google Gemini — 1,500 requests/day free'
                : 'Groq (Llama 3.3) — 14,400 requests/day, ultra fast',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // Step 1
          _buildStepCard(
            step: '1',
            title: 'Open the key page',
            subtitle: keyUrl,
            action: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in browser'),
              onPressed: () => _launchUrl(keyUrl),
            ),
          ),

          const SizedBox(height: 12),

          // Step 2
          _buildStepCard(
            step: '2',
            title: 'Create & copy the key',
            subtitle: 'Sign in → create new key → copy it',
          ),

          const SizedBox(height: 12),

          // Step 3: Paste
          _buildStepCard(
            step: '3',
            title: 'Paste it here',
            action: TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'Your API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _currentPage = 1),
                child: const Text('Back'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _currentPage = 3),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: hasKey ? _saveKeyAndContinue : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(step,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: action),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _apiKeyController.text = text;
    }
  }

  Future<void> _saveKeyAndContinue() async {
    final key = _apiKeyController.text.trim();
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setAiProvider(_onboardingProvider);
    if (_onboardingProvider == AiProviderType.gemini) {
      await notifier.setGeminiApiKey(key);
    } else {
      await notifier.setGroqApiKey(key);
    }
    if (mounted) setState(() => _currentPage = 3);
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
              onPressed: () => setState(() => _currentPage = 2),
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
