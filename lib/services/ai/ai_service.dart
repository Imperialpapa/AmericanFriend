import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/language/app_language.dart';

/// 내용이 빈 메시지를 뺀 대화 히스토리. 모든 서비스의 요청 빌더가 거친다.
/// Anthropic은 빈 content가 하나라도 섞이면 400을 돌려, 빈 답변 한 번 뒤로
/// 앱을 재시작할 때까지 모든 턴이 실패했다(tobe A-05).
Iterable<Message> nonEmptyHistory(Iterable<Message> history) =>
    history.where((m) => m.content.trim().isNotEmpty);

/// 제공자가 답변을 막았다(Gemini finishReason SAFETY 등).
/// 조용히 끝내면 빈 답변과 구분이 안 되고, 다시 보내도 같은 결과라 따로 올린다.
class AiResponseBlockedException implements Exception {
  final String reason;
  const AiResponseBlockedException(this.reason);

  @override
  String toString() => 'AI response blocked ($reason)';
}

/// AI 서비스 추상 인터페이스
/// Claude, OpenAI 등 구체 구현체가 이 인터페이스를 구현한다.
abstract class AiService {
  /// 메시지 전송 + 전체 응답 수신
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  });

  /// 스트리밍 응답 (토큰 단위)
  Stream<String> streamMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  });

  /// 사용자 레벨 평가. 던지지 않는다 — 실패는 [LevelAssessment.failed].
  Future<LevelAssessment> assessLevel({
    required List<Message> recentMessages,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
  });

  /// 발음 평가. 실패(네트워크·파싱)는 던진다 — 0점으로 위장하지 않는다.
  Future<PronunciationResult> evaluatePronunciation({
    required String prompt,
  });

  /// 대화 제안 생성. 던지지 않는다 — 실패는 빈 목록.
  Future<List<Suggestion>> generateSuggestions({
    required List<Message> conversationHistory,
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
    String? lastAiMessage,
  });
}
