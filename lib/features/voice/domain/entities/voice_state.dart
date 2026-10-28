enum VoiceStatus { idle, listening, processing, speaking }

class VoiceState {
  final VoiceStatus status;
  final String partialText; // STT 중간 결과
  final bool sttAvailable;

  /// 자동 전송이 OFF일 때, 인식 완료된 텍스트가 여기에 들어가서 input bar로 전달됨.
  /// input bar가 컨트롤러에 채운 후 clearDraft()로 비워야 함.
  final String recognizedDraft;

  /// 핸즈프리 세션이 실제로 도는 중인지. **런타임 세션 플래그**이며
  /// UserSettings의 저장된 선호와 별개다 — voiceProvider가 ttsQueueProvider를
  /// watch하므로 TTS가 재생성되면 VoiceNotifier가 초기 상태로 리셋되는데,
  /// 그때 저장된 설정만 보고 있으면 세션이 조용히 죽는지 살았는지 알 수 없다.
  final bool handsFreeActive;

  /// 앱이 백그라운드로 갔거나 다른 화면이 마이크를 가져가서 일시중지된 상태.
  /// handsFreeActive는 true로 유지되므로 복귀 시 자동 재개된다.
  final bool handsFreeSuspended;

  /// STT 초기화 실패 등 사용자에게 보여야 하는 음성 오류. UI가 표시 후 clear.
  final String? voiceError;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.partialText = '',
    this.sttAvailable = false,
    this.recognizedDraft = '',
    this.handsFreeActive = false,
    this.handsFreeSuspended = false,
    this.voiceError,
  });

  /// 핸즈프리가 켜져 있고 일시중지도 아닌, 실제로 루프가 도는 상태
  bool get handsFreeRunning => handsFreeActive && !handsFreeSuspended;

  VoiceState copyWith({
    VoiceStatus? status,
    String? partialText,
    bool? sttAvailable,
    String? recognizedDraft,
    bool? handsFreeActive,
    bool? handsFreeSuspended,
    String? voiceError,

    /// voiceError를 null로 되돌릴 때 사용 (`??` 패턴으로는 불가능)
    bool clearError = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
      sttAvailable: sttAvailable ?? this.sttAvailable,
      recognizedDraft: recognizedDraft ?? this.recognizedDraft,
      handsFreeActive: handsFreeActive ?? this.handsFreeActive,
      handsFreeSuspended: handsFreeSuspended ?? this.handsFreeSuspended,
      voiceError: clearError ? null : (voiceError ?? this.voiceError),
    );
  }
}
