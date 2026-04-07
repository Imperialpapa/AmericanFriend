import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/ai_service_factory.dart';
import 'package:eng_friend/services/feature_flags/feature_flag_service.dart';
import 'package:eng_friend/services/feature_flags/local_feature_flags.dart';
import 'package:eng_friend/services/local_db/app_database.dart';
import 'package:eng_friend/services/pipeline/conversation_pipeline.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';

/// SharedPreferences 인스턴스 (앱 시작 시 override)
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

/// Feature Flag 서비스
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalFeatureFlags(prefs);
});

/// AI 서비스 — settingsProvider에서 프로바이더, API 키, 모델을 실시간으로 읽음
final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(settingsProvider);

  return AiServiceFactory.create(
    provider: settings.aiProvider,
    apiKey: settings.activeApiKey,
    modelId: settings.activeModelId,
  );
});

/// FlutterTts 인스턴스 — 설정의 속도와 성별을 실시간 반영
final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final settings = ref.watch(settingsProvider);
  final tts = FlutterTts();
  tts.setLanguage(settings.ttsLanguage);
  tts.setSpeechRate(settings.ttsSpeechRate);
  // 여성: 높은 피치, 남성: 낮은 피치
  tts.setPitch(settings.ttsVoiceGender == TtsVoiceGender.female ? 1.2 : 0.8);
  return tts;
});

/// TTS 큐
final ttsQueueProvider = Provider<TtsQueue>((ref) {
  final tts = ref.watch(flutterTtsProvider);
  return TtsQueue(tts);
});

/// 로컬 DB
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// 대화 파이프라인
final conversationPipelineProvider = Provider<ConversationPipeline>((ref) {
  return ConversationPipeline(
    aiService: ref.watch(aiServiceProvider),
    ttsQueue: ref.watch(ttsQueueProvider),
  );
});
