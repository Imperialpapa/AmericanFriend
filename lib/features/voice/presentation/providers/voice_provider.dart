import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:eng_friend/core/error/redact_secrets.dart';
import 'package:eng_friend/features/voice/domain/entities/voice_state.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/audio/audio_focus_service.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

/// 핸즈프리에서 AI 발화 종료 후 마이크를 다시 열기까지의 유예.
/// 스피커 잔향이 마이크로 들어가는 걸 줄이고, 사용자가 숨 고를 틈을 준다.
const _kReArmDelay = Duration(milliseconds: 400);

/// 마이크를 열었는데 아무 말도 안 들어올 때 한 사이클을 끝내는 시간.
const _kNoSpeechTimeout = Duration(seconds: 25);

/// 빈 사이클이 이만큼 연속되면 핸즈프리를 자동 종료 (배터리/오작동 방지).
const _kMaxEmptyCycles = 3;

/// 메시지를 보냈는데 AI 응답이 전혀 진행되지 않을 때의 상한.
/// **AI 스트리밍 활동으로 리셋된다** — TTS 재생으로 리셋하면 대상 언어 TTS를
/// 꺼둔 사용자에게는 리셋 소스가 없어져 정상 응답도 강제 중단된다.
const _kStreamTimeout = Duration(seconds: 30);

/// turnDone 직후 이 시간 안에 들어온 인식 결과는 자기 TTS의 에코일 수 있다.
const _kEchoWindow = Duration(milliseconds: 1500);

/// 핸즈프리에서 침묵 판정 최소 시간. sttPauseSeconds 슬라이더는 0까지 내려가는데
/// 0이면 첫 partial이 오자마자 한 단어를 전송해버린다.
const _kMinHandsFreePauseSec = 2;

/// 사용자가 말하는 중(silence window)에 STT 세션이 끊겼을 때의 재시작 지연.
/// 짧아야 발화가 잘리지 않는다.
const _kSttRestartInUtterance = Duration(milliseconds: 80);

/// 핸즈프리로 그냥 듣고만 있을 때의 재시작 지연. 여기서 짧게 돌면
/// 아무 소득 없이 인식기만 두들기게 되므로 더 여유를 둔다.
const _kSttRestartIdle = Duration(milliseconds: 400);

/// STT 에러 후 재시작 백오프 (지수적으로 증가).
const _kSttErrorBackoffBaseMs = 600;
const _kSttErrorBackoffMaxMs = 5000;

/// STT 에러 예산 — **시간 창 기준**.
/// CRITICAL: "연속 N회"로 세면 안 된다. speech_to_text는 에러와 정상 onStatus를
/// 번갈아 뱉기 때문에, 정상 이벤트가 카운터를 리셋해서 예산이 영원히 차지 않는다
/// (실기기 로그에서 계속 1/5로 찍히며 무한 루프가 유지됨).
/// 대신 짧은 창 안에 에러가 몇 번 났는지로 판단한다.
const _kSttErrorWindow = Duration(seconds: 12);
const _kMaxSttErrorsInWindow = 5;

/// AI 호출이 연속 이만큼 실패하면 핸즈프리를 종료한다.
/// 1회로 끊으면 네트워크가 잠깐 흔들릴 때마다 사용자가 다시 켜야 한다.
const _kMaxConsecutiveChatErrors = 3;

/// 재시작해도 되는(=실패로 치지 않는) STT 에러. "말이 없었다"는 정상 결과다.
const _kBenignSttErrors = {'error_no_match', 'error_speech_timeout'};

/// 계속 듣기(핸즈프리)에서는 정상 부산물인 에러들.
///
/// Samsung 인식기는 침묵 2~3초에 세션을 강제 종료하므로 계속 들으려면 3초마다
/// 세션을 새로 열어야 하고, 그 과정에서 busy/client가 필연적으로 발생한다.
/// 이걸 장애로 세면 정상 동작 중에도 예산이 차서 핸즈프리가 스스로 꺼진다
/// (실기기에서 두 번 재현됨). 백오프만 하고 종료 사유로는 삼지 않는다.
///
/// "정말로 STT가 죽었다"는 판정은 [_kMaxEmptyCycles] × [_kNoSpeechTimeout]
/// (= 75초 동안 한 마디도 인식 못 함)이 담당한다. 그게 옳은 안전망이다.
const _kChurnSttErrors = {'error_busy', 'error_client'};

