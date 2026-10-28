import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 이번 실행에서 신고한 AI 메시지 id — 말풍선을 흐리게 표시하는 용도뿐이다.
/// 잎(leaf) provider: chatProvider는 이것을 읽지 않는다(BUG #5).
final reportedMessageIdsProvider =
    StateProvider<Set<String>>((ref) => const <String>{});
