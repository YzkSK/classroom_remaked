# Classroom Remaked — Phase 2: Dashboard + Assignments (Pub/Sub対応)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** キャッシュファースト + Google Cloud Pub/Sub push通知でAPI呼び出しを最小化しつつ、ダッシュボード（コース一覧・直近締め切り・ドラッグ&ドロップ並び替え）と課題一覧（締め切り順・フィルター）を実装する。

**Architecture:** `GoogleClassroomRepository` はキャッシュファースト（drift優先、空の場合のみAPI）。変更通知は `registrations.create` → Cloud Pub/Sub pull で受け取り、変更があったコースのみ選択的にAPIリフレッシュ。`PubSubService` がPub/Sub管理、`ClassroomSyncService` がキャッシュ無効化を担う。

**API呼び出し戦略:**
- 初回起動: getCourses（1回） + getAssignments×コース数
- 2回目以降: Pub/Sub pull（1回） → 変更コースのみrefreshAssignments

**Tech Stack:** drift 2.20, googleapis 13.x（pubsub/v1 + classroom/v1）, google_sign_in 7.x, flutter_riverpod 2.6, shadcn_ui 0.54, skeletonizer 2.1, go_router 14.x

---

## ファイルマップ

| ファイル | 役割 |
|---------|------|
| `lib/core/constants/app_constants.dart` | GCPプロジェクトID定数 |
| `lib/core/services/auth_service.dart` | pubsub・push-notificationsスコープ追加 |
| `lib/data/datasources/local/app_database.dart` | SyncStatesテーブル追加 |
| `lib/data/datasources/local/course_order_datasource.dart` | コース並び順CRUD |
| `lib/data/datasources/local/sync_state_datasource.dart` | Pub/Sub登録有効期限・セットアップ状態保存 |
| `lib/data/datasources/remote/classroom_http_client.dart` | OAuth2トークン付与HTTPクライアント |
| `lib/data/repositories/google_classroom_repository.dart` | LmsRepository実装（キャッシュファースト） |
| `lib/core/services/pubsub_service.dart` | Pub/Subトピック/サブスクリプション/IAM/registration管理 |
| `lib/core/services/classroom_sync_service.dart` | pull→差分検出→キャッシュ更新のオーケストレーション |
| `lib/core/di/providers.dart` | 全プロバイダー |
| `lib/presentation/viewmodels/dashboard_viewmodel.dart` | DashboardViewModel |
| `lib/presentation/viewmodels/assignments_viewmodel.dart` | AssignmentsViewModel |
| `lib/presentation/views/shared/scaffold_with_nav.dart` | BottomNavigationBarシェル |
| `lib/presentation/views/dashboard/dashboard_screen.dart` | ダッシュボード（置換） |
| `lib/presentation/views/dashboard/widgets/course_list.dart` | ReorderableListView |
| `lib/presentation/views/dashboard/widgets/deadline_widget.dart` | 直近7日締め切り |
| `lib/presentation/views/assignments/assignments_screen.dart` | 課題一覧 |
| `lib/core/router/app_router.dart` | StatefulShellRoute（更新） |
| `test/data/repositories/google_classroom_repository_test.dart` | Repositoryテスト |
| `test/presentation/viewmodels/dashboard_viewmodel_test.dart` | DashboardViewModelテスト |
| `test/presentation/viewmodels/assignments_viewmodel_test.dart` | AssignmentsViewModelテスト |

---

## Task 1: Branchセットアップ

- [ ] **Step 1: ブランチを作成する**

```bash
git checkout main && git pull origin main
git checkout -b page/dashboard
git checkout -b feature/3-4-5-7-phase2-dashboard
```

---

## Task 2: GCP Project ID 設定（手動確認あり）

**Files:**
- Create: `lib/core/constants/app_constants.dart`

- [ ] **Step 1: GCPプロジェクトIDを確認する**

Google Cloud Console (https://console.cloud.google.com/) を開き、プロジェクト選択メニューで「ClassroomRemaked」プロジェクトの **プロジェクトID**（文字列、例: `classroomremaked-12345`）をメモする。  
※プロジェクト番号（`184568296872`）とは別物。

- [ ] **Step 2: `app_constants.dart` を作成する**

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const gcpProjectId = 'YOUR_GCP_PROJECT_ID'; // ← 実際のIDに変更
  static const pubsubTopicId = 'classroom-changes';
  static const pubsubSubscriptionId = 'classroom-changes-sub';
  static const classroomServiceAccount =
      'classroom-notifications@system.gserviceaccount.com';
}
```

- [ ] **Step 3: コミットする**

```bash
git add lib/core/constants/app_constants.dart
git commit -m "chore: GCPプロジェクトID定数を追加"
```

---

## Task 3: AuthService スコープ更新

**Files:**
- Modify: `lib/core/services/auth_service.dart`

- [ ] **Step 1: pubsubとpush-notificationsスコープを追加する**

`lib/core/services/auth_service.dart` の `scopes` を以下に置き換える:

```dart
static const scopes = [
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
  'https://www.googleapis.com/auth/classroom.announcements.readonly',
  'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
  'https://www.googleapis.com/auth/classroom.rosters.readonly',
  'https://www.googleapis.com/auth/classroom.push-notifications',
  'https://www.googleapis.com/auth/pubsub',
];
```

- [ ] **Step 2: テストがまだパスすることを確認する**

```bash
flutter test test/core/services/auth_service_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 3: コミットする**

