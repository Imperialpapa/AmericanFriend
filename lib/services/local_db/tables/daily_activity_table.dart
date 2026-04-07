import 'package:drift/drift.dart';

class DailyActivity extends Table {
  // 날짜 문자열 'yyyy-MM-dd' 를 PK로 사용
  TextColumn get date => text()();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  BoolColumn get goalReached => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date};
}
