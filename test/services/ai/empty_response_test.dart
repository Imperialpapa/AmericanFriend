import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/core/error/failures.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/claude/claude_service.dart';
import 'package:eng_friend/services/ai/gemini/gemini_service.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/services/pipeline/conversation_pipeline.dart';
import 'package:eng_friend/services/pipeline/pipeline_event.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

Message _msg(String content, MessageRole role) => Message(
      id: content,
      content: content,
      role: role,
      timestamp: DateTime(2026),
    );

class _TokenAi implements AiService {
  final Stream<String> Function() tokens;
  _TokenAi(this.tokens);

  @override
  Stream<String> streamMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) =>
      tokens();

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) =>
      throw UnimplementedError();

  @override
  Future<LevelAssessment> assessLevel({
    required List<Message> recentMessages,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
  }) =>
      throw UnimplementedError();

  @override
  Future<PronunciationResult> evaluatePronunciation({required String prompt}) =>
      throw UnimplementedError();

  @override
  Future<List<Suggestion>> generateSuggestions({
    required List<Message> conversationHistory,
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
    String? lastAiMessage,
  }) =>
      throw UnimplementedError();
}

/// TTS 없이 턴 경계만 흉내 낸다 (FlutterTts는 플랫폼 채널이 필요하다).
class _FakeTtsQueue implements TtsQueue {
  int _turn = 0;
  final ended = <int>[];

  @override
  int beginTurn() => ++_turn;

  @override
  void markTurnEnd(int turnId) => ended.add(turnId);

  @override
  Future<void> enqueue(String sentence) async {}

  @override
  Future<void> interrupt() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<PipelineEvent>> _run(Stream<String> Function() tokens,
    {_FakeTtsQueue? tts}) {
  final pipeline = ConversationPipeline(
    aiService: _TokenAi(tokens),
    ttsQueue: tts ?? _FakeTtsQueue(),
  );
  return pipeline
      .processTextInput(
        text: 'hi',
        conversationHistory: [_msg('hi', MessageRole.user)],
        systemPrompt: 'sys',
        userLevel: 1,
        targetTtsEnabled: false,
      )
      .toList();
}

void main() {
  group('ConversationPipeline 빈 응답', () {
    test('토큰이 없으면 AiResponseComplete 대신 EmptyResponseFailure', () async {
      final tts = _FakeTtsQueue();
      final events = await _run(() => const Stream.empty(), tts: tts);
      expect(events.whereType<AiResponseComplete>(), isEmpty);
      final err = events.whereType<PipelineError>().single;
      expect(err.failure, isA<EmptyResponseFailure>());
      // 실패도 턴 종료다 — 핸즈프리가 다시 마이크를 열 수 있어야 한다.
      expect(tts.ended, [1]);
    });

    test('공백만 온 응답도 빈 응답으로 본다', () async {
      final events = await _run(() => Stream.fromIterable(['  ', '\n']));
      expect(events.whereType<AiResponseComplete>(), isEmpty);
      expect(events.whereType<PipelineError>().single.failure,
          isA<EmptyResponseFailure>());
    });

    test('안전 차단 예외는 EmptyResponseFailure로 옮긴다', () async {
      final events = await _run(
          () => Stream.error(const AiResponseBlockedException('SAFETY')));
      expect(events.whereType<PipelineError>().single.failure,
          isA<EmptyResponseFailure>());
    });

    test('정상 응답은 그대로 완료된다', () async {
      final events = await _run(() => Stream.fromIterable(['Hi ', 'there.']));
      expect(events.whereType<PipelineError>(), isEmpty);
      expect(events.whereType<AiResponseComplete>().single.fullResponse,
          'Hi there.');
    });
  });

  group('nonEmptyHistory', () {
    test('내용이 비거나 공백뿐인 메시지를 뺀다', () {
      final history = [
        _msg('hello', MessageRole.user),
        _msg('', MessageRole.assistant),
        _msg('  \n', MessageRole.assistant),
        _msg('again', MessageRole.user),
      ];
      expect(nonEmptyHistory(history).map((m) => m.content),
          ['hello', 'again']);
    });
  });

  group('ClaudeService.textFromSseData', () {
    test('text_delta만 텍스트로 꺼낸다', () {
      expect(
          ClaudeService.textFromSseData(
              '{"type":"content_block_delta","delta":{"type":"text_delta","text":"Hi"}}'),
          'Hi');
      expect(
          ClaudeService.textFromSseData(
              '{"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"x"}}'),
          isNull);
      expect(ClaudeService.textFromSseData('{"type":"message_stop"}'), isNull);
      expect(ClaudeService.textFromSseData('not json'), isNull);
    });

    test('error 이벤트는 삼키지 않고 던진다', () {
      expect(
        () => ClaudeService.textFromSseData(
            '{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}'),
        throwsA(predicate((e) => e.toString().contains('overloaded_error'))),
      );
    });

    test('max_tokens 중단은 로그만 남기고 계속한다', () {
      expect(
          ClaudeService.textFromSseData(
              '{"type":"message_delta","delta":{"stop_reason":"max_tokens"}}'),
          isNull);
    });

    const refusal =
        '{"type":"message_delta","delta":{"stop_reason":"refusal"},"stop_details":{"type":"refusal","category":"general_harms"}}';

    test('텍스트 없이 거절(refusal)로 끝나면 차단 예외를 던진다', () {
      expect(() => ClaudeService.textFromSseData(refusal),
          throwsA(isA<AiResponseBlockedException>()));
    });

    test('이미 텍스트를 보냈다면 거절에도 답변을 살린다', () {
      expect(ClaudeService.textFromSseData(refusal, hasText: true), isNull);
    });
  });

  group('ClaudeService.textOf 거절', () {
    test('text 블록 없이 stop_reason refusal이면 차단 예외', () {
      expect(
        () => ClaudeService.textOf({
          'content': const [],
          'stop_reason': 'refusal',
        }),
        throwsA(isA<AiResponseBlockedException>()),
      );
    });

    test('text가 있으면 거절이어도 텍스트를 돌려준다', () {
      expect(
        ClaudeService.textOf({
          'content': const [
            {'type': 'text', 'text': 'Partial'},
          ],
          'stop_reason': 'refusal',
        }),
        'Partial',
      );
    });
  });

  group('GeminiService.textFromSseData', () {
    test('첫 part의 text를 꺼낸다', () {
      expect(
          GeminiService.textFromSseData(
              '{"candidates":[{"content":{"parts":[{"text":"Hello"}]}}]}'),
          'Hello');
    });

    test('텍스트 없이 SAFETY로 끝나면 던진다', () {
      expect(
        () => GeminiService.textFromSseData(
            '{"candidates":[{"finishReason":"SAFETY"}]}'),
        throwsA(isA<AiResponseBlockedException>()),
      );
    });

    test('프롬프트 차단(promptFeedback.blockReason)도 던진다', () {
      expect(
        () => GeminiService.textFromSseData(
            '{"promptFeedback":{"blockReason":"PROHIBITED_CONTENT"}}'),
        throwsA(isA<AiResponseBlockedException>()),
      );
    });

    test('이미 텍스트를 보냈다면 SAFETY에도 답변을 살린다', () {
      expect(
          GeminiService.textFromSseData(
              '{"candidates":[{"finishReason":"SAFETY"}]}',
              hasText: true),
          isNull);
    });

    test('MAX_TOKENS는 텍스트를 그대로 돌려준다', () {
      expect(
          GeminiService.textFromSseData(
              '{"candidates":[{"content":{"parts":[{"text":"cut"}]},"finishReason":"MAX_TOKENS"}]}'),
          'cut');
    });
  });
}
