import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/language/app_language.dart';

enum TtsVoiceGender { female, male }

class UserSettings {
  final String claudeApiKey;
  final String openaiApiKey;
  final String geminiApiKey;
  final String groqApiKey;
  final AiProviderType aiProvider;
  final AppLanguage nativeLanguage;
  final AppLanguage targetLanguage;

  /// 모국어: 화면 표시 (default: ON)
  final bool showNativeHint;

  /// 모국어: 음성 읽기 (default: OFF)
  final bool nativeTtsEnabled;

  /// 대상 언어: 화면 표시 (default: ON)
  final bool showTargetText;

  /// 대상 언어: 음성 읽기 (default: ON)
  final bool targetTtsEnabled;

  final SuggestionMode suggestionMode;
  final int suggestionDelaySec;
  final double ttsSpeechRate;
  final TtsVoiceGender ttsVoiceGender;

  const UserSettings({
    this.claudeApiKey = '',
    this.openaiApiKey = '',
    this.geminiApiKey = '',
    this.groqApiKey = '',
    this.aiProvider = AiProviderType.gemini,
    this.nativeLanguage = AppLanguage.korean,
    this.targetLanguage = AppLanguage.englishUS,
    this.showNativeHint = true,
    this.nativeTtsEnabled = false,
    this.showTargetText = true,
    this.targetTtsEnabled = true,
    this.suggestionMode = SuggestionMode.immediate,
    this.suggestionDelaySec = 5,
    this.ttsSpeechRate = 0.5,
    this.ttsVoiceGender = TtsVoiceGender.female,
  });

  /// 현재 선택된 프로바이더의 API 키
  String get activeApiKey => switch (aiProvider) {
        AiProviderType.claude => claudeApiKey,
        AiProviderType.openai => openaiApiKey,
        AiProviderType.gemini => geminiApiKey,
        AiProviderType.groq => groqApiKey,
      };

  /// TTS용 언어 코드 (대상 언어 기반)
  String get ttsLanguage => targetLanguage.ttsCode;

  /// STT용 언어 코드 (대상 언어 기반)
  String get sttLanguage => targetLanguage.sttCode;

  UserSettings copyWith({
    String? claudeApiKey,
    String? openaiApiKey,
    String? geminiApiKey,
    String? groqApiKey,
    AiProviderType? aiProvider,
    AppLanguage? nativeLanguage,
    AppLanguage? targetLanguage,
    bool? showNativeHint,
    bool? nativeTtsEnabled,
    bool? showTargetText,
    bool? targetTtsEnabled,
    SuggestionMode? suggestionMode,
    int? suggestionDelaySec,
    double? ttsSpeechRate,
    TtsVoiceGender? ttsVoiceGender,
  }) {
    return UserSettings(
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      aiProvider: aiProvider ?? this.aiProvider,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      showNativeHint: showNativeHint ?? this.showNativeHint,
      nativeTtsEnabled: nativeTtsEnabled ?? this.nativeTtsEnabled,
      showTargetText: showTargetText ?? this.showTargetText,
      targetTtsEnabled: targetTtsEnabled ?? this.targetTtsEnabled,
      suggestionMode: suggestionMode ?? this.suggestionMode,
      suggestionDelaySec: suggestionDelaySec ?? this.suggestionDelaySec,
      ttsSpeechRate: ttsSpeechRate ?? this.ttsSpeechRate,
      ttsVoiceGender: ttsVoiceGender ?? this.ttsVoiceGender,
    );
  }
}
