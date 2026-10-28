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

/// 아직 살아 있지만 같은 라인의 새 모델로 교체해 카탈로그에서 뺀 ID.
/// 저장한 사용자가 있으므로 역시 내장 매핑에 대체가 있어야 한다.
const _supersededByokIds = {
  'claude-sonnet-5',
  'claude-haiku-4-5-20251001',
  'gpt-4o', // 2026-10-14 deprecated, 2027-01-14 셧다운
  'gpt-4o-mini', // 〃
  'gemini-3.6-flash', // 이전 세대, 3.8 Flash와 같은 가격
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

  test('은퇴·교체한 ID가 어떤 카탈로그에도 없다', () {
    expect(
        allIds.intersection(
            {..._retiredByokIds, ..._supersededByokIds, ..._retiredGroqIds}),
        isEmpty);
  });

  test('내장 매핑: 원본은 카탈로그에 없고, 대상은 카탈로그에 있다', () {
    for (final e in localModelMigrations.entries) {
      expect(allIds, isNot(contains(e.key)), reason: e.key);
      expect(allIds, contains(e.value), reason: '${e.key} -> ${e.value}');
    }
  });

  test('내장 매핑이 은퇴·교체한 BYOK ID를 모두 덮는다', () {
    for (final id in {..._retiredByokIds, ..._supersededByokIds}) {
      expect(localModelMigrations, contains(id), reason: id);
    }
  });

  group('요청 추가 필드', () {
    test('Haiku 5.5는 thinking을 disabled로 끈다', () {
      expect(AiProviderType.claude.requestExtrasFor('claude-haiku-5-5'), {
        'thinking': {'type': 'disabled'},
      });
    });

    test('Sonnet 5.5는 disabled가 400이라 between_tools만 보낸다', () {
      // thinking 안에 다른 필드(display·budget_tokens 등)를 같이 넣어도 400이다.
      expect(AiProviderType.claude.requestExtrasFor('claude-sonnet-5-5'), {
        'thinking': {'type': 'between_tools'},
      });
    });

    test('Claude 모델은 모두 thinking을 명시적으로 끈다', () {
      // 현행 모델은 thinking이 기본 ON이다. 빠뜨리면 보조 호출의 작은 max_tokens를
      // thinking이 먹어 JSON이 잘린다(tobe A-03).
      for (final m in AiProviderType.claude.availableModels) {
        final thinking = m.requestExtras['thinking'];
        expect(thinking, isA<Map>(), reason: m.id);
        expect((thinking as Map)['type'], isIn(['disabled', 'between_tools']),
            reason: m.id);
      }
    });

    test('between_tools는 Sonnet 5.5에만 보낸다(다른 모델은 400)', () {
      for (final m in AiProviderType.claude.availableModels) {
        if (m.id == 'claude-sonnet-5-5') continue;
        expect(m.requestExtras['thinking'], isNot({'type': 'between_tools'}),
            reason: m.id);
      }
    });

    test('Claude 요청에 temperature/top_p/top_k를 넣지 않는다', () {
      for (final m in AiProviderType.claude.availableModels) {
        for (final k in const ['temperature', 'top_p', 'top_k']) {
          expect(m.requestExtras.containsKey(k), isFalse, reason: '${m.id} $k');
        }
      }
    });

    test('Gemini 모델은 모두 thinkingLevel을 낮춘다', () {
      // 3.x는 thinking이 기본 ON이고 maxOutputTokens에 thought 토큰이 포함된다.
      for (final m in AiProviderType.gemini.availableModels) {
        final config = m.requestExtras['generationConfig'] as Map;
        final level = (config['thinkingConfig'] as Map)['thinkingLevel'];
        expect(level, isIn(['minimal', 'low']), reason: m.id);
      }
    });

    test('Gemini 3.8 Flash에는 minimal을 보내지 않는다(미지원, 오류)', () {
      expect(AiProviderType.gemini.requestExtrasFor('gemini-3.8-flash'), {
        'generationConfig': {
          'thinkingConfig': {'thinkingLevel': 'low'},
        },
      });
    });

    test('Preview 모델(qwen)은 기본값이 아니다', () {
      // 예고 없이 내려갈 수 있다. 기본값이면 모델을 고른 적 없는 사용자 전원이 실패한다.
      expect(AiProviderType.groq.defaultModelId, 'openai/gpt-oss-120b');
      expect(
          AiProviderType.groq.availableModels.map((m) => m.id),
          contains('qwen/qwen3.8-27b'));
    });

    test('OpenAI 모델은 모두 reasoning_effort none만 보낸다', () {
      // GPT-6 계열은 기본 effort medium이고 minimal 값이 없다. max_tokens는 deprecated,
      // temperature는 effort none일 때만 허용 — 카탈로그에서 넣지 않는다.
      for (final m in AiProviderType.openai.availableModels) {
        expect(m.requestExtras, {'reasoning_effort': 'none'}, reason: m.id);
      }
    });
  });
}