/// 재시도해도 소용없는 치명적 에러 — 즉시 포기해야 한다.
const _kFatalSttErrors = {
  'error_permission',
  'error_insufficient_permissions',
};

/// VoiceNotifier — STT 침묵 감지를 직접 관리.
///
/// 배경: Android(특히 Samsung 등 한국 OEM)는 SpeechRecognizer의
/// `EXTRA_SPEECH_INPUT_*_SILENCE_LENGTH_MILLIS` 인자를 자체 silence detection으로
/// 덮어쓰는 경우가 흔함. 그래서 `speech_to_text`의 `pauseFor`를 8초로 줘도
/// 2~3초만에 final이 떨어지고 즉시 send되어 사용자가 답변 도중 가로채이는
/// 문제가 발생.
///
/// 우회: STT final을 받아도 즉시 send하지 않고 `_pendingText`에 누적.
/// `sttPauseSeconds` 길이의 silence 타이머를 켠 뒤, 그 사이 STT가 자체
/// 종료되면 자동 재시작해서 추가 발화를 받음. 추가 final이 오면 텍스트
/// 누적 + 타이머 리셋. 타이머 만료 시 누적된 텍스트를 send.
///
/// 핸즈프리 모드: 위 루프를 AI 턴 종료 신호([TtsQueueState.turnDone])와 이어붙여
/// 사용자가 마이크 버튼을 누르지 않아도 대화가 계속 순환하게 한다.
/// 반이중(half-duplex)이다 — AI가 말하는 동안 마이크는 닫힌다.
/// Android SpeechRecognizer는 audio session id를 노출하지 않아 하드웨어 AEC를
/// 붙일 수 없으므로, 마이크를 닫는 것이 에코를 막는 유일하게 확실한 방법이다.
class VoiceNotifier extends StateNotifier<VoiceState> with WidgetsBindingObserver {
  final SpeechToText _stt;
  final TtsQueue _ttsQueue;
  final ChatNotifier _chatNotifier;
  final AudioFocusService _audioFocus;
  final UserSettings Function() _getSettings;

  String _pendingText = '';
  Timer? _silenceTimer;

  StreamSubscription<TtsQueueState>? _ttsSub;
  Timer? _reArmTimer;
  Timer? _noSpeechTimer;
  Timer? _streamWatchdog;
  int _emptyCycles = 0;
  DateTime? _turnDoneAt;
  bool _lifecycleObserverAdded = false;

  Timer? _restartTimer;

  /// 최근 STT 에러 발생 시각. [_kSttErrorWindow] 밖은 버린다.
  final List<DateTime> _recentSttErrors = [];

  /// AI 호출 연속 실패 횟수. 일시적 네트워크 오류로 세션이 즉사하지 않게 한다.
  int _consecutiveChatErrors = 0;

  /// _startSttSession 중복 진입 가드. 겹쳐 부르면 listen()이 쌓여 error_busy가 난다.
  bool _sttStarting = false;

  /// 연속 에러 단계 — 재시작 백오프 계산용. 인식 결과가 오면 0으로 회복.
  int _backoffStep = 0;

  VoiceNotifier(
    this._stt,
    this._ttsQueue,
    this._chatNotifier,
    this._audioFocus, {
    required UserSettings Function() getSettings,
  })  : _getSettings = getSettings,
        super(const VoiceState());

