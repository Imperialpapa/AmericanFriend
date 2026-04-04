import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/di/service_providers.dart';

const _claudeKeyKey = 'claude_api_key';
const _openaiKeyKey = 'openai_api_key';
const _geminiKeyKey = 'gemini_api_key';
const _groqKeyKey = 'groq_api_key';
const _aiProviderKey = 'ai_provider';
const _suggestionModeKey = 'suggestion_mode';
const _suggestionDelayKey = 'suggestion_delay';
const _ttsSpeechRateKey = 'tts_speech_rate';
const _showKoreanHintKey = 'show_korean_hint';
const _ttsVoiceGenderKey = 'tts_voice_gender';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

class SettingsNotifier extends StateNotifier<UserSettings> {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  SettingsNotifier(this._secureStorage, this._prefs)
      : super(const UserSettings());

  Future<void> load() async {
    final claudeKey = await _secureStorage.read(key: _claudeKeyKey) ?? '';
    final openaiKey = await _secureStorage.read(key: _openaiKeyKey) ?? '';
    final geminiKey = await _secureStorage.read(key: _geminiKeyKey) ?? '';
    final groqKey = await _secureStorage.read(key: _groqKeyKey) ?? '';
    final providerStr = _prefs.getString(_aiProviderKey) ?? 'gemini';
    final modeStr = _prefs.getString(_suggestionModeKey);
    final delay = _prefs.getInt(_suggestionDelayKey) ?? 5;
    final rate = _prefs.getDouble(_ttsSpeechRateKey) ?? 0.5;
    final showKoreanHint = _prefs.getBool(_showKoreanHintKey) ?? true;
    final genderStr = _prefs.getString(_ttsVoiceGenderKey);

    state = UserSettings(
      claudeApiKey: claudeKey,
      openaiApiKey: openaiKey,
      geminiApiKey: geminiKey,
      groqApiKey: groqKey,
      aiProvider: AiProviderType.values.firstWhere(
        (e) => e.name == providerStr,
        orElse: () => AiProviderType.gemini,
      ),
      suggestionMode: modeStr == 'delayed'
          ? SuggestionMode.delayed
          : SuggestionMode.immediate,
      suggestionDelaySec: delay,
      ttsSpeechRate: rate,
      showKoreanHint: showKoreanHint,
      ttsVoiceGender: genderStr == 'male'
          ? TtsVoiceGender.male
          : TtsVoiceGender.female,
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

  Future<void> setShowKoreanHint(bool show) async {
    await _prefs.setBool(_showKoreanHintKey, show);
    state = state.copyWith(showKoreanHint: show);
  }

  Future<void> setTtsVoiceGender(TtsVoiceGender gender) async {
    await _prefs.setString(_ttsVoiceGenderKey, gender.name);
    state = state.copyWith(ttsVoiceGender: gender);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(secureStorage, prefs);
});
