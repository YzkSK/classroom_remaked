// lib/data/datasources/local/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
part 'app_database.g.dart';

@DataClassName('CourseRow')
class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get section => text().nullable()();
  TextColumn get room => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get courseState =>
      text().withDefault(const Constant('ACTIVE'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AssignmentRow')
class Assignments extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get dueDateMillis => integer().nullable()();
  TextColumn get state =>
      text().withDefault(const Constant('published'))();
  TextColumn get submissionState => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CourseOrderRow')
class CourseOrders extends Table {
  TextColumn get courseId => text()();
  IntColumn get sortIndex => integer()();

  @override
  Set<Column> get primaryKey => {courseId};
}

@DataClassName('SyncStateRow')
class SyncStates extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Courses, Assignments, CourseOrders, SyncStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
