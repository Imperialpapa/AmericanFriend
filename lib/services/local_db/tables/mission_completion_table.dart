import 'package:drift/drift.dart';

class MissionCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get missionId => text()();
  IntColumn get turnCount => integer()();
  IntColumn get starsEarned => integer()();
  DateTimeColumn get completedAt => dateTime()();
}
