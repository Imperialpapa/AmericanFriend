import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/services/notification/notification_service.dart';
import 'package:eng_friend/features/report/presentation/screens/weekly_report_screen.dart';
import 'package:eng_friend/features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // ===== Weekly Report =====
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.orange),
              title: const Text('Weekly Report'),
              subtitle: const Text('View your learning progress'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.book, color: Colors.blue),
              title: const Text('My Vocabulary'),
              subtitle: const Text('Review saved words & expressions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VocabularyScreen()),
                );
              },
            ),
          ),

          const Divider(height: 32),

          // ===== Language =====
          Text('Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          _buildLanguageDropdown(
            label: 'Native Language',
            value: settings.nativeLanguage,
            disabledValue: settings.targetLanguage,
            onChanged: (lang) => notifier.setNativeLanguage(lang),
          ),
          const SizedBox(height: 12),

          _buildLanguageDropdown(
            label: 'Target Language',
            value: settings.targetLanguage,
            disabledValue: settings.nativeLanguage,
            onChanged: (lang) => notifier.setTargetLanguage(lang),
          ),

          // 언어-모델 호환성 경고
          _buildLanguageWarning(settings),

          const Divider(height: 32),

          // ===== Level =====
          _buildLevelSection(context, ref),

          const Divider(height: 32),

          // ===== AI Model 선택 =====
          Text('AI Model', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ...AiProviderType.values.map((provider) {
            final info = _providerInfo(provider);
            return RadioListTile<AiProviderType>(
              value: provider,
              groupValue: settings.aiProvider,
              onChanged: (v) => notifier.setAiProvider(v!),
              title: Text(info.name),
              subtitle: Text(info.description),
              secondary: IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Get API Key',
                onPressed: () => _launchApiKeyPage(info.keyUrl),
              ),
            );
          }),

          const SizedBox(height: 12),

          // ===== 선택된 프로바이더의 모델 선택 =====
          Text('Model Version',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Choose a specific model for ${_providerInfo(settings.aiProvider).name}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...settings.aiProvider.availableModels.map((model) {
            final isSelected = settings.activeModelId == model.id;
            return RadioListTile<String>(
              value: model.id,
              groupValue: settings.activeModelId,
              onChanged: (v) {
                if (v != null) notifier.setModelId(settings.aiProvider, v);
              },
              title: Text(model.displayName),
              subtitle: Text(model.description),
              dense: true,
              secondary: isSelected
                  ? Icon(Icons.check_circle_outline,
                      size: 20,
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

          // ===== Target Language Options =====
          Text('${settings.targetLanguage.displayName} (Target)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Show text'),
            subtitle: const Text('Display AI response text on screen'),
            value: settings.showTargetText,
            onChanged: (v) => notifier.setShowTargetText(v),
          ),
          SwitchListTile(
            title: const Text('Read aloud'),
            subtitle: const Text('TTS playback of AI responses'),
            value: settings.targetTtsEnabled,
            onChanged: (v) => notifier.setTargetTtsEnabled(v),
          ),

          const Divider(height: 32),

          // ===== Native Language Options =====
          Text('${settings.nativeLanguage.displayName} (Native)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Show translation'),
            subtitle: Text('Display (${settings.nativeLanguage.displayName}) hints in responses'),
            value: settings.showNativeHint,
            onChanged: (v) => notifier.setShowNativeHint(v),
          ),
          SwitchListTile(
            title: const Text('Read translation aloud'),
            subtitle: Text('Include ${settings.nativeLanguage.displayName} in TTS playback'),
            value: settings.nativeTtsEnabled,
            onChanged: (v) => notifier.setNativeTtsEnabled(v),
          ),

          const Divider(height: 32),

          // ===== TTS =====
          Text('Voice', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          SegmentedButton<TtsVoiceGender>(
            segments: const [
              ButtonSegment(
                value: TtsVoiceGender.female,
                label: Text('Female'),
                icon: Icon(Icons.female),
              ),
              ButtonSegment(
                value: TtsVoiceGender.male,
                label: Text('Male'),
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

          const Divider(height: 32),

          // ===== Avatar =====
          Text('Avatar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Show avatar'),
            subtitle: const Text('Display animated avatar during conversation'),
            value: settings.avatarEnabled,
            onChanged: (v) => notifier.setAvatarEnabled(v),
          ),

          const Divider(height: 32),

          // ===== Daily Reminder =====
          Text('Daily Reminder',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Enable reminder'),
            subtitle: const Text('Get notified to practice daily'),
            value: settings.reminderEnabled,
            onChanged: (v) async {
              await notifier.setReminderEnabled(v);
              if (v) {
                await NotificationService.initialize();
                await NotificationService.scheduleDailyReminder(
                  hour: settings.reminderHour,
                  minute: settings.reminderMinute,
                );
              } else {
                await NotificationService.cancelAll();
              }
            },
          ),
          if (settings.reminderEnabled)
            ListTile(
              title: const Text('Reminder time'),
              subtitle: Text(
                '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                  ),
                );
                if (picked != null) {
                  await notifier.setReminderTime(picked.hour, picked.minute);
                  await NotificationService.scheduleDailyReminder(
                    hour: picked.hour,
                    minute: picked.minute,
                  );
                }
              },
            ),

          const Divider(height: 32),

          // ===== Feedback =====
          Text('Feedback', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline, color: Colors.green),
              title: const Text('Send Feedback'),
              subtitle: const Text('Suggest improvements or report issues'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchFeedbackEmail(settings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelProvider);
    final level = levelState.currentLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Adjusts vocabulary difficulty and response length',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$level',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LevelConstants.levelNames[level],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    _levelDescription(level),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        Slider(
          value: level.toDouble(),
          min: LevelConstants.minLevel.toDouble(),
          max: LevelConstants.maxLevel.toDouble(),
          divisions: LevelConstants.maxLevel - LevelConstants.minLevel,
          label: '$level',
          onChanged: (v) {
            ref.read(levelProvider.notifier).setLevel(v.round());
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Beginner', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text('Native', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  String _levelDescription(int level) {
    return switch (level) {
      1 => '1 sentence, basic words',
      2 => '1-2 sentences, everyday words',
      3 => '2 sentences, simple phrases',
      4 => '2-3 sentences, common idioms',
      5 => '2-3 sentences, natural conversation',
      6 => '3-4 sentences, idioms & phrasal verbs',
      7 => '3-4 sentences, rich vocabulary',
      8 => '4-5 sentences, advanced expressions',
      9 => '4-5 sentences, near-native nuance',
      10 => '5 sentences, full native level',
      _ => '',
    };
  }

  Widget _buildLanguageWarning(UserSettings settings) {
    final warnings = <String>[];

    final nativeSupport = settings.aiProvider.supportFor(settings.nativeLanguage);
    final targetSupport = settings.aiProvider.supportFor(settings.targetLanguage);

    if (nativeSupport.warningMessage != null) {
      warnings.add(nativeSupport.warningMessage!);
    }
    if (targetSupport.warningMessage != null) {
      warnings.add(targetSupport.warningMessage!);
    }

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade900.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade700.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade300, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                warnings.join('\n'),
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String label,
    required AppLanguage value,
    required AppLanguage disabledValue,
    required void Function(AppLanguage) onChanged,
  }) {
    return DropdownButtonFormField<AppLanguage>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: AppLanguage.values.map((lang) {
        final isDisabled = lang == disabledValue;
        return DropdownMenuItem<AppLanguage>(
          value: lang,
          enabled: !isDisabled,
          child: Text(
            lang.label,
            style: isDisabled
                ? TextStyle(color: Colors.grey.shade400)
                : null,
          ),
        );
      }).toList(),
      onChanged: (lang) {
        if (lang != null) onChanged(lang);
      },
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
          keyHint: 'Get your key at aistudio.google.com/apikey',
          keyUrl: 'https://aistudio.google.com/apikey',
        ),
      AiProviderType.groq => _ProviderInfo(
          name: 'Groq (Llama 3.3)',
          description: 'Free tier: 14,400 req/day, ultra fast',
          keyHint: 'Get your key at console.groq.com/keys',
          keyUrl: 'https://console.groq.com/keys',
        ),
      AiProviderType.claude => _ProviderInfo(
          name: 'Claude (Sonnet)',
          description: 'Paid — highest quality',
          keyHint: 'Get your key at console.anthropic.com',
          keyUrl: 'https://console.anthropic.com/settings/keys',
        ),
      AiProviderType.openai => _ProviderInfo(
          name: 'OpenAI (GPT-4o)',
          description: 'Paid',
          keyHint: 'Get your key at platform.openai.com/api-keys',
          keyUrl: 'https://platform.openai.com/api-keys',
        ),
    };
  }

  Future<void> _launchApiKeyPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchFeedbackEmail(UserSettings settings) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'raphael70kim@gmail.com',
      queryParameters: {
        'subject': '[EngFriend] Feedback',
        'body':
            '\n\n---\nApp: EngFriend v0.1.0\nAI: ${settings.aiProvider.name} (${settings.activeModelId})\nLevel: ${ref.read(levelProvider).currentLevel}\nNative: ${settings.nativeLanguage.displayName}\nTarget: ${settings.targetLanguage.displayName}',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
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
  final String keyUrl;

  _ProviderInfo({
    required this.name,
    required this.description,
    required this.keyHint,
    required this.keyUrl,
  });
}