```bash
git add lib/core/services/auth_service.dart
git commit -m "feat: Pub/Sub認証スコープを追加"
```

---

## Task 4: Drift DB スキーマ（SyncStates追加）

**Files:**
- Create: `lib/data/datasources/local/app_database.dart`
- Create: `lib/data/datasources/local/sync_state_datasource.dart`
- Create: `lib/data/datasources/local/course_order_datasource.dart`
- Create: `test/data/datasources/local/app_database_test.dart`

- [ ] **Step 1: テストを先に書く**

```dart
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
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/data/datasources/local/app_database_test.dart
```

Expected: FAIL — `AppDatabase` が未定義

- [ ] **Step 3: `app_database.dart` を作成する**

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
```

- [ ] **Step 4: `sync_state_datasource.dart` を作成する**

```dart
// lib/data/datasources/local/sync_state_datasource.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

class SyncStateDataSource {
  SyncStateDataSource(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (
      _db.select(_db.syncStates)..where((t) => t.key.equals(key))
    ).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await _db.into(_db.syncStates).insertOnConflictUpdate(
      SyncStatesCompanion.insert(key: key, value: value),
    );
  }

  Future<void> delete(String key) async {
    await (_db.delete(_db.syncStates)..where((t) => t.key.equals(key))).go();
  }
}
```

- [ ] **Step 5: `course_order_datasource.dart` を作成する**

```dart
// lib/data/datasources/local/course_order_datasource.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

class CourseOrderDataSource {
  CourseOrderDataSource(this._db);

  final AppDatabase _db;

  Future<List<String>> getOrderedIds() async {
    final rows = await (_db.select(_db.courseOrders)
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .get();
    return rows.map((r) => r.courseId).toList();
  }

  Future<void> initializeNewCourses(List<String> allCourseIds) async {
    final existing = await _db.select(_db.courseOrders).get();
    final existingIds = existing.map((r) => r.courseId).toSet();
    final newIds =
        allCourseIds.where((id) => !existingIds.contains(id)).toList();
    if (newIds.isEmpty) return;

    final maxIdx = existing.isEmpty
        ? -1
        : existing.map((r) => r.sortIndex).reduce((a, b) => a > b ? a : b);

    await _db.batch((batch) {
      for (int i = 0; i < newIds.length; i++) {
        batch.insert(
          _db.courseOrders,
          CourseOrdersCompanion.insert(
            courseId: newIds[i],
            sortIndex: maxIdx + 1 + i,
          ),
        );
      }
    });
  }

  Future<void> updateOrder(List<String> orderedIds) async {
    await _db.batch((batch) {
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          _db.courseOrders,
          CourseOrdersCompanion(sortIndex: Value(i)),
          where: (t) => t.courseId.equals(orderedIds[i]),
        );
      }
    });
  }
}
```

- [ ] **Step 6: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` が生成される

- [ ] **Step 7: テストを実行してパスを確認する**

```bash
flutter test test/data/datasources/local/app_database_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 8: コミットする**

```bash
git add lib/data/datasources/local/ test/data/datasources/local/
git commit -m "feat: driftスキーマ（SyncStates追加）とDataSourceを実装"
```

---

## Task 5: ClassroomHttpClient + GoogleClassroomRepository

**Files:**
- Create: `lib/data/datasources/remote/classroom_http_client.dart`
- Create: `lib/data/repositories/google_classroom_repository.dart`
- Create: `test/data/repositories/google_classroom_repository_test.dart`

- [ ] **Step 1: `classroom_http_client.dart` を作成する**

```dart
// lib/data/datasources/remote/classroom_http_client.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../core/services/auth_service.dart';

class ClassroomHttpClient extends http.BaseClient {
  ClassroomHttpClient(this._account);

