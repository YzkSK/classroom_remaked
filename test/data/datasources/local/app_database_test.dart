// test/data/datasources/local/app_database_test.dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('コースを挿入して取得できる', () async {
    await db.into(db.courses).insert(
      CoursesCompanion.insert(id: 'c1', name: 'Math'),
    );
    final rows = await db.select(db.courses).get();
    expect(rows.length, 1);
    expect(rows.first.courseState, 'ACTIVE');
  });

  test('SyncStateをキーで保存・取得できる', () async {
    await db.into(db.syncStates).insert(
      SyncStatesCompanion.insert(key: 'pubsub_setup', value: 'done'),
    );
    final row = await (db.select(db.syncStates)
          ..where((t) => t.key.equals('pubsub_setup')))
        .getSingleOrNull();
    expect(row?.value, 'done');
  });

  test('HiddenItemを保存・取得・削除できる', () async {
    await db.into(db.hiddenItems).insert(
      HiddenItemsCompanion.insert(
        itemId: 'c1',
        type: 'course',
        hiddenAt: DateTime(2026, 1, 1),
      ),
    );

    final rows = await (db.select(db.hiddenItems)
          ..where((t) => t.type.equals('course')))
        .get();
    expect(rows.length, 1);
    expect(rows.first.itemId, 'c1');

    await (db.delete(db.hiddenItems)
          ..where((t) => t.itemId.equals('c1')))
        .go();
    final afterDelete = await db.select(db.hiddenItems).get();
    expect(afterDelete, isEmpty);
  });

  test('UserPreferences を保存・取得できる', () async {
    await db.into(db.userPreferences).insert(
      UserPreferencesCompanion.insert(key: 'notifyBeforeHours', value: '24'),
    );
    final row = await (db.select(db.userPreferences)
          ..where((t) => t.key.equals('notifyBeforeHours')))
        .getSingleOrNull();
    expect(row?.value, '24');
  });

  test('NotificationLog を保存・取得できる', () async {
    await db.into(db.notificationLogs).insert(
      NotificationLogsCompanion.insert(
        assignmentId: 'a1',
        notifiedAt: DateTime(2026, 5, 8),
      ),
    );
    final rows = await db.select(db.notificationLogs).get();
    expect(rows.length, 1);
    expect(rows.first.assignmentId, 'a1');
  });

  test('SnoozedItem を保存・取得できる', () async {
    await db.into(db.snoozedItems).insert(
      SnoozedItemsCompanion.insert(
        assignmentId: 'a1',
        snoozedUntil: DateTime(2026, 5, 8, 13, 0),
      ),
    );
    final rows = await db.select(db.snoozedItems).get();
    expect(rows.length, 1);
    expect(rows.first.snoozedUntil, DateTime(2026, 5, 8, 13, 0));
  });
}
