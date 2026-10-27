import 'dart:convert';
import 'package:dio/dio.dart';
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

class OpenAiService implements AiService {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _baseUrl = 'https://api.openai.com/v1';

  // 기본 모델 인자를 두지 않는다 — 카탈로그(ai_provider_type.dart)와 어긋나면 죽은 ID가 남는다.
  OpenAiService({required this.apiKey, required this.model, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
            ));

  /// 모델별 추가 필드(GPT-5.x의 reasoning_effort 등, 카탈로그 참고)를 합친 요청 본문.
  /// 추론 모델은 기본값이면 답변 전에 속으로 생각해 음성 첫 응답이 늦어진다.
  Map<String, dynamic> _body(Map<String, dynamic> body) =>
      withRequestExtras(body, AiProviderType.openai.requestExtrasFor(model));

  String _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return 'Invalid OpenAI API key. Please check in Settings.';
    } else if (statusCode == 429) {
      return 'Rate limit exceeded. Please try again later.';
    } else if (statusCode == 400) {
      final body = e.response?.data;
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
      final response = await _dio.post('/chat/completions', data: _body({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...nonEmptyHistory(conversationHistory).map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              }),
        ],
      }));

      final choices = response.data['choices'] as List;
      return choices.first['message']['content'] as String;
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
        '/chat/completions',
        data: _body({
          'model': model,
          'stream': true,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...nonEmptyHistory(conversationHistory).map((m) => {
                  'role': m.role == MessageRole.user ? 'user' : 'assistant',
                  'content': m.content,
                }),
          ],
        }),
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }

    // 멀티바이트 문자가 청크 경계에 걸리면 utf8.decode가 FormatException을 던져
    // 스트림이 통째로 죽는다(한글·일본어는 3바이트라 흔하다).
    // .transform(utf8.decoder)는 안 된다 — Dio 본문은 Stream<Uint8List>라 런타임 타입
    // 검사에서 모든 응답이 TypeError로 끝난다(BUG #13).
    final stream =
        utf8.decoder.bind(response.data.stream as Stream<List<int>>);
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
          final choices = json['choices'] as List;
          final delta = choices.first['delta'] as Map<String, dynamic>;
          final content = delta['content'] as String?;
          if (content != null) yield content;
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

    // post도 try 안에 — 밖에 있으면 네트워크 오류가 호출자로 던져진다.
    try {
      final response = await _dio.post('/chat/completions', data: _body({
        'model': model,
        'messages': [
          {'role': 'system', 'content': LevelPrompt.build(nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)},
          {'role': 'user', 'content': userMessages},
        ],
      }));
      final choices = response.data['choices'] as List;
      return parseLevelAssessment(choices.first['message']['content'] as String);
    } catch (_) {
      return const LevelAssessment.failed();
    }
  }

  @override
  Future<PronunciationResult> evaluatePronunciation({
    required String prompt,
  }) async {
    try {
      final response = await _dio.post('/chat/completions', data: _body({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }));
      final choices = response.data['choices'] as List;
      return PronunciationResult.fromJson(
          extractJson(choices.first['message']['content'] as String));
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
      final response = await _dio.post('/chat/completions', data: _body({
        'model': model,
        'messages': messages,
      }));
      final choices = response.data['choices'] as List;
      return parseSuggestions(choices.first['message']['content'] as String);
    } catch (_) {
      return [];
    }
  }
}
