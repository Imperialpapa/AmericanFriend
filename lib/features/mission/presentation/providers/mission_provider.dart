import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/mission/domain/entities/mission.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';
import 'package:eng_friend/features/topic/domain/entities/topic.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

class MissionState {
  final Mission? activeMission;
  final int turnCount;
  final Set<String> completedMissionIds;
  /// 미션 완료 직후 축하 표시용
  final bool justCompleted;
  final int starsJustEarned;

  const MissionState({
    this.activeMission,
    this.turnCount = 0,
    this.completedMissionIds = const {},
    this.justCompleted = false,
    this.starsJustEarned = 0,
  });

  bool get isActive => activeMission != null;

  MissionState copyWith({
    Mission? activeMission,
    int? turnCount,
    Set<String>? completedMissionIds,
    bool? justCompleted,
    int? starsJustEarned,
  }) {
    return MissionState(
      activeMission: activeMission ?? this.activeMission,
      turnCount: turnCount ?? this.turnCount,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      justCompleted: justCompleted ?? this.justCompleted,
      starsJustEarned: starsJustEarned ?? this.starsJustEarned,
    );
  }
}

class MissionNotifier extends StateNotifier<MissionState> {
  final AppDatabase _db;
  final TopicNotifier _topicNotifier;

  MissionNotifier(this._db, this._topicNotifier) : super(const MissionState()) {
    _loadCompletions();
  }

  Future<void> _loadCompletions() async {
    final completions = await _db.getAllMissionCompletions();
    final ids = completions.map((c) => c.missionId).toSet();
    state = state.copyWith(completedMissionIds: ids);
  }

  /// 미션 시작 → Topic Focus Mode도 같이 활성화
  Future<void> startMission(Mission mission) async {
    // Topic 시스템을 통해 AI 역할 설정
    final topic = Topic(
      id: 'mission_${mission.id}',
      category: TopicCategory.daily,
      title: mission.title,
      situation: mission.situation,
      aiRole: mission.aiRole,
    );
    await _topicNotifier.startTopic(topic);

    state = MissionState(
      activeMission: mission,
      turnCount: 0,
      completedMissionIds: state.completedMissionIds,
    );
  }

  /// 턴 기록 + 완료 체크
  Future<void> recordTurn() async {
    if (!state.isActive) return;

    final newCount = state.turnCount + 1;
    final mission = state.activeMission!;

    if (newCount >= mission.requiredTurns && !state.completedMissionIds.contains(mission.id)) {
      // 미션 완료!
      final stars = mission.difficulty.stars;
      await _db.insertMissionCompletion(
        missionId: mission.id,
        turnCount: newCount,
        starsEarned: stars,
      );

      state = state.copyWith(
        turnCount: newCount,
        completedMissionIds: {...state.completedMissionIds, mission.id},
        justCompleted: true,
        starsJustEarned: stars,
      );
    } else {
      state = state.copyWith(turnCount: newCount);
    }
  }

  void clearJustCompleted() {
    state = state.copyWith(justCompleted: false, starsJustEarned: 0);
  }

  /// 미션 종료
  Future<void> endMission() async {
    await _topicNotifier.endTopic();
    state = MissionState(completedMissionIds: state.completedMissionIds);
  }
}

final missionProvider = StateNotifierProvider<MissionNotifier, MissionState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final topicNotifier = ref.watch(topicProvider.notifier);
  return MissionNotifier(db, topicNotifier);
});