  /// STT 초기화 + TTS 상태 구독
  Future<void> initialize() async {
    final available = await _stt.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _onSttSessionEnded();
        }
      },
      onError: (err) => _onSttSessionEnded(errorMsg: err.errorMsg),
    );
    state = state.copyWith(sttAvailable: available);
    debugPrint('[Voice] STT available=$available');

    // 진단: 기기가 실제로 지원하는 로케일과 우리가 넘기는 코드가 맞는지.
    // 안 맞으면 인식기가 에러 없이 조용히 아무것도 반환하지 않는다.
    if (available) {
      try {
        final wanted = _getSettings().sttLanguage;
        final locales = await _stt.locales();
        final match = locales.where((l) =>
            l.localeId == wanted ||
            l.localeId.replaceAll('_', '-') == wanted.replaceAll('_', '-'));
        debugPrint('[Voice] STT locale wanted=$wanted '
            'match=${match.isEmpty ? "NONE" : match.first.localeId} '
            'total=${locales.length}');
        if (match.isEmpty) {
          debugPrint('[Voice] STT sample locales: '
              '${locales.take(8).map((l) => l.localeId).join(", ")}');
        }
      } catch (e) {
        debugPrint('[Voice] STT locales() failed: $e');
      }
    }

    // CRITICAL: toggleListening()이 sttAvailable==false일 때 initialize()를 다시
    // 부르므로, 구독을 저장하고 재진입 시 취소하지 않으면 마이크를 누를 때마다
    // 리스너가 하나씩 쌓인다.
    await _ttsSub?.cancel();
    _ttsSub = _ttsQueue.stateStream.listen(_onTtsState);

    if (!_lifecycleObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverAdded = true;
    }

    // 전화 수신·알람은 액티비티를 pause시키지 않아 lifecycle로 못 잡는다.
    await _audioFocus.initialize(
      onInterrupted: _onAudioInterrupted,
      onInterruptionEnded: _onAudioInterruptionEnded,
    );
  }

  void _onAudioInterrupted() {
    if (!state.handsFreeActive) return;
    // 통화/알람에 대고 계속 읽지 않도록 TTS부터 끊는다.
    unawaited(_ttsQueue.interrupt());
    unawaited(suspendHandsFree());
  }

  void _onAudioInterruptionEnded() {
    if (!state.handsFreeActive) return;
    unawaited(resumeHandsFree());
  }

  // ---------------------------------------------------------------- TTS 신호

  /// CRITICAL — 오디오 포커스는 **TTS가 말하는 동안에만** 잡는다.
  ///
  /// 핸즈프리 내내 포커스를 들고 있으면, 우리 SpeechRecognizer가 녹음을 시작할 때
  /// 우리가 잡은 미디어 포커스를 스스로 빼앗는다. audio_session은 그걸 외부
  /// 인터럽션으로 보고하고 → suspendHandsFree() → STT 정지 → 포커스 복귀 →
  /// resumeHandsFree() → STT 시작 → 다시 포커스 상실 … 무한 루프가 된다.
  /// (실기기 로그에서 BEGIN/END가 초 단위로 반복되며 인식이 전혀 안 됐음)
  ///
  /// 듣는 동안 전화가 오면 포커스 이벤트는 못 받지만, 통화가 마이크를 가져가므로
  /// STT가 에러를 뱉고 에러 예산에 걸려 핸즈프리가 스스로 멈춘다.
  void _onTtsState(TtsQueueState ttsState) {
    switch (ttsState) {
      case TtsQueueState.speaking:
        if (state.status == VoiceStatus.listening) return; // 듣는 중이면 무시
        _streamWatchdog?.cancel();
        _streamWatchdog = null;
        // 읽어주는 동안만 포커스 확보 → 이때 걸려온 전화를 감지할 수 있다.
        unawaited(_audioFocus.activate());
        setSpeaking();

      case TtsQueueState.turnDone:
        _turnDoneAt = DateTime.now();
        _streamWatchdog?.cancel();
        _streamWatchdog = null;
        // 마이크를 열기 전에 반드시 반납 — 안 하면 위 주석의 자기충돌 루프 발생.
        unawaited(_audioFocus.deactivate());
        if (state.handsFreeRunning) {
          _scheduleReArm();
        } else {
          setIdle();
        }

      case TtsQueueState.idle:
        // 스트리밍 중 문장 사이에 큐가 잠깐 비면 idle이 나간다. 이건 턴 종료가
        // 아니므로 핸즈프리는 무시한다 — turnDone만 신뢰.
        if (state.handsFreeActive) return;
        unawaited(_audioFocus.deactivate());
        if (state.status == VoiceStatus.listening) return;
        setIdle();
    }
  }

  /// 채팅 상태 변화 = AI 스트리밍이 살아있다는 증거. 워치독을 리셋한다.
  /// 에러가 올라오면 핸즈프리를 멈춘다 (무한 재시도 방지).
  void onChatActivity(ChatState chatState) {
    if (!state.handsFreeActive) return;

    if (chatState.error != null) {
      debugPrint('[Voice] chat error (${chatState.errorKind?.name}): '
          '${redactSecrets(chatState.error!)}');

      // 쿼터 소진 / 키 없음은 재시도해도 소용없다 → 즉시 종료.
      final fatal = chatState.errorKind == ChatErrorKind.quota ||
          chatState.errorKind == ChatErrorKind.noKey;
      if (fatal) {
        // 원문(Dio 예외 문자열)을 그대로 넘기지 말 것 — 화면에 덤프된다.
        // 상세 내용은 채팅 에러 배너가 이미 보여준다.
        stopHandsFree(
          errorMessage: chatState.errorKind == ChatErrorKind.quota
              ? 'hands_free_quota'
              : 'hands_free_error',
        );
        return;
      }

      // 네트워크 등 일시적 오류로 세션을 죽이면 사용자가 매번 다시 켜야 한다.
      // 연속 실패가 쌓일 때만 종료하고, 그 전엔 다시 듣기로 돌아간다.
      _consecutiveChatErrors++;
      if (_consecutiveChatErrors >= _kMaxConsecutiveChatErrors) {
        debugPrint('[Voice] chat failing repeatedly — stopping hands-free');
        stopHandsFree(errorMessage: 'hands_free_error');
        return;
      }
      if (state.handsFreeRunning) _scheduleReArm();
      return;
    }

    // 정상 응답이 오면 실패 누적 해제
    if (chatState.isAiTyping || chatState.currentAiResponse.isNotEmpty) {
      _consecutiveChatErrors = 0;
    }

    if (state.status == VoiceStatus.processing && _streamWatchdog != null) {
      _streamWatchdog!.cancel();
      _streamWatchdog = Timer(_kStreamTimeout, _onStreamStalled);
    }
  }

  void _onStreamStalled() {
    _streamWatchdog = null;
    if (!state.handsFreeRunning) return;
    debugPrint('[Voice] stream watchdog fired — re-arming');
    _scheduleReArm();
  }

  // ------------------------------------------------------------- 핸즈프리 제어

  Future<void> startHandsFree() async {
    if (!state.sttAvailable) {
      await initialize();
      if (!state.sttAvailable) {
        state = state.copyWith(voiceError: 'stt_unavailable');
        return;
      }
    }

    _emptyCycles = 0;
    _recentSttErrors.clear();
    _backoffStep = 0;
    _consecutiveChatErrors = 0;
    state = state.copyWith(
      handsFreeActive: true,
      handsFreeSuspended: false,
      clearError: true,
    );
    debugPrint('[Voice] hands-free ON');

    // 여기서 오디오 포커스를 잡으면 안 된다 — _onTtsState 주석 참조.

    // AI가 말하는 중이면 기다린다 — turnDone이 알아서 마이크를 연다.
    if (state.status == VoiceStatus.speaking ||
        state.status == VoiceStatus.processing) {
      return;
    }
    _scheduleReArm();
  }

  Future<void> stopHandsFree({String? errorMessage}) async {
    _cancelHandsFreeTimers();
    _pendingText = '';
    _emptyCycles = 0;
    state = state.copyWith(
      handsFreeActive: false,
      handsFreeSuspended: false,
      status: VoiceStatus.idle,
      partialText: '',
      voiceError: errorMessage,
      clearError: errorMessage == null,
    );
    debugPrint('[Voice] hands-free OFF');
    await _stopStt();
    // 포커스 반납 — 다른 앱이 음악을 다시 틀 수 있게.
    await _audioFocus.deactivate();
  }

  Future<void> toggleHandsFree() async {
    if (state.handsFreeActive) {
      await stopHandsFree();
    } else {
      await startHandsFree();
    }
  }

  /// 발음 연습 시트처럼 다른 화면이 마이크를 가져갈 때 호출.
  Future<void> suspendHandsFree() async {
    if (!state.handsFreeActive || state.handsFreeSuspended) return;
    _cancelHandsFreeTimers();
    _pendingText = '';
    state = state.copyWith(
      handsFreeSuspended: true,
      status: VoiceStatus.idle,
      partialText: '',
    );
    debugPrint('[Voice] hands-free SUSPENDED');
    await _stopStt();
  }

  Future<void> resumeHandsFree() async {
    if (!state.handsFreeActive || !state.handsFreeSuspended) return;
    state = state.copyWith(handsFreeSuspended: false);
    debugPrint('[Voice] hands-free RESUMED');
    _scheduleReArm();
  }

  void _cancelHandsFreeTimers() {
    _restartTimer?.cancel();
    _restartTimer = null;
    _reArmTimer?.cancel();
    _reArmTimer = null;
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
    _streamWatchdog?.cancel();
    _streamWatchdog = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _scheduleReArm() {
    _reArmTimer?.cancel();
    // 이전 사이클이 남긴 재시작 타이머가 새로 연 세션을 죽이지 않도록 함께 취소.
    _restartTimer?.cancel();
    _restartTimer = null;
    state = state.copyWith(status: VoiceStatus.idle, partialText: '');
    _reArmTimer = Timer(_kReArmDelay, () {
      _reArmTimer = null;
      if (!state.handsFreeRunning) return;
      _beginListenCycle();
    });
  }

  Future<void> _beginListenCycle() async {
    if (!state.sttAvailable) return;
    _pendingText = '';
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;

    state = state.copyWith(status: VoiceStatus.listening, partialText: '');

    _noSpeechTimer?.cancel();
    _noSpeechTimer = Timer(_kNoSpeechTimeout, _onNoSpeech);

    await _startSttSession();
  }

  void _onNoSpeech() {
    _noSpeechTimer = null;
    if (!state.handsFreeRunning) return;
    // 말이 들어오는 중이면 종료하지 않는다
    if (_pendingText.trim().isNotEmpty || state.partialText.trim().isNotEmpty) {
      return;
    }

    _emptyCycles++;
    debugPrint('[Voice] empty cycle $_emptyCycles/$_kMaxEmptyCycles');
    _stopStt();

    if (_emptyCycles >= _kMaxEmptyCycles) {
      stopHandsFree(errorMessage: 'hands_free_idle');
      return;
    }
    _scheduleReArm();
  }

  // ------------------------------------------------------------- 수동 마이크

  /// 마이크 토글
  Future<void> toggleListening() async {
    if (!state.sttAvailable) {
      try {
        await initialize();
      } catch (e) {
        // 던지게 두면 버튼이 무반응으로 보인다. 아래 startListening이 안내한다.
        debugPrint('[Voice] STT re-initialize failed: $e');
      }
    }

    if (state.status == VoiceStatus.listening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// 음성 입력 시작
  Future<void> startListening() async {
    if (!state.sttAvailable) {
      // BUG #7: 조용히 return하면 권한 영구 거부·인식기 부재에서 마이크가 그냥
      // 무반응으로 보인다. 핸즈프리와 같은 스낵바(설정 열기 포함)로 알린다.
      state = state.copyWith(voiceError: 'stt_unavailable');
      return;
    }

    // AI가 말하고 있으면 중단 (barge-in)
    if (state.status == VoiceStatus.speaking) {
      await _ttsQueue.interrupt();
      await _chatNotifier.interrupt();
    }

    _pendingText = '';
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _reArmTimer?.cancel();
    _reArmTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    _recentSttErrors.clear();
    _backoffStep = 0;

    state = state.copyWith(
      status: VoiceStatus.listening,
      partialText: '',
    );

    if (state.handsFreeRunning) {
      _noSpeechTimer?.cancel();
      _noSpeechTimer = Timer(_kNoSpeechTimeout, _onNoSpeech);
    }

    await _startSttSession();
  }

  Future<void> _startSttSession() async {
    // CRITICAL: 겹쳐 호출되면 listen()이 쌓여 error_busy가 나고, 그 에러가 다시
    // 재시작을 부르는 폭주 루프가 된다.
    if (_sttStarting) return;
    _sttStarting = true;

    try {
      if (_stt.isListening) {
        await _stopStt();
        // 인식기가 정리될 시간을 준다. 너무 짧으면 곧바로 error_busy.
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final settings = _getSettings();
      await _stt.listen(
        onResult: (result) {
          // 결과가 들어온다 = 인식기가 정상. 예산·백오프 회복.
          _recentSttErrors.clear();
          _backoffStep = 0;

          final live = result.recognizedWords;
          // 콜백이 아예 안 오는 것과 빈 문자열로 오는 것을 구분하기 위해
          // partial도 찍는다 (진단용).
          debugPrint('[Voice] STT ${result.finalResult ? "final" : "partial"}'
              ': "$live"');

          // 핸즈프리: turnDone 직후 창에서 자기 TTS를 되받은 것이면 버린다.
          if (result.finalResult && _isLikelyEcho(live)) {
            debugPrint('[Voice] echo discarded: "$live"');
            return;
          }

          state = state.copyWith(partialText: _composePartial(live));

          if (result.finalResult && live.isNotEmpty) {
            _accumulateFinal(live);
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
        ),
        localeId: settings.sttLanguage,
        pauseFor: Duration(seconds: _effectivePauseSeconds()),
        listenFor: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('[Voice] listen() failed: $e');
      _recentSttErrors.add(DateTime.now());
    } finally {
      _sttStarting = false;
    }
  }

  /// 우리 의도로 STT를 멈춘다.
  /// Android는 stop()에 대해 error_client를 되쏘는데, 그건 [_kChurnSttErrors]로
  /// 분류되어 종료 사유가 되지 않는다.
  Future<void> _stopStt() async => _stt.stop();

  int _effectivePauseSeconds() {
    final raw = _getSettings().sttPauseSeconds;
    if (!state.handsFreeActive) return raw;
    return raw < _kMinHandsFreePauseSec ? _kMinHandsFreePauseSec : raw;
  }

  /// AI가 방금 말한 문장을 마이크가 되받았는지 판별.
  /// 반이중이라 원칙적으론 안 생기지만, 스피커 잔향과 STT 버퍼 지연 때문에
  /// 재무장 직후 짧은 창에서는 실제로 발생한다.
  bool _isLikelyEcho(String text) {
    if (!state.handsFreeActive) return false;
    final at = _turnDoneAt;
    if (at == null) return false;
    if (DateTime.now().difference(at) > _kEchoWindow) return false;

    final spoken = _ttsQueue.lastSpokenText;
    if (spoken == null || spoken.isEmpty) return false;

    final a = _normalizeForEcho(text);
    final b = _normalizeForEcho(spoken);
    if (a.isEmpty || a.length < 4) return false;
    return b.contains(a) || a.contains(b);
  }

  static String _normalizeForEcho(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');

  /// 누적된 _pendingText와 STT 새 세션의 live partial을 합쳐 표시 텍스트 생성.
  /// STT가 자체 종료 후 재시작될 때 같은 발화를 처음부터 재인식하는 OEM 동작 대응 —
  /// live가 _pendingText를 prefix로 포함하면 누적이 아니라 교체.
  String _composePartial(String live) {
    if (_pendingText.isEmpty) return live;
    if (live.isEmpty) return _pendingText;
    if (_isPrefix(live, _pendingText)) return live;
    return '$_pendingText $live';
  }

  void _accumulateFinal(String text) {
    if (text.isEmpty) return;
    if (_pendingText.isEmpty) {
      _pendingText = text;
    } else if (_isPrefix(text, _pendingText)) {
      // STT 재시작이 같은 발화를 처음부터 재인식한 경우 → 누적이 아니라 교체
      _pendingText = text;
    } else {
      _pendingText = '$_pendingText $text';
    }
    state = state.copyWith(partialText: _pendingText);
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
    _emptyCycles = 0;
    _restartSilenceTimer();
  }

  /// candidate가 base를 (대소문자 무시) prefix로 포함하는지
  static bool _isPrefix(String candidate, String base) {
    if (candidate.length < base.length) return false;
    return candidate.toLowerCase().startsWith(base.toLowerCase());
  }

  void _restartSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer =
        Timer(Duration(seconds: _effectivePauseSeconds()), _onSilenceExpired);
  }

  /// silence 타이머 만료 → 누적 텍스트 send
  void _onSilenceExpired() {
    _silenceTimer = null;
    // _pendingText가 비어있더라도 partialText에 인식된 텍스트가 남아있으면 그걸로 fallback
    var text = _pendingText.trim();
    if (text.isEmpty) {
      text = state.partialText.trim();
    }
    _pendingText = '';
    _stopStt();

    if (text.isEmpty) {
      if (state.handsFreeRunning) {
        _scheduleReArm();
      } else {
        state = state.copyWith(status: VoiceStatus.idle, partialText: '');
      }
      return;
    }
    _dispatch(text);
  }

  /// STT 세션이 끝남 — 정상 종료(OEM silence detection / listenFor 만료)이거나 에러.
  /// silence window 안이면 재시작, 핸즈프리면 계속 듣기, 아니면 idle.
  void _onSttSessionEnded({String? errorMsg}) {
    final isChurn = errorMsg != null && _kChurnSttErrors.contains(errorMsg);
    final isError =
        errorMsg != null && !_kBenignSttErrors.contains(errorMsg);
    if (isError) {
      _backoffStep++;
      if (isChurn) {
        // 계속 듣기의 정상 부산물 — 백오프만 하고 종료 사유로 삼지 않는다.
        debugPrint('[Voice] STT churn: $errorMsg (backoff $_backoffStep)');
      } else {
        final now = DateTime.now();
        _recentSttErrors
          ..add(now)
          ..removeWhere((t) => now.difference(t) > _kSttErrorWindow);
        debugPrint('[Voice] STT error: $errorMsg '
            '(${_recentSttErrors.length}/$_kMaxSttErrorsInWindow in ${_kSttErrorWindow.inSeconds}s)');
      }
    }

    // 권한 문제는 재시도해도 소용없다 — 즉시 포기하고 안내한다.
    if (errorMsg != null && _kFatalSttErrors.contains(errorMsg)) {
      debugPrint('[Voice] STT fatal: $errorMsg');
      _restartTimer?.cancel();
      _restartTimer = null;
      if (state.handsFreeActive) {
        stopHandsFree(errorMessage: 'stt_unavailable');
      } else {
        state = state.copyWith(status: VoiceStatus.idle, partialText: '');
      }
      return;
    }

    if (state.status != VoiceStatus.listening) return;

    // CRITICAL: Android OEM(특히 Samsung)은 종종 final result 없이 세션을 끝냄.
    // 이 경우 partialText에는 인식된 텍스트가 있는데 _pendingText는 비어있음 →
    // silence 타이머도 안 시작되어 send가 영영 발생 안 함.
    // 그러므로 STT 종료 시 partialText가 _pendingText보다 길면 그 차이를 final로 간주.
    final fullPartial = state.partialText.trim();
    if (fullPartial.length > _pendingText.length) {
      _pendingText = fullPartial;
      state = state.copyWith(partialText: _pendingText);
      _restartSilenceTimer();
    }

    // 예산은 이제 **churn이 아닌** 에러만 센다. busy/client는 Samsung에서
    // 계속 듣기를 하면 필연적으로 발생하므로, 그걸로 종료하면 정상 동작 중에도 꺼진다.
    // "진짜 STT가 죽었다"는 판정은 _emptyCycles(75초 무인식)가 담당한다.
    if (_recentSttErrors.length >= _kMaxSttErrorsInWindow) {
      debugPrint('[Voice] STT failing repeatedly — giving up');
      _restartTimer?.cancel();
      _restartTimer = null;
      if (state.handsFreeActive) {
        stopHandsFree(errorMessage: 'stt_unavailable');
      } else {
        state = state.copyWith(status: VoiceStatus.idle, partialText: '');
      }
      return;
    }

    final inSilenceWindow = _silenceTimer != null || _pendingText.isNotEmpty;

    // 발화도 없고 핸즈프리도 아니면 기존대로 idle로 떨어진다.
    if (!inSilenceWindow && !state.handsFreeRunning) {
      state = state.copyWith(status: VoiceStatus.idle, partialText: '');
      return;
    }

    _scheduleSttRestart(isError: isError, inUtterance: inSilenceWindow);
  }

  void _scheduleSttRestart({required bool isError, required bool inUtterance}) {
    _restartTimer?.cancel();

    final Duration delay;
    if (isError) {
      final n = _backoffStep.clamp(1, 8);
      final ms = _kSttErrorBackoffBaseMs * (1 << (n - 1));
      delay = Duration(milliseconds: ms.clamp(0, _kSttErrorBackoffMaxMs));
    } else {
      delay = inUtterance ? _kSttRestartInUtterance : _kSttRestartIdle;
    }

    _restartTimer = Timer(delay, () {
      _restartTimer = null;
      if (state.status != VoiceStatus.listening) return;
      final stillWanted =
          _silenceTimer != null || _pendingText.isNotEmpty || state.handsFreeRunning;
      if (!stillWanted) return;
      _startSttSession();
    });
  }

  /// 음성 입력 중지 (사용자가 마이크 버튼 다시 누름)
  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    await _stopStt();

    // partialText에는 누적된 final + 마지막 partial이 합쳐져 있음
    final text = state.partialText.trim().isNotEmpty
        ? state.partialText.trim()
        : _pendingText.trim();
    _pendingText = '';

    if (text.isEmpty) {
      if (state.handsFreeRunning) {
        _scheduleReArm();
      } else {
        state = state.copyWith(status: VoiceStatus.idle, partialText: '');
      }
      return;
    }
    _dispatch(text);
  }

  void _dispatch(String text) {
    final settings = _getSettings();

    // 핸즈프리에서는 자동 전송이 전제다 (버튼을 안 누르는 게 목적이므로).
    if (!state.handsFreeActive && !settings.autoSendVoice) {
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

    if (state.handsFreeActive) {
      _streamWatchdog?.cancel();
      _streamWatchdog = Timer(_kStreamTimeout, _onStreamStalled);
    }

    _chatNotifier.sendMessage(text);

    // 핸즈프리는 turnDone까지 processing을 유지한다. 수동 모드는 기존대로 즉시 idle.
    if (!state.handsFreeActive) {
      state = state.copyWith(status: VoiceStatus.idle);
    }
  }

  /// input bar가 draft를 컨트롤러에 옮긴 뒤 호출하여 비움
  void clearDraft() {
    if (state.recognizedDraft.isNotEmpty) {
      state = state.copyWith(recognizedDraft: '');
    }
  }

  void clearVoiceError() {
    if (state.voiceError != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void setSpeaking() {
    state = state.copyWith(status: VoiceStatus.speaking);
  }

  void setIdle() {
    state = state.copyWith(status: VoiceStatus.idle);
  }

  // ------------------------------------------------------------- 라이프사이클

  // 파라미터명을 state로 두면 StateNotifier.state를 가려서 this.state를 못 읽는다.
  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (!state.handsFreeActive) return;
    if (lifecycleState == AppLifecycleState.resumed) {
      resumeHandsFree();
    } else {
      suspendHandsFree();
    }
  }

  @override
  void dispose() {
    if (_lifecycleObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleObserverAdded = false;
    }
    _cancelHandsFreeTimers();
    _ttsSub?.cancel();
    _stt.stop();
    super.dispose();
  }
}

final speechToTextProvider = Provider<SpeechToText>((ref) => SpeechToText());

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final stt = ref.watch(speechToTextProvider);
  final ttsQueue = ref.watch(ttsQueueProvider);
  final chatNotifier = ref.watch(chatProvider.notifier);
  final audioFocus = ref.watch(audioFocusServiceProvider);
  final notifier = VoiceNotifier(
    stt,
    ttsQueue,
    chatNotifier,
    audioFocus,
    getSettings: () => ref.read(settingsProvider),
  );

  // AI 스트리밍 생존 확인 + 에러 시 핸즈프리 종료
  ref.listen<ChatState>(chatProvider, (_, next) => notifier.onChatActivity(next));

  return notifier;
});
