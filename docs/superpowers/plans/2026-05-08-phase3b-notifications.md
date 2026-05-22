# Phase 3b: 通知機能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** workmanager + flutter_local_notifications で締め切り前通知・スヌーズ・怠惰人間モード・初回オンボーディング・設定画面を実装する。

**Architecture:** バックグラウンドタスク（workmanager 1h periodic）が drift DB を直接開いて課題を取得し通知を発火。スヌーズ状態・通知ログは drift に保存。Riverpod は foreground のみで使用し、background isolate では使わない。

**Tech Stack:** Flutter 3.x, drift 2.20, workmanager 0.5.x, flutter_local_notifications 18.x, Riverpod 2.6, shadcn_ui 0.54, go_router 14.x

---

## ファイルマップ

| ファイル | 役割 |
|---------|------|
| `pubspec.yaml` | workmanager 依存追加 |
| `lib/data/datasources/local/app_database.dart` | schema v3・3テーブル追加・`openBackground()` 追加 |
| `lib/data/datasources/local/user_preferences_datasource.dart` | notifyBeforeHours / lazyMode / onboardingDone の KV 読み書き |
| `lib/data/datasources/local/notification_logs_datasource.dart` | 通知済み assignmentId の記録・取得 |
| `lib/data/datasources/local/snoozed_items_datasource.dart` | スヌーズ状態の upsert・期限切れ取得 |
| `lib/core/di/providers.dart` | 3 datasource プロバイダー追加 |
| `lib/domain/usecases/can_disable_lazy_mode_usecase.dart` | notifyBefore 以内の未提出課題数を返す純粋関数 |
| `lib/core/services/notification_service.dart` | flutter_local_notifications ラッパー（初期化・権限・通知発火） |
| `lib/core/services/background_notification_task.dart` | callbackDispatcher + 通知フィルタリングロジック |
| `lib/main.dart` | workmanager init + 通知レスポンスハンドラー登録 |
| `lib/presentation/viewmodels/settings_viewmodel.dart` | 設定画面の状態管理 |
| `lib/core/router/app_router.dart` | onboarding route + redirect ロジック + settings branch 追加 |
| `lib/presentation/views/shared/scaffold_with_nav.dart` | 設定タブ追加 |
| `lib/presentation/views/notification_setup/notification_setup_screen.dart` | 初回オンボーディング画面 |
| `lib/presentation/views/settings/settings_screen.dart` | 設定画面 |

---

## Task 1: pubspec.yaml — workmanager 追加

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: workmanager を dependencies に追加する**

`pubspec.yaml` の `# workmanager: Phase 3（バックグラウンド通知）実装時に追加` 行を以下に置き換える:

```yaml
  workmanager: ^0.5.2
```

- [ ] **Step 2: パッケージを取得する**

```bash
flutter pub get
```

Expected: エラーなく完了する

- [ ] **Step 3: コミットする**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: workmanager を追加"
```

---

## Task 2: DB スキーマ v3 — UserPreferences / NotificationLogs / SnoozedItems テーブル追加

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`
- Modify: `test/data/datasources/local/app_database_test.dart`

- [ ] **Step 1: 3テーブルのテストを書く**

`test/data/datasources/local/app_database_test.dart` の末尾に追加:

```dart
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
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/data/datasources/local/app_database_test.dart
```

Expected: FAIL — `UserPreferences`, `NotificationLogs`, `SnoozedItems` が未定義

- [ ] **Step 3: `app_database.dart` に3テーブルを追加する**

```dart
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

  @override
  int get schemaVersion => 3;

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
        },
      );

  static Future<AppDatabase> openBackground() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return AppDatabase.forTesting(NativeDatabase(file));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 4: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` が再生成される

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/app_database_test.dart
```

Expected: All tests passed!

- [ ] **Step 6: コミットする**

```bash
git add lib/data/datasources/local/app_database.dart \
        lib/data/datasources/local/app_database.g.dart \
        test/data/datasources/local/app_database_test.dart
git commit -m "feat: DBスキーマv3 - UserPreferences/NotificationLogs/SnoozedItemsテーブル追加"
```

---

## Task 3: UserPreferencesDataSource

**Files:**
- Create: `lib/data/datasources/local/user_preferences_datasource.dart`
- Create: `test/data/datasources/local/user_preferences_datasource_test.dart`

- [ ] **Step 1: テストを書く**

```dart
// test/data/datasources/local/user_preferences_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/user_preferences_datasource.dart';

