import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// 오디오 포커스 감시 — 전화 수신·알람·타 미디어 앱이 오디오를 가져갈 때 알려준다.
///
/// **왜 lifecycle 콜백으로는 안 되는가**: 안드로이드에서 전화는 보통 heads-up
/// 알림으로 포그라운드 액티비티 위에 뜬다. 액티비티가 pause되지 않으므로
/// `WidgetsBindingObserver.didChangeAppLifecycleState`가 아예 발화하지 않고,
/// 핸즈프리는 통화 중에도 마이크를 열어둔 채 TTS를 통화에 대고 재생한다.
/// 알람, 다른 미디어 앱, 이 앱 자체의 일일 알림도 전부 같은 구멍이다.
///
/// **주의**: 안드로이드에서 interruption 이벤트는 audio focus 변화로 전달된다.
/// 따라서 이벤트를 받으려면 우리가 먼저 focus를 요청해야 한다([activate]).
/// focus를 잡지 않으면 스트림은 영원히 조용하다.
class AudioFocusService {
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  bool _active = false;

  bool get isActive => _active;

  /// [onInterrupted] 오디오를 뺏김 — 즉시 마이크/TTS를 멈춰야 한다.
  /// [onInterruptionEnded] 돌려받음. 자동 재개해도 되는 경우에만 호출된다.
  Future<void> initialize({
    required void Function() onInterrupted,
    required void Function() onInterruptionEnded,
  }) async {
    if (_session != null) return;

    try {
      final session = await AudioSession.instance;
      // playAndRecord: STT(녹음)와 TTS(재생)를 함께 쓰므로 iOS에서 playback만으로는 부족.
      // Android는 speech content/media usage — TTS 출력 경로를 바꾸지 않기 위해
      // voiceCommunication이 아니라 media를 쓴다(전자는 통화용 이어피스로 라우팅될 수 있음).
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      _interruptionSub = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // 마이크는 볼륨을 낮출 수 없다 — duck이든 pause든 일단 멈춘다.
          debugPrint('[AudioFocus] interruption BEGIN (${event.type.name})');
          onInterrupted();
          return;
        }

        // unknown은 "언제 끝날지 모름" — 자동 재개하지 않는다.
        if (event.type == AudioInterruptionType.unknown) {
          debugPrint('[AudioFocus] interruption END (unknown) — no auto resume');
          return;
        }
        debugPrint('[AudioFocus] interruption END (${event.type.name}) — resuming');
        onInterruptionEnded();
      });

      _session = session;
    } catch (e) {
      // 오디오 포커스를 못 잡아도 핸즈프리 자체는 동작해야 한다.
      debugPrint('[AudioFocus] initialize failed: $e');
    }
  }

  /// 오디오 포커스 요청. 이걸 해야 interruption 이벤트가 온다.
  Future<void> activate() async {
    final session = _session;
    if (session == null || _active) return;
    try {
      _active = await session.setActive(true);
      debugPrint('[AudioFocus] activate -> $_active');
    } catch (e) {
      debugPrint('[AudioFocus] activate failed: $e');
    }
  }

  /// 포커스 반납. 다른 앱이 음악을 계속 틀 수 있게 해준다.
  Future<void> deactivate() async {
    final session = _session;
    if (session == null || !_active) return;
    try {
      await session.setActive(false);
    } catch (e) {
      debugPrint('[AudioFocus] deactivate failed: $e');
    } finally {
      _active = false;
    }
  }

  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    await deactivate();
    _session = null;
  }
}
