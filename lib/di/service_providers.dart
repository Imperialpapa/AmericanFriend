import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/ai_service_factory.dart';
import 'package:eng_friend/services/feature_flags/feature_flag_service.dart';
import 'package:eng_friend/services/feature_flags/local_feature_flags.dart';
import 'package:eng_friend/core/config/proxy_config.dart';
import 'package:eng_friend/services/audio/audio_focus_service.dart';
import 'package:eng_friend/services/status/app_status.dart';
import 'package:eng_friend/services/status/app_status_service.dart';
import 'package:eng_friend/services/local_db/app_database.dart';
import 'package:eng_friend/services/pipeline/conversation_pipeline.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/services/report/report_service.dart';
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

/// AI 서비스 — settingsProvider에서 프로바이더, API 키, 모델을 실시간으로 읽음.
///
/// settingsProvider 전체를 watch하면 폰트 크기처럼 AI와 무관한 설정을 바꿔도
/// AiService가 재생성되고, conversationPipelineProvider까지 cascade로 재생성되어
/// 진행 중인 대화 스트림이 끊긴다. flutterTtsProvider는 이미 같은 이유로 좁혀져 있다.
/// Dart 3 record는 값 비교라서 select의 리빌드 판정이 그대로 동작한다.
final aiServiceProvider = Provider<AiService>((ref) {
  final (provider, apiKey, modelId) = ref.watch(
    settingsProvider
        .select((s) => (s.aiProvider, s.activeApiKey, s.activeModelId)),
  );

  return AiServiceFactory.create(
    provider: provider,
    apiKey: apiKey,
    modelId: modelId,
  );
});

/// FlutterTts 인스턴스 — 한 번 생성 후 관련 설정 변경 시 메서드만 호출.
/// (이전엔 settingsProvider 전체를 watch해서 무관한 설정 변경에도 인스턴스가 재생성되며
///  TtsQueue/ConversationPipeline까지 cascade로 재생성되어 진행 중인 TTS가 끊겼다.)
final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();

  final s = ref.read(settingsProvider);
  tts.setLanguage(s.ttsLanguage);
  tts.setSpeechRate(s.ttsSpeechRate);
  // 여성: 높은 피치, 남성: 낮은 피치
  tts.setPitch(s.ttsVoiceGender == TtsVoiceGender.female ? 1.2 : 0.8);

  ref.listen<String>(
    settingsProvider.select((s) => s.ttsLanguage),
    (_, v) => tts.setLanguage(v),
  );
  ref.listen<double>(
    settingsProvider.select((s) => s.ttsSpeechRate),
    (_, v) => tts.setSpeechRate(v),
  );
  ref.listen<TtsVoiceGender>(
    settingsProvider.select((s) => s.ttsVoiceGender),
    (_, v) => tts.setPitch(v == TtsVoiceGender.female ? 1.2 : 0.8),
  );

  ref.onDispose(() => tts.stop());
  return tts;
});

/// TTS 큐
final ttsQueueProvider = Provider<TtsQueue>((ref) {
  final tts = ref.watch(flutterTtsProvider);
  return TtsQueue(tts);
});

/// 오디오 포커스 — 전화 수신/알람 시 핸즈프리를 멈추기 위해 필요.
/// 안드로이드에서 전화는 액티비티를 pause시키지 않으므로 lifecycle로는 못 잡는다.
final audioFocusServiceProvider = Provider<AudioFocusService>((ref) {
  final service = AudioFocusService();
  ref.onDispose(service.dispose);
  return service;
});

/// 앱 상태/공지 — 제공자 모델 셧다운 같은 사고를 앱 배포 없이 알리고 고치기 위한 통로.
final appStatusServiceProvider = Provider<AppStatusService>((ref) {
  return AppStatusService(
    baseUrl: ProxyConfig.freeTierBaseUrl,
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// 앱 시작 시 1회 조회. 실패해도 null이며 앱 동작을 막지 않는다.
final appStatusProvider = FutureProvider<AppStatus?>((ref) async {
  return ref.watch(appStatusServiceProvider).fetch();
});

/// 핸즈프리를 쓸 수 있는가 — 서버 원격 스위치([RemoteFlags.handsFree]).
/// 상태를 아직 모르거나(조회 중·실패·캐시 없음) 서버에 값이 없으면 쓸 수 있다.
final handsFreeAllowedProvider = Provider<bool>((ref) {
  final status = ref.watch(appStatusProvider).value;
  return status?.isEnabled(RemoteFlags.handsFree, fallback: true) ?? true;
});

/// AI 응답 신고 — 제공자(BYOK 포함)와 무관하게 무료 티어 서버로 보낸다(tobe P-01).
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    baseUrl: ProxyConfig.freeTierBaseUrl,
    prefs: ref.watch(sharedPreferencesProvider),
  );
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
