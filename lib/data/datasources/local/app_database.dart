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
  TextColumn get submissionId => text().nullable()();
  TextColumn get materialsJson => text().nullable()();
  TextColumn get submissionAttachmentsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AnnouncementRow')
class Announcements extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()();
  TextColumn get body => text()();
  IntColumn get creationTimeMillis => integer()();
  IntColumn get updateTimeMillis => integer().nullable()();
  TextColumn get title => text().nullable()();
  BoolColumn get isMaterial => boolean().withDefault(const Constant(false))();
  TextColumn get materialsJson => text().nullable()();

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

@DataClassName('HiddenItemRow')
class HiddenItems extends Table {
  TextColumn get itemId => text()();
  TextColumn get type => text()();
  DateTimeColumn get hiddenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}

@DataClassName('UserPreferenceRow')
class UserPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('NotificationLogRow')
class NotificationLogs extends Table {
  TextColumn get assignmentId => text()();
  DateTimeColumn get notifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assignmentId};
}

@DataClassName('SnoozedItemRow')
class SnoozedItems extends Table {
  TextColumn get assignmentId => text()();
  DateTimeColumn get snoozedUntil => dateTime()();

  @override
  Set<Column> get primaryKey => {assignmentId};
}

@DriftDatabase(tables: [
  Courses,
  Assignments,
  Announcements,
  CourseOrders,
  SyncStates,
  HiddenItems,
  UserPreferences,
  NotificationLogs,
  SnoozedItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);
  AppDatabase.withConnection(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(hiddenItems);
          }
          if (from < 3) {
            await m.createTable(userPreferences);
            await m.createTable(notificationLogs);
            await m.createTable(snoozedItems);
          }
          if (from < 4) {
            await m.addColumn(assignments, assignments.submissionId);
            await m.addColumn(assignments, assignments.materialsJson);
            await m.createTable(announcements);
          }
          if (from < 5) {
            await m.addColumn(assignments,
                assignments.submissionAttachmentsJson as GeneratedColumn);
          }
          if (from < 6) {
            final existing = await customSelect(
              "SELECT name FROM pragma_table_info('announcements')",
            ).get();
            final cols = existing.map((r) => r.read<String>('name')).toSet();
            for (final col in [
              announcements.title,
              announcements.isMaterial,
              announcements.materialsJson,
            ]) {
              if (!cols.contains(col.name)) {
                await m.addColumn(announcements, col);
              }
            }
          }
        },
      );

  Future<List<AssignmentRow>> searchAssignments(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(assignments)
          ..where((t) =>
              t.title.lower().like(q) |
              t.description.lower().like(q)))
        .get();
  }

  Future<List<AnnouncementRow>> searchAnnouncements(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(announcements)
          ..where((t) => t.body.lower().like(q))
          ..orderBy([(t) => OrderingTerm.desc(t.creationTimeMillis)]))
        .get();
  }

  static Future<AppDatabase> openBackground() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return AppDatabase.withConnection(NativeDatabase(file));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
