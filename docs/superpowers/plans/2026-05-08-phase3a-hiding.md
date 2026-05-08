# Phase 3a: コース・課題の非表示機能 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ダッシュボードのコース一覧と課題一覧で、長押し/スワイプで非表示にでき、フィルタートグルで復元できる機能を実装する。

**Architecture:** ViewModel クライアントサイドフィルタリング。drift `HiddenItems` テーブルに非表示 ID を保存し、`DashboardViewModel` / `AssignmentsViewModel` が `showHidden: bool` フラグでフィルタリングする。コースは `ReorderableListView` 制約により長押しのみ、課題は長押し + 左スワイプの両方をサポート。

**Tech Stack:** Flutter 3.x, drift 2.20, Riverpod 2.x (riverpod_annotation), shadcn_ui 0.54, mocktail

---

## ファイルマップ

| ファイル | 変更 | 役割 |
|---------|------|------|
| `lib/data/datasources/local/app_database.dart` | Modify | `HiddenItems` テーブル追加・schemaVersion 2・migration |
| `lib/data/datasources/local/hidden_items_datasource.dart` | Create | hide/unhide/getHiddenIds |
| `lib/domain/usecases/hide_item.dart` | Create | HideItemUseCase |
| `lib/domain/usecases/unhide_item.dart` | Create | UnhideItemUseCase |
| `lib/core/di/providers.dart` | Modify | hiddenItemsDataSourceProvider 追加 |
| `lib/presentation/viewmodels/dashboard_viewmodel.dart` | Modify | showHidden・hideItem・unhideItem・toggleShowHidden |
| `lib/presentation/viewmodels/assignments_viewmodel.dart` | Modify | showHidden・hideItem・unhideItem・toggleShowHidden |
| `lib/presentation/views/dashboard/widgets/course_list.dart` | Modify | 長押し ShadContextMenu・フィルタートグル・drag handle 修正 |
| `lib/presentation/views/assignments/assignments_screen.dart` | Modify | 長押し ShadContextMenu・Dismissible スワイプ・フィルタートグル |
| `test/data/datasources/local/hidden_items_datasource_test.dart` | Create | HiddenItemsDataSource 単体テスト |
| `test/presentation/viewmodels/dashboard_viewmodel_test.dart` | Modify | hideItem・unhideItem・toggleShowHidden テスト追加 |
| `test/presentation/viewmodels/assignments_viewmodel_test.dart` | Modify | hideItem・unhideItem・toggleShowHidden テスト追加 |

---

## Task 1: DB スキーマ migration（HiddenItems テーブル追加）

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`
- Modify: `test/data/datasources/local/app_database_test.dart`

- [ ] **Step 1: テストを書く**

`test/data/datasources/local/app_database_test.dart` に以下を追加する:

```dart
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
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
flutter test test/data/datasources/local/app_database_test.dart
```

Expected: `HiddenItem` が未定義でコンパイルエラー

- [ ] **Step 3: app_database.dart を更新する**

`lib/data/datasources/local/app_database.dart` を以下に置き換える:

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

@DriftDatabase(tables: [Courses, Assignments, CourseOrders, SyncStates, HiddenItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(hiddenItems);
          }
        },
      );
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
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` が再生成される（`hiddenItems` getter が追加される）

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/app_database_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/data/datasources/local/app_database.dart \
        lib/data/datasources/local/app_database.g.dart \
        test/data/datasources/local/app_database_test.dart
git commit -m "feat: HiddenItemsテーブルを追加・schemaVersion 2に更新"
```

---

## Task 2: HiddenItemsDataSource

**Files:**
- Create: `lib/data/datasources/local/hidden_items_datasource.dart`
- Create: `test/data/datasources/local/hidden_items_datasource_test.dart`

- [ ] **Step 1: テストを書く**

`test/data/datasources/local/hidden_items_datasource_test.dart` を新規作成する:

```dart
// test/data/datasources/local/hidden_items_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/hidden_items_datasource.dart';