void main() {
  late AppDatabase db;
  late UserPreferencesDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = UserPreferencesDataSource(db);
  });

  tearDown(() async => db.close());

  test('getNotifyBeforeHours はデフォルト 24 を返す', () async {
    final hours = await ds.getNotifyBeforeHours();
    expect(hours, 24);
  });

  test('setNotifyBeforeHours で値が保存される', () async {
    await ds.setNotifyBeforeHours(48);
    final hours = await ds.getNotifyBeforeHours();
    expect(hours, 48);
  });

  test('getLazyModeEnabled はデフォルト false を返す', () async {
    final enabled = await ds.getLazyModeEnabled();
    expect(enabled, false);
  });

  test('setLazyModeEnabled(true) で値が保存される', () async {
    await ds.setLazyModeEnabled(true);
    final enabled = await ds.getLazyModeEnabled();
    expect(enabled, true);
  });

  test('getOnboardingDone はデフォルト false を返す', () async {
    final done = await ds.getOnboardingDone();
    expect(done, false);
  });

  test('setOnboardingDone(true) で値が保存される', () async {
    await ds.setOnboardingDone(true);
    final done = await ds.getOnboardingDone();
    expect(done, true);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/data/datasources/local/user_preferences_datasource_test.dart
```

Expected: FAIL — `UserPreferencesDataSource` が未定義

- [ ] **Step 3: 実装する**

```dart
// lib/data/datasources/local/user_preferences_datasource.dart
import 'app_database.dart';

class UserPreferencesDataSource {
  UserPreferencesDataSource(this._db);

  final AppDatabase _db;

  static const _keyNotifyBeforeHours = 'notifyBeforeHours';
  static const _keyLazyModeEnabled = 'lazyModeEnabled';
  static const _keyOnboardingDone = 'notificationOnboardingDone';

  Future<String?> _get(String key) async {
    final row = await (_db.select(_db.userPreferences)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) async {
    await _db.into(_db.userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion.insert(key: key, value: value),
    );
  }

  Future<int> getNotifyBeforeHours() async {
    final v = await _get(_keyNotifyBeforeHours);
    return v != null ? int.parse(v) : 24;
  }

  Future<void> setNotifyBeforeHours(int hours) =>
      _set(_keyNotifyBeforeHours, hours.toString());

  Future<bool> getLazyModeEnabled() async {
    final v = await _get(_keyLazyModeEnabled);
    return v == 'true';
  }

  Future<void> setLazyModeEnabled(bool enabled) =>
      _set(_keyLazyModeEnabled, enabled.toString());

  Future<bool> getOnboardingDone() async {
    final v = await _get(_keyOnboardingDone);
    return v == 'true';
  }

  Future<void> setOnboardingDone(bool done) =>
      _set(_keyOnboardingDone, done.toString());
}
```

- [ ] **Step 4: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/user_preferences_datasource_test.dart
```

Expected: All tests passed!

- [ ] **Step 5: コミットする**

```bash
git add lib/data/datasources/local/user_preferences_datasource.dart \
        test/data/datasources/local/user_preferences_datasource_test.dart
git commit -m "feat: UserPreferencesDataSourceを実装"
```

---

## Task 4: NotificationLogsDataSource

**Files:**
- Create: `lib/data/datasources/local/notification_logs_datasource.dart`
- Create: `test/data/datasources/local/notification_logs_datasource_test.dart`

- [ ] **Step 1: テストを書く**

```dart
// test/data/datasources/local/notification_logs_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/notification_logs_datasource.dart';

void main() {
  late AppDatabase db;
  late NotificationLogsDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = NotificationLogsDataSource(db);
  });

  tearDown(() async => db.close());

  test('log した ID が getLoggedIds に含まれる', () async {
    await ds.log('a1');
    await ds.log('a2');
    final ids = await ds.getLoggedIds();
    expect(ids, containsAll(['a1', 'a2']));
  });

  test('同じ ID を2回 log しても重複しない', () async {
    await ds.log('a1');
    await ds.log('a1');
    final ids = await ds.getLoggedIds();
    expect(ids.length, 1);
  });

  test('delete で ID が消える', () async {
    await ds.log('a1');
    await ds.delete('a1');
    final ids = await ds.getLoggedIds();
    expect(ids, isEmpty);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/data/datasources/local/notification_logs_datasource_test.dart
```

Expected: FAIL — `NotificationLogsDataSource` が未定義

- [ ] **Step 3: 実装する**

```dart
// lib/data/datasources/local/notification_logs_datasource.dart
import 'app_database.dart';

class NotificationLogsDataSource {
  NotificationLogsDataSource(this._db);

  final AppDatabase _db;

  Future<void> log(String assignmentId) async {
    await _db.into(_db.notificationLogs).insertOnConflictUpdate(
      NotificationLogsCompanion.insert(
        assignmentId: assignmentId,
        notifiedAt: DateTime.now(),
      ),
    );
  }

  Future<Set<String>> getLoggedIds() async {
    final rows = await _db.select(_db.notificationLogs).get();
    return rows.map((r) => r.assignmentId).toSet();
  }

  Future<void> delete(String assignmentId) async {
    await (_db.delete(_db.notificationLogs)
          ..where((t) => t.assignmentId.equals(assignmentId)))
        .go();
  }
}
```

- [ ] **Step 4: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/notification_logs_datasource_test.dart
```

Expected: All tests passed!

- [ ] **Step 5: コミットする**

```bash
git add lib/data/datasources/local/notification_logs_datasource.dart \
        test/data/datasources/local/notification_logs_datasource_test.dart
git commit -m "feat: NotificationLogsDataSourceを実装"
```

---

## Task 5: SnoozedItemsDataSource

**Files:**
- Create: `lib/data/datasources/local/snoozed_items_datasource.dart`
- Create: `test/data/datasources/local/snoozed_items_datasource_test.dart`

- [ ] **Step 1: テストを書く**

```dart
// test/data/datasources/local/snoozed_items_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/snoozed_items_datasource.dart';

void main() {
  late AppDatabase db;
  late SnoozedItemsDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = SnoozedItemsDataSource(db);
  });

  tearDown(() async => db.close());

  test('upsert した ID が getActiveSnoozed に含まれる', () async {
    final until = DateTime(2026, 5, 8, 14, 0);
    await ds.upsert('a1', until);
    final map = await ds.getActiveSnoozed(DateTime(2026, 5, 8, 12, 0));
    expect(map['a1'], until);
  });

  test('期限切れの ID は getActiveSnoozed に含まれない', () async {
    await ds.upsert('a1', DateTime(2026, 5, 8, 10, 0));
    final map = await ds.getActiveSnoozed(DateTime(2026, 5, 8, 12, 0));
    expect(map, isEmpty);
  });

  test('getExpiredIds で期限切れ ID のみ返す', () async {
    await ds.upsert('a1', DateTime(2026, 5, 8, 10, 0)); // expired
    await ds.upsert('a2', DateTime(2026, 5, 8, 14, 0)); // active
    final expired = await ds.getExpiredIds(DateTime(2026, 5, 8, 12, 0));
    expect(expired, {'a1'});
  });

  test('delete で ID が消える', () async {
    await ds.upsert('a1', DateTime(2026, 5, 8, 14, 0));
    await ds.delete('a1');
    final map = await ds.getActiveSnoozed(DateTime(2026, 5, 8, 12, 0));
    expect(map, isEmpty);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/data/datasources/local/snoozed_items_datasource_test.dart
```

Expected: FAIL — `SnoozedItemsDataSource` が未定義

- [ ] **Step 3: 実装する**

```dart
// lib/data/datasources/local/snoozed_items_datasource.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

class SnoozedItemsDataSource {
  SnoozedItemsDataSource(this._db);

  final AppDatabase _db;

  Future<void> upsert(String assignmentId, DateTime snoozedUntil) async {
    await _db.into(_db.snoozedItems).insertOnConflictUpdate(
      SnoozedItemsCompanion.insert(
        assignmentId: assignmentId,
        snoozedUntil: snoozedUntil,
      ),
    );
  }

  Future<Map<String, DateTime>> getActiveSnoozed(DateTime now) async {
    final rows = await (_db.select(_db.snoozedItems)
          ..where((t) => t.snoozedUntil.isBiggerThanValue(now)))
        .get();
    return {for (final r in rows) r.assignmentId: r.snoozedUntil};
  }

  Future<Set<String>> getExpiredIds(DateTime now) async {
    final rows = await (_db.select(_db.snoozedItems)
          ..where((t) => t.snoozedUntil.isSmallerOrEqualValue(now)))
        .get();
    return rows.map((r) => r.assignmentId).toSet();
  }

  Future<void> delete(String assignmentId) async {
    await (_db.delete(_db.snoozedItems)
          ..where((t) => t.assignmentId.equals(assignmentId)))
        .go();
  }
}
```

- [ ] **Step 4: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/snoozed_items_datasource_test.dart
```

Expected: All tests passed!

- [ ] **Step 5: コミットする**

```bash
git add lib/data/datasources/local/snoozed_items_datasource.dart \
        test/data/datasources/local/snoozed_items_datasource_test.dart
git commit -m "feat: SnoozedItemsDataSourceを実装"
```

---

## Task 6: providers.dart — 3 datasource プロバイダー追加

**Files:**
- Modify: `lib/core/di/providers.dart`

- [ ] **Step 1: 3プロバイダーを追加する**

`lib/core/di/providers.dart` を以下に置き換える:

```dart
// lib/core/di/providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
import '../services/classroom_sync_service.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/course_order_datasource.dart';
import '../../data/datasources/local/hidden_items_datasource.dart';
import '../../data/datasources/local/notification_logs_datasource.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';
import '../../data/repositories/google_classroom_repository.dart';
import '../../domain/repositories/lms_repository.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
part 'providers.g.dart';

@riverpod
AuthService authService(AuthServiceRef ref) => AuthService();

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
SyncStateDataSource syncStateDataSource(SyncStateDataSourceRef ref) =>
    SyncStateDataSource(ref.watch(appDatabaseProvider));

@riverpod
CourseOrderDataSource courseOrderDataSource(CourseOrderDataSourceRef ref) =>
    CourseOrderDataSource(ref.watch(appDatabaseProvider));

@riverpod
HiddenItemsDataSource hiddenItemsDataSource(HiddenItemsDataSourceRef ref) =>
    HiddenItemsDataSource(ref.watch(appDatabaseProvider));

@riverpod
UserPreferencesDataSource userPreferencesDataSource(
        UserPreferencesDataSourceRef ref) =>
    UserPreferencesDataSource(ref.watch(appDatabaseProvider));

@riverpod
NotificationLogsDataSource notificationLogsDataSource(
        NotificationLogsDataSourceRef ref) =>
    NotificationLogsDataSource(ref.watch(appDatabaseProvider));

@riverpod
SnoozedItemsDataSource snoozedItemsDataSource(
        SnoozedItemsDataSourceRef ref) =>
    SnoozedItemsDataSource(ref.watch(appDatabaseProvider));

@riverpod
GoogleClassroomRepository googleClassroomRepository(
    GoogleClassroomRepositoryRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  if (account == null) throw StateError('Not signed in');
  return GoogleClassroomRepository(
    database: ref.watch(appDatabaseProvider),
    account: account,
  );
}

@riverpod
LmsRepository lmsRepository(LmsRepositoryRef ref) =>
    ref.watch(googleClassroomRepositoryProvider);

@riverpod
ClassroomSyncService classroomSyncService(ClassroomSyncServiceRef ref) =>
    ClassroomSyncService(
      syncState: ref.watch(syncStateDataSourceProvider),
      repository: ref.watch(googleClassroomRepositoryProvider),
    );
```

- [ ] **Step 2: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `providers.g.dart` が再生成される

- [ ] **Step 3: 静的解析を確認する**

```bash
flutter analyze lib/
```

Expected: No issues found!

- [ ] **Step 4: コミットする**

```bash
git add lib/core/di/providers.dart lib/core/di/providers.g.dart
git commit -m "feat: UserPreferences/NotificationLogs/SnoozedItemsプロバイダーを追加"
```

---

## Task 7: CanDisableLazyModeUseCase

**Files:**
- Create: `lib/domain/usecases/can_disable_lazy_mode_usecase.dart`
- Create: `test/domain/usecases/can_disable_lazy_mode_usecase_test.dart`

- [ ] **Step 1: テストを書く**

```dart
// test/domain/usecases/can_disable_lazy_mode_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/usecases/can_disable_lazy_mode_usecase.dart';

void main() {
  const uc = CanDisableLazyModeUseCase();
  final now = DateTime(2026, 5, 8, 12, 0);
  const window = Duration(hours: 24);

  Assignment makeAssignment({
    required String id,
    required DateTime dueDate,
    SubmissionState? submissionState,
  }) =>
      Assignment(
        id: id,
        courseId: 'c1',
        title: 'Title',
        dueDate: dueDate,
        submissionState: submissionState,
      );

  test('期限内の未提出課題がある場合はカウント > 0', () {
    final assignments = [
      makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 1);
  });

  test('提出済み課題はカウントしない', () {
    final assignments = [
      makeAssignment(
        id: 'a1',
        dueDate: now.add(const Duration(hours: 12)),
        submissionState: SubmissionState.turnedIn,
      ),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 0);
  });

  test('期限外の課題はカウントしない', () {
    final assignments = [
      makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 48))),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 0);
  });

  test('期限なしの課題はカウントしない', () {
    final assignments = [
      const Assignment(id: 'a1', courseId: 'c1', title: 'No due'),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 0);
  });

  test('混在するケースで正しくカウントする', () {
    final assignments = [
      makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 6))),  // blocking
      makeAssignment(id: 'a2', dueDate: now.add(const Duration(hours: 30))), // outside window
      makeAssignment(
        id: 'a3',
        dueDate: now.add(const Duration(hours: 10)),
        submissionState: SubmissionState.turnedIn,
      ), // submitted
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 1);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/domain/usecases/can_disable_lazy_mode_usecase_test.dart
```

Expected: FAIL — `CanDisableLazyModeUseCase` が未定義

- [ ] **Step 3: 実装する**

```dart
// lib/domain/usecases/can_disable_lazy_mode_usecase.dart
import '../entities/assignment.dart';

class CanDisableLazyModeUseCase {
  const CanDisableLazyModeUseCase();

  int countBlockingAssignments({
    required List<Assignment> assignments,
    required Duration notifyBefore,
    required DateTime now,
  }) {
    final cutoff = now.add(notifyBefore);
    return assignments.where((a) {
      if (a.submissionState == SubmissionState.turnedIn) return false;
      if (a.dueDate == null) return false;
      return a.dueDate!.isBefore(cutoff);
    }).length;
  }
}
```

- [ ] **Step 4: テストを実行してパスを確認する**

```bash
flutter test test/domain/usecases/can_disable_lazy_mode_usecase_test.dart
```

Expected: All tests passed!

- [ ] **Step 5: コミットする**

```bash
git add lib/domain/usecases/can_disable_lazy_mode_usecase.dart \
        test/domain/usecases/can_disable_lazy_mode_usecase_test.dart
git commit -m "feat: CanDisableLazyModeUseCaseを実装"
```

---

## Task 8: NotificationService

**Files:**
- Create: `lib/core/services/notification_service.dart`

注: `NotificationService` は flutter_local_notifications / OS に強く依存するため単体テスト対象外。

- [ ] **Step 1: `notification_service.dart` を実装する**

```dart
// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/assignment.dart';

const _channelId = 'deadlines';
const _channelName = '締め切り通知';
const _categoryFull = 'deadline_full';
const _categoryLazy = 'deadline_lazy';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryFull,
          actions: [
            DarwinNotificationAction.plain('snooze_30min', '30分'),
            DarwinNotificationAction.plain('snooze_1h', '1時間'),
            DarwinNotificationAction.plain('snooze_3h', '3時間'),
          ],
        ),
        DarwinNotificationCategory(
          _categoryLazy,
          actions: [
            DarwinNotificationAction.plain('snooze_1h', '1時間'),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
    );
  }

  static void _onForegroundTap(NotificationResponse details) {
    // フォアグラウンドタップ: Phase 3b ではルーティング不要のため何もしない
  }

  Future<bool> isPermissionGranted() async {
    final androidGranted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
    if (androidGranted) return true;
    final iosPermissions = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    return iosPermissions?.isEnabled ?? false;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> show(Assignment assignment, {required bool lazyMode}) async {
    final notifId = assignment.id.hashCode.abs() % 0x7FFFFFFF;
    final due = assignment.dueDate!;
    final hoursLeft = due.difference(DateTime.now()).inHours;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      actions: lazyMode
          ? const [AndroidNotificationAction('snooze_1h', '1時間')]
          : const [
              AndroidNotificationAction('snooze_30min', '30分'),
              AndroidNotificationAction('snooze_1h', '1時間'),
              AndroidNotificationAction('snooze_3h', '3時間'),
            ],
    );

    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: lazyMode ? _categoryLazy : _categoryFull,
    );

    await _plugin.show(
      notifId,
      '締め切りまで${hoursLeft}時間',
      assignment.title,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: assignment.id,
    );
  }
}

@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse details) async {
  final assignmentId = details.payload;
  if (assignmentId == null || details.actionId == null) return;
  if (details.actionId == 'confirm') return;

  Duration snooze;
  switch (details.actionId) {
    case 'snooze_30min':
      snooze = const Duration(minutes: 30);
    case 'snooze_1h':
      snooze = const Duration(hours: 1);
    case 'snooze_3h':
      snooze = const Duration(hours: 3);
    default:
      return;
  }

  final db = await AppDatabase.openBackground();
  await SnoozedItemsDataSource(db).upsert(
    assignmentId,
    DateTime.now().add(snooze),
  );
  await db.close();
}
```

`onNotificationTapBackground` が参照する `AppDatabase` と `SnoozedItemsDataSource` を import するためにファイル先頭に追加:

```dart
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
```

- [ ] **Step 2: 静的解析を確認する**

```bash
flutter analyze lib/core/services/notification_service.dart
```

Expected: No issues found!

- [ ] **Step 3: コミットする**

```bash
git add lib/core/services/notification_service.dart
git commit -m "feat: NotificationServiceを実装"
```

---

## Task 9: BackgroundNotificationTask + callbackDispatcher

**Files:**
- Create: `lib/core/services/background_notification_task.dart`
- Create: `test/core/services/background_notification_task_test.dart`

- [ ] **Step 1: フィルタリングロジックのテストを書く**

```dart
// test/core/services/background_notification_task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/core/services/background_notification_task.dart';

void main() {
  final now = DateTime(2026, 5, 8, 12, 0);
  const window = Duration(hours: 24);

  Assignment makeAssignment({
    required String id,
    DateTime? dueDate,
    SubmissionState? submissionState,
  }) =>
      Assignment(
        id: id,
        courseId: 'c1',
        title: id,
        dueDate: dueDate,
        submissionState: submissionState,
      );

  test('期限内の未提出課題が候補になる', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result.map((a) => a.id), ['a1']);
  });

  test('期限外の課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 48))),
      ],
      notifiedIds: {},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('提出済み課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(
          id: 'a1',
          dueDate: now.add(const Duration(hours: 12)),
          submissionState: SubmissionState.turnedIn,
        ),
      ],
      notifiedIds: {},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('通知済みでスヌーズなしの課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('アクティブなスヌーズ中の課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {'a1': now.add(const Duration(hours: 1))},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('スヌーズ期限切れの課題は再通知候補になる', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {},
      expiredSnoozeIds: {'a1'},
      notifyBefore: window,
      now: now,
    );
    expect(result.map((a) => a.id), ['a1']);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/core/services/background_notification_task_test.dart
```

Expected: FAIL — `BackgroundNotificationTask` が未定義

- [ ] **Step 3: 実装する**

```dart
// lib/core/services/background_notification_task.dart
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/notification_logs_datasource.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';
import '../../domain/entities/assignment.dart';
import 'notification_service.dart';

const notificationTaskName = 'checkDeadlines';
const notificationTaskUniqueName = 'notificationTask';

class BackgroundNotificationTask {
  const BackgroundNotificationTask();

  Future<bool> execute(AppDatabase db) async {
    final now = DateTime.now();

    final prefsDs = UserPreferencesDataSource(db);
    final logsDs = NotificationLogsDataSource(db);
    final snoozeDs = SnoozedItemsDataSource(db);

    final notifyBeforeHours = await prefsDs.getNotifyBeforeHours();
    final lazyMode = await prefsDs.getLazyModeEnabled();
    final notifyBefore = Duration(hours: notifyBeforeHours);

    final rows = await db.select(db.assignments).get();
    final assignments = rows
        .where((r) =>
            r.state == 'published' &&
            r.submissionState != 'TURNED_IN' &&
            r.dueDateMillis != null)
        .map((r) => Assignment(
              id: r.id,
              courseId: r.courseId,
              title: r.title,
              dueDate: DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!),
              submissionState: r.submissionState == 'TURNED_IN'
                  ? SubmissionState.turnedIn
                  : null,
            ))
        .toList();

    final notifiedIds = await logsDs.getLoggedIds();
    final snoozedUntilMap = await snoozeDs.getActiveSnoozed(now);
    final expiredSnoozeIds = await snoozeDs.getExpiredIds(now);

    final candidates = filterCandidates(
      assignments: assignments,
      notifiedIds: notifiedIds,
      snoozedUntilMap: snoozedUntilMap,
      expiredSnoozeIds: expiredSnoozeIds,
      notifyBefore: notifyBefore,
      now: now,
    );

    final service = NotificationService._plugin;
    final notifService = NotificationService._();

    // スヌーズ期限切れ分を削除
    for (final id in expiredSnoozeIds) {
      if (candidates.any((a) => a.id == id)) {
        await snoozeDs.delete(id);
      }
    }

    for (final assignment in candidates) {
      await notifService.show(assignment, lazyMode: lazyMode);
      await logsDs.log(assignment.id);
    }

    return true;
  }

  static List<Assignment> filterCandidates({
    required List<Assignment> assignments,
    required Set<String> notifiedIds,
    required Map<String, DateTime> snoozedUntilMap,
    required Set<String> expiredSnoozeIds,
    required Duration notifyBefore,
    required DateTime now,
  }) {
    final cutoff = now.add(notifyBefore);
    return assignments.where((a) {
      if (a.submissionState == SubmissionState.turnedIn) return false;
      if (a.dueDate == null) return false;
      if (!a.dueDate!.isBefore(cutoff)) return false;

      // アクティブなスヌーズ中 → 候補外
      if (snoozedUntilMap.containsKey(a.id)) return false;

      // スヌーズ期限切れ → 再通知候補
      if (expiredSnoozeIds.contains(a.id)) return true;

      // 通知済みでスヌーズ記録なし → 候補外
      if (notifiedIds.contains(a.id)) return false;

      return true;
    }).toList();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.initialize();
    final db = await AppDatabase.openBackground();
    try {
      return await const BackgroundNotificationTask().execute(db);
    } finally {
      await db.close();
    }
  });
}
```

注: `NotificationService._()` と `NotificationService._plugin` は private なので、`execute` 内での呼び出しを `NotificationService` のインスタンスメソッドに書き換える必要がある。`notification_service.dart` の `NotificationService` クラスのコンストラクタを `const NotificationService()` にする（`_()` から変更）:

`lib/core/services/notification_service.dart` の `NotificationService._();` を `const NotificationService();` に変更する。

- [ ] **Step 4: notification_service.dart のコンストラクタを修正する**

`lib/core/services/notification_service.dart` の1行を修正:

変更前: `  NotificationService._();`
変更後: `  const NotificationService();`

- [ ] **Step 5: background_notification_task.dart の execute メソッドを修正する**

`execute` 内の以下2行を削除:

```dart
    final service = NotificationService._plugin;
    final notifService = NotificationService._();
```

かわりに `NotificationService()` で呼ぶよう修正:

```dart
    final notifService = const NotificationService();
```

- [ ] **Step 6: テストを実行してパスを確認する**

```bash
flutter test test/core/services/background_notification_task_test.dart
```

Expected: All tests passed!

- [ ] **Step 7: コミットする**

```bash
git add lib/core/services/background_notification_task.dart \
        lib/core/services/notification_service.dart \
        test/core/services/background_notification_task_test.dart
git commit -m "feat: BackgroundNotificationTaskとcallbackDispatcherを実装"
```

---

## Task 10: main.dart — workmanager 初期化

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: main.dart を更新する**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/auth_service.dart';
import 'core/services/background_notification_task.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialize();
  await NotificationService.initialize();
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    notificationTaskUniqueName,
    notificationTaskName,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 2: 静的解析を確認する**

```bash
flutter analyze lib/main.dart
```

Expected: No issues found!

- [ ] **Step 3: コミットする**

```bash
git add lib/main.dart
git commit -m "feat: workmanagerの定期タスク登録をmain.dartに追加"
```

---

## Task 11: SettingsViewModel

**Files:**
- Create: `lib/presentation/viewmodels/settings_viewmodel.dart`
- Create: `test/presentation/viewmodels/settings_viewmodel_test.dart`

- [ ] **Step 1: テストを書く**

```dart
// test/presentation/viewmodels/settings_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/data/datasources/local/user_preferences_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/presentation/viewmodels/settings_viewmodel.dart';

class MockUserPreferencesDataSource extends Mock
    implements UserPreferencesDataSource {}

void main() {
  late MockUserPreferencesDataSource mockPrefs;

  setUp(() {
    mockPrefs = MockUserPreferencesDataSource();
    when(() => mockPrefs.getNotifyBeforeHours()).thenAnswer((_) async => 24);
    when(() => mockPrefs.getLazyModeEnabled()).thenAnswer((_) async => false);
    when(() => mockPrefs.setNotifyBeforeHours(any()))
        .thenAnswer((_) async {});
    when(() => mockPrefs.setLazyModeEnabled(any())).thenAnswer((_) async {});
    when(() => mockPrefs.getOnboardingDone()).thenAnswer((_) async => false);
    when(() => mockPrefs.setOnboardingDone(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        userPreferencesDataSourceProvider.overrideWithValue(mockPrefs),
      ]);

  test('build 時に UserPreferences から設定を読み込む', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    final state = container.read(settingsViewModelProvider).value!;
    expect(state.notifyBeforeHours, 24);
    expect(state.lazyModeEnabled, false);
  });

  test('setNotifyBeforeHours で状態と datasource が更新される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setNotifyBeforeHours(48);
    verify(() => mockPrefs.setNotifyBeforeHours(48)).called(1);
    final state = container.read(settingsViewModelProvider).value!;
    expect(state.notifyBeforeHours, 48);
  });

  test('setNotifyBeforeHours(23) は無視される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setNotifyBeforeHours(23);
    verifyNever(() => mockPrefs.setNotifyBeforeHours(any()));
  });

  test('enableLazyMode で状態と datasource が更新される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    await container.read(settingsViewModelProvider.notifier).enableLazyMode();
    verify(() => mockPrefs.setLazyModeEnabled(true)).called(1);
    final state = container.read(settingsViewModelProvider).value!;
    expect(state.lazyModeEnabled, true);
  });

  test('tryDisableLazyMode — 未提出課題あり → false を返す', () async {
    when(() => mockPrefs.getLazyModeEnabled()).thenAnswer((_) async => true);
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    final now = DateTime.now();
    final blocking = [
      Assignment(
        id: 'a1',
        courseId: 'c1',
        title: 'A',
        dueDate: now.add(const Duration(hours: 12)),
      ),
    ];
    final result = await container
        .read(settingsViewModelProvider.notifier)
        .tryDisableLazyMode(blocking);
    expect(result, false);
    verifyNever(() => mockPrefs.setLazyModeEnabled(any()));
  });

  test('tryDisableLazyMode — 未提出課題なし → true を返し OFF に切り替わる', () async {
    when(() => mockPrefs.getLazyModeEnabled()).thenAnswer((_) async => true);
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    final result = await container
        .read(settingsViewModelProvider.notifier)
        .tryDisableLazyMode([]);
    expect(result, true);
    verify(() => mockPrefs.setLazyModeEnabled(false)).called(1);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/settings_viewmodel_test.dart
```

Expected: FAIL — `settingsViewModelProvider` が未定義

- [ ] **Step 3: 実装する**

```dart
// lib/presentation/viewmodels/settings_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/usecases/can_disable_lazy_mode_usecase.dart';
part 'settings_viewmodel.g.dart';

class SettingsState {
  const SettingsState({
    required this.notifyBeforeHours,
    required this.lazyModeEnabled,
  });

  final int notifyBeforeHours;
  final bool lazyModeEnabled;

  SettingsState copyWith({int? notifyBeforeHours, bool? lazyModeEnabled}) =>
      SettingsState(
        notifyBeforeHours: notifyBeforeHours ?? this.notifyBeforeHours,
        lazyModeEnabled: lazyModeEnabled ?? this.lazyModeEnabled,
      );
}

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  Future<SettingsState> build() async {
    final prefs = ref.watch(userPreferencesDataSourceProvider);
    final hours = await prefs.getNotifyBeforeHours();
    final lazy = await prefs.getLazyModeEnabled();
    return SettingsState(notifyBeforeHours: hours, lazyModeEnabled: lazy);
  }

  Future<void> setNotifyBeforeHours(int hours) async {
    if (hours < 24) return;
    await ref.read(userPreferencesDataSourceProvider).setNotifyBeforeHours(hours);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(notifyBeforeHours: hours));
  }

  Future<void> enableLazyMode() async {
    await ref.read(userPreferencesDataSourceProvider).setLazyModeEnabled(true);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(lazyModeEnabled: true));
  }

  Future<bool> tryDisableLazyMode(List<Assignment> assignments) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final count = const CanDisableLazyModeUseCase().countBlockingAssignments(
      assignments: assignments,
      notifyBefore: Duration(hours: current.notifyBeforeHours),
      now: DateTime.now(),
    );
    if (count > 0) return false;
    await ref.read(userPreferencesDataSourceProvider).setLazyModeEnabled(false);
    state = AsyncData(current.copyWith(lazyModeEnabled: false));
    return true;
  }

  Future<void> completeOnboarding() async {
    await ref.read(userPreferencesDataSourceProvider).setOnboardingDone(true);
  }
}
```

- [ ] **Step 4: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `settings_viewmodel.g.dart` が生成される

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/presentation/viewmodels/settings_viewmodel_test.dart
```

Expected: All tests passed!

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/viewmodels/settings_viewmodel.dart \
        lib/presentation/viewmodels/settings_viewmodel.g.dart \
        test/presentation/viewmodels/settings_viewmodel_test.dart
git commit -m "feat: SettingsViewModelを実装"
```

---

## Task 12: app_router.dart + ScaffoldWithNav — 設定タブ・オンボーディングルート追加

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/presentation/views/shared/scaffold_with_nav.dart`

- [ ] **Step 1: scaffold_with_nav.dart に設定タブを追加する**

```dart
// lib/presentation/views/shared/scaffold_with_nav.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: '課題',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: app_router.dart を更新する**

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';
import '../../core/di/providers.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/assignments/assignments_screen.dart';
import '../../presentation/views/auth/sign_in_screen.dart';
import '../../presentation/views/dashboard/dashboard_screen.dart';
import '../../presentation/views/notification_setup/notification_setup_screen.dart';
import '../../presentation/views/settings/settings_screen.dart';
import '../../presentation/views/shared/scaffold_with_nav.dart';
import '../../presentation/views/splash/splash_screen.dart';
part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      if (authState.isLoading) return '/splash';

      final isSignedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      if (!isSignedIn && loc != '/sign-in') return '/sign-in';
      if (!isSignedIn) return null;

      // サインイン済み: オンボーディング確認
      if (loc == '/sign-in' || loc == '/splash') {
        final prefsDs = ref.read(userPreferencesDataSourceProvider);
        final onboardingDone = await prefsDs.getOnboardingDone();
        return onboardingDone ? '/dashboard' : '/notification-setup';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: '/notification-setup',
        builder: (_, __) => const NotificationSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/assignments',
              builder: (_, __) => const AssignmentsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 3: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: 静的解析を確認する**

```bash
flutter analyze lib/core/router/ lib/presentation/views/shared/
```

Expected: No issues found! (SettingsScreen と NotificationSetupScreen は次のタスクで作成するため、このタスクでは一時的にエラーになる)

- [ ] **Step 5: コミットする**

```bash
git add lib/core/router/app_router.dart \
        lib/core/router/app_router.g.dart \
        lib/presentation/views/shared/scaffold_with_nav.dart
git commit -m "feat: ルーターに設定タブ・オンボーディングルートを追加"
```

---

## Task 13: NotificationSetupScreen — 初回オンボーディング

**Files:**
- Create: `lib/presentation/views/notification_setup/notification_setup_screen.dart`

- [ ] **Step 1: ディレクトリを作成して画面を実装する**

```bash
mkdir -p lib/presentation/views/notification_setup
```

```dart
// lib/presentation/views/notification_setup/notification_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../../core/services/notification_service.dart';

class NotificationSetupScreen extends ConsumerStatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  ConsumerState<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState
    extends ConsumerState<NotificationSetupScreen> {
  late TextEditingController _hoursController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '24');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _complete({required bool requestPermission}) async {
    final hours = int.tryParse(_hoursController.text) ?? 24;
    final notifier = ref.read(settingsViewModelProvider.notifier);
    await notifier.setNotifyBeforeHours(hours < 24 ? 24 : hours);
    if (requestPermission) {
      await NotificationService().requestPermission();
    }
    await notifier.completeOnboarding();
    if (mounted) context.go('/dashboard');
  }

  Future<void> _onLazyModeToggle(bool value) async {
    if (!value) {
      final assignments =
          ref.read(settingsViewModelProvider).valueOrNull?.lazyModeEnabled ==
                  true
              ? <dynamic>[]
              : <dynamic>[];
      ref.read(settingsViewModelProvider.notifier).enableLazyMode();
      return;
    }
    // value == true: 確認ダイアログ
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('怠惰人間モードを有効にしますか？'),
        description: const Text(
          '・スヌーズが1時間固定になります\n'
          '・OFFに戻すには、設定した通知タイミング以内に\n'
          '　締め切りがある課題をすべて提出するまで\n'
          '　無効にできません',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('有効にする'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(settingsViewModelProvider.notifier).enableLazyMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsViewModelProvider);
    final lazyMode = settingsAsync.valueOrNull?.lazyModeEnabled ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                '通知を設定しましょう',
                style: ShadTheme.of(context).textTheme.h3,
              ),
              const SizedBox(height: 32),
              Text(
                '締め切りの何時間前に通知しますか？',
                style: ShadTheme.of(context).textTheme.muted,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: ShadInput(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('時間前',
                      style: ShadTheme.of(context).textTheme.p),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('怠惰人間モード',
                          style: ShadTheme.of(context).textTheme.p),
                      Text('ONのときスヌーズは1時間固定',
                          style: ShadTheme.of(context).textTheme.muted),
                    ],
                  ),
                  ShadSwitch(
                    value: lazyMode,
                    onChanged: _onLazyModeToggle,
                  ),
                ],
              ),
              const Spacer(),
              ShadButton(
                onPressed: () => _complete(requestPermission: true),
                child: const Text('通知を許可して開始する'),
              ),
              const SizedBox(height: 12),
              ShadButton.ghost(
                onPressed: () => _complete(requestPermission: false),
                child: const Text('後でスキップ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 静的解析を確認する**

```bash
flutter analyze lib/presentation/views/notification_setup/
```

Expected: No issues found!

- [ ] **Step 3: コミットする**

```bash
git add lib/presentation/views/notification_setup/notification_setup_screen.dart
git commit -m "feat: 初回オンボーディング画面を実装"
```

---

## Task 14: SettingsScreen

**Files:**
- Create: `lib/presentation/views/settings/settings_screen.dart`

- [ ] **Step 1: SettingsScreen を実装する**

```dart
// lib/presentation/views/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _hoursController;
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController();
    _checkPermission();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService().isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _onLazyModeToggle(bool value) async {
    if (value) {
      // ON: 確認ダイアログ
      final confirmed = await showShadDialog<bool>(
        context: context,
        builder: (context) => ShadDialog(
          title: const Text('怠惰人間モードを有効にしますか？'),
          description: const Text(
            '・スヌーズが1時間固定になります\n'
            '・OFFに戻すには、設定した通知タイミング以内に\n'
            '　締め切りがある課題をすべて提出するまで\n'
            '　無効にできません',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ShadButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('有効にする'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(settingsViewModelProvider.notifier).enableLazyMode();
      }
    } else {
      // OFF: CanDisableLazyModeUseCase で判定
      final assignments = ref
              .read(assignmentsViewModelProvider)
              .valueOrNull
              ?.assignments ??
          [];
      final canDisable = await ref
          .read(settingsViewModelProvider.notifier)
          .tryDisableLazyMode(assignments);
      if (!canDisable && mounted) {
        final notifyBeforeHours = ref
                .read(settingsViewModelProvider)
                .valueOrNull
                ?.notifyBeforeHours ??
            24;
        final blocked = assignments
            .where((a) =>
                a.dueDate != null &&
                a.dueDate!
                    .isBefore(DateTime.now().add(Duration(hours: notifyBeforeHours))) &&
                a.submissionState?.name != 'turnedIn')
            .length;
        ShadToaster.of(context).show(
          ShadToast(
            title: Text('あと$blocked件提出するとOFFにできます'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsViewModelProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings != null && _hoursController.text.isEmpty) {
      _hoursController.text = settings.notifyBeforeHours.toString();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_permissionGranted)
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_off, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('通知が許可されていません')),
                    ShadButton.outline(
                      onPressed: () async {
                        await NotificationService().requestPermission();
                        await _checkPermission();
                      },
                      child: const Text('許可する'),
                    ),
                  ],
                ),
              ),
            ),
          if (!_permissionGranted) const SizedBox(height: 16),
          Text('通知タイミング',
              style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: ShadInput(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onEditingComplete: () {
                    final hours = int.tryParse(_hoursController.text) ?? 24;
                    if (hours < 24) {
                      _hoursController.text = '24';
                      ShadToaster.of(context).show(
                        const ShadToast(
                          title: Text('最低24時間以上を設定してください'),
                        ),
                      );
                    } else {
                      ref
                          .read(settingsViewModelProvider.notifier)
                          .setNotifyBeforeHours(hours);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('時間前に通知', style: ShadTheme.of(context).textTheme.p),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('怠惰人間モード',
                      style: ShadTheme.of(context).textTheme.p),
                  Text('ONのときスヌーズは1時間固定',
                      style: ShadTheme.of(context).textTheme.muted),
                ],
              ),
              ShadSwitch(
                value: settings?.lazyModeEnabled ?? false,
                onChanged: settings != null ? _onLazyModeToggle : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 静的解析を確認する**

```bash
flutter analyze lib/presentation/views/settings/
```

Expected: No issues found!

- [ ] **Step 3: コミットする**

```bash
git add lib/presentation/views/settings/settings_screen.dart
git commit -m "feat: 設定画面を実装"
```

---

## Task 15: 全テスト実行・動作確認・PR 作成

**Files:** なし（テスト・PR のみ）

- [ ] **Step 1: 全テストを実行する**

```bash
flutter test
```

Expected: All tests passed!

- [ ] **Step 2: 静的解析を実行する**

```bash
flutter analyze lib/
```

Expected: No issues found!

- [ ] **Step 3: iOS の Background Modes を確認する（手動）**

workmanager の iOS 動作には Xcode で Background Modes 設定が必要:
1. Xcode で `ios/Runner.xcworkspace` を開く
2. Runner ターゲット → Signing & Capabilities → `+ Capability` → "Background Modes" を追加
3. "Background fetch" と "Background processing" にチェックを入れる
4. `ios/Runner/Info.plist` に以下が追加されていることを確認:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>be.tramckrijte.workmanagerExample.iOSBackgroundAppRefresh</string>
</array>
```

- [ ] **Step 4: PR を作成する**

```bash
gh pr create \
  --title "feat: 締め切り通知・スヌーズ・怠惰人間モード・設定画面を実装" \
  --body "Closes #8

## 変更内容
- workmanager 1h定期タスクで締め切り前通知を発火
- スヌーズ機能（lazyMode OFF: 30分/1時間/3時間、ON: 1時間固定）
- 怠惰人間モード（確認ダイアログ + notifyBefore以内完了でのみOFF可能）
- 初回オンボーディング画面（/notification-setup）
- 設定画面 (/settings) をボトムナビに追加
- drift schema v3 (UserPreferences / NotificationLogs / SnoozedItems)

## テスト
- UserPreferencesDataSource: 6件
- NotificationLogsDataSource: 3件
- SnoozedItemsDataSource: 4件
- CanDisableLazyModeUseCase: 5件
- BackgroundNotificationTask.filterCandidates: 6件
- SettingsViewModel: 6件" \
  --base main
```

---

## 検証チェックリスト（Phase 3b 完了条件）

- [ ] `flutter test` で全テストが PASS する
- [ ] `flutter analyze lib/` でエラーなし
- [ ] 初回サインイン後にオンボーディング画面が表示される
- [ ] 怠惰人間モードをONにすると確認ダイアログが出る
- [ ] 「通知を許可して開始する」でOS通知許可ダイアログが出る
- [ ] ダッシュボード・課題・設定の3タブが機能する
- [ ] 設定画面で通知時間を24時間未満に設定しようとするとエラートーストが出る
- [ ] 設定画面で怠惰人間モードをOFFにしようとして課題が残っている場合「あとN件提出するとOFFにできます」が出る
