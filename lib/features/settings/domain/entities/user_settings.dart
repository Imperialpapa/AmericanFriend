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

  /// 프로바이더별 선택된 모델 ID
  final String? claudeModelId;
  final String? openaiModelId;
  final String? geminiModelId;
  final String? groqModelId;

  /// 아바타 표시
  final bool avatarEnabled;

  /// 알림 설정
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

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
    this.claudeModelId,
    this.openaiModelId,
    this.geminiModelId,
    this.groqModelId,
    this.avatarEnabled = false,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  /// 현재 선택된 프로바이더의 API 키
  String get activeApiKey => switch (aiProvider) {
        AiProviderType.claude => claudeApiKey,
        AiProviderType.openai => openaiApiKey,
        AiProviderType.gemini => geminiApiKey,
        AiProviderType.groq => groqApiKey,
      };

  /// 현재 선택된 프로바이더의 모델 ID (유효성 검증 포함)
  String get activeModelId => aiProvider.resolveModelId(switch (aiProvider) {
        AiProviderType.claude => claudeModelId,
        AiProviderType.openai => openaiModelId,
        AiProviderType.gemini => geminiModelId,
        AiProviderType.groq => groqModelId,
      });

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
    String? claudeModelId,
    String? openaiModelId,
    String? geminiModelId,
    String? groqModelId,
    bool? avatarEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
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
      claudeModelId: claudeModelId ?? this.claudeModelId,
      openaiModelId: openaiModelId ?? this.openaiModelId,
      geminiModelId: geminiModelId ?? this.geminiModelId,
      groqModelId: groqModelId ?? this.groqModelId,
      avatarEnabled: avatarEnabled ?? this.avatarEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}
