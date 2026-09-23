import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
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

  /// 모델별 추가 필드(Sonnet 5의 thinking disabled 등)를 합친 요청 본문.
  Map<String, dynamic> _body(Map<String, dynamic> body) =>
      withRequestExtras(body, AiProviderType.claude.requestExtrasFor(model));

  /// thinking을 쓰는 모델은 text 앞에 thinking 블록이 올 수 있어 첫 블록을
  /// text로 가정하면 깨진다. type=='text' 블록만 이어 붙인다.
  /// text 블록이 하나도 없으면 예전(content.first['text'])처럼 던진다.
  @visibleForTesting
  static String textOf(dynamic data) {
    final texts = [
      for (final block in data['content'] as List)
        if (block is Map && block['type'] == 'text') block['text'] as String,
    ];
    if (texts.isEmpty) throw StateError('Claude response has no text block');
    return texts.join();
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
        'messages': conversationHistory
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
          'messages': conversationHistory
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

    await for (final chunk in stream) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          // thinking_delta·signature_delta는 사용자에게 보일 텍스트가 아니다.
          if (json['type'] == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>;
            if (delta['type'] != 'text_delta') continue;
            final text = delta['text'] as String?;
            if (text != null) yield text;
          }
        } catch (_) {}
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

    final response = await _dio.post('/messages', data: _body({
      'model': model,
      'max_tokens': 256,
      'system': LevelPrompt.build(nativeLanguage: nativeLanguage, targetLanguage: targetLanguage),
      'messages': [
        {'role': 'user', 'content': userMessages},
      ],
    }));

    final text = textOf(response.data);

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return LevelAssessment(
        currentLevel: 0,
        suggestedLevel: json['suggestedLevel'] as int,
        reasoning: json['reasoning'] as String? ?? '',
      );
    } catch (_) {
      return const LevelAssessment(
        currentLevel: 0,
        suggestedLevel: 5,
        reasoning: 'Failed to parse assessment',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> evaluatePronunciation({
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

      var text = textOf(response.data);
      text = text.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      return {'score': 0, 'feedback': [], 'overall': 'Evaluation failed: $e'};
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
    final messages = conversationHistory
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    messages.add({
      'role': 'user',
      'content': SuggestionPrompt.build(userLevel: userLevel, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage, count: count, lastAiMessage: lastAiMessage),
    });

    final response = await _dio.post('/messages', data: _body({
      'model': model,
      'max_tokens': 512,
      'messages': messages,
    }));

    final text = textOf(response.data);

    try {
      final jsonList = jsonDecode(text) as List;
      return jsonList
          .map((item) => Suggestion(
                text: item['text'] as String,
                koreanHint: item['koreanHint'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
