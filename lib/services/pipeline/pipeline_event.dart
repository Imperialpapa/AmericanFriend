import 'package:eng_friend/core/error/failures.dart';

sealed class PipelineEvent {}

// STT 단계
class SttPartialResult extends PipelineEvent {
  final String partial;
  SttPartialResult(this.partial);
}

class SttFinalResult extends PipelineEvent {
  final String text;
  SttFinalResult(this.text);
}

// AI 단계
class AiTokenReceived extends PipelineEvent {
  final String token;
  AiTokenReceived(this.token);
}

class AiSentenceComplete extends PipelineEvent {
  final String sentence;
  AiSentenceComplete(this.sentence);
}

class AiResponseComplete extends PipelineEvent {
  final String fullResponse;
  AiResponseComplete(this.fullResponse);
}

// TTS 단계
class TtsSpeakingStarted extends PipelineEvent {
  final String sentence;
  TtsSpeakingStarted(this.sentence);
}

class TtsSpeakingDone extends PipelineEvent {}

// 에러
class PipelineError extends PipelineEvent {
  final Failure failure;
  PipelineError(this.failure);
}
