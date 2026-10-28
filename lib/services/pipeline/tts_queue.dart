import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// [idle]      — 큐가 비어 재생할 게 없음. **AI 턴이 끝났다는 뜻이 아니다.**
///               AI 응답은 문장 단위로 스트리밍되므로, 문장 n을 다 읽었는데
///               문장 n+1이 아직 안 왔으면 큐가 잠깐 비어 idle이 나간다.
/// [speaking]  — 문장 재생 중.
/// [turnDone]  — **AI 턴 전체가 끝났고 마지막 문장까지 다 읽었다.**
///               핸즈프리 모드가 마이크를 다시 열 시점은 오직 이 신호다.
enum TtsQueueState { idle, speaking, turnDone }

/// 큐 항목. 일반 문장이거나, 턴 종료를 표시하는 센티넬.
class _TtsItem {
  final String? text;

  /// null이 아니면 턴 종료 센티넬이며, 값은 그 턴의 id.
  final int? turnEndId;

  const _TtsItem.text(String this.text) : turnEndId = null;
  const _TtsItem.turnEnd(int this.turnEndId) : text = null;

  bool get isTurnEnd => turnEndId != null;
}

/// 문장을 순서대로 TTS 재생하는 큐.
///
/// 턴 경계: [beginTurn]으로 턴을 열고 [markTurnEnd]로 센티넬을 큐 끝에 넣는다.
/// 센티넬이 재생 순서상 자기 차례가 되면 [TtsQueueState.turnDone]이 방출된다.
/// 즉 "AI가 할 말을 다 했고 스피커도 조용해졌다"가 한 이벤트로 표현된다.
class TtsQueue {
  final FlutterTts _tts;
  final Queue<_TtsItem> _queue = Queue();
  final _stateController = StreamController<TtsQueueState>.broadcast();
  bool _isSpeaking = false;

  /// 단조 증가 턴 id. [interrupt]와 [beginTurn]이 올려서 이전 턴을 무효화한다.
  int _currentTurnId = 0;

  /// 마지막으로 스피커로 내보낸 문장. 핸즈프리에서 자기 목소리를 다시
  /// 받아쓴 건 아닌지(에코) 판별하는 데 쓴다.
  String? _lastSpokenText;

  TtsQueue(this._tts) {
    _tts.setCompletionHandler(_onUtteranceEnded);
    // CRITICAL: cancel/error 핸들러가 없으면 대상 언어 음성 데이터 미설치 같은
    // 흔한 실패에서 _isSpeaking이 true로 굳고 _playNext가 다시 안 불려
    // 큐가 영구 정지한다. turnDone을 기다리는 핸즈프리 루프도 같이 멈춘다.
    _tts.setCancelHandler(_onUtteranceEnded);
    _tts.setErrorHandler((message) {
      debugPrint('[TtsQueue] TTS error: $message');
      _onUtteranceEnded();
    });
  }

  Stream<TtsQueueState> get stateStream => _stateController.stream;

  String? get lastSpokenText => _lastSpokenText;

  /// 새 AI 턴 시작. 반환된 id를 [markTurnEnd]에 그대로 넘길 것.
  /// 이전 턴의 센티넬이 큐에 남아 있어도 여기서 무효화된다.
  int beginTurn() => ++_currentTurnId;

  /// 문장 추가. 재생 중이면 대기열에, 아니면 즉시 재생
  Future<void> enqueue(String sentence) async {
    _queue.add(_TtsItem.text(sentence));
    if (!_isSpeaking) {
      await _playNext();
    }
  }

  /// [turnId] 턴의 종료를 큐 끝에 표시. 앞의 문장들이 다 재생된 뒤
  /// [TtsQueueState.turnDone]이 방출된다.
  ///
  /// 이미 다른 턴이 시작됐거나 [interrupt]가 걸린 뒤라면 조용히 무시한다 —
  /// 취소된 턴의 뒤늦은 센티넬이 마이크를 잘못 여는 걸 막는다.
  void markTurnEnd(int turnId) {
    if (turnId != _currentTurnId) return;
    _queue.add(_TtsItem.turnEnd(turnId));
    if (!_isSpeaking) {
      unawaited(_playNext());
    }
  }

  /// 즉시 중단 + 큐 비움 (사용자 끼어들기).
  /// 진행 중인 턴을 무효화하므로 이후 도착하는 센티넬은 폐기된다.
  Future<void> interrupt() async {
    _currentTurnId++;
    _queue.clear();
    await _tts.stop();
    _isSpeaking = false;
    _stateController.add(TtsQueueState.idle);
  }

  void _onUtteranceEnded() {
    _isSpeaking = false;
    unawaited(_playNext());
  }

  Future<void> _playNext() async {
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();

      if (item.isTurnEnd) {
        // 센티넬을 큐에 넣은 뒤 턴이 교체됐으면 방출하지 않는다.
        if (item.turnEndId == _currentTurnId) {
          _isSpeaking = false;
          debugPrint('[TtsQueue] turnDone (turn=${item.turnEndId})');
          _stateController.add(TtsQueueState.turnDone);
        } else {
          debugPrint(
              '[TtsQueue] stale sentinel dropped (turn=${item.turnEndId}, current=$_currentTurnId)');
        }
        continue;
      }

      _isSpeaking = true;
      _lastSpokenText = item.text;
      _stateController.add(TtsQueueState.speaking);
      await _tts.speak(item.text!);
      return; // 재생 완료/취소/에러 핸들러가 다시 _playNext를 부른다
    }

    _isSpeaking = false;
    _stateController.add(TtsQueueState.idle);
  }

  Future<void> dispose() async {
    await interrupt();
    await _stateController.close();
  }
}
