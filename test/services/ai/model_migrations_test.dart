import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/model_migrations.dart';

void main() {
  String? target(
    AiProviderType provider,
    String? stored, [
    Map<String, String> server = const {},
  ]) =>
      modelMigrationTarget(provider: provider, stored: stored, server: server);

  group('내장 매핑 (서버 매핑 없이)', () {
    test('은퇴한 Claude Sonnet ID → claude-sonnet-5-5', () {
      expect(target(AiProviderType.claude, 'claude-sonnet-4-20250514'),
          'claude-sonnet-5-5');
      expect(target(AiProviderType.claude, 'claude-3-5-sonnet-20241022'),
          'claude-sonnet-5-5');
    });

    test('교체한 Claude ID는 같은 라인의 새 모델로 간다', () {
      // Sonnet을 고른 사용자를 기본값(Haiku)으로 떨어뜨리지 않는다.
      expect(target(AiProviderType.claude, 'claude-sonnet-5'),
          'claude-sonnet-5-5');
      expect(target(AiProviderType.claude, 'claude-haiku-4-5-20251001'),
          'claude-haiku-5-5');
    });

    test('셧다운·제한·교체된 Gemini Flash/Pro ID → 3.8 Flash', () {
      for (final id in const [
        'gemini-2.0-flash',
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-3.6-flash',
      ]) {
        expect(target(AiProviderType.gemini, id), 'gemini-3.8-flash',
            reason: id);
      }
    });

    test('셧다운·deprecated OpenAI ID는 같은 가격대로 간다', () {
      expect(target(AiProviderType.openai, 'gpt-4.1-nano'), 'gpt-6-luna');
      expect(target(AiProviderType.openai, 'gpt-4o-mini'), 'gpt-6-luna');
      // 4o를 고른 사용자를 기본값(저가)으로 떨어뜨리지 않는다.
      expect(target(AiProviderType.openai, 'gpt-4o'), 'gpt-6.1-terra');
    });

    test('카탈로그에 있는 ID는 그대로 둔다', () {
      expect(target(AiProviderType.claude, 'claude-haiku-5-5'), isNull);
      expect(target(AiProviderType.claude, 'claude-sonnet-5-5'), isNull);
      expect(target(AiProviderType.gemini, 'gemini-3.8-flash'), isNull);
      expect(target(AiProviderType.gemini, 'gemini-3.5-flash-lite'), isNull);
      expect(target(AiProviderType.openai, 'gpt-6-luna'), isNull);
      expect(target(AiProviderType.openai, 'gpt-6.1-terra'), isNull);
      expect(target(AiProviderType.groq, 'openai/gpt-oss-20b'), isNull);
      expect(target(AiProviderType.groq, 'qwen/qwen3.8-27b'), isNull);
    });

    test('모델을 고른 적 없는 사용자(null)를 현재 기본값에 고정하지 않는다', () {
      for (final p in [
        AiProviderType.claude,
        AiProviderType.openai,
        AiProviderType.gemini,
        AiProviderType.groq,
      ]) {
        expect(target(p, null), isNull, reason: p.name);
      }
    });

    test('매핑 없는 알 수 없는 ID는 건드리지 않는다(resolveModelId가 기본값 사용)', () {
      expect(target(AiProviderType.claude, 'claude-unknown'), isNull);
    });

    test('다른 제공자의 카탈로그 ID로는 옮기지 않는다', () {
      // gpt-4.1-nano → gpt-6-luna는 Claude 카탈로그에 없으므로 무시
      expect(target(AiProviderType.claude, 'gpt-4.1-nano'), isNull);
    });
  });

  group('서버 매핑', () {
    test('서버 매핑이 내장 매핑보다 우선한다', () {
      expect(
        target(AiProviderType.openai, 'gpt-4.1-nano',
            {'gpt-4.1-nano': 'gpt-6.1-terra'}),
        'gpt-6.1-terra',
      );
    });

    test('서버 대상이 카탈로그에 없으면 버리고 내장 매핑을 쓴다', () {
      expect(
        target(AiProviderType.openai, 'gpt-4.1-nano',
            {'gpt-4.1-nano': 'gpt-5.6-luna'}),
        'gpt-6-luna',
      );
    });

    test('서버 대상이 카탈로그에 없고 내장 매핑도 없으면 바꾸지 않는다', () {
      expect(
        target(AiProviderType.claude, 'claude-haiku-5-5',
            {'claude-haiku-5-5': 'claude-haiku-9'}),
        isNull,
      );
    });

    test('카탈로그에 있는 ID도 서버가 은퇴를 알리면 옮긴다', () {
      expect(
        target(AiProviderType.claude, 'claude-haiku-5-5',
            {'claude-haiku-5-5': 'claude-sonnet-5-5'}),
        'claude-sonnet-5-5',
      );
    });

    test('기본값 사용자(null)도 실제 호출될 ID 기준으로 교정한다', () {
      final dflt = AiProviderType.claude.defaultModelId;
      final other = AiProviderType.claude.availableModels
          .map((m) => m.id)
          .firstWhere((id) => id != dflt);
      expect(target(AiProviderType.claude, null, {dflt: other}), other);
    });

    test('기본값 사용자라도 대상이 카탈로그에 없으면 쓰지 않는다', () {
      final dflt = AiProviderType.claude.defaultModelId;
      expect(target(AiProviderType.claude, null, {dflt: 'claude-future-9'}),
          isNull);
    });

    test('자기 자신으로의 매핑은 무시한다', () {
      expect(
        target(
            AiProviderType.openai, 'gpt-6-luna', {'gpt-6-luna': 'gpt-6-luna'}),
        isNull,
      );
    });
  });
}
