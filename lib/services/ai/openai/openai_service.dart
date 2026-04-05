import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/prompts/level_prompts.dart';
import 'package:eng_friend/services/ai/prompts/suggestion_prompt.dart';
import 'package:eng_friend/services/language/app_language.dart';

class OpenAiService implements AiService {
  final String apiKey;
  final Dio _dio;

  static const _baseUrl = 'https://api.openai.com/v1';
  static const _model = 'gpt-4o';

  OpenAiService({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

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
      final response = await _dio.post('/chat/completions', data: {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...conversationHistory.map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              }),
        ],
      });

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
          'model': _model,
          'stream': true,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...conversationHistory.map((m) => {
                  'role': m.role == MessageRole.user ? 'user' : 'assistant',
                  'content': m.content,
                }),
          ],
        },
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
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

    final response = await _dio.post('/chat/completions', data: {
      'model': _model,
      'messages': [
        {'role': 'system', 'content': LevelPrompt.build(nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)},
        {'role': 'user', 'content': userMessages},
      ],
    });

    final choices = response.data['choices'] as List;
    final text = choices.first['message']['content'] as String;

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
  Future<List<Suggestion>> generateSuggestions({
    required List<Message> conversationHistory,
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
  }) async {
    final messages = conversationHistory
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    messages.add({
      'role': 'user',
      'content': SuggestionPrompt.build(userLevel: userLevel, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage, count: count),
    });

    final response = await _dio.post('/chat/completions', data: {
      'model': _model,
      'messages': messages,
    });

    final choices = response.data['choices'] as List;
    final text = choices.first['message']['content'] as String;

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
