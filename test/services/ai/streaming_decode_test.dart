import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/claude/claude_service.dart';
import 'package:eng_friend/services/ai/free_tier/free_tier_ai_service.dart';
import 'package:eng_friend/services/ai/gemini/gemini_service.dart';
import 'package:eng_friend/services/ai/groq/groq_service.dart';
import 'package:eng_friend/services/ai/openai/openai_service.dart';

/// 실제 Dio처럼 스트림 본문을 `Stream<Uint8List>`로 준다. 가짜 서비스로 streamMessage를
/// 통째로 바꾸는 테스트로는 이 경로를 못 탄다 — 그래서 5개 서비스가 전부 깨진 채 지나갔다(BUG #13).
/// 한글 '안'(3바이트)의 가운데에서 청크를 끊어 경계 처리도 함께 본다.
class _SseAdapter implements HttpClientAdapter {
  final String body;
  _SseAdapter(this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = utf8.encode(body);
    final cut = utf8.encode(body.substring(0, body.indexOf('안'))).length + 1;
    return ResponseBody(
      Stream<Uint8List>.fromIterable([
        Uint8List.fromList(bytes.sublist(0, cut)),
        Uint8List.fromList(bytes.sublist(cut)),
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(String sse) => Dio()..httpClientAdapter = _SseAdapter(sse);

const _deltas = ['안녕', '하세요'];

/// OpenAI 호환(OpenAI·Groq·무료 티어) 스트림.
final _openAiSse = [
  for (final d in _deltas)
    'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': d}
            }
          ]
        })}\n\n',
  'data: [DONE]\n\n',
].join();

final _claudeSse = [
  for (final d in _deltas)
    'event: content_block_delta\n'
        'data: ${jsonEncode({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': d},
        })}\n\n',
  'event: message_stop\ndata: {"type":"message_stop"}\n\n',
].join();

final _geminiSse = [
  for (final d in _deltas)
    'data: ${jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': d}
                ]
              }
            }
          ]
        })}\r\n\r\n',
].join();

Future<String> _collect(AiService ai) => ai
    .streamMessage(
      conversationHistory: [
        Message(
          id: '1',
          content: 'hi',
          role: MessageRole.user,
          timestamp: DateTime(2026),
        ),
      ],
      systemPrompt: 'sys',
      userLevel: 3,
    )
    .join();

void main() {
  group('streamMessage — 실제 Dio 스트림(Stream<Uint8List>) 디코딩', () {
    test('무료 티어', () async {
      final ai = FreeTierAiService(
          baseUrl: '', deviceId: 'test-device', dio: _dio(_openAiSse));
      expect(await _collect(ai), '안녕하세요');
    });

    test('Groq', () async {
      final ai = GroqService(apiKey: 'k', dio: _dio(_openAiSse));
      expect(await _collect(ai), '안녕하세요');
    });

    test('OpenAI', () async {
      final ai =
          OpenAiService(apiKey: 'k', model: 'gpt-6-luna', dio: _dio(_openAiSse));
      expect(await _collect(ai), '안녕하세요');
    });

    test('Claude', () async {
      final ai = ClaudeService(
          apiKey: 'k', model: 'claude-haiku-5-5', dio: _dio(_claudeSse));
      expect(await _collect(ai), '안녕하세요');
    });

    test('Gemini', () async {
      final ai = GeminiService(
          apiKey: 'k', model: 'gemini-3.5-flash-lite', dio: _dio(_geminiSse));
      expect(await _collect(ai), '안녕하세요');
    });
  });
}