void main() {
  late AppDatabase db;
  late HiddenItemsDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = HiddenItemsDataSource(db);
  });

  tearDown(() async => db.close());

  test('hide したアイテムが getHiddenIds に含まれる', () async {
    await ds.hide('c1', 'course');
    await ds.hide('c2', 'course');
    await ds.hide('a1', 'assignment');

    final courseIds = await ds.getHiddenIds('course');
    expect(courseIds, {'c1', 'c2'});

    final assignmentIds = await ds.getHiddenIds('assignment');
    expect(assignmentIds, {'a1'});
  });

  test('unhide したアイテムが getHiddenIds から消える', () async {
    await ds.hide('c1', 'course');
    await ds.unhide('c1');

    final ids = await ds.getHiddenIds('course');
    expect(ids, isEmpty);
  });

  test('同じ itemId を2回 hide しても重複しない', () async {
    await ds.hide('c1', 'course');
    await ds.hide('c1', 'course');

    final ids = await ds.getHiddenIds('course');
    expect(ids.length, 1);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/data/datasources/local/hidden_items_datasource_test.dart
```

Expected: `HiddenItemsDataSource` が未定義でコンパイルエラー

- [ ] **Step 3: HiddenItemsDataSource を実装する**

`lib/data/datasources/local/hidden_items_datasource.dart` を作成する:

```dart
// lib/data/datasources/local/hidden_items_datasource.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

class HiddenItemsDataSource {
  HiddenItemsDataSource(this._db);

  final AppDatabase _db;

  Future<Set<String>> getHiddenIds(String type) async {
    final rows = await (_db.select(_db.hiddenItems)
          ..where((t) => t.type.equals(type)))
        .get();
    return rows.map((r) => r.itemId).toSet();
  }

  Future<void> hide(String itemId, String type) async {
    await _db.into(_db.hiddenItems).insertOnConflictUpdate(
      HiddenItemsCompanion.insert(
        itemId: itemId,
        type: type,
        hiddenAt: DateTime.now(),
      ),
    );
  }

  Future<void> unhide(String itemId) async {
    await (_db.delete(_db.hiddenItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }
}
```

- [ ] **Step 4: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/hidden_items_datasource_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: コミットする**

```bash
git add lib/data/datasources/local/hidden_items_datasource.dart \
        test/data/datasources/local/hidden_items_datasource_test.dart
git commit -m "feat: HiddenItemsDataSourceを実装"
```

---

## Task 3: providers.dart に hiddenItemsDataSourceProvider を追加

**Files:**
- Modify: `lib/core/di/providers.dart`

- [ ] **Step 1: providers.dart を更新する**

`lib/core/di/providers.dart` を以下に置き換える:

```dart
// lib/core/di/providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
import '../services/classroom_sync_service.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/course_order_datasource.dart';
import '../../data/datasources/local/hidden_items_datasource.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
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
dart run build_runner build --delete-conflicting-outputs
```

Expected: `providers.g.dart` が再生成され `hiddenItemsDataSourceProvider` が追加される

- [ ] **Step 3: コミットする**

```bash
git add lib/core/di/providers.dart lib/core/di/providers.g.dart
git commit -m "feat: hiddenItemsDataSourceProviderを追加"
```

---

## Task 4: DashboardViewModel に非表示ロジックを追加

**Files:**
- Modify: `lib/presentation/viewmodels/dashboard_viewmodel.dart`
- Modify: `test/presentation/viewmodels/dashboard_viewmodel_test.dart`

- [ ] **Step 1: テストを追加する**

`test/presentation/viewmodels/dashboard_viewmodel_test.dart` を以下に置き換える:

```dart
// test/presentation/viewmodels/dashboard_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/core/services/classroom_sync_service.dart';
import 'package:classroom_remaked/data/datasources/local/course_order_datasource.dart';
import 'package:classroom_remaked/data/datasources/local/hidden_items_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/dashboard_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}
class MockClassroomSyncService extends Mock implements ClassroomSyncService {}
class MockCourseOrderDataSource extends Mock implements CourseOrderDataSource {}
class MockHiddenItemsDataSource extends Mock implements HiddenItemsDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(days: 7));
  });

  late MockLmsRepository mockRepo;
  late MockClassroomSyncService mockSync;
  late MockCourseOrderDataSource mockOrder;
  late MockHiddenItemsDataSource mockHidden;
  late ProviderContainer container;

  final fakeCourses = [
    const Course(id: 'c1', name: 'Math'),
    const Course(id: 'c2', name: 'Science'),
  ];

  ProviderContainer makeContainer({Set<String> hiddenIds = const {}}) {
    when(() => mockSync.fullSync()).thenAnswer((_) async {});
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getUpcomingDeadlines(within: any(named: 'within')))
        .thenAnswer((_) async => Right(<Assignment>[]));
    when(() => mockOrder.getOrderedIds())
        .thenAnswer((_) async => ['c1', 'c2']);
    when(() => mockOrder.initializeNewCourses(any()))
        .thenAnswer((_) async {});
    when(() => mockHidden.getHiddenIds('course'))
        .thenAnswer((_) async => hiddenIds);
    when(() => mockHidden.hide(any(), any())).thenAnswer((_) async {});
    when(() => mockHidden.unhide(any())).thenAnswer((_) async {});

    return ProviderContainer(
      overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
        classroomSyncServiceProvider.overrideWithValue(mockSync),
        courseOrderDataSourceProvider.overrideWithValue(mockOrder),
        hiddenItemsDataSourceProvider.overrideWithValue(mockHidden),
      ],
    );
  }

  setUp(() {
    mockRepo = MockLmsRepository();
    mockSync = MockClassroomSyncService();
    mockOrder = MockCourseOrderDataSource();
    mockHidden = MockHiddenItemsDataSource();
    container = makeContainer();
  });

  tearDown(() => container.dispose());

  test('build時にfullSyncを呼びDashboardStateを返す', () async {
    await container.read(dashboardViewModelProvider.future);
    final state = container.read(dashboardViewModelProvider);

    verify(() => mockSync.fullSync()).called(1);
    expect(state.value!.visibleCourses.length, 2);
    expect(state.value!.visibleCourses.first.id, 'c1');
  });

  test('非表示コースは visibleCourses に含まれない', () async {
    container.dispose();
    container = makeContainer(hiddenIds: {'c1'});

    await container.read(dashboardViewModelProvider.future);
    final state = container.read(dashboardViewModelProvider);

    expect(state.value!.visibleCourses.length, 1);
    expect(state.value!.visibleCourses.first.id, 'c2');
  });

  test('toggleShowHidden で非表示コースが表示される', () async {
    container.dispose();
    container = makeContainer(hiddenIds: {'c1'});

    await container.read(dashboardViewModelProvider.future);
    container.read(dashboardViewModelProvider.notifier).toggleShowHidden();
    final state = container.read(dashboardViewModelProvider);

    expect(state.value!.showHidden, isTrue);
    expect(state.value!.visibleCourses.length, 2);
  });

  test('hideItem が HiddenItemsDataSource.hide を呼ぶ', () async {
    await container.read(dashboardViewModelProvider.future);
    await container
        .read(dashboardViewModelProvider.notifier)
        .hideItem('c1');

    verify(() => mockHidden.hide('c1', 'course')).called(1);
  });

  test('reorderCourses で並び順が更新される', () async {
    when(() => mockOrder.updateOrder(any())).thenAnswer((_) async {});

    await container.read(dashboardViewModelProvider.future);
    await container
        .read(dashboardViewModelProvider.notifier)
        .reorderCourses(0, 2);

    verify(() => mockOrder.updateOrder(['c2', 'c1'])).called(1);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/dashboard_viewmodel_test.dart
```

Expected: `visibleCourses`・`showHidden`・`hideItem`・`toggleShowHidden` が未定義でエラー

- [ ] **Step 3: DashboardViewModel を更新する**

`lib/presentation/viewmodels/dashboard_viewmodel.dart` を以下に置き換える:

```dart
// lib/presentation/viewmodels/dashboard_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/course.dart';
part 'dashboard_viewmodel.g.dart';

class DashboardState {
  const DashboardState({
    required this.courses,
    required this.hiddenCourseIds,
    required this.orderedCourseIds,
    required this.upcomingDeadlines,
    this.showHidden = false,
  });

  final List<Course> courses;
  final Set<String> hiddenCourseIds;
  final List<String> orderedCourseIds;
  final List<Assignment> upcomingDeadlines;
  final bool showHidden;

  List<Course> get _orderedCourses {
    if (orderedCourseIds.isEmpty) return courses;
    final map = {for (final c in courses) c.id: c};
    final ordered = orderedCourseIds
        .map((id) => map[id])
        .whereType<Course>()
        .toList();
    final orderedSet = orderedCourseIds.toSet();
    final rest = courses.where((c) => !orderedSet.contains(c.id));
    return [...ordered, ...rest];
  }

  List<Course> get visibleCourses {
    if (showHidden) return _orderedCourses;
    return _orderedCourses
        .where((c) => !hiddenCourseIds.contains(c.id))
        .toList();
  }

  bool isHidden(String courseId) => hiddenCourseIds.contains(courseId);

  DashboardState copyWith({
    List<Course>? courses,
    Set<String>? hiddenCourseIds,
    List<String>? orderedCourseIds,
    List<Assignment>? upcomingDeadlines,
    bool? showHidden,
  }) =>
      DashboardState(
        courses: courses ?? this.courses,
        hiddenCourseIds: hiddenCourseIds ?? this.hiddenCourseIds,
        orderedCourseIds: orderedCourseIds ?? this.orderedCourseIds,
        upcomingDeadlines: upcomingDeadlines ?? this.upcomingDeadlines,
        showHidden: showHidden ?? this.showHidden,
      );
}

@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  Future<DashboardState> build() async {
    final sync = ref.watch(classroomSyncServiceProvider);
    final repo = ref.watch(lmsRepositoryProvider);
    final orderDs = ref.watch(courseOrderDataSourceProvider);
    final hiddenDs = ref.watch(hiddenItemsDataSourceProvider);

    await sync.fullSync();

    final coursesResult = await repo.getCourses();
    final deadlinesResult =
        await repo.getUpcomingDeadlines(within: const Duration(days: 7));

    final courses = coursesResult.getOrElse(() => []);
    final deadlines = deadlinesResult.getOrElse(() => []);

    await orderDs.initializeNewCourses(courses.map((c) => c.id).toList());
    final orderedIds = await orderDs.getOrderedIds();
    final hiddenIds = await hiddenDs.getHiddenIds('course');

    return DashboardState(
      courses: courses,
      hiddenCourseIds: hiddenIds,
      orderedCourseIds: orderedIds,
      upcomingDeadlines: deadlines,
    );
  }

  Future<void> reorderCourses(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final ids =
        List<String>.from(current.visibleCourses.map((c) => c.id));
    if (newIndex > oldIndex) newIndex--;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);

    await ref.read(courseOrderDataSourceProvider).updateOrder(ids);
    state = AsyncData(current.copyWith(orderedCourseIds: ids));
  }

  Future<void> hideItem(String courseId) async {
    await ref.read(hiddenItemsDataSourceProvider).hide(courseId, 'course');
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      hiddenCourseIds: {...current.hiddenCourseIds, courseId},
    ));
  }

  Future<void> unhideItem(String courseId) async {
    await ref.read(hiddenItemsDataSourceProvider).unhide(courseId);
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = Set<String>.from(current.hiddenCourseIds)
      ..remove(courseId);
    state = AsyncData(current.copyWith(hiddenCourseIds: updated));
  }

  void toggleShowHidden() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(showHidden: !current.showHidden));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(classroomSyncServiceProvider).forceRefresh();
    ref.invalidateSelf();
  }
}
```

- [ ] **Step 4: コード生成を実行する**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `dashboard_viewmodel.g.dart` が再生成される

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/presentation/viewmodels/dashboard_viewmodel_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/viewmodels/dashboard_viewmodel.dart \
        lib/presentation/viewmodels/dashboard_viewmodel.g.dart \
        test/presentation/viewmodels/dashboard_viewmodel_test.dart
git commit -m "feat: DashboardViewModelに非表示ロジックを追加"
```

