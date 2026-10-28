import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/claude/claude_service.dart';

void main() {
  group('withRequestExtras', () {
    test('extras가 비면 본문을 그대로 돌려준다', () {
      final body = {'model': 'm', 'max_tokens': 10};
      expect(withRequestExtras(body, const {}), same(body));
    });

    test('최상위 필드를 추가한다 (Claude thinking)', () {
      final merged = withRequestExtras(
        {'model': 'm', 'max_tokens': 256},
        const {
          'thinking': {'type': 'disabled'},
        },
      );
      expect(merged, {
        'model': 'm',
        'max_tokens': 256,
        'thinking': {'type': 'disabled'},
      });
    });

    test('중첩 Map은 기존 키를 지우지 않고 합친다 (Gemini generationConfig)', () {
      final merged = withRequestExtras(
        {
          'contents': const [],
          'generationConfig': {'maxOutputTokens': 1024},
        },
        const {
          'generationConfig': {
            'thinkingConfig': {'thinkingLevel': 'minimal'},
          },
        },
      );
      expect(merged['generationConfig'], {
        'maxOutputTokens': 1024,
        'thinkingConfig': {'thinkingLevel': 'minimal'},
      });
    });

    test('본문에 없는 중첩 키는 새로 만든다', () {
      final merged = withRequestExtras(
        {'contents': const []},
        const {
          'generationConfig': {
            'thinkingConfig': {'thinkingLevel': 'minimal'},
          },
        },
      );
      expect(merged['generationConfig'], {
        'thinkingConfig': {'thinkingLevel': 'minimal'},
      });
    });

    test('원본 본문을 변경하지 않는다', () {
      final config = {'maxOutputTokens': 1024};
      final body = {'generationConfig': config};
      withRequestExtras(body, const {
        'generationConfig': {'x': 1},
      });
      expect(config, {'maxOutputTokens': 1024});
    });
  });

  group('ClaudeService.textOf', () {
    test('thinking 블록이 앞에 와도 text 블록만 모은다', () {
      final data = {
        'content': [
          {'type': 'thinking', 'thinking': '...', 'signature': 'sig'},
          {'type': 'text', 'text': '{"suggestedLevel": 3}'},
        ],
      };
      expect(ClaudeService.textOf(data), '{"suggestedLevel": 3}');
    });

    test('text 블록이 여러 개면 이어 붙인다', () {
      final data = {
        'content': [
          {'type': 'text', 'text': 'Hello, '},
          {'type': 'text', 'text': 'world'},
        ],
      };
      expect(ClaudeService.textOf(data), 'Hello, world');
    });

    test('text 블록이 없으면 던진다 (기존 실패 경로 유지)', () {
      final data = {
        'content': [
          {'type': 'thinking', 'thinking': '...'},
        ],
      };
      expect(() => ClaudeService.textOf(data), throwsStateError);
    });
  });
}
