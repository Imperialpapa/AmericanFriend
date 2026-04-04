enum VoiceStatus { idle, listening, processing, speaking }

class VoiceState {
  final VoiceStatus status;
  final String partialText; // STT 중간 결과
  final bool sttAvailable;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.partialText = '',
    this.sttAvailable = false,
  });

  VoiceState copyWith({
    VoiceStatus? status,
    String? partialText,
    bool? sttAvailable,
  }) {
    return VoiceState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
      sttAvailable: sttAvailable ?? this.sttAvailable,
    );
  }
}
