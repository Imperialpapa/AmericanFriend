import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_json.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/prompts/level_prompts.dart';
import 'package:eng_friend/services/ai/prompts/suggestion_prompt.dart';
import 'package:eng_friend/services/language/app_language.dart';

/// 일일 한도 초과 시 throw.
/// UI에서 catch 하여 "API 키 등록" 모달 유도.
class FreeTierRateLimitException implements Exception {
  final int limit;
  final int used;
  final String? resetAt;

  const FreeTierRateLimitException({
    required this.limit,
    required this.used,
    this.resetAt,
  });

  @override
  String toString() =>
      'Daily free limit reached ($used/$limit). Resets at ${resetAt ?? "UTC midnight"}.';
}

/// 무료 티어 프록시/업스트림 장애.
///
/// 사용자 잘못이 아니고 재시도해도 대개 소용없다. 본인 API 키를 등록하면 즉시 우회 가능.
/// (BUG_HISTORY #9: 제공사가 모델을 셧다운해 프록시가 404를 뱉은 사례)
class FreeTierUnavailableException implements Exception {
  final int? statusCode;
  final bool isNetwork;

  /// 사용자에게 보여줄 문구가 아니라, 문의·진단용 원문.
  final String technicalDetail;

  const FreeTierUnavailableException({
    required this.technicalDetail,
    this.statusCode,
    this.isNetwork = false,
  });

  @override
  String toString() => technicalDetail;
}

/// 프록시를 통한 무료 티어 AI 서비스.
/// Groq와 같은 OpenAI 호환 스키마를 쓰지만, 인증은 deviceId 헤더.
class FreeTierAiService implements AiService {
  final String baseUrl;
  final String deviceId;
  final Dio _dio;

  FreeTierAiService({required this.baseUrl, required this.deviceId})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'x-device-id': deviceId,
            'Content-Type': 'application/json',
            'User-Agent': 'KoreanFriend/${AppConstants.appVersion}',
          },
        ));

  FreeTierRateLimitException? _rateLimitFrom(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode != 429) return null;
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['code'] == 'rate_limit_exceeded') {
        return FreeTierRateLimitException(
          limit: (err['limit'] as num?)?.toInt() ?? 20,
          used: (err['used'] as num?)?.toInt() ?? 20,
          resetAt: err['resetAt'] as String?,
        );
      }
    }
    return const FreeTierRateLimitException(limit: 20, used: 20);
  }

  Never _throwError(DioException e) {
    final rl = _rateLimitFrom(e);
    if (rl != null) throw rl;

    final offline = switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        true,
      _ => false,
    };

    // 원문(technicalDetail)은 버리지 않는다 — UI는 친절한 문구를 보여주되
    // "복사" 버튼으로 원문을 넘겨야 사용자가 문의할 때 진단이 가능하다.
    throw FreeTierUnavailableException(
      statusCode: e.response?.statusCode,
      isNetwork: offline,
      technicalDetail: 'Free tier error (${e.response?.statusCode}): '
          '${e.message ?? e.type.name}',
    );
  }

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) async {
    try {
      final response = await _dio.post('/api/v1/chat/completions', data: {
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...nonEmptyHistory(conversationHistory).map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              }),
        ],
      });
      final choices = response.data['choices'] as List;
      return choices.first['message']['content'] as String;
    } on DioException catch (e) {
      _throwError(e);
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
        '/api/v1/chat/completions',
        data: {
          'stream': true,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...nonEmptyHistory(conversationHistory).map((m) => {
                  'role': m.role == MessageRole.user ? 'user' : 'assistant',
                  'content': m.content,
                }),
          ],
        },
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      _throwError(e);
    }

    // 멀티바이트 문자가 청크 경계에 걸리면 utf8.decode가 FormatException을 던져
    // 스트림이 통째로 죽는다(한글·일본어는 3바이트라 흔하다).
    // 스트리밍 디코더는 경계를 넘어 이어붙여 준다.
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
      final response = await _dio.post('/api/v1/chat/completions', data: {
        'messages': [
          {
            'role': 'system',
            'content': LevelPrompt.build(
                nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)
          },
          {'role': 'user', 'content': userMessages},
        ],
      });
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
      final response = await _dio.post('/api/v1/chat/completions', data: {
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      });
      final choices = response.data['choices'] as List;
      return PronunciationResult.fromJson(
          extractJson(choices.first['message']['content'] as String));
    } on DioException catch (e) {
      _throwError(e);
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
      'content': SuggestionPrompt.build(
          userLevel: userLevel,
          nativeLanguage: nativeLanguage,
          targetLanguage: targetLanguage,
          count: count,
          lastAiMessage: lastAiMessage),
    });

    try {
      final response = await _dio.post('/api/v1/chat/completions', data: {
        'messages': messages,
      });
      final choices = response.data['choices'] as List;
      return parseSuggestions(choices.first['message']['content'] as String);
    } catch (_) {
      return [];
    }
  }

  /// 현재 사용량 조회 (증가 없음). UI에 "X / 20 free" 표시용.
  Future<FreeTierQuota?> fetchQuota() async {
    try {
      final response = await _dio.get('/api/v1/quota');
      final data = response.data as Map<String, dynamic>;
      return FreeTierQuota(
        limit: (data['limit'] as num).toInt(),
        remaining: (data['remaining'] as num).toInt(),
        used: (data['used'] as num).toInt(),
        resetAt: data['resetAt'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class FreeTierQuota {
  final int limit;
  final int remaining;
  final int used;
  final String? resetAt;

  const FreeTierQuota({
    required this.limit,
    required this.remaining,
    required this.used,
    this.resetAt,
  });
}
