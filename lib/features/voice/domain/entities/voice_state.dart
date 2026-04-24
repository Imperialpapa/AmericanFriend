enum VoiceStatus { idle, listening, processing, speaking }

class VoiceState {
  final VoiceStatus status;
  final String partialText; // STT 중간 결과
  final bool sttAvailable;

  /// 자동 전송이 OFF일 때, 인식 완료된 텍스트가 여기에 들어가서 input bar로 전달됨.
  /// input bar가 컨트롤러에 채운 후 clearDraft()로 비워야 함.
  final String recognizedDraft;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.partialText = '',
    this.sttAvailable = false,
    this.recognizedDraft = '',
  });

  VoiceState copyWith({
    VoiceStatus? status,
    String? partialText,
    bool? sttAvailable,
    String? recognizedDraft,
  }) {
    return VoiceState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
      sttAvailable: sttAvailable ?? this.sttAvailable,
      recognizedDraft: recognizedDraft ?? this.recognizedDraft,
    );
  }
}
