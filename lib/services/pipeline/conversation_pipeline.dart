import 'dart:async';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/pipeline/pipeline_event.dart';
import 'package:eng_friend/services/pipeline/sentence_splitter.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/core/error/failures.dart';

/// 대화 루프를 총괄하는 파이프라인 오케스트레이터
/// 텍스트/음성 입력 → AI 스트리밍 → 문장 분리 → TTS 순차 재생
class ConversationPipeline {
  final AiService aiService;
  final TtsQueue ttsQueue;
  final SentenceSplitter _splitter = SentenceSplitter();

  ConversationPipeline({
    required this.aiService,
    required this.ttsQueue,
  });

  /// 텍스트 입력 → AI 스트리밍 → 문장별 TTS
  Stream<PipelineEvent> processTextInput({
    required String text,
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) async* {
    try {
      // AI 스트리밍 시작
      final tokenStream = aiService.streamMessage(
        conversationHistory: conversationHistory,
        systemPrompt: systemPrompt,
        userLevel: userLevel,
      );

      // 토큰을 모아서 화면 표시 + 문장 단위로 TTS
      final fullResponse = StringBuffer();
      final sentenceStream = _splitter.split(tokenStream);

      await for (final sentence in sentenceStream) {
        fullResponse.write('$sentence ');

        // 화면에 문장 표시
        yield AiSentenceComplete(sentence);

        // 한글 번역 괄호 제거 + 잔여 한글 문자 제거 후 영어만 TTS 재생
        final englishOnly = sentence
            .replaceAll(RegExp(r'\s*\([^)]*[가-힣]+[^)]*\)'), '')
            .replaceAll(RegExp(r'[가-힣ㄱ-ㅎㅏ-ㅣ]+'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();
        if (englishOnly.isNotEmpty) {
          yield TtsSpeakingStarted(englishOnly);
          await ttsQueue.enqueue(englishOnly);
        }
      }

      yield AiResponseComplete(fullResponse.toString().trim());
    } catch (e) {
      yield PipelineError(GeneralFailure(e.toString()));
    }
  }

  /// 사용자 끼어들기 - TTS 중단
  Future<void> interrupt() async {
    await ttsQueue.interrupt();
    _splitter.reset();
  }

  void dispose() {
    _splitter.reset();
  }
}