---

## Task 5: AssignmentsViewModel に非表示ロジックを追加

**Files:**
- Modify: `lib/presentation/viewmodels/assignments_viewmodel.dart`
- Modify: `test/presentation/viewmodels/assignments_viewmodel_test.dart`

- [ ] **Step 1: 既存テストを確認してから追加テストを書く**

`test/presentation/viewmodels/assignments_viewmodel_test.dart` を以下に置き換える:

```dart
// test/presentation/viewmodels/assignments_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/data/datasources/local/hidden_items_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/assignments_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}
class MockHiddenItemsDataSource extends Mock implements HiddenItemsDataSource {}

void main() {
  late MockLmsRepository mockRepo;
  late MockHiddenItemsDataSource mockHidden;
  late ProviderContainer container;

  final fakeCourses = [const Course(id: 'c1', name: 'Math')];
  final fakeAssignments = [
    Assignment(
      id: 'a1',
      courseId: 'c1',
      title: 'Assignment 1',
      dueDate: DateTime(2026, 6, 1),
    ),
    Assignment(
      id: 'a2',
      courseId: 'c1',
      title: 'Assignment 2',
      dueDate: DateTime(2026, 6, 2),
    ),
  ];

  ProviderContainer makeContainer({Set<String> hiddenIds = const {}}) {
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getAssignments(any()))
        .thenAnswer((_) async => Right(fakeAssignments));
    when(() => mockHidden.getHiddenIds('assignment'))
        .thenAnswer((_) async => hiddenIds);
    when(() => mockHidden.hide(any(), any())).thenAnswer((_) async {});
    when(() => mockHidden.unhide(any())).thenAnswer((_) async {});

    return ProviderContainer(
      overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
        hiddenItemsDataSourceProvider.overrideWithValue(mockHidden),
      ],
    );
  }

  setUp(() {
    mockRepo = MockLmsRepository();
    mockHidden = MockHiddenItemsDataSource();
    container = makeContainer();
  });

  tearDown(() => container.dispose());

  test('build時に課題一覧を締め切り順で返す', () async {
    await container.read(assignmentsViewModelProvider.future);
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.visibleAssignments.length, 2);
    expect(state.value!.visibleAssignments.first.id, 'a1');
  });

  test('非表示課題は visibleAssignments に含まれない', () async {
    container.dispose();
    container = makeContainer(hiddenIds: {'a1'});

    await container.read(assignmentsViewModelProvider.future);
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.visibleAssignments.length, 1);
    expect(state.value!.visibleAssignments.first.id, 'a2');
  });

  test('toggleShowHidden で非表示課題が表示される', () async {
    container.dispose();
    container = makeContainer(hiddenIds: {'a1'});

    await container.read(assignmentsViewModelProvider.future);
    container.read(assignmentsViewModelProvider.notifier).toggleShowHidden();
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.showHidden, isTrue);
    expect(state.value!.visibleAssignments.length, 2);
  });

  test('hideItem が HiddenItemsDataSource.hide を呼ぶ', () async {
    await container.read(assignmentsViewModelProvider.future);
    await container
        .read(assignmentsViewModelProvider.notifier)
        .hideItem('a1');

    verify(() => mockHidden.hide('a1', 'assignment')).called(1);
  });

  test('setFilter で未提出のみ絞り込める', () async {
    await container.read(assignmentsViewModelProvider.future);
    container
        .read(assignmentsViewModelProvider.notifier)
        .setFilter(AssignmentsFilter.unsubmitted);
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.filter, AssignmentsFilter.unsubmitted);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/assignments_viewmodel_test.dart
```

