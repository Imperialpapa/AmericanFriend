import 'package:drift/drift.dart';

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get content => text()();
  TextColumn get role => text()(); // 'user' or 'assistant'
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
