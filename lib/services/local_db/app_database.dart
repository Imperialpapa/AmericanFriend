import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:eng_friend/services/local_db/tables/conversations_table.dart';
import 'package:eng_friend/services/local_db/tables/messages_table.dart';
import 'package:eng_friend/services/local_db/tables/level_history_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Conversations, Messages, LevelHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'eng_friend.db'));
    return NativeDatabase.createInBackground(file);
  });
}
