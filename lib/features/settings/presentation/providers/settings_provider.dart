import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/di/service_providers.dart';

const _claudeKeyKey = 'claude_api_key';
const _openaiKeyKey = 'openai_api_key';
const _geminiKeyKey = 'gemini_api_key';
const _groqKeyKey = 'groq_api_key';
const _aiProviderKey = 'ai_provider';
const _nativeLanguageKey = 'native_language';
const _targetLanguageKey = 'target_language';
const _suggestionModeKey = 'suggestion_mode';
const _suggestionDelayKey = 'suggestion_delay';
const _ttsSpeechRateKey = 'tts_speech_rate';
const _showNativeHintKey = 'show_native_hint';
const _nativeTtsEnabledKey = 'native_tts_enabled';
const _showTargetTextKey = 'show_target_text';
const _targetTtsEnabledKey = 'target_tts_enabled';
const _ttsVoiceGenderKey = 'tts_voice_gender';
const _claudeModelKey = 'claude_model_id';
const _openaiModelKey = 'openai_model_id';
const _geminiModelKey = 'gemini_model_id';
const _groqModelKey = 'groq_model_id';
const _avatarEnabledKey = 'avatar_enabled';
const _reminderEnabledKey = 'reminder_enabled';
const _reminderHourKey = 'reminder_hour';
const _reminderMinuteKey = 'reminder_minute';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

class SettingsNotifier extends StateNotifier<UserSettings> {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  SettingsNotifier(this._secureStorage, this._prefs)
      : super(const UserSettings());

  /// 복호화 실패(BadPaddingException 등)는 키스토어/저장된 데이터 불일치로
  /// 주로 안드로이드 보안 업데이트·디바이스 변경·백업 복원 후 발생.
  /// 이 경우 저장소 전체를 비워서 앱이 정상 부팅되도록 한다 (API 키 재입력 필요).
  Future<String> _safeReadKey(String key) async {
    try {
      return await _secureStorage.read(key: key) ?? '';
    } on PlatformException catch (e) {
      debugPrint('[Settings] secure storage read failed for $key: $e');
      rethrow;
    }
  }

