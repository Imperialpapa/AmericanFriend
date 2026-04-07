import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/prompts/level_prompts.dart';
import 'package:eng_friend/services/ai/prompts/suggestion_prompt.dart';
import 'package:eng_friend/services/language/app_language.dart';

class GeminiService implements AiService {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _baseUrl = 'https://generativelanguage.googleapis.com';
  static const _maxRetries = 3;

  GeminiService({required this.apiKey, this.model = 'gemini-2.5-flash'})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ));

  /// 429 발생 시 exponential backoff 재시도
  Future<Response> _postWithRetry(
    String path, {
    required Map<String, dynamic> data,
    Options? options,
  }) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _dio.post(path, data: data, options: options);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429 && attempt < _maxRetries - 1) {
          final waitSeconds = 2 << attempt; // 2s, 4s, 8s
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Gemini: max retries exceeded');
  }

  String _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final detail = (body is Map)
        ? (body['error']?['message'] ?? '').toString()
        : '';

    if (statusCode == 400 && detail.contains('API_KEY')) {
      return 'Invalid Gemini API key. Please check in Settings.';
    } else if (statusCode == 400) {
      return 'Gemini request error: $detail';
    } else if (statusCode == 403) {
      return 'Gemini API access denied. Please check key permissions.\n$detail';
    } else if (statusCode == 429) {
      return 'Gemini rate limit exceeded. Please try again later.\n$detail';
    }
    final url = e.requestOptions.uri.toString();
    return 'Gemini ($statusCode): $detail\nURL: $url';
  }

  List<Map<String, dynamic>> _buildContents(
      List<Message> history, String systemPrompt) {
    final contents = <Map<String, dynamic>>[];

    // Gemini는 system instruction을 별도로 처리
    for (final m in history) {
      contents.add({
        'role': m.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': m.content}
        ],
      });
    }
    return contents;
  }

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) async {
    try {
      final response = await _postWithRetry(
        '/v1beta/models/$model:generateContent?key=$apiKey',
        data: {
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': _buildContents(conversationHistory, systemPrompt),
          'generationConfig': {
            'maxOutputTokens': 1024,
          },
        },
      );

      final candidates = response.data['candidates'] as List;
      final parts = candidates.first['content']['parts'] as List;
      return parts.first['text'] as String;
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
      response = await _postWithRetry(
        '/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey',
        data: {
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': _buildContents(conversationHistory, systemPrompt),
          'generationConfig': {
            'maxOutputTokens': 1024,
          },
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
        final data = line.substring(6).trim();
        if (data.isEmpty) continue;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final candidates = json['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) continue;
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts == null || parts.isEmpty) continue;
          final text = parts.first['text'] as String?;
          if (text != null) yield text;
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
      final response = await _postWithRetry(
        '/v1beta/models/$model:generateContent?key=$apiKey',
        data: {
          'system_instruction': {
            'parts': [
              {'text': LevelPrompt.build(nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': userMessages}
              ]
            }
          ],
        },
      );

      final candidates = response.data['candidates'] as List;
      var text = (candidates.first['content']['parts'] as List).first['text'] as String;
      text = text.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();
      final json = jsonDecode(text) as Map<String, dynamic>;
      return LevelAssessment(
        currentLevel: 0,
        suggestedLevel: json['suggestedLevel'] as int,
        reasoning: json['reasoning'] as String? ?? '',
      );
    } catch (_) {
      return const LevelAssessment(
          currentLevel: 0, suggestedLevel: 5, reasoning: 'Assessment failed');
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
    final contents = _buildContents(conversationHistory, '');
    contents.add({
      'role': 'user',
      'parts': [
        {'text': SuggestionPrompt.build(userLevel: userLevel, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage, count: count, lastAiMessage: lastAiMessage)}
      ]
    });

    try {
      final response = await _postWithRetry(
        '/v1beta/models/$model:generateContent?key=$apiKey',
        data: {'contents': contents},
      );

      final candidates = response.data['candidates'] as List;
      var text = (candidates.first['content']['parts'] as List).first['text'] as String;
      // Gemini가 ```json ... ``` 코드블록으로 감싸는 경우 제거
      text = text.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();
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