  final GoogleSignInAccount _account;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final auth =
        await _account.authorizationClient
            .authorizationForScopes(AuthService.scopes) ??
        await _account.authorizationClient
            .authorizeScopes(AuthService.scopes);
    request.headers['Authorization'] = 'Bearer ${auth.accessToken}';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
```

- [ ] **Step 2: テストを先に書く**

```dart
// test/data/repositories/google_classroom_repository_test.dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/repositories/google_classroom_repository.dart';

class MockClassroomApi extends Mock implements classroom.ClassroomApi {}
class MockCoursesResource extends Mock implements classroom.CoursesResource {}
class MockCoursesCourseWorkResource extends Mock
    implements classroom.CoursesCourseWorkResource {}

void main() {
  late AppDatabase db;
  late MockClassroomApi mockApi;
  late GoogleClassroomRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockApi = MockClassroomApi();
    repository =
        GoogleClassroomRepository.withApi(database: db, api: mockApi);
  });

  tearDown(() async => db.close());

  group('getCourses (cache-first)', () {
    test('キャッシュが空の場合はAPIから取得してキャッシュする', () async {
      final mockCourses = MockCoursesResource();
      when(() => mockApi.courses).thenReturn(mockCourses);
      when(() => mockCourses.list(
                courseStates: any(named: 'courseStates'),
                pageSize: any(named: 'pageSize'),
              ))
          .thenAnswer((_) async => classroom.ListCoursesResponse(
                courses: [
                  classroom.Course(id: 'c1', name: 'Math'),
                ],
              ));

      final result = await repository.getCourses();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).first.name, 'Math');
      final cached = await db.select(db.courses).get();
      expect(cached.length, 1);
    });

    test('キャッシュがある場合はAPIを呼ばずにキャッシュを返す', () async {
      await db.into(db.courses).insert(
        CoursesCompanion.insert(id: 'c1', name: 'Cached'),
      );

      final result = await repository.getCourses();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).first.name, 'Cached');
      verifyNever(() => mockApi.courses);
    });

    test('refreshCourses はキャッシュがあってもAPIを呼ぶ', () async {
      await db.into(db.courses).insert(
        CoursesCompanion.insert(id: 'c1', name: 'Old'),
      );

      final mockCourses = MockCoursesResource();
      when(() => mockApi.courses).thenReturn(mockCourses);
      when(() => mockCourses.list(
                courseStates: any(named: 'courseStates'),
                pageSize: any(named: 'pageSize'),
              ))
          .thenAnswer((_) async => classroom.ListCoursesResponse(
                courses: [classroom.Course(id: 'c1', name: 'Updated')],
              ));

      final result = await repository.refreshCourses();

      expect(result.getOrElse(() => []).first.name, 'Updated');
    });
  });

  group('getUpcomingDeadlines', () {
    test('driftキャッシュから今後7日以内の未提出課題を返す', () async {
      final now = DateTime.now();

      await db.batch((batch) {
        batch.insertAll(db.assignments, [
          AssignmentsCompanion.insert(
            id: 'a1', courseId: 'c1', title: '明日',
            dueDateMillis: Value(
                now.add(const Duration(days: 1)).millisecondsSinceEpoch),
          ),
          AssignmentsCompanion.insert(
            id: 'a2', courseId: 'c1', title: '10日後（範囲外）',
            dueDateMillis: Value(
                now.add(const Duration(days: 10)).millisecondsSinceEpoch),
          ),
          AssignmentsCompanion.insert(
            id: 'a3', courseId: 'c1', title: '提出済み',
            dueDateMillis: Value(
                now.add(const Duration(days: 2)).millisecondsSinceEpoch),
            submissionState: const Value('turnedIn'),
          ),
        ]);
      });

      final result = await repository.getUpcomingDeadlines(
          within: const Duration(days: 7));

      expect(result.isRight(), true);
      final deadlines = result.getOrElse(() => []);
      expect(deadlines.length, 1);
      expect(deadlines.first.title, '明日');
    });
  });
}
```

- [ ] **Step 3: テストを実行して失敗を確認する**

```bash
flutter test test/data/repositories/google_classroom_repository_test.dart
```

Expected: FAIL

- [ ] **Step 4: `google_classroom_repository.dart` を作成する**

```dart
// lib/data/repositories/google_classroom_repository.dart
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../../domain/entities/announcement.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/course.dart';
import '../../domain/errors/failures.dart';
import '../../domain/repositories/lms_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/classroom_http_client.dart';

class GoogleClassroomRepository implements LmsRepository {
  GoogleClassroomRepository({
    required AppDatabase database,
    required GoogleSignInAccount account,
  })  : _db = database,
        _api = classroom.ClassroomApi(ClassroomHttpClient(account));

  GoogleClassroomRepository.withApi({
    required AppDatabase database,
    required classroom.ClassroomApi api,
  })  : _db = database,
        _api = api;

  final AppDatabase _db;
  final classroom.ClassroomApi _api;

  // ---- キャッシュファースト ----

  @override
  Future<Either<Failure, List<Course>>> getCourses() async {
    final cached = await _db.select(_db.courses).get();
    if (cached.isNotEmpty) {
      return Right(cached.map(_courseRowToDomain).toList());
    }
    return _fetchAndCacheCourses();
  }

  Future<Either<Failure, List<Course>>> refreshCourses() =>
      _fetchAndCacheCourses();

  @override
  Future<Either<Failure, List<Assignment>>> getAssignments(
      String courseId) async {
    final cached = await (_db.select(_db.assignments)
          ..where((t) => t.courseId.equals(courseId)))
        .get();
    if (cached.isNotEmpty) {
      return Right(cached.map(_assignmentRowToDomain).toList());
    }
    return _fetchAndCacheAssignments(courseId);
  }

  Future<Either<Failure, List<Assignment>>> refreshAssignments(
      String courseId) =>
      _fetchAndCacheAssignments(courseId);

