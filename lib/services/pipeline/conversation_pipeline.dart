import 'dart:async';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/services/ai/ai_service.dart'
    show AiService, AiResponseBlockedException;
import 'package:eng_friend/services/ai/free_tier/free_tier_ai_service.dart'
    show FreeTierRateLimitException, FreeTierUnavailableException;
import 'package:eng_friend/services/pipeline/pipeline_event.dart';
import 'package:eng_friend/services/pipeline/sentence_splitter.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/core/error/failures.dart';
import 'package:eng_friend/core/error/redact_secrets.dart';

class ConversationPipeline {
  final AiService aiService;
  final TtsQueue ttsQueue;
  final SentenceSplitter _splitter = SentenceSplitter();

  ConversationPipeline({
    required this.aiService,
    required this.ttsQueue,
  });

  Stream<PipelineEvent> processTextInput({
    required String text,
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
    bool targetTtsEnabled = true,
    bool nativeTtsEnabled = false,
  }) async* {
    final turnId = ttsQueue.beginTurn();
    var turnCompleted = false;
    try {
      final tokenStream = aiService.streamMessage(
        conversationHistory: conversationHistory,
        systemPrompt: systemPrompt,
        userLevel: userLevel,
      );

      final fullResponse = StringBuffer();
      final sentenceStream = _splitter.split(tokenStream);

      await for (final sentence in sentenceStream) {
        fullResponse.write('$sentence ');
        yield AiSentenceComplete(sentence);

        final trimmedLeft = sentence.trimLeft();
        if (targetTtsEnabled &&
            !trimmedLeft.startsWith('💡') &&
            !trimmedLeft.startsWith('💬')) {
          final ttsText = nativeTtsEnabled
              ? sentence.trim()
              : sentence
                  .replaceAll(RegExp(r'\s*\([^)]*\)'), '')   // 완전한 괄호 제거
                  .replaceAll(RegExp(r'\s*\([^)]*$'), '')     // 끝에 열린 괄호 제거
                  .replaceAll(RegExp(r'^[^(]*\)\s*'), '')     // 앞에 닫힌 괄호 제거
                  .replaceAll(RegExp(r'\s{2,}'), ' ')
                  .trim();
          final cleanTts = _stripSpecialChars(ttsText);
          if (cleanTts.isNotEmpty) {
            yield TtsSpeakingStarted(cleanTts);
            await ttsQueue.enqueue(cleanTts);
          }
        }
      }

      // 빈 답변을 정상 완료로 올리면 빈 assistant 메시지가 히스토리에 남아
      // 이후 Claude 요청이 매 턴 400이 된다(A-05). 오류로 올리고 저장하지 않는다.
      final text = fullResponse.toString().trim();
      if (text.isEmpty) {
        yield PipelineError(const EmptyResponseFailure('Empty AI response'));
      } else {
        yield AiResponseComplete(text);
      }
      turnCompleted = true;
    } catch (e) {
      yield PipelineError(_toFailure(e));
      turnCompleted = true; // 실패도 "AI가 더 말할 게 없다" = 턴 종료
    } finally {
      // CRITICAL: 이 메서드는 async* 제너레이터고, ChatNotifier는 barge-in마다
      // (chat_provider.dart:254) 그리고 매 sendMessage 직전에(:187) 구독을 취소한다.
      // async* 구독 취소는 예외가 아니라서 catch도, await for 이후 코드도 실행되지
      // 않는다 — 오직 finally만 돈다. 턴 종료 신호를 루프 뒤나 catch에 두면
      // 사용자가 말을 끊을 때마다(정상 경로다) 핸즈프리 루프가 멈춘다.
      //
      // 취소된 턴은 turnCompleted가 false라 센티넬을 보내지 않는다. barge-in 시엔
      // 사용자가 이미 말하는 중이므로 마이크를 다시 열면 안 되기 때문.
      if (turnCompleted) {
        ttsQueue.markTurnEnd(turnId);
      }
    }
  }

  /// 예외를 타입 있는 Failure로 옮긴다.
  /// e.toString()으로 뭉개면 상위(ChatState → VoiceNotifier)에서 쿼터 소진과
  /// 네트워크 오류를 구분할 방법이 영문 메시지 부분 문자열 매칭밖에 없어진다.
  static Failure _toFailure(Object e) {
    if (e is FreeTierRateLimitException) {
      return RateLimitFailure(
        e.toString(),
        limit: e.limit,
        used: e.used,
        resetAt: e.resetAt,
      );
    }
    if (e is AiResponseBlockedException) {
      return EmptyResponseFailure(e.toString());
    }
    if (e is FreeTierUnavailableException) {
      return FreeTierUnavailableFailure(
        redactSecrets(e.technicalDetail),
        statusCode: e.statusCode,
        isNetwork: e.isNetwork,
      );
    }
    // 원문은 '복사' 버튼·debugPrint로 나간다. 키가 섞였을 수 있으니 여기서 가린다.
    return GeneralFailure(redactSecrets(e.toString()));
  }

  Future<void> interrupt() async {
    await ttsQueue.interrupt();
    _splitter.reset();
  }

  static final _specialCharPattern = RegExp(
    r'[\u{1F000}-\u{1FFFF}]|'  // 이모지
    r'[\u{2600}-\u{27BF}]|'    // 기호 & 딩뱃
    r'[\u{FE00}-\u{FE0F}]|'    // 변형 선택자
    r'[\u{200D}]|'              // Zero width joiner
    r'[→←↑↓↔↕]|'               // 화살표
    r'[*_~`]',                  // 마크다운 서식
    unicode: true,
  );

  static String _stripSpecialChars(String text) {
    return text
        .replaceAll(_specialCharPattern, '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  void dispose() {
    _splitter.reset();
  }
}
