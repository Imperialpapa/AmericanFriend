import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/ai_json.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/prompts/level_prompts.dart';
import 'package:eng_friend/services/ai/prompts/suggestion_prompt.dart';
import 'package:eng_friend/services/language/app_language.dart';

class ClaudeService implements AiService {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _baseUrl = 'https://api.anthropic.com/v1';

  // 기본 모델 인자를 두지 않는다 — 카탈로그(ai_provider_type.dart)와 어긋나면 죽은 ID가 남는다.
  ClaudeService({required this.apiKey, required this.model})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ));

  /// 모델별 추가 필드(thinking 끄기 등, 카탈로그 참고)를 합친 요청 본문.
  Map<String, dynamic> _body(Map<String, dynamic> body) =>
      withRequestExtras(body, AiProviderType.claude.requestExtrasFor(model));

  /// thinking을 쓰는 모델은 text 앞에 thinking 블록이 올 수 있어 첫 블록을
  /// text로 가정하면 깨진다. type=='text' 블록만 이어 붙인다.
  /// text 블록이 하나도 없으면 예전(content.first['text'])처럼 던진다.
  /// 안전 분류기가 거절했으면(HTTP 200 + stop_reason refusal, Haiku 5.5·Sonnet 5.5부터)
  /// Gemini 안전 차단과 같은 [AiResponseBlockedException]으로 올린다.
  @visibleForTesting
  static String textOf(dynamic data) {
    final texts = [
      for (final block in data['content'] as List)
        if (block is Map && block['type'] == 'text') block['text'] as String,
    ];
    if (texts.isEmpty) {
      if (data['stop_reason'] == 'refusal') {
        throw const AiResponseBlockedException('refusal');
      }
      throw StateError('Claude response has no text block');
    }
    return texts.join();
  }

  /// SSE data 한 줄에서 사용자에게 보일 텍스트를 꺼낸다. 없으면 null.
  /// error 이벤트(overloaded_error 등)는 던진다 — 예전엔 삼켜서 빈 답변이
  /// 정상 완료로 저장됐고, 그 빈 메시지 때문에 이후 모든 요청이 400이 났다(A-05).
  /// 거절(stop_reason refusal)도 텍스트가 아직 없으면 던진다. 이미 텍스트를
  /// 보냈다면([hasText]) 그 답변을 살리려고 로그만 남긴다.
  @visibleForTesting
  static String? textFromSseData(String data, {bool hasText = false}) {
    final Object? json;
    try {
      json = jsonDecode(data);
    } catch (_) {
      return null;
    }
    if (json is! Map) return null;
    switch (json['type']) {
      // thinking_delta·signature_delta는 사용자에게 보일 텍스트가 아니다.
      case 'content_block_delta':
        final delta = json['delta'];
        if (delta is Map && delta['type'] == 'text_delta') {
          final text = delta['text'];
          if (text is String) return text;
        }
      case 'error':
        final err = json['error'];
        final type = err is Map ? err['type'] : null;
        final message = err is Map ? err['message'] : null;
        throw Exception('Claude stream error: ${type ?? 'unknown'} ${message ?? ''}'
            .trim());
      case 'message_delta':
        final delta = json['delta'];
        final stopReason = delta is Map ? delta['stop_reason'] : null;
        if (stopReason == 'max_tokens') {
          debugPrint('[Claude] response truncated (max_tokens)');
        } else if (stopReason == 'refusal') {
          if (!hasText) throw const AiResponseBlockedException('refusal');
          debugPrint('[Claude] response cut by refusal');
        }
    }
    return null;
  }

  String _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    if (statusCode == 401) {
      return 'Invalid Claude API key. Please check in Settings.';
    } else if (statusCode == 403) {
      return 'Claude API access denied. Please check your key permissions.';
    } else if (statusCode == 429) {
      return 'Rate limit exceeded. Please try again later.';
    } else if (statusCode == 400) {
      final msg = (body is Map) ? (body['error']?['message'] ?? '') : '';
      return 'API request error: $msg';
    }
    return 'API error ($statusCode): ${e.message}';
  }

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) async {
    try {
      final response = await _dio.post('/messages', data: _body({
        'model': model,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': nonEmptyHistory(conversationHistory)
            .map((m) => {
                  'role': m.role == MessageRole.user ? 'user' : 'assistant',
                  'content': m.content,
                })
            .toList(),
      }));

      return textOf(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Stream<String> streamMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) async* {
    late final Response response;
    try {
      response = await _dio.post(
        '/messages',
        data: _body({
          'model': model,
          'max_tokens': 1024,
          'stream': true,
          'system': systemPrompt,
          'messages': nonEmptyHistory(conversationHistory)
              .map((m) => {
                    'role': m.role == MessageRole.user ? 'user' : 'assistant',
                    'content': m.content,
                  })
              .toList(),
        }),
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }

    // 멀티바이트 문자가 청크 경계에 걸리면 utf8.decode가 FormatException을 던져
    // 스트림이 통째로 죽는다(한글·일본어는 3바이트라 흔하다).
    final stream =
        (response.data.stream as Stream<List<int>>).transform(utf8.decoder);
    String buffer = '';
    var hasText = false;

    await for (final chunk in stream) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') return;

        final text = textFromSseData(data, hasText: hasText);
        if (text == null) continue;
        if (text.isNotEmpty) hasText = true;
        yield text;
      }
    }
  }

  @override
  Future<LevelAssessment> assessLevel({
    required List<Message> recentMessages,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
  }) async {
    final userMessages = recentMessages
        .where((m) => m.role == MessageRole.user)
        .map((m) => m.content)
        .join('\n');

    // post도 try 안에 — 밖에 있으면 네트워크 오류가 호출자로 던져진다.
    try {
      final response = await _dio.post('/messages', data: _body({
        'model': model,
        'max_tokens': 256,
        'system': LevelPrompt.build(nativeLanguage: nativeLanguage, targetLanguage: targetLanguage),
        'messages': [
          {'role': 'user', 'content': userMessages},
        ],
      }));
      return parseLevelAssessment(textOf(response.data));
    } catch (_) {
      return const LevelAssessment.failed();
    }
  }

  @override
  Future<PronunciationResult> evaluatePronunciation({
    required String prompt,
  }) async {
    try {
      final response = await _dio.post('/messages', data: _body({
        'model': model,
        'max_tokens': 512,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }));
      return PronunciationResult.fromJson(extractJson(textOf(response.data)));
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<Suggestion>> generateSuggestions({
    required List<Message> conversationHistory,
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
    String? lastAiMessage,
  }) async {
    final messages = nonEmptyHistory(conversationHistory)
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    messages.add({
      'role': 'user',
      'content': SuggestionPrompt.build(userLevel: userLevel, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage, count: count, lastAiMessage: lastAiMessage),
    });

    try {
      final response = await _dio.post('/messages', data: _body({
        'model': model,
        'max_tokens': 512,
        'messages': messages,
      }));
      return parseSuggestions(textOf(response.data));
    } catch (_) {
      return [];
    }
  }
}