  @override
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({
    required Duration within,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final limit = DateTime.now().add(within).millisecondsSinceEpoch;

      final rows = await (_db.select(_db.assignments)
            ..where((t) =>
                t.dueDateMillis.isBiggerOrEqualValue(now) &
                t.dueDateMillis.isSmallerOrEqualValue(limit) &
                (t.submissionState.isNull() |
                    t.submissionState.equals('turnedIn').not()))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDateMillis)]))
          .get();

      return Right(rows.map(_assignmentRowToDomain).toList());
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements(
      String courseId) async => const Right([]);

  @override
  Future<Either<Failure, List<SearchResult>>> search(String query) async =>
      const Right([]);

  @override
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  ) async => const Right(null);

  @override
  Future<Either<Failure, List<Comment>>> getComments(
    String courseId,
    String itemId, {
    CommentVisibility? filterBy,
  }) async => const Right([]);

  // ---- API fetch helpers ----

  Future<Either<Failure, List<Course>>> _fetchAndCacheCourses() async {
    try {
      final all = <classroom.Course>[];
      String? pageToken;
      do {
        final res = await _api.courses.list(
          courseStates: ['ACTIVE'],
          pageSize: 50,
          pageToken: pageToken,
        );
        all.addAll(res.courses ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      final domains = all.map(_courseToDomain).toList();
      await _db.batch((batch) {
        batch.insertAll(
          _db.courses,
          domains.map(_courseToCompanion).toList(),
          mode: InsertMode.replace,
        );
      });
      return Right(domains);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Assignment>>> _fetchAndCacheAssignments(
      String courseId) async {
    try {
      final all = <classroom.CourseWork>[];
      String? pageToken;
      do {
        final res = await _api.courses.courseWork.list(
          courseId,
          courseWorkStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: pageToken,
        );
        all.addAll(res.courseWork ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      final domains = all.map(_courseWorkToDomain).toList();
      await _db.batch((batch) {
        batch.insertAll(
          _db.assignments,
          domains.map(_assignmentToCompanion).toList(),
          mode: InsertMode.replace,
        );
      });
      return Right(domains);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  // ---- Domain mapping ----

  Course _courseToDomain(classroom.Course c) => Course(
        id: c.id!,
        name: c.name ?? '',
        description: c.description,
        section: c.section,
        room: c.room,
        ownerId: c.ownerId,
        courseState: c.courseState ?? 'ACTIVE',
      );

  CoursesCompanion _courseToCompanion(Course c) => CoursesCompanion.insert(
        id: c.id,
        name: c.name,
        description: Value(c.description),
        section: Value(c.section),
        room: Value(c.room),
        ownerId: Value(c.ownerId),
        courseState: Value(c.courseState),
      );

  Course _courseRowToDomain(CourseRow r) => Course(
        id: r.id,
        name: r.name,
        description: r.description,
        section: r.section,
        room: r.room,
        ownerId: r.ownerId,
        courseState: r.courseState,
      );

  Assignment _courseWorkToDomain(classroom.CourseWork cw) {
    DateTime? dueDate;
    if (cw.dueDate != null) {
      dueDate = DateTime(
        cw.dueDate!.year!,
        cw.dueDate!.month!,
        cw.dueDate!.day!,
        cw.dueTime?.hours ?? 23,
        cw.dueTime?.minutes ?? 59,
      );
    }
    return Assignment(
      id: cw.id!,
      courseId: cw.courseId!,
      title: cw.title ?? '',
      description: cw.description,
      dueDate: dueDate,
      state: _parseState(cw.state),
    );
  }

  AssignmentState _parseState(String? s) => switch (s?.toUpperCase()) {
        'PUBLISHED' => AssignmentState.published,
        'DRAFT' => AssignmentState.draft,
        'DELETED' => AssignmentState.deleted,
        _ => AssignmentState.published,
      };

  AssignmentsCompanion _assignmentToCompanion(Assignment a) =>
      AssignmentsCompanion.insert(
        id: a.id,
        courseId: a.courseId,
        title: a.title,
        description: Value(a.description),
        dueDateMillis: Value(a.dueDate?.millisecondsSinceEpoch),
        state: Value(a.state.name),
        submissionState: Value(a.submissionState?.name),
      );

  Assignment _assignmentRowToDomain(AssignmentRow r) => Assignment(
        id: r.id,
        courseId: r.courseId,
        title: r.title,
        description: r.description,
        dueDate: r.dueDateMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!)
            : null,
        state: AssignmentState.values.firstWhere(
          (e) => e.name == r.state,
          orElse: () => AssignmentState.published,
        ),
        submissionState: r.submissionState != null
            ? SubmissionState.values.firstWhere(
                (e) => e.name == r.submissionState,
                orElse: () => SubmissionState.newSubmission,
              )
            : null,
      );
}
```

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/data/repositories/google_classroom_repository_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/data/datasources/remote/classroom_http_client.dart \
        lib/data/repositories/google_classroom_repository.dart \
        test/data/repositories/google_classroom_repository_test.dart
git commit -m "feat: ClassroomHttpClient・GoogleClassroomRepository（キャッシュファースト）を実装"
```

---

## Task 6: PubSubService

**Files:**
- Create: `lib/core/services/pubsub_service.dart`

- [ ] **Step 1: `pubsub_service.dart` を作成する**

```dart
// lib/core/services/pubsub_service.dart
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/pubsub/v1.dart' as pubsub;
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../constants/app_constants.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
import '../../data/datasources/remote/classroom_http_client.dart';

class PubSubService {
  PubSubService({
    required GoogleSignInAccount account,
    required SyncStateDataSource syncState,
  })  : _account = account,
        _syncState = syncState;

  final GoogleSignInAccount _account;
  final SyncStateDataSource _syncState;

  String get _topicName =>
      'projects/${AppConstants.gcpProjectId}/topics/${AppConstants.pubsubTopicId}';
  String get _subscriptionName =>
      'projects/${AppConstants.gcpProjectId}/subscriptions/${AppConstants.pubsubSubscriptionId}';

  pubsub.PubsubApi get _pubsubApi =>
      pubsub.PubsubApi(ClassroomHttpClient(_account));
  classroom.ClassroomApi get _classroomApi =>
      classroom.ClassroomApi(ClassroomHttpClient(_account));

  Future<void> ensureSetup() async {
    final done = await _syncState.get('pubsub_setup');
    if (done == 'true') return;

    await _ensureTopic();
    await _ensureIamPolicy();
    await _ensureSubscription();

    await _syncState.set('pubsub_setup', 'true');
  }

  Future<void> ensureRegistration(String courseId) async {
    const key = 'reg_expiry_';
    final expiryStr = await _syncState.get('$key$courseId');
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (expiry.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
        return;
      }
    }

    await _classroomApi.registrations.create(
      classroom.Registration(
        feed: classroom.Feed(
          feedType: 'COURSE_WORK_CHANGES',
          courseWorkChangesInfo:
              classroom.CourseWorkChangesInfo(courseId: courseId),
        ),
        cloudPubsubTopic:
            classroom.CloudPubsubTopic(topicName: _topicName),
      ),
    );

    final expiry = DateTime.now().add(const Duration(days: 7));
    await _syncState.set('$key$courseId', expiry.toIso8601String());
  }

  Future<List<String>> pullChangedCourseIds() async {
    final response = await _pubsubApi.projects.subscriptions.pull(
      pubsub.PullRequest(maxMessages: 100),
      _subscriptionName,
    );

    final messages = response.receivedMessages ?? [];
    if (messages.isEmpty) return [];

    final courseIds = <String>{};
    final ackIds = <String>[];

    for (final msg in messages) {
      if (msg.ackId != null) ackIds.add(msg.ackId!);

      final data = msg.message?.data;
      if (data != null) {
        try {
          final json = jsonDecode(
            utf8.decode(base64.decode(data)),
          ) as Map<String, dynamic>;
          final message = json['message'] as Map<String, dynamic>?;
          final courseId = message?['courseId'] as String?;
          if (courseId != null) courseIds.add(courseId);
        } catch (_) {}
      }
    }

    if (ackIds.isNotEmpty) {
      await _pubsubApi.projects.subscriptions.acknowledge(
        pubsub.AcknowledgeRequest(ackIds: ackIds),
        _subscriptionName,
      );
    }

    return courseIds.toList();
  }

  Future<void> _ensureTopic() async {
    try {
      await _pubsubApi.projects.topics.get(_topicName);
    } catch (_) {
      await _pubsubApi.projects.topics.create(
        pubsub.Topic(name: _topicName),
        _topicName,
      );
    }
  }

  Future<void> _ensureIamPolicy() async {
    await _pubsubApi.projects.topics.setIamPolicy(
      pubsub.SetIamPolicyRequest(
        policy: pubsub.Policy(
          bindings: [
            pubsub.Binding(
              role: 'roles/pubsub.publisher',
              members: [
                'serviceAccount:${AppConstants.classroomServiceAccount}'
              ],
            ),
          ],
        ),
      ),
      _topicName,
    );
  }

  Future<void> _ensureSubscription() async {
    try {
      await _pubsubApi.projects.subscriptions.get(_subscriptionName);
    } catch (_) {
      await _pubsubApi.projects.subscriptions.create(
        pubsub.Subscription(
          name: _subscriptionName,
          topic: _topicName,
          ackDeadlineSeconds: 60,
        ),
        _subscriptionName,
      );
    }
  }
}
```

- [ ] **Step 2: dart analyze を通す**

```bash
dart analyze lib/core/services/pubsub_service.dart
```

Expected: No issues

- [ ] **Step 3: コミットする**

```bash
git add lib/core/services/pubsub_service.dart
git commit -m "feat: PubSubService（topic/subscription/IAM/registration管理）を実装"
```

---

## Task 7: ClassroomSyncService

**Files:**
- Create: `lib/core/services/classroom_sync_service.dart`

- [ ] **Step 1: `classroom_sync_service.dart` を作成する**

```dart
// lib/core/services/classroom_sync_service.dart
import '../../data/repositories/google_classroom_repository.dart';
import 'pubsub_service.dart';

class ClassroomSyncService {
  ClassroomSyncService({
    required PubSubService pubSubService,
    required GoogleClassroomRepository repository,
  })  : _pubSub = pubSubService,
        _repo = repository;

  final PubSubService _pubSub;
  final GoogleClassroomRepository _repo;

  /// 初回起動 or フォアグラウンド復帰時に呼ぶ。
  /// Pub/Sub設定 → registration → pull → 差分コースのみリフレッシュ
  Future<void> fullSync() async {
    await _pubSub.ensureSetup();

    // キャッシュがあればキャッシュ返し、なければAPI取得
    final coursesResult = await _repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);

    // 各コースのregistrationを確認・更新
    await Future.wait(
      courses.map((c) => _pubSub.ensureRegistration(c.id)),
    );

    // Pub/Subからメッセージをpull
    final changedIds = await _pubSub.pullChangedCourseIds();

    // 変更があったコースのみAPIリフレッシュ
    if (changedIds.isNotEmpty) {
      await Future.wait(
        changedIds.map((id) => _repo.refreshAssignments(id)),
      );
    }
  }

  /// Pull-to-refresh用: コース一覧・全課題を強制リフレッシュ
  Future<void> forceRefresh() async {
    await _repo.refreshCourses();
    final coursesResult = await _repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);
    await Future.wait(courses.map((c) => _repo.refreshAssignments(c.id)));
  }
}
```

- [ ] **Step 2: コミットする**

```bash
git add lib/core/services/classroom_sync_service.dart
git commit -m "feat: ClassroomSyncService（Pub/Sub pull → 差分リフレッシュ）を実装"
```

---

## Task 8: Providers 更新

**Files:**
- Modify: `lib/core/di/providers.dart`

- [ ] **Step 1: `providers.dart` を更新する**

```dart
// lib/core/di/providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/classroom_sync_service.dart';
import '../services/pubsub_service.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/course_order_datasource.dart';
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
PubSubService pubSubService(PubSubServiceRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  if (account == null) throw StateError('Not signed in');
  return PubSubService(
    account: account,
    syncState: ref.watch(syncStateDataSourceProvider),
  );
}

@riverpod
ClassroomSyncService classroomSyncService(ClassroomSyncServiceRef ref) =>
    ClassroomSyncService(
      pubSubService: ref.watch(pubSubServiceProvider),
      repository: ref.watch(googleClassroomRepositoryProvider),
    );
```

- [ ] **Step 2: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `providers.g.dart` が再生成される

- [ ] **Step 3: コミットする**

```bash
git add lib/core/di/providers.dart lib/core/di/providers.g.dart
git commit -m "feat: Pub/Sub関連プロバイダーを追加"
```

---

## Task 9: DashboardViewModel + テスト

**Files:**
- Create: `lib/presentation/viewmodels/dashboard_viewmodel.dart`
- Create: `test/presentation/viewmodels/dashboard_viewmodel_test.dart`

- [ ] **Step 1: テストを先に書く**

```dart
// test/presentation/viewmodels/dashboard_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/core/services/classroom_sync_service.dart';
import 'package:classroom_remaked/data/datasources/local/course_order_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/dashboard_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}
class MockClassroomSyncService extends Mock implements ClassroomSyncService {}
class MockCourseOrderDataSource extends Mock implements CourseOrderDataSource {}

void main() {
  late MockLmsRepository mockRepo;
  late MockClassroomSyncService mockSync;
  late MockCourseOrderDataSource mockOrder;
  late ProviderContainer container;

  final fakeCourses = [
    const Course(id: 'c1', name: 'Math'),
    const Course(id: 'c2', name: 'Science'),
  ];

  setUp(() {
    mockRepo = MockLmsRepository();
    mockSync = MockClassroomSyncService();
    mockOrder = MockCourseOrderDataSource();

    when(() => mockSync.fullSync()).thenAnswer((_) async {});
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getUpcomingDeadlines(within: any(named: 'within')))
        .thenAnswer((_) async => Right(<Assignment>[]));
    when(() => mockOrder.getOrderedIds())
        .thenAnswer((_) async => ['c1', 'c2']);
    when(() => mockOrder.initializeNewCourses(any()))
        .thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
        classroomSyncServiceProvider.overrideWithValue(mockSync),
        courseOrderDataSourceProvider.overrideWithValue(mockOrder),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build時にfullSyncを呼びDashboardStateを返す', () async {
    await container.read(dashboardViewModelProvider.future);
    final state = container.read(dashboardViewModelProvider);

    verify(() => mockSync.fullSync()).called(1);
    expect(state.value!.courses.length, 2);
    expect(state.value!.orderedCourses.first.id, 'c1');
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

Expected: FAIL

- [ ] **Step 3: `dashboard_viewmodel.dart` を作成する**

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
    required this.orderedCourseIds,
    required this.upcomingDeadlines,
  });

  final List<Course> courses;
  final List<String> orderedCourseIds;
  final List<Assignment> upcomingDeadlines;

  List<Course> get orderedCourses {
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

  DashboardState copyWith({
    List<Course>? courses,
    List<String>? orderedCourseIds,
    List<Assignment>? upcomingDeadlines,
  }) =>
      DashboardState(
        courses: courses ?? this.courses,
        orderedCourseIds: orderedCourseIds ?? this.orderedCourseIds,
        upcomingDeadlines: upcomingDeadlines ?? this.upcomingDeadlines,
      );
}

@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  Future<DashboardState> build() async {
    final sync = ref.watch(classroomSyncServiceProvider);
    final repo = ref.watch(lmsRepositoryProvider);
    final orderDs = ref.watch(courseOrderDataSourceProvider);

    // Pub/Sub pull → 差分リフレッシュ（キャッシュが空の場合はAPI取得も担う）
    await sync.fullSync();

    final coursesResult = await repo.getCourses();
    final deadlinesResult =
        await repo.getUpcomingDeadlines(within: const Duration(days: 7));

    final courses = coursesResult.getOrElse(() => []);
    final deadlines = deadlinesResult.getOrElse(() => []);

    await orderDs.initializeNewCourses(courses.map((c) => c.id).toList());
    final orderedIds = await orderDs.getOrderedIds();

    return DashboardState(
      courses: courses,
      orderedCourseIds: orderedIds,
      upcomingDeadlines: deadlines,
    );
  }

  Future<void> reorderCourses(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final ids = List<String>.from(current.orderedCourses.map((c) => c.id));
    if (newIndex > oldIndex) newIndex--;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);

    await ref.read(courseOrderDataSourceProvider).updateOrder(ids);
    state = AsyncData(current.copyWith(orderedCourseIds: ids));
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
flutter pub run build_runner build --delete-conflicting-outputs
```

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
git commit -m "feat: DashboardViewModelを実装（Pub/Sub sync連携）"
```

---

## Task 10: go_router + Screens

**Files:**
- Create: `lib/presentation/views/shared/scaffold_with_nav.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/presentation/views/dashboard/dashboard_screen.dart`
- Create: `lib/presentation/views/dashboard/widgets/course_list.dart`
- Create: `lib/presentation/views/dashboard/widgets/deadline_widget.dart`
- Create: `lib/presentation/views/assignments/assignments_screen.dart`
- Create: `lib/presentation/viewmodels/assignments_viewmodel.dart`
- Create: `test/presentation/viewmodels/assignments_viewmodel_test.dart`

- [ ] **Step 1: `scaffold_with_nav.dart` を作成する**

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
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `app_router.dart` を更新する**

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/assignments/assignments_screen.dart';
import '../../presentation/views/auth/sign_in_screen.dart';
import '../../presentation/views/dashboard/dashboard_screen.dart';
import '../../presentation/views/shared/scaffold_with_nav.dart';
import '../../presentation/views/splash/splash_screen.dart';
part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';
      final isSignedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      if (!isSignedIn && loc != '/sign-in' && loc != '/splash') {
        return '/sign-in';
      }
      if (isSignedIn && (loc == '/sign-in' || loc == '/splash')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
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
        ],
      ),
    ],
  );
}
```

- [ ] **Step 3: `deadline_widget.dart` を作成する**

```dart
// lib/presentation/views/dashboard/widgets/deadline_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../domain/entities/assignment.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';

class DeadlineWidget extends ConsumerWidget {
  const DeadlineWidget({super.key});

  static final _fakeDeadlines = List.generate(
    3,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Sample Assignment Title',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardViewModelProvider);
    final isLoading = async.isLoading;
    final deadlines =
        async.valueOrNull?.upcomingDeadlines ?? _fakeDeadlines;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('直近の締め切り（7日以内）',
              style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 8),
          if (!isLoading && deadlines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('締め切りが近い課題はありません'),
            )
          else
            Skeletonizer(
              enabled: isLoading,
              child: Column(
                children:
                    deadlines.map((a) => _DeadlineTile(assignment: a)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final daysLeft =
        due != null ? due.difference(DateTime.now()).inDays : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(assignment.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (due != null)
              ShadBadge(
                backgroundColor:
                    daysLeft != null && daysLeft <= 1 ? Colors.red : null,
                child: Text(DateFormat('M/d').format(due)),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: `course_list.dart` を作成する**

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

    final courses = async.value!.orderedCourses;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) => ref
          .read(dashboardViewModelProvider.notifier)
          .reorderCourses(oldIndex, newIndex),
      itemCount: courses.length,
      itemBuilder: (context, index) =>
          _CourseCard(key: ValueKey(courses[index].id), course: courses[index]),
    );
  }

  Widget _buildStaticList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) =>
          _CourseCard(key: ValueKey(courses[index].id), course: courses[index]),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({super.key, required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              const Icon(Icons.drag_handle_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: `dashboard_screen.dart` を置換する**

```dart
// lib/presentation/views/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'widgets/course_list.dart';
import 'widgets/deadline_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Remaked'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'サインアウト',
            onPressed: () =>
                ref.read(authViewModelProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardViewModelProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: DeadlineWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('コース',
                    style: ShadTheme.of(context).textTheme.h4),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: CourseList()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: AssignmentsViewModelのテストを書く**

```dart
// test/presentation/viewmodels/assignments_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/assignments_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}

void main() {
  late MockLmsRepository mockRepo;
  late ProviderContainer container;

  final fakeCourses = [const Course(id: 'c1', name: 'Math')];
  final fakeAssignments = [
    Assignment(id: 'a1', courseId: 'c1', title: 'Early',
        dueDate: DateTime(2026, 6, 1)),
    Assignment(id: 'a2', courseId: 'c1', title: 'Late',
        dueDate: DateTime(2026, 6, 10)),
    Assignment(id: 'a3', courseId: 'c1', title: 'Submitted',
        dueDate: DateTime(2026, 6, 5),
        submissionState: SubmissionState.turnedIn),
  ];

  setUp(() {
    mockRepo = MockLmsRepository();
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getAssignments(any()))
        .thenAnswer((_) async => Right(fakeAssignments));

    container = ProviderContainer(
      overrides: [lmsRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('締め切り順に並ぶ', () async {
    await container.read(assignmentsViewModelProvider.future);
    final assignments =
        container.read(assignmentsViewModelProvider).value!.filteredAssignments;
    expect(assignments[0].title, 'Early');
    expect(assignments[1].title, 'Submitted');
    expect(assignments[2].title, 'Late');
  });

  test('未提出フィルターで提出済みを除外する', () async {
    await container.read(assignmentsViewModelProvider.future);
    container.read(assignmentsViewModelProvider.notifier)
        .setFilter(AssignmentsFilter.unsubmitted);
    final assignments =
        container.read(assignmentsViewModelProvider).value!.filteredAssignments;
    expect(assignments.length, 2);
    expect(assignments.any((a) => a.title == 'Submitted'), false);
  });
}
```

- [ ] **Step 7: `assignments_viewmodel.dart` を作成する**

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
    this.filter = AssignmentsFilter.all,
  });

  final List<Assignment> assignments;
  final AssignmentsFilter filter;

  List<Assignment> get filteredAssignments {
    if (filter == AssignmentsFilter.all) return assignments;
    return assignments
        .where((a) => a.submissionState != SubmissionState.turnedIn)
        .toList();
  }

  AssignmentsState copyWith(
          {List<Assignment>? assignments, AssignmentsFilter? filter}) =>
      AssignmentsState(
        assignments: assignments ?? this.assignments,
        filter: filter ?? this.filter,
      );
}

@riverpod
class AssignmentsViewModel extends _$AssignmentsViewModel {
  @override
  Future<AssignmentsState> build() async {
    final repo = ref.watch(lmsRepositoryProvider);
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

    return AssignmentsState(assignments: all);
  }

  void setFilter(AssignmentsFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }
}
```

- [ ] **Step 8: `assignments_screen.dart` を作成する**

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
              filter:
                  async.valueOrNull?.filter ?? AssignmentsFilter.all),
          Expanded(child: _buildList(async)),
        ],
      ),
    );
  }

  Widget _buildList(AsyncValue<AssignmentsState> async) {
    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }
    final isLoading = async.isLoading;
    final assignments =
        async.valueOrNull?.filteredAssignments ?? _fakeAssignments;

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: assignments.length,
        itemBuilder: (context, index) =>
            _AssignmentCard(assignment: assignments[index]),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});
  final AssignmentsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: AssignmentsFilter.values.map((f) {
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
                    onPressed: () => ref
                        .read(assignmentsViewModelProvider.notifier)
                        .setFilter(f),
                    child: Text(label),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final isSubmitted =
        assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
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
                ShadBadge(
                    backgroundColor: Colors.red,
                    child: const Text('期限切れ'))
              else if (due != null)
                ShadBadge.outline(
                  child: Text(
                      '${due.difference(DateTime.now()).inDays}日後'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 9: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 10: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 11: コミットする**

```bash
git add lib/core/router/ \
        lib/presentation/views/ \
        lib/presentation/viewmodels/assignments_viewmodel.dart \
        lib/presentation/viewmodels/assignments_viewmodel.g.dart \
        test/presentation/viewmodels/assignments_viewmodel_test.dart
git commit -m "feat: ルーター・ダッシュボード・課題画面を実装"
```

---

## Task 11: PR作成・マージ

- [ ] **Step 1: feature → page/dashboard へPRを作成してマージ**

```bash
gh pr create \
  --title "feat: Phase 2 Dashboard + Assignments + Pub/Sub" \
  --body "Closes #3
Closes #4
Closes #5
Closes #7

## 変更内容
- drift DBスキーマ（SyncStates追加）
- GoogleClassroomRepository（キャッシュファースト + refreshCourses/refreshAssignments）
- PubSubService（topic/subscription/IAM/registration管理）
- ClassroomSyncService（pull → 差分リフレッシュ）
- DashboardViewModel（Pub/Sub sync連携）
- AssignmentsViewModel
- StatefulShellRoute + BottomNavigationBar
- ダッシュボード・課題一覧画面

## テスト
- AppDatabase: PASS
- GoogleClassroomRepository: PASS
- DashboardViewModel: PASS
- AssignmentsViewModel: PASS" \
  --base page/dashboard
gh pr merge --squash --delete-branch
```

- [ ] **Step 2: page/dashboard → main へPR**

```bash
git checkout page/dashboard && git pull origin page/dashboard
gh pr create \
  --title "feat: Phase 2 完了（Dashboard + Assignments + Pub/Sub）" \
  --body "Phase 2 全実装。Issues #3 #4 #5 #7 close。" \
  --base main
gh pr merge --squash --delete-branch
```

- [ ] **Step 3: ブランチ整理**

```bash
git checkout main && git pull origin main
git fetch --prune
git branch -D page/dashboard feature/3-4-5-7-phase2-dashboard
```

---

## 検証チェックリスト

- [ ] `flutter test` 全件PASS
- [ ] `dart analyze lib/` エラーなし
- [ ] 初回起動: APIからコース・課題を取得してdriftにキャッシュ
- [ ] 2回目以降: キャッシュから即表示、Pub/Sub pullで差分のみリフレッシュ
- [ ] コースのドラッグ&ドロップで並び替えが保存される
- [ ] 直近7日の締め切りウィジェットが表示される
- [ ] Pull-to-refreshで全データを強制更新できる
- [ ] 課題一覧が締め切り順に表示される
- [ ] 「未提出」フィルターが機能する
- [ ] BottomNavigationBarでダッシュボード⇔課題を切り替えられる
