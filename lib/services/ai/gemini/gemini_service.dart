import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
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

  // 기본 모델 인자를 두지 않는다 — 카탈로그(ai_provider_type.dart)와 어긋나면 죽은 ID가 남는다.
  // 키는 URL(?key=)이 아니라 헤더로 보낸다. URL은 Dio 오류 문자열·로그에 그대로 찍힌다(S-03).
  GeminiService({required this.apiKey, required this.model})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        ));

  /// 모델별 추가 필드(3.x의 thinkingConfig 등)를 합친 요청 본문.
  /// maxOutputTokens에 thought 토큰이 포함되므로 모든 호출에 적용한다.
  Map<String, dynamic> _body(Map<String, dynamic> body) =>
      withRequestExtras(body, AiProviderType.gemini.requestExtrasFor(model));

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

  static const _blockedFinishReasons = {
    'SAFETY',
    'PROHIBITED_CONTENT',
    'BLOCKLIST',
    'SPII',
  };

  /// SSE data 한 줄에서 텍스트를 꺼낸다. 없으면 null.
  /// 안전 차단(finishReason SAFETY 등, promptFeedback.blockReason)은 던진다 —
  /// 조용히 끝나면 빈 답변이 정상 완료로 저장된다(A-05). 이미 텍스트를
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

    String? text;
    String? blocked;
    final candidates = json['candidates'];
    final first =
        candidates is List && candidates.isNotEmpty ? candidates.first : null;
    if (first is Map) {
      final content = first['content'];
      final parts = content is Map ? content['parts'] : null;
      if (parts is List && parts.isNotEmpty) {
        final part = parts.first;
        final t = part is Map ? part['text'] : null;
        if (t is String) text = t;
      }
      final finish = first['finishReason'];
      if (finish is String && _blockedFinishReasons.contains(finish)) {
        blocked = finish;
      } else if (finish == 'MAX_TOKENS') {
        debugPrint('[Gemini] response truncated (MAX_TOKENS)');
      }
    }
    final feedback = json['promptFeedback'];
    final blockReason = feedback is Map ? feedback['blockReason'] : null;
    if (blockReason != null) blocked ??= '$blockReason';

    if (blocked != null) {
      if (!hasText && (text == null || text.isEmpty)) {
        throw AiResponseBlockedException(blocked);
      }
      debugPrint('[Gemini] response cut by $blocked');
    }
    return text;
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
    // 요청 URL은 붙이지 않는다 — 복사 버튼·logcat으로 그대로 나간다.
    return 'Gemini ($statusCode): ${detail.isNotEmpty ? detail : e.type.name}';
  }

  List<Map<String, dynamic>> _buildContents(
      List<Message> history, String systemPrompt) {
    final contents = <Map<String, dynamic>>[];

    // Gemini는 system instruction을 별도로 처리
    for (final m in nonEmptyHistory(history)) {
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
        '/v1beta/models/$model:generateContent',
        data: _body({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': _buildContents(conversationHistory, systemPrompt),
          'generationConfig': {
            'maxOutputTokens': 1024,
          },
        }),
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
        '/v1beta/models/$model:streamGenerateContent?alt=sse',
        data: _body({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': _buildContents(conversationHistory, systemPrompt),
          'generationConfig': {
            'maxOutputTokens': 1024,
          },
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
        final data = line.substring(6).trim();
        if (data.isEmpty) continue;

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

    try {
      final response = await _postWithRetry(
        '/v1beta/models/$model:generateContent',
        data: _body({
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
        }),
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
  Future<Map<String, dynamic>> evaluatePronunciation({
    required String prompt,
  }) async {
    try {
      final response = await _postWithRetry(
        '/v1beta/models/$model:generateContent',
        data: _body({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
        }),
      );

      final candidates = response.data['candidates'] as List;
      var text = (candidates.first['content']['parts'] as List).first['text'] as String;
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
    final contents = _buildContents(conversationHistory, '');
    contents.add({
      'role': 'user',
      'parts': [
        {'text': SuggestionPrompt.build(userLevel: userLevel, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage, count: count, lastAiMessage: lastAiMessage)}
      ]
    });

    try {
      final response = await _postWithRetry(
        '/v1beta/models/$model:generateContent',
        data: _body({'contents': contents}),
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
