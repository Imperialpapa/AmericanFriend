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

        if (targetTtsEnabled) {
          final ttsText = nativeTtsEnabled
              ? sentence.trim()
              : sentence
                  .replaceAll(RegExp(r'\s*\([^)]*\)'), '')   // 완전한 괄호 제거
                  .replaceAll(RegExp(r'\s*\([^)]*$'), '')     // 끝에 열린 괄호 제거
                  .replaceAll(RegExp(r'^[^(]*\)\s*'), '')     // 앞에 닫힌 괄호 제거
                  .replaceAll(RegExp(r'\s{2,}'), ' ')
                  .trim();
          if (ttsText.isNotEmpty) {
            yield TtsSpeakingStarted(ttsText);
            await ttsQueue.enqueue(ttsText);
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

  void dispose() {
    _splitter.reset();
  }
}
