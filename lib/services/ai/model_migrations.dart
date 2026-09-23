import 'package:eng_friend/services/ai/ai_provider_type.dart';

/// 앱에 내장한 「은퇴·셧다운 model ID → 대체 ID」 매핑.
/// 상태 엔드포인트(서버 매핑)에 닿지 못해도 시작할 때마다 적용된다.
///
/// 카탈로그에서 ID를 뺄 때는 반드시 여기에 대체를 추가할 것 — 빠지면 그 ID를 고른
/// 사용자가 알림 없이 카탈로그 첫 항목으로 폴백한다(gpt-4.1-nano → 고가 gpt-4o).
const Map<String, String> localModelMigrations = {
  // Claude: sonnet-4는 2026-06-15, 3.5 sonnet은 2025-10-28 은퇴
  'claude-sonnet-4-20250514': 'claude-sonnet-5',
  'claude-3-5-sonnet-20241022': 'claude-sonnet-5',
  // Gemini: 2.0-flash는 2026-06-01 셧다운, 2.5 계열은 기존 사용자 한정
  'gemini-2.0-flash': 'gemini-3.6-flash',
  'gemini-2.5-flash': 'gemini-3.6-flash',
  'gemini-2.5-pro': 'gemini-3.8-flash',
  // OpenAI: 2026-10-23 셧다운. 저가 모델을 고른 사용자는 저가 모델로 보낸다.
  'gpt-4.1-nano': 'gpt-4o-mini',
};

/// [provider]에 저장된 모델 [stored]를 무엇으로 바꿔 저장해야 하는지. 바꿀 게 없으면 null.
///
/// - 사용자가 고른 ID(stored)를 먼저 본다. 카탈로그에서 빠진 ID라도 원래 의도(저가 모델 등)를 살린다.
/// - 다음으로 실제 호출될 ID(resolveModelId)를 본다. 모델을 고른 적 없는 기본값 사용자
///   (stored == null)도 여기서 잡힌다.
/// - 서버 매핑이 로컬보다 우선한다. 대상이 현재 카탈로그에 없으면 버린다 —
///   저장해 봐야 resolveModelId가 다시 기본값으로 돌려놓는다.
/// - 기본값을 따르는 사용자를 현재 기본값에 고정하지 않는다(기본값이 바뀌면 따라가야 한다).
String? modelMigrationTarget({
  required AiProviderType provider,
  required String? stored,
  Map<String, String> server = const {},
  Map<String, String> local = localModelMigrations,
}) {
  final effective = provider.resolveModelId(stored);
  bool inCatalog(String id) => provider.availableModels.any((m) => m.id == id);

  for (final source in <String>{?stored, effective}) {
    for (final table in [server, local]) {
      final target = table[source];
      if (target == null || !inCatalog(target)) continue;
      return target == (stored ?? effective) ? null : target;
    }
  }
  return null;
}
