import 'package:drift/drift.dart';

class VocabularyItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// 단어 또는 표현 (대상 언어)
  TextColumn get expression => text()();
  /// 뜻 (모국어)
  TextColumn get meaning => text().withDefault(const Constant(''))();
  /// 예문
  TextColumn get example => text().withDefault(const Constant(''))();
  /// 다음 복습 시점 (Spaced Repetition)
  DateTimeColumn get nextReviewAt => dateTime()();
  /// 복습 간격 (일 단위)
  IntColumn get intervalDays => integer().withDefault(const Constant(1))();
  /// 연속 정답 횟수
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
