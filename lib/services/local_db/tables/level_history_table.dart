import 'package:drift/drift.dart';

class LevelHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get level => integer()();
  TextColumn get reasoning => text().withDefault(const Constant(''))();
  DateTimeColumn get assessedAt => dateTime()();
}
