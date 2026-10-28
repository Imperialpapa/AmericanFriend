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

/// 미사용. AI 턴 종료는 [PipelineEvent]로 전달할 수 없다 —
/// processTextInput의 async* 스트림은 AiResponseComplete 직후 닫히는데
/// 그 시점엔 TtsQueue에 아직 읽을 문장이 남아 있기 때문.
/// 턴 종료는 TtsQueue.stateStream의 TtsQueueState.turnDone으로 관측할 것.
class TtsSpeakingDone extends PipelineEvent {}

// 에러
class PipelineError extends PipelineEvent {
  final Failure failure;
  PipelineError(this.failure);
}