Expected: `visibleAssignments`・`showHidden`・`hideItem`・`toggleShowHidden` が未定義でエラー

- [ ] **Step 3: AssignmentsViewModel を更新する**

`lib/presentation/viewmodels/assignments_viewmodel.dart` を以下に置き換える:

```dart
// lib/presentation/viewmodels/assignments_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
part 'assignments_viewmodel.g.dart';

enum AssignmentsFilter { all, unsubmitted }

class AssignmentsState {
  const AssignmentsState({
    required this.assignments,
    required this.hiddenAssignmentIds,
    this.filter = AssignmentsFilter.all,
    this.showHidden = false,
  });

  final List<Assignment> assignments;
  final Set<String> hiddenAssignmentIds;
  final AssignmentsFilter filter;
  final bool showHidden;

  List<Assignment> get visibleAssignments {
    var list = showHidden
        ? assignments
        : assignments.where((a) => !hiddenAssignmentIds.contains(a.id)).toList();

    if (filter == AssignmentsFilter.unsubmitted) {
      list = list
          .where((a) => a.submissionState != SubmissionState.turnedIn)
          .toList();
    }
    return list;
  }

  bool isHidden(String assignmentId) =>
      hiddenAssignmentIds.contains(assignmentId);

  AssignmentsState copyWith({
    List<Assignment>? assignments,
    Set<String>? hiddenAssignmentIds,
    AssignmentsFilter? filter,
    bool? showHidden,
  }) =>
      AssignmentsState(
        assignments: assignments ?? this.assignments,
        hiddenAssignmentIds: hiddenAssignmentIds ?? this.hiddenAssignmentIds,
        filter: filter ?? this.filter,
        showHidden: showHidden ?? this.showHidden,
      );
}

@riverpod
class AssignmentsViewModel extends _$AssignmentsViewModel {
  @override
  Future<AssignmentsState> build() async {
    final repo = ref.watch(lmsRepositoryProvider);
    final hiddenDs = ref.watch(hiddenItemsDataSourceProvider);

    final coursesResult = await repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);

    final results =
        await Future.wait(courses.map((c) => repo.getAssignments(c.id)));

    final all = results
        .expand((r) => r.getOrElse(() => []))
        .where((a) => a.state == AssignmentState.published)
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    final hiddenIds = await hiddenDs.getHiddenIds('assignment');

    return AssignmentsState(
      assignments: all,
      hiddenAssignmentIds: hiddenIds,
    );
  }

  void setFilter(AssignmentsFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }

  void toggleShowHidden() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(showHidden: !current.showHidden));
  }

  Future<void> hideItem(String assignmentId) async {
    await ref
        .read(hiddenItemsDataSourceProvider)
        .hide(assignmentId, 'assignment');
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      hiddenAssignmentIds: {...current.hiddenAssignmentIds, assignmentId},
    ));
  }

  Future<void> unhideItem(String assignmentId) async {
    await ref.read(hiddenItemsDataSourceProvider).unhide(assignmentId);
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = Set<String>.from(current.hiddenAssignmentIds)
      ..remove(assignmentId);
    state = AsyncData(current.copyWith(hiddenAssignmentIds: updated));
  }
}
```

