import 'package:drift/drift.dart';

class TopicSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topicId => text()();
  TextColumn get topicTitle => text()();
  TextColumn get category => text()();
  IntColumn get turnCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
}
