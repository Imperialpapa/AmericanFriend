import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart' show MessageRole;
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/mission/presentation/providers/mission_provider.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';

/// 스트릭·토픽 턴·미션 턴 집계를 chatProvider 상태에서 파생한다 (BUG #10).
///
/// 예전엔 입력창 콜백 한 곳에서만 기록해서 음성 자동전송·핸즈프리·제안 칩으로 보낸
/// 메시지는 0으로 집계되고, 키가 없어 전송이 막혀도 +1이 됐다. 전송 경로가 몇 개든
/// "대화에 사용자 메시지가 실제로 추가됐다"는 사실 하나만 센다.
///
/// 의존 방향은 이 provider → chatProvider 한쪽뿐이다. chatProvider와 그것이 read하는
/// provider(topic 등)는 이 provider를 read/watch하면 안 된다 (BUG #5 순환).
/// ChatScreen이 한 번 read해서 앱 수명 동안 살려 둔다 — autoDispose로 바꾸지 말 것.
final activityRecorderProvider = Provider<void>((ref) {
  ref.listen<ChatState>(chatProvider, (prev, next) {
    if (prev == null || !isNewUserTurn(prev, next)) return;
    unawaited(ref.read(streakProvider.notifier).recordMessage());
    unawaited(ref.read(topicProvider.notifier).recordTurn());
    unawaited(ref.read(missionProvider.notifier).recordTurn());
  });
});

/// 같은 대화에서 사용자 메시지가 정확히 1개 늘었고 내용이 비어 있지 않으면 true.
/// 스트리밍 토큰 갱신, 대화 전환·불러오기(conversationId 변경)는 세지 않는다.
bool isNewUserTurn(ChatState prev, ChatState next) {
  if (identical(prev.messages, next.messages)) return false;
  final id = next.conversationId;
  if (id == null || prev.conversationId != id) return false;
  if (next.messages.isEmpty) return false;
  final last = next.messages.last;
  if (last.role != MessageRole.user || last.content.trim().isEmpty) {
    return false;
  }
  return _userCount(next) == _userCount(prev) + 1;
}

int _userCount(ChatState s) =>
    s.messages.where((m) => m.role == MessageRole.user).length;
