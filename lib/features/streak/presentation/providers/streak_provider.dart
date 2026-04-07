import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

/// Streak 상태
class StreakState {
  final int currentStreak;
  final int todayMessageCount;
  final int dailyGoal;
  final bool goalReachedToday;
  /// 목표 달성 직후 true → UI에서 축하 효과 후 false로 리셋
  final bool justReachedGoal;

  const StreakState({
    this.currentStreak = 0,
    this.todayMessageCount = 0,
    this.dailyGoal = 5,
    this.goalReachedToday = false,
    this.justReachedGoal = false,
  });

  StreakState copyWith({
    int? currentStreak,
    int? todayMessageCount,
    int? dailyGoal,
    bool? goalReachedToday,
    bool? justReachedGoal,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      todayMessageCount: todayMessageCount ?? this.todayMessageCount,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      goalReachedToday: goalReachedToday ?? this.goalReachedToday,
      justReachedGoal: justReachedGoal ?? this.justReachedGoal,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  final AppDatabase _db;

  StreakNotifier(this._db) : super(const StreakState()) {
    _loadToday();
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 앱 시작 시 오늘 데이터 로드
  Future<void> _loadToday() async {
    final today = await _db.getDailyActivity(_todayStr);
    final yesterday = await _db.getYesterdayActivity(_todayStr);

    int currentStreak;
    if (today != null && today.goalReached) {
      // 오늘 이미 목표 달성
      currentStreak = today.streakCount;
    } else if (yesterday != null && yesterday.goalReached) {
      // 어제 달성했으므로 오늘 달성하면 streak 이어짐
      currentStreak = yesterday.streakCount;
    } else {
      // streak 끊김 → 오늘 달성하면 1부터 시작
      currentStreak = 0;
    }

    state = state.copyWith(
      todayMessageCount: today?.messageCount ?? 0,
      goalReachedToday: today?.goalReached ?? false,
      currentStreak: currentStreak,
    );
  }

  /// 사용자 메시지 전송 시 호출
  Future<void> recordMessage() async {
    final wasGoalReached = state.goalReachedToday;

    // streak 계산: 아직 오늘 목표 미달성이면 새 streak 계산
    int newStreakForDb;
    if (wasGoalReached) {
      // 이미 달성 → streak 변동 없음
      newStreakForDb = state.currentStreak;
    } else {
      // 목표 달성 직전/직후 판단
      final newCount = state.todayMessageCount + 1;
      if (newCount >= state.dailyGoal) {
        // 지금 달성!
        final yesterday = await _db.getYesterdayActivity(_todayStr);
        newStreakForDb = (yesterday != null && yesterday.goalReached)
            ? yesterday.streakCount + 1
            : 1;
      } else {
        newStreakForDb = state.currentStreak;
      }
    }

    await _db.incrementDailyMessage(
      date: _todayStr,
      dailyGoal: state.dailyGoal,
      newStreakCount: newStreakForDb,
    );

    final newCount = state.todayMessageCount + 1;
    final justReached = !wasGoalReached && newCount >= state.dailyGoal;

    state = state.copyWith(
      todayMessageCount: newCount,
      goalReachedToday: wasGoalReached || newCount >= state.dailyGoal,
      currentStreak: justReached ? newStreakForDb : state.currentStreak,
      justReachedGoal: justReached,
    );
  }

  /// 축하 효과 표시 후 리셋
  void clearJustReachedGoal() {
    state = state.copyWith(justReachedGoal: false);
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StreakNotifier(db);
});
