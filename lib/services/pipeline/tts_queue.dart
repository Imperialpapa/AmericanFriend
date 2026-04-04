import 'dart:async';
import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsQueueState { idle, speaking }

/// 문장을 순서대로 TTS 재생하는 큐
class TtsQueue {
  final FlutterTts _tts;
  final Queue<String> _queue = Queue();
  final _stateController = StreamController<TtsQueueState>.broadcast();
  bool _isSpeaking = false;

  TtsQueue(this._tts) {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _playNext();
    });
  }

  Stream<TtsQueueState> get stateStream => _stateController.stream;

  /// 문장 추가. 재생 중이면 대기열에, 아니면 즉시 재생
  Future<void> enqueue(String sentence) async {
    _queue.add(sentence);
    if (!_isSpeaking) {
      await _playNext();
    }
  }

  /// 즉시 중단 + 큐 비움 (사용자 끼어들기)
  Future<void> interrupt() async {
    _queue.clear();
    await _tts.stop();
    _isSpeaking = false;
    _stateController.add(TtsQueueState.idle);
  }

  Future<void> _playNext() async {
    if (_queue.isEmpty) {
      _stateController.add(TtsQueueState.idle);
      return;
    }

    _isSpeaking = true;
    _stateController.add(TtsQueueState.speaking);
    final sentence = _queue.removeFirst();
    await _tts.speak(sentence);
  }

  Future<void> dispose() async {
    await interrupt();
    await _stateController.close();
  }
}