- [ ] **Step 4: コード生成を実行する**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `assignments_viewmodel.g.dart` が再生成される

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/presentation/viewmodels/assignments_viewmodel_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: 全テストを実行する**

```bash
flutter test
```

Expected: 全テスト PASS（既存テストが壊れていないこと）

- [ ] **Step 7: コミットする**

```bash
git add lib/presentation/viewmodels/assignments_viewmodel.dart \
        lib/presentation/viewmodels/assignments_viewmodel.g.dart \
        test/presentation/viewmodels/assignments_viewmodel_test.dart
git commit -m "feat: AssignmentsViewModelに非表示ロジックを追加"
```

---

## Task 6: CourseList ウィジェット更新（長押しコンテキストメニュー + フィルタートグル）

**Files:**
- Modify: `lib/presentation/views/dashboard/widgets/course_list.dart`

> **注意:** `ReorderableListView` と `Dismissible` は競合するため、コースの非表示操作は長押しのみ。スワイプ非表示は Task 7 の課題一覧のみ実装する。
> 現在の実装では `ReorderableListView` がデフォルトで長押し全体でドラッグを開始するため、まず `buildDefaultDragHandles: false` + `ReorderableDragStartListener` に切り替える。

- [ ] **Step 1: course_list.dart を更新する**

