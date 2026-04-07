import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/topic/domain/entities/topic.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

/// Topic Focus 상태
class TopicState {
  final Topic? activeTopic;
  final int? activeSessionId;
  final int turnCount;
  final bool isActive;

  const TopicState({
    this.activeTopic,
    this.activeSessionId,
    this.turnCount = 0,
    this.isActive = false,
  });

  TopicState copyWith({
    Topic? activeTopic,
    int? activeSessionId,
    int? turnCount,
    bool? isActive,
  }) {
    return TopicState(
      activeTopic: isActive ?? this.isActive ? (activeTopic ?? this.activeTopic) : null,
      activeSessionId: isActive ?? this.isActive ? (activeSessionId ?? this.activeSessionId) : null,
      turnCount: turnCount ?? this.turnCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TopicNotifier extends StateNotifier<TopicState> {
  final AppDatabase _db;

  TopicNotifier(this._db) : super(const TopicState());

  /// 주제 선택 → 집중 모드 시작
  Future<void> startTopic(Topic topic) async {
    // 기존 세션이 있으면 먼저 종료
    if (state.isActive && state.activeSessionId != null) {
      await _endCurrentSession();
    }

    final session = await _db.startTopicSession(
      topicId: topic.id,
      topicTitle: topic.title,
      category: topic.category.name,
    );

    state = TopicState(
      activeTopic: topic,
      activeSessionId: session.id,
      turnCount: 0,
      isActive: true,
    );
  }

  /// 사용자 메시지 전송 시 턴 카운트 증가
  Future<void> recordTurn() async {
    if (!state.isActive || state.activeSessionId == null) return;

    final newCount = state.turnCount + 1;
    state = state.copyWith(turnCount: newCount);
    await _db.updateTopicSessionTurnCount(state.activeSessionId!, newCount);
  }

  /// 주제 집중 모드 종료
  Future<void> endTopic() async {
    await _endCurrentSession();
    state = const TopicState();
  }

  Future<void> _endCurrentSession() async {
    if (state.activeSessionId != null) {
      await _db.endTopicSession(state.activeSessionId!, state.turnCount);
    }
  }

  /// 오늘의 추천 주제 (날짜 기반 rotation)
  Topic get todaysTopic {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return TopicCatalog.all[dayOfYear % TopicCatalog.all.length];
  }

  @override
  void dispose() {
    // 앱 종료 시 열린 세션 정리
    if (state.isActive && state.activeSessionId != null) {
      _db.endTopicSession(state.activeSessionId!, state.turnCount);
    }
    super.dispose();
  }
}

final topicProvider = StateNotifierProvider<TopicNotifier, TopicState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TopicNotifier(db);
});
