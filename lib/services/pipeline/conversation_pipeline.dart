import 'dart:async';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/pipeline/pipeline_event.dart';
import 'package:eng_friend/services/pipeline/sentence_splitter.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/core/error/failures.dart';

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

        if (targetTtsEnabled && !sentence.trimLeft().startsWith('💡')) {
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

      yield AiResponseComplete(fullResponse.toString().trim());
    } catch (e) {
      yield PipelineError(GeneralFailure(e.toString()));
    }
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
