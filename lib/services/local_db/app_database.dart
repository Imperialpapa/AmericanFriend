import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:eng_friend/services/local_db/tables/conversations_table.dart';
import 'package:eng_friend/services/local_db/tables/messages_table.dart';
import 'package:eng_friend/services/local_db/tables/level_history_table.dart';
import 'package:eng_friend/services/local_db/tables/daily_activity_table.dart';
import 'package:eng_friend/services/local_db/tables/topic_session_table.dart';
import 'package:eng_friend/services/local_db/tables/mission_completion_table.dart';
import 'package:eng_friend/services/local_db/tables/vocabulary_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Conversations, Messages, LevelHistory, DailyActivity, TopicSessions, MissionCompletions, VocabularyItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(dailyActivity);
          }
          if (from < 3) {
            await m.createTable(topicSessions);
          }
          if (from < 4) {
            await m.createTable(missionCompletions);
          }
          if (from < 5) {
            await m.createTable(vocabularyItems);
          }
        },
      );

  // ===== Conversations =====

  Future<List<Conversation>> getAllConversations() =>
      (select(conversations)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<Conversation> createConversation(String id) {
    final now = DateTime.now();
    return into(conversations).insertReturning(ConversationsCompanion.insert(
      id: id,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> updateConversationTitle(String id, String title) =>
      (update(conversations)..where((t) => t.id.equals(id)))
          .write(ConversationsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ));

  // ===== Messages =====

  Future<List<Message>> getMessages(String conversationId) =>
      (select(messages)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  Future<void> insertMessage(MessagesCompanion message) =>
      into(messages).insert(message);

  // ===== Level History =====

  Future<void> insertLevelRecord(int level, String reasoning) =>
      into(levelHistory).insert(LevelHistoryCompanion.insert(
        level: level,
        reasoning: Value(reasoning),
        assessedAt: DateTime.now(),
      ));

  Future<List<LevelHistoryData>> getLevelHistory() =>
      (select(levelHistory)..orderBy([(t) => OrderingTerm.desc(t.assessedAt)]))
          .get();

  // ===== Daily Activity =====

  /// 특정 날짜의 activity 조회
  Future<DailyActivityData?> getDailyActivity(String date) =>
      (select(dailyActivity)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  /// activity upsert (메시지 카운트 증가 + streak 갱신)
  Future<void> incrementDailyMessage({
    required String date,
    required int dailyGoal,
    required int newStreakCount,
  }) async {
    final existing = await getDailyActivity(date);
    if (existing == null) {
      final count = 1;
      await into(dailyActivity).insert(DailyActivityCompanion.insert(
        date: date,
        messageCount: Value(count),
        streakCount: Value(newStreakCount),
        goalReached: Value(count >= dailyGoal),
      ));
    } else {
      final count = existing.messageCount + 1;
      final goalJustReached = !existing.goalReached && count >= dailyGoal;
      await (update(dailyActivity)..where((t) => t.date.equals(date))).write(
        DailyActivityCompanion(
          messageCount: Value(count),
          streakCount: Value(goalJustReached ? newStreakCount : existing.streakCount),
          goalReached: Value(existing.goalReached || count >= dailyGoal),
        ),
      );
    }
  }

  /// 어제의 activity 조회 (streak 계산용)
  Future<DailyActivityData?> getYesterdayActivity(String todayDate) {
    final today = DateTime.parse(todayDate);
    final yesterday = today.subtract(const Duration(days: 1));
    final yStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return getDailyActivity(yStr);
  }

  /// 최근 N일간 activity 조회
  Future<List<DailyActivityData>> getRecentActivity(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    return (select(dailyActivity)
          ..where((t) => t.date.isBiggerOrEqualValue(cutoffStr))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // ===== Topic Sessions =====

  Future<TopicSession> startTopicSession({
    required String topicId,
    required String topicTitle,
    required String category,
  }) =>
      into(topicSessions).insertReturning(TopicSessionsCompanion.insert(
        topicId: topicId,
        topicTitle: topicTitle,
        category: category,
        startedAt: DateTime.now(),
      ));

  Future<void> endTopicSession(int sessionId, int turnCount) =>
      (update(topicSessions)..where((t) => t.id.equals(sessionId))).write(
        TopicSessionsCompanion(
          turnCount: Value(turnCount),
          endedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateTopicSessionTurnCount(int sessionId, int turnCount) =>
      (update(topicSessions)..where((t) => t.id.equals(sessionId))).write(
        TopicSessionsCompanion(turnCount: Value(turnCount)),
      );

  Future<List<TopicSession>> getRecentTopicSessions(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (select(topicSessions)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  // ===== Mission Completions =====

  Future<void> insertMissionCompletion({
    required String missionId,
    required int turnCount,
    required int starsEarned,
  }) =>
      into(missionCompletions).insert(MissionCompletionsCompanion.insert(
        missionId: missionId,
        turnCount: turnCount,
        starsEarned: starsEarned,
        completedAt: DateTime.now(),
      ));

  Future<List<MissionCompletion>> getAllMissionCompletions() =>
      (select(missionCompletions)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();

  Future<List<MissionCompletion>> getCompletionsForMission(String missionId) =>
      (select(missionCompletions)
            ..where((t) => t.missionId.equals(missionId)))
          .get();

  // ===== Vocabulary =====

  Future<void> addVocabularyItem({
    required String expression,
    String meaning = '',
    String example = '',
  }) =>
      into(vocabularyItems).insert(VocabularyItemsCompanion.insert(
        expression: expression,
        meaning: Value(meaning),
        example: Value(example),
        nextReviewAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

  Future<List<VocabularyItem>> getAllVocabulary() =>
      (select(vocabularyItems)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<VocabularyItem>> getDueVocabulary() =>
      (select(vocabularyItems)
            ..where((t) => t.nextReviewAt.isSmallerOrEqualValue(DateTime.now()))
            ..orderBy([(t) => OrderingTerm.asc(t.nextReviewAt)]))
          .get();

  /// Spaced Repetition: 정답 시 간격 증가, 오답 시 리셋
  Future<void> reviewVocabulary(int itemId, {required bool correct}) async {
    final item = await (select(vocabularyItems)..where((t) => t.id.equals(itemId))).getSingle();

    int newInterval;
    int newCorrectCount;
    if (correct) {
      newCorrectCount = item.correctCount + 1;
      // 간격 배수: 1 → 2 → 4 → 7 → 14 → 30
      newInterval = switch (newCorrectCount) {
        1 => 1,
        2 => 2,
        3 => 4,
        4 => 7,
        5 => 14,
        _ => 30,
      };
    } else {
      newCorrectCount = 0;
      newInterval = 1;
    }

    await (update(vocabularyItems)..where((t) => t.id.equals(itemId))).write(
      VocabularyItemsCompanion(
        intervalDays: Value(newInterval),
        correctCount: Value(newCorrectCount),
        nextReviewAt: Value(DateTime.now().add(Duration(days: newInterval))),
      ),
    );
  }

  Future<void> deleteVocabulary(int itemId) =>
      (delete(vocabularyItems)..where((t) => t.id.equals(itemId))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'eng_friend.db'));
    return NativeDatabase.createInBackground(file);
  });
}