`lib/presentation/views/dashboard/widgets/course_list.dart` を以下に置き換える:

```dart
// lib/presentation/views/dashboard/widgets/course_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../domain/entities/course.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';

class CourseList extends ConsumerWidget {
  const CourseList({super.key});

  static final _fakeCourses = List.generate(
    4,
    (i) => Course(id: 'fake_$i', name: 'Course Name Example'),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardViewModelProvider);

    if (async.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: _buildStaticList(context, _fakeCourses),
      );
    }

    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }

    final dashState = async.value!;
    final courses = dashState.visibleCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HiddenToggleRow(),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) => ref
              .read(dashboardViewModelProvider.notifier)
              .reorderCourses(oldIndex, newIndex),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final isHidden = dashState.isHidden(course.id);
            return _CourseCard(
              key: ValueKey(course.id),
              course: course,
              isHidden: isHidden,
              index: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStaticList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) =>
          _CourseCard(
            key: ValueKey(courses[index].id),
            course: courses[index],
            isHidden: false,
            index: index,
          ),
    );
  }
}

class _HiddenToggleRow extends ConsumerWidget {
  const _HiddenToggleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHidden =
        ref.watch(dashboardViewModelProvider).valueOrNull?.showHidden ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadButton.ghost(
            onPressed: () => ref
                .read(dashboardViewModelProvider.notifier)
                .toggleShowHidden(),
            child: Row(
              children: [
                Icon(
                  showHidden ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(showHidden ? '非表示を隠す' : '非表示も表示'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({
    super.key,
    required this.course,
    required this.isHidden,
    required this.index,
  });

  final Course course;
  final bool isHidden;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);

    return Opacity(
      opacity: isHidden ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ShadContextMenu(
          items: [
            if (isHidden)
              ShadContextMenuItem(
                leading: const Icon(Icons.visibility, size: 16),
                onPressed: () => notifier.unhideItem(course.id),
                child: const Text('非表示を解除'),
              )
            else
              ShadContextMenuItem(
                leading: const Icon(Icons.visibility_off, size: 16),
                onPressed: () => notifier.hideItem(course.id),
                child: const Text('非表示にする'),
              ),
          ],
          child: ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (course.section != null)
                          Text(course.section!,
                              style: ShadTheme.of(context).textTheme.muted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze を実行して型エラーがないか確認する**

```bash
flutter analyze lib/presentation/views/dashboard/widgets/course_list.dart
```

Expected: エラーなし（警告のみ許容）

- [ ] **Step 3: コミットする**

```bash
git add lib/presentation/views/dashboard/widgets/course_list.dart
git commit -m "feat: コース一覧に長押し非表示メニューとフィルタートグルを追加"
```

---

## Task 7: AssignmentsScreen 更新（長押し + 左スワイプ + フィルタートグル）

**Files:**
- Modify: `lib/presentation/views/assignments/assignments_screen.dart`

- [ ] **Step 1: assignments_screen.dart を更新する**

`lib/presentation/views/assignments/assignments_screen.dart` を以下に置き換える:

```dart
// lib/presentation/views/assignments/assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  static final _fakeAssignments = List.generate(
    5,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Assignment Title Example Long',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('課題')),
      body: Column(
        children: [
          _FilterBar(
            filter: async.valueOrNull?.filter ?? AssignmentsFilter.all,
            showHidden: async.valueOrNull?.showHidden ?? false,
          ),
          Expanded(child: _buildList(context, async)),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, AsyncValue<AssignmentsState> async) {
    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }
    final isLoading = async.isLoading;
    final assignments =
        async.valueOrNull?.visibleAssignments ?? _fakeAssignments;
    final state = async.valueOrNull;

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          final isHidden = state?.isHidden(assignment.id) ?? false;
          return _AssignmentCard(
            assignment: assignment,
            isHidden: isHidden,
          );
        },
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter, required this.showHidden});

  final AssignmentsFilter filter;
  final bool showHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignmentsViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...AssignmentsFilter.values.map((f) {
            final isSelected = f == filter;
            final label =
                f == AssignmentsFilter.all ? 'すべて' : '未提出';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isSelected
                  ? ShadButton(
                      onPressed: () {},
                      child: Text(label),
                    )
                  : ShadButton.outline(
                      onPressed: () => notifier.setFilter(f),
                      child: Text(label),
                    ),
            );
          }),
          const Spacer(),
          ShadButton.ghost(
            onPressed: () => notifier.toggleShowHidden(),
            child: Row(
              children: [
                Icon(
                  showHidden ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(showHidden ? '非表示を隠す' : '非表示も表示'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.isHidden,
  });

  final Assignment assignment;
  final bool isHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignmentsViewModelProvider.notifier);

    return Opacity(
      opacity: isHidden ? 0.4 : 1.0,
      child: Dismissible(
        key: ValueKey('dismiss_${assignment.id}'),
        direction: isHidden
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.red.shade100,
          child: const Icon(Icons.visibility_off, color: Colors.red),
        ),
        confirmDismiss: (_) async {
          await notifier.hideItem(assignment.id);
          if (context.mounted) {
            ShadToaster.of(context).show(
              ShadToast(
                title: const Text('課題を非表示にしました'),
                action: ShadButton.outline(
                  onPressed: () => notifier.unhideItem(assignment.id),
                  child: const Text('元に戻す'),
                ),
              ),
            );
          }
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShadContextMenu(
            items: [
              if (isHidden)
                ShadContextMenuItem(
                  leading: const Icon(Icons.visibility, size: 16),
                  onPressed: () => notifier.unhideItem(assignment.id),
                  child: const Text('非表示を解除'),
                )
              else
                ShadContextMenuItem(
                  leading: const Icon(Icons.visibility_off, size: 16),
                  onPressed: () => notifier.hideItem(assignment.id),
                  child: const Text('非表示にする'),
                ),
            ],
            child: _AssignmentCardContent(assignment: assignment),
          ),
        ),
      ),
    );
  }
}

