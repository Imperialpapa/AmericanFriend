import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';

enum TtsVoiceGender { female, male }

class UserSettings {
  final String claudeApiKey;
  final String openaiApiKey;
  final String geminiApiKey;
  final String groqApiKey;
  final AiProviderType aiProvider;
  final SuggestionMode suggestionMode;
  final int suggestionDelaySec;
  final double ttsSpeechRate;
  final String ttsLanguage;
  final bool showKoreanHint;
  final TtsVoiceGender ttsVoiceGender;

  const UserSettings({
    this.claudeApiKey = '',
    this.openaiApiKey = '',
    this.geminiApiKey = '',
    this.groqApiKey = '',
    this.aiProvider = AiProviderType.gemini,
    this.suggestionMode = SuggestionMode.immediate,
    this.suggestionDelaySec = 5,
    this.ttsSpeechRate = 0.5,
    this.ttsLanguage = 'en-US',
    this.showKoreanHint = true,
    this.ttsVoiceGender = TtsVoiceGender.female,
  });

  /// 현재 선택된 프로바이더의 API 키
  String get activeApiKey => switch (aiProvider) {
        AiProviderType.claude => claudeApiKey,
        AiProviderType.openai => openaiApiKey,
        AiProviderType.gemini => geminiApiKey,
        AiProviderType.groq => groqApiKey,
      };

  UserSettings copyWith({
    String? claudeApiKey,
    String? openaiApiKey,
    String? geminiApiKey,
    String? groqApiKey,
    AiProviderType? aiProvider,
    SuggestionMode? suggestionMode,
    int? suggestionDelaySec,
    double? ttsSpeechRate,
    String? ttsLanguage,
    bool? showKoreanHint,
    TtsVoiceGender? ttsVoiceGender,
  }) {
    return UserSettings(
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      aiProvider: aiProvider ?? this.aiProvider,
      suggestionMode: suggestionMode ?? this.suggestionMode,
      suggestionDelaySec: suggestionDelaySec ?? this.suggestionDelaySec,
      ttsSpeechRate: ttsSpeechRate ?? this.ttsSpeechRate,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      showKoreanHint: showKoreanHint ?? this.showKoreanHint,
      ttsVoiceGender: ttsVoiceGender ?? this.ttsVoiceGender,
    );
  }
}
