import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_json.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/prompts/level_prompts.dart';
import 'package:eng_friend/services/ai/prompts/suggestion_prompt.dart';
import 'package:eng_friend/services/language/app_language.dart';

/// Groq API — OpenAI 호환 포맷, 무료 + 초고속
class GroqService implements AiService {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _baseUrl = 'https://api.groq.com/openai/v1';

  // 기본값은 ai_provider_type.dart의 Groq 첫 항목과 일치시킬 것.
  // llama-3.3-70b-versatile은 2026-06-17 폐기되어 호출 시 404.
  GroqService({required this.apiKey, this.model = 'openai/gpt-oss-120b'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

  /// gpt-oss 계열은 추론 모델이라 기본값이면 답변 전에 수백 토큰을 속으로 생각한다.
  /// 음성 대화에서는 사용자가 말을 마친 뒤의 침묵으로 나타난다.
  /// 실측(2026-08-18): 기본 110토큰/0.237s → effort=low 26토큰/0.086s.
  Map<String, dynamic> get _reasoningParams =>
      model.contains('gpt-oss') ? const {'reasoning_effort': 'low'} : const {};

  String _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return 'Invalid Groq API key. Please check in Settings.';
    } else if (statusCode == 429) {
      return 'Groq rate limit exceeded. Please try again later.';
    }
    return 'Groq API error ($statusCode): ${e.message}';
  }

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          ..._reasoningParams,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...nonEmptyHistory(conversationHistory).map(
              (m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              },
            ),
          ],
        },
      );

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
        data: {
          'model': model,
          ..._reasoningParams,
          'stream': true,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...nonEmptyHistory(conversationHistory).map(
              (m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              },
            ),
          ],
        },
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }

    // 멀티바이트 문자가 청크 경계에 걸리면 utf8.decode가 FormatException을 던져
    // 스트림이 통째로 죽는다(한글·일본어는 3바이트라 흔하다).
    final stream = (response.data.stream as Stream<List<int>>).transform(
      utf8.decoder,
    );
    String buffer = '';

    await for (final chunk in stream) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data.trim() == '[DONE]') return;

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

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          ..._reasoningParams,
          'messages': [
            {
              'role': 'system',
              'content': LevelPrompt.build(
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
              ),
            },
            {'role': 'user', 'content': userMessages},
          ],
        },
      );

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
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          ..._reasoningParams,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final choices = response.data['choices'] as List;
      return PronunciationResult.fromJson(
        extractJson(choices.first['message']['content'] as String),
      );
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
        .map(
          (m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    messages.add({
      'role': 'user',
      'content': SuggestionPrompt.build(
        userLevel: userLevel,
        nativeLanguage: nativeLanguage,
        targetLanguage: targetLanguage,
        count: count,
        lastAiMessage: lastAiMessage,
      ),
    });

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {'model': model, ..._reasoningParams, 'messages': messages},
      );

      final choices = response.data['choices'] as List;
      return parseSuggestions(choices.first['message']['content'] as String);
    } catch (_) {
      return [];
    }
  }
}