class _AssignmentCardContent extends StatelessWidget {
  const _AssignmentCardContent({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final isSubmitted =
        assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (due != null)
                    Text(
                      '締め切り: ${DateFormat('yyyy/M/d HH:mm').format(due)}',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSubmitted)
              const ShadBadge.secondary(child: Text('提出済み'))
            else if (isOverdue)
              const ShadBadge(
                  backgroundColor: Colors.red, child: Text('期限切れ'))
            else if (due != null)
              ShadBadge.outline(
                child: Text('${due.difference(DateTime.now()).inDays}日後'),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze を実行する**

```bash
flutter analyze lib/presentation/views/assignments/assignments_screen.dart
```

Expected: エラーなし

- [ ] **Step 3: コミットする**

```bash
git add lib/presentation/views/assignments/assignments_screen.dart
git commit -m "feat: 課題一覧に長押し・スワイプ非表示とフィルタートグルを追加"
```

---

## Task 8: 全テスト実行・動作確認・PR 作成

**Files:**
- なし（動作確認・PR 操作のみ）

- [ ] **Step 1: 全テストを実行する**

```bash
flutter test
```

Expected: 全テスト PASS

- [ ] **Step 2: flutter analyze を実行する**

```bash
flutter analyze
```

Expected: エラーなし

- [ ] **Step 3: PR を作成する**

```bash
gh pr create \
  --title "feat: コース・課題の非表示機能を実装" \
  --body "## 変更内容
- HiddenItems drift テーブル追加（schemaVersion 1→2、migration 付き）
- HiddenItemsDataSource（hide/unhide/getHiddenIds）
- DashboardViewModel・AssignmentsViewModel に showHidden フラグ追加
- コース: 長押し ShadContextMenu で非表示/解除
- 課題: 長押し + 左スワイプ（ShadSonner で元に戻す）で非表示/解除
- フィルタートグルで非表示アイテムをグレーアウト表示

## テスト
- HiddenItemsDataSource: 3件
- DashboardViewModel: 5件
- AssignmentsViewModel: 5件" \
  --base main
```

Expected: PR URL が表示される
