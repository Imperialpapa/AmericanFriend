import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:eng_friend/features/voice/domain/entities/voice_state.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

class VoiceNotifier extends StateNotifier<VoiceState> {
  final SpeechToText _stt;
  final TtsQueue _ttsQueue;
  final ChatNotifier _chatNotifier;
  final UserSettings Function() _getSettings;

  VoiceNotifier(
    this._stt,
    this._ttsQueue,
    this._chatNotifier, {
    required UserSettings Function() getSettings,
  })  : _getSettings = getSettings,
        super(const VoiceState());

  /// STT 초기화 + TTS 상태 구독
  Future<void> initialize() async {
    final available = await _stt.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _onListeningDone();
        }
      },
    );
    state = state.copyWith(sttAvailable: available);

    // TTS 재생 상태 구독 → barge-in 및 UI 상태 반영
    _ttsQueue.stateStream.listen((ttsState) {
      if (state.status == VoiceStatus.listening) return; // 듣는 중이면 무시
      if (ttsState == TtsQueueState.speaking) {
        setSpeaking();
      } else {
        setIdle();
      }
    });
  }

  /// 마이크 토글
  Future<void> toggleListening() async {
    // 아직 초기화 안 됐으면 자동 초기화
    if (!state.sttAvailable) {
      await initialize();
    }

    if (state.status == VoiceStatus.listening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// 음성 입력 시작
  Future<void> startListening() async {
    if (!state.sttAvailable) return;

    // AI가 말하고 있으면 중단 (barge-in)
    if (state.status == VoiceStatus.speaking) {
      await _ttsQueue.interrupt();
      await _chatNotifier.interrupt();
    }

    state = state.copyWith(
      status: VoiceStatus.listening,
      partialText: '',
    );

    final settings = _getSettings();
    await _stt.listen(
      onResult: (result) {
        state = state.copyWith(partialText: result.recognizedWords);

        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _sendRecognizedText(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
      localeId: settings.sttLanguage,
      pauseFor: Duration(seconds: settings.sttPauseSeconds),
      listenFor: const Duration(seconds: 60),
    );
  }

  /// 음성 입력 중지
  Future<void> stopListening() async {
    await _stt.stop();
    if (state.partialText.isNotEmpty) {
      _sendRecognizedText(state.partialText);
    }
  }

  void _onListeningDone() {
    if (state.status == VoiceStatus.listening) {
      state = state.copyWith(status: VoiceStatus.idle);
    }
  }

  void _sendRecognizedText(String text) {
    final settings = _getSettings();
    if (!settings.autoSendVoice) {
      // 자동 전송 OFF — input bar가 채울 수 있도록 draft에 보관
      state = state.copyWith(
        status: VoiceStatus.idle,
        partialText: '',
        recognizedDraft: text,
      );
      return;
    }
    state = state.copyWith(
      status: VoiceStatus.processing,
      partialText: '',
    );
    _chatNotifier.sendMessage(text);
    state = state.copyWith(status: VoiceStatus.idle);
  }

  /// input bar가 draft를 컨트롤러에 옮긴 뒤 호출하여 비움
  void clearDraft() {
    if (state.recognizedDraft.isNotEmpty) {
      state = state.copyWith(recognizedDraft: '');
    }
  }

  void setSpeaking() {
    state = state.copyWith(status: VoiceStatus.speaking);
  }

  void setIdle() {
    state = state.copyWith(status: VoiceStatus.idle);
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }
}

final speechToTextProvider = Provider<SpeechToText>((ref) => SpeechToText());

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final stt = ref.watch(speechToTextProvider);
  final ttsQueue = ref.watch(ttsQueueProvider);
  final chatNotifier = ref.watch(chatProvider.notifier);
  return VoiceNotifier(
    stt,
    ttsQueue,
    chatNotifier,
    getSettings: () => ref.read(settingsProvider),
  );
});
