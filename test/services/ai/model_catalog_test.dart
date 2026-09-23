import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/model_migrations.dart';

/// 제공자가 은퇴·셧다운했거나 신규 키로 쓸 수 없는 BYOK ID. 저장한 사용자가 있으므로
/// 내장 매핑에 대체가 있어야 한다.
const _retiredByokIds = {
  'claude-sonnet-4-20250514',
  'claude-3-5-sonnet-20241022',
  'gemini-2.0-flash',
  'gemini-2.5-flash',
  'gemini-2.5-pro',
  'gpt-4.1-nano',
};

/// Groq가 폐기한 ID(BUG #9). 카탈로그에 다시 들어오면 안 된다.
const _retiredGroqIds = {
  'llama-3.3-70b-versatile',
  'llama-3.1-8b-instant',
  'gemma2-9b-it',
};

void main() {
  final allIds = {
    for (final p in AiProviderType.values)
      for (final m in p.availableModels) m.id,
  };

  test('제공자마다 모델이 있고 기본값이 목록 안에 있으며 ID가 중복되지 않는다', () {
    for (final p in AiProviderType.values) {
      final ids = p.availableModels.map((m) => m.id).toList();
      expect(ids, isNotEmpty, reason: p.name);
      expect(ids, contains(p.defaultModelId), reason: p.name);
      expect(ids.toSet().length, ids.length, reason: p.name);
    }
  });

  test('은퇴한 ID가 어떤 카탈로그에도 없다', () {
    expect(allIds.intersection({..._retiredByokIds, ..._retiredGroqIds}),
        isEmpty);
  });

  test('내장 매핑: 원본은 카탈로그에 없고, 대상은 카탈로그에 있다', () {
    for (final e in localModelMigrations.entries) {
      expect(allIds, isNot(contains(e.key)), reason: e.key);
      expect(allIds, contains(e.value), reason: '${e.key} -> ${e.value}');
    }
  });

  test('내장 매핑이 은퇴한 BYOK ID를 모두 덮는다', () {
    for (final id in _retiredByokIds) {
      expect(localModelMigrations, contains(id), reason: id);
    }
  });

  group('요청 추가 필드', () {
    test('claude-sonnet-5는 thinking을 끈다', () {
      expect(AiProviderType.claude.requestExtrasFor('claude-sonnet-5'), {
        'thinking': {'type': 'disabled'},
      });
    });

    test('Haiku 4.5에는 thinking 필드를 보내지 않는다', () {
      expect(
        AiProviderType.claude
            .requestExtrasFor('claude-haiku-4-5-20251001')
            .containsKey('thinking'),
        isFalse,
      );
    });

    test('Claude 요청에 temperature/top_p/top_k를 넣지 않는다', () {
      for (final m in AiProviderType.claude.availableModels) {
        for (final k in const ['temperature', 'top_p', 'top_k']) {
          expect(m.requestExtras.containsKey(k), isFalse, reason: '${m.id} $k');
        }
      }
    });

    test('Gemini 모델은 모두 thinkingLevel minimal', () {
      for (final m in AiProviderType.gemini.availableModels) {
        expect(
          m.requestExtras,
          {
            'generationConfig': {
              'thinkingConfig': {'thinkingLevel': 'minimal'},
            },
          },
          reason: m.id,
        );
      }
    });
  });
}