  Future<void> load() async {
    String claudeKey = '';
    String openaiKey = '';
    String geminiKey = '';
    String groqKey = '';
    try {
      claudeKey = await _safeReadKey(_claudeKeyKey);
      openaiKey = await _safeReadKey(_openaiKeyKey);
      geminiKey = await _safeReadKey(_geminiKeyKey);
      groqKey = await _safeReadKey(_groqKeyKey);
    } on PlatformException {
      debugPrint('[Settings] secure storage corrupt — wiping all entries');
      try {
        await _secureStorage.deleteAll();
      } catch (err) {
        debugPrint('[Settings] deleteAll also failed: $err');
      }
    }
    final providerStr = _prefs.getString(_aiProviderKey) ?? 'gemini';
    final nativeLangStr = _prefs.getString(_nativeLanguageKey);
    final targetLangStr = _prefs.getString(_targetLanguageKey);
    final modeStr = _prefs.getString(_suggestionModeKey);
    final delay = _prefs.getInt(_suggestionDelayKey) ?? 5;
    final rate = _prefs.getDouble(_ttsSpeechRateKey) ?? 0.5;
    // 기존 show_korean_hint에서 마이그레이션
    final showNativeHint = _prefs.getBool(_showNativeHintKey)
        ?? _prefs.getBool('show_korean_hint')
        ?? true;
    final nativeTtsEnabled = _prefs.getBool(_nativeTtsEnabledKey) ?? false;
    final showTargetText = _prefs.getBool(_showTargetTextKey) ?? true;
    final targetTtsEnabled = _prefs.getBool(_targetTtsEnabledKey) ?? true;
    final genderStr = _prefs.getString(_ttsVoiceGenderKey);
    final claudeModelId = _prefs.getString(_claudeModelKey);
    final openaiModelId = _prefs.getString(_openaiModelKey);
    final geminiModelId = _prefs.getString(_geminiModelKey);
    final groqModelId = _prefs.getString(_groqModelKey);
    final avatarEnabled = _prefs.getBool(_avatarEnabledKey) ?? false;
    final reminderEnabled = _prefs.getBool(_reminderEnabledKey) ?? false;
    final reminderHour = _prefs.getInt(_reminderHourKey) ?? 20;
    final reminderMinute = _prefs.getInt(_reminderMinuteKey) ?? 0;

    state = UserSettings(
      claudeApiKey: claudeKey,
      openaiApiKey: openaiKey,
      geminiApiKey: geminiKey,
      groqApiKey: groqKey,
      aiProvider: AiProviderType.values.firstWhere(
        (e) => e.name == providerStr,
        orElse: () => AiProviderType.gemini,
      ),
      nativeLanguage: nativeLangStr != null
          ? AppLanguage.fromCode(nativeLangStr)
          : AppLanguage.korean,
      targetLanguage: targetLangStr != null
          ? AppLanguage.fromCode(targetLangStr)
          : AppLanguage.englishUS,
      suggestionMode: modeStr == 'delayed'
          ? SuggestionMode.delayed
          : SuggestionMode.immediate,
      suggestionDelaySec: delay,
      ttsSpeechRate: rate,
      showNativeHint: showNativeHint,
      nativeTtsEnabled: nativeTtsEnabled,
      showTargetText: showTargetText,
      targetTtsEnabled: targetTtsEnabled,
      ttsVoiceGender: genderStr == 'male'
          ? TtsVoiceGender.male
          : TtsVoiceGender.female,
      claudeModelId: claudeModelId,
      openaiModelId: openaiModelId,
      geminiModelId: geminiModelId,
      groqModelId: groqModelId,
      avatarEnabled: avatarEnabled,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
  }

  Future<void> setClaudeApiKey(String key) async {
    await _secureStorage.write(key: _claudeKeyKey, value: key);
    state = state.copyWith(claudeApiKey: key);
  }

  Future<void> setOpenaiApiKey(String key) async {
    await _secureStorage.write(key: _openaiKeyKey, value: key);
    state = state.copyWith(openaiApiKey: key);
  }

  Future<void> setGeminiApiKey(String key) async {
    await _secureStorage.write(key: _geminiKeyKey, value: key);
    state = state.copyWith(geminiApiKey: key);
  }

  Future<void> setGroqApiKey(String key) async {
    await _secureStorage.write(key: _groqKeyKey, value: key);
    state = state.copyWith(groqApiKey: key);
  }

  Future<void> setAiProvider(AiProviderType provider) async {
    await _prefs.setString(_aiProviderKey, provider.name);
    state = state.copyWith(aiProvider: provider);
  }

  Future<void> setSuggestionMode(SuggestionMode mode) async {
    await _prefs.setString(_suggestionModeKey, mode.name);
    state = state.copyWith(suggestionMode: mode);
  }

  Future<void> setSuggestionDelay(int seconds) async {
    await _prefs.setInt(_suggestionDelayKey, seconds);
    state = state.copyWith(suggestionDelaySec: seconds);
  }

  Future<void> setTtsSpeechRate(double rate) async {
    await _prefs.setDouble(_ttsSpeechRateKey, rate);
    state = state.copyWith(ttsSpeechRate: rate);
  }

  Future<void> setNativeLanguage(AppLanguage lang) async {
    await _prefs.setString(_nativeLanguageKey, lang.code);
    state = state.copyWith(nativeLanguage: lang);
  }

  Future<void> setTargetLanguage(AppLanguage lang) async {
    await _prefs.setString(_targetLanguageKey, lang.code);
    state = state.copyWith(targetLanguage: lang);
  }

  Future<void> setShowNativeHint(bool show) async {
    await _prefs.setBool(_showNativeHintKey, show);
    state = state.copyWith(showNativeHint: show);
  }

  Future<void> setNativeTtsEnabled(bool enabled) async {
    await _prefs.setBool(_nativeTtsEnabledKey, enabled);
    state = state.copyWith(nativeTtsEnabled: enabled);
  }

  Future<void> setShowTargetText(bool show) async {
    await _prefs.setBool(_showTargetTextKey, show);
    state = state.copyWith(showTargetText: show);
  }

  Future<void> setTargetTtsEnabled(bool enabled) async {
    await _prefs.setBool(_targetTtsEnabledKey, enabled);
    state = state.copyWith(targetTtsEnabled: enabled);
  }

  Future<void> setTtsVoiceGender(TtsVoiceGender gender) async {
    await _prefs.setString(_ttsVoiceGenderKey, gender.name);
    state = state.copyWith(ttsVoiceGender: gender);
  }

  Future<void> setModelId(AiProviderType provider, String modelId) async {
    switch (provider) {
      case AiProviderType.claude:
        await _prefs.setString(_claudeModelKey, modelId);
        state = state.copyWith(claudeModelId: modelId);
      case AiProviderType.openai:
        await _prefs.setString(_openaiModelKey, modelId);
        state = state.copyWith(openaiModelId: modelId);
      case AiProviderType.gemini:
        await _prefs.setString(_geminiModelKey, modelId);
        state = state.copyWith(geminiModelId: modelId);
      case AiProviderType.groq:
        await _prefs.setString(_groqModelKey, modelId);
        state = state.copyWith(groqModelId: modelId);
    }
  }

  Future<void> setAvatarEnabled(bool enabled) async {
    await _prefs.setBool(_avatarEnabledKey, enabled);
    state = state.copyWith(avatarEnabled: enabled);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _prefs.setBool(_reminderEnabledKey, enabled);
    state = state.copyWith(reminderEnabled: enabled);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    await _prefs.setInt(_reminderHourKey, hour);
    await _prefs.setInt(_reminderMinuteKey, minute);
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(secureStorage, prefs);
});
