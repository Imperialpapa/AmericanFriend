import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _claudeKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _groqKeyController = TextEditingController();
  final Map<String, bool> _showKey = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _claudeKeyController.text = settings.claudeApiKey;
      _openaiKeyController.text = settings.openaiApiKey;
      _geminiKeyController.text = settings.geminiApiKey;
      _groqKeyController.text = settings.groqApiKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== AI Model 선택 =====
          Text('AI Model', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ...AiProviderType.values.map((provider) {
            final info = _providerInfo(provider);
            final isSelected = settings.aiProvider == provider;
            return RadioListTile<AiProviderType>(
              value: provider,
              groupValue: settings.aiProvider,
              onChanged: (v) => notifier.setAiProvider(v!),
              title: Text(info.name),
              subtitle: Text(info.description),
              secondary: isSelected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
            );
          }),

          const Divider(height: 32),

          // ===== API Key (선택된 모델만 표시) =====
          Text('API Key', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _providerInfo(settings.aiProvider).keyHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),

          _buildKeyField(
            label: '${_providerInfo(settings.aiProvider).name} API Key',
            controller: _controllerFor(settings.aiProvider),
            onChanged: (v) => _saveKey(notifier, settings.aiProvider, v),
            tag: settings.aiProvider.name,
          ),

          const Divider(height: 32),

          // ===== Suggestion =====
          Text('Conversation Suggestions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          SegmentedButton<SuggestionMode>(
            segments: const [
              ButtonSegment(
                value: SuggestionMode.immediate,
                label: Text('Immediate'),
                icon: Icon(Icons.flash_on),
              ),
              ButtonSegment(
                value: SuggestionMode.delayed,
                label: Text('Delayed'),
                icon: Icon(Icons.timer),
              ),
            ],
            selected: {settings.suggestionMode},
            onSelectionChanged: (modes) {
              notifier.setSuggestionMode(modes.first);
            },
          ),

          if (settings.suggestionMode == SuggestionMode.delayed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Delay: '),
                Expanded(
                  child: Slider(
                    value: settings.suggestionDelaySec.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    label: '${settings.suggestionDelaySec}s',
                    onChanged: (v) => notifier.setSuggestionDelay(v.round()),
                  ),
                ),
                Text('${settings.suggestionDelaySec}s'),
              ],
            ),
          ],

          const Divider(height: 32),

          // ===== Korean Hint =====
          Text('한글 번역', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'AI 응답과 제안에 한글 번역을 함께 표시합니다',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          SwitchListTile(
            title: const Text('한글 번역 표시'),
            subtitle: const Text('영어 표현 옆에 (한국어 번역) 표시'),
            value: settings.showKoreanHint,
            onChanged: (v) => notifier.setShowKoreanHint(v),
          ),

          const Divider(height: 32),

          // ===== TTS =====
          Text('Voice', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          SegmentedButton<TtsVoiceGender>(
            segments: const [
              ButtonSegment(
                value: TtsVoiceGender.female,
                label: Text('여성'),
                icon: Icon(Icons.female),
              ),
              ButtonSegment(
                value: TtsVoiceGender.male,
                label: Text('남성'),
                icon: Icon(Icons.male),
              ),
            ],
            selected: {settings.ttsVoiceGender},
            onSelectionChanged: (genders) {
              notifier.setTtsVoiceGender(genders.first);
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text('Speech speed: '),
              Expanded(
                child: Slider(
                  value: settings.ttsSpeechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _speedLabel(settings.ttsSpeechRate),
                  onChanged: (v) => notifier.setTtsSpeechRate(v),
                ),
              ),
              Text(_speedLabel(settings.ttsSpeechRate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyField({
    required String label,
    required TextEditingController controller,
    required void Function(String) onChanged,
    required String tag,
  }) {
    final show = _showKey[tag] ?? false;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showKey[tag] = !show),
        ),
      ),
      obscureText: !show,
      onChanged: (v) => onChanged(v.trim()),
    );
  }

  TextEditingController _controllerFor(AiProviderType provider) {
    return switch (provider) {
      AiProviderType.claude => _claudeKeyController,
      AiProviderType.openai => _openaiKeyController,
      AiProviderType.gemini => _geminiKeyController,
      AiProviderType.groq => _groqKeyController,
    };
  }

  void _saveKey(SettingsNotifier notifier, AiProviderType provider, String v) {
    switch (provider) {
      case AiProviderType.claude:
        notifier.setClaudeApiKey(v);
      case AiProviderType.openai:
        notifier.setOpenaiApiKey(v);
      case AiProviderType.gemini:
        notifier.setGeminiApiKey(v);
      case AiProviderType.groq:
        notifier.setGroqApiKey(v);
    }
  }

  _ProviderInfo _providerInfo(AiProviderType provider) {
    return switch (provider) {
      AiProviderType.gemini => _ProviderInfo(
          name: 'Google Gemini',
          description: 'Free tier: 1,500 req/day',
          keyHint: 'https://aistudio.google.com/apikey 에서 발급',
        ),
      AiProviderType.groq => _ProviderInfo(
          name: 'Groq (Llama 3.3)',
          description: 'Free tier: 14,400 req/day, ultra fast',
          keyHint: 'https://console.groq.com/keys 에서 발급',
        ),
      AiProviderType.claude => _ProviderInfo(
          name: 'Claude (Sonnet)',
          description: 'Paid — highest quality',
          keyHint: 'https://console.anthropic.com 에서 발급',
        ),
      AiProviderType.openai => _ProviderInfo(
          name: 'OpenAI (GPT-4o)',
          description: 'Paid',
          keyHint: 'https://platform.openai.com/api-keys 에서 발급',
        ),
    };
  }

  String _speedLabel(double rate) {
    if (rate <= 0.3) return 'Slow';
    if (rate <= 0.6) return 'Normal';
    return 'Fast';
  }

  @override
  void dispose() {
    _claudeKeyController.dispose();
    _openaiKeyController.dispose();
    _geminiKeyController.dispose();
    _groqKeyController.dispose();
    super.dispose();
  }
}

class _ProviderInfo {
  final String name;
  final String description;
  final String keyHint;

  _ProviderInfo({
    required this.name,
    required this.description,
    required this.keyHint,
  });
}
