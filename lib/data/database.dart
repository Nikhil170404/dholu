import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Brief section 10 tables. Only redacted text is ever stored.
class NotificationEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text()();
  TextColumn get pkg => text()();
  TextColumn get appName => text()();
  TextColumn get sender => text()();
  TextColumn get textRedacted => text()();
  DateTimeColumn get ts => dateTime()();
  TextColumn get category => text()();
  TextColumn get priority => text()();
  TextColumn get action => text()();
  TextColumn get summary => text()();
  BoolColumn get handled => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {key, ts},
  ];
}

class AppPrefs extends Table {
  TextColumn get pkg => text()();
  TextColumn get name => text()();
  BoolColumn get important => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {pkg};
}

class Contacts extends Table {
  TextColumn get name => text()();

  /// 0 normal, 1 important (starred / family / boss).
  IntColumn get importance => integer().withDefault(const Constant(1))();
  @override
  Set<Column> get primaryKey => {name};
}

class Feedbacks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer()();
  TextColumn get sender => text()();
  TextColumn get userAction =>
      text()(); // opened | dismissed | later | wrong_priority
  DateTimeColumn get ts => dateTime()();
}

@DriftDatabase(tables: [NotificationEvents, AppPrefs, Contacts, Feedbacks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? driftDatabase(name: 'dholu'));

  @override
  int get schemaVersion => 1;
}
