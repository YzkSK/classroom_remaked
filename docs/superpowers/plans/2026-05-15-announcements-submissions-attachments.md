# お知らせ・提出状況・添付ファイル・課題提出 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** コメント関連の死にコードを削除しつつ、スタブになっていた4機能（お知らせ・提出状況APISync・添付ファイル表示・課題提出）を実装してアプリを実用レベルに仕上げる。

**Architecture:** 既存 Clean Architecture + MVVM パターンに完全準拠。DB スキーマ v4 に Announcements テーブルと Assignments の2カラムを追加。googleapis Classroom API の `announcements.list` / `studentSubmissions.list` / `studentSubmissions.turnIn` を使用。添付ファイルは url_launcher でブラウザ開き。

**Tech Stack:** Flutter 3.x, Dart 3.x, drift 2.20, flutter_riverpod 2.6, riverpod_annotation 2.6, googleapis 13.x, url_launcher 6.x, shadcn_ui 0.54, freezed 2.5

**スコープ外:** コメント機能（Google Classroom API v1 は private な提出コメントを REST で公開していない）

---

## ファイルマップ

| ファイル | 操作 | 役割 |
|---------|------|------|
| `lib/domain/entities/comment.dart` | Delete | Comment エンティティ削除 |
| `lib/domain/entities/comment.freezed.dart` | Delete | 生成ファイル削除 |
| `lib/domain/repositories/lms_repository.dart` | Modify | getComments メソッドと import 削除 |
| `lib/data/repositories/google_classroom_repository.dart` | Modify | getComments スタブと import 削除 |
| `pubspec.yaml` | Modify | url_launcher + pdfx を追加 |
| `lib/core/services/auth_service.dart` | Modify | drive.readonly スコープを追加 |
| `lib/core/services/drive_file_service.dart` | Create | Drive API ファイルダウンロード + Google Workspace → PDF エクスポート |
| `lib/core/di/providers.dart` | Modify | driveFileServiceProvider / fileViewerProvider を追加 |
| `lib/core/router/app_router.dart` | Modify | `/viewer/:fileId` ルートを追加 |
| `lib/presentation/views/shared/file_viewer_screen.dart` | Create | PDF ビューア画面（pdfx） |
| `lib/data/datasources/local/app_database.dart` | Modify | schema v4: Announcements テーブル + materialsJson/submissionId カラム |
| `lib/domain/entities/assignment_material.dart` | Create | AssignmentMaterial エンティティ（純 Dart クラス） |
| `lib/domain/entities/assignment.dart` | Modify | materials / submissionId フィールドを追加 |
| `lib/domain/entities/assignment.freezed.dart` | Regenerate | build_runner で自動生成 |
| `lib/domain/repositories/lms_repository.dart` | Modify | turnIn メソッド追加 |
| `lib/data/repositories/google_classroom_repository.dart` | Modify | getAnnouncements / 提出状況sync / materials parse / turnIn を実装 |
| `lib/core/services/classroom_sync_service.dart` | Modify | _refreshAll でお知らせもSyncする |
| `lib/presentation/viewmodels/announcements_viewmodel.dart` | Create | AnnouncementsViewModel (family AsyncNotifier) |
| `lib/presentation/viewmodels/announcements_viewmodel.g.dart` | Generate | build_runner |
| `lib/presentation/views/dashboard/course_detail_screen.dart` | Modify | スタブ → _AnnouncementsTab |
| `lib/presentation/views/assignments/assignment_detail_screen.dart` | Modify | 添付ファイルセクション + 提出ボタン追加 |
| `test/presentation/viewmodels/announcements_viewmodel_test.dart` | Create | AnnouncementsViewModel テスト |

---

## Task 0: コメント関連コードを削除

**Files:**
- Delete: `lib/domain/entities/comment.dart`
- Delete: `lib/domain/entities/comment.freezed.dart`
- Modify: `lib/domain/repositories/lms_repository.dart`
- Modify: `lib/data/repositories/google_classroom_repository.dart`

削除対象:
- `Comment` freezed エンティティ（`id`, `authorName`, `body`, `createdAt`, `visibility`）
- `CommentVisibility` enum
- `LmsRepository.getComments()` 抽象メソッド
- `GoogleClassroomRepository.getComments()` スタブ実装
- 各ファイルの `comment.dart` import

- [ ] **Step 1: エンティティファイルを削除する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
rm lib/domain/entities/comment.dart lib/domain/entities/comment.freezed.dart
```

- [ ] **Step 2: lms_repository.dart から getComments を削除する**

`lib/domain/repositories/lms_repository.dart` を以下に置き換える（`comment.dart` import と `getComments` メソッドを除去）:

```dart
// lib/domain/repositories/lms_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/assignment.dart';
import '../entities/announcement.dart';
import '../entities/course.dart';
import '../errors/failures.dart';

class SearchResult {
  const SearchResult({
    required this.id,
    required this.courseId,
    required this.title,
    required this.snippet,
    required this.type,
  });

  final String id;
  final String courseId;
  final String title;
  final String snippet;
  final SearchResultType type;
}

enum SearchResultType { assignment, announcement }

class AssignmentSubmission {
  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.state,
    this.submittedAt,
  });

  final String id;
  final String assignmentId;
  final SubmissionState state;
  final DateTime? submittedAt;
}

abstract class LmsRepository {
  Future<Either<Failure, List<Course>>> getCourses();
  Future<Either<Failure, List<Assignment>>> getAssignments(String courseId);
  Future<Either<Failure, List<Announcement>>> getAnnouncements(String courseId);
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({
    required Duration within,
  });
  Future<Either<Failure, List<SearchResult>>> search(String query);
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  );
  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  );
}
```

- [ ] **Step 3: google_classroom_repository.dart から getComments を削除する**

`lib/data/repositories/google_classroom_repository.dart` の以下2箇所を削除する:

1. import 行を削除:
```dart
import '../../domain/entities/comment.dart';
```

2. `getComments` メソッド全体を削除:
```dart
  @override
  Future<Either<Failure, List<Comment>>> getComments(
    String courseId,
    String itemId, {
    CommentVisibility? filterBy,
  }) async =>
      const Right([]);
```

- [ ] **Step 4: analyze を通す**

```bash
dart analyze lib/domain/ lib/data/repositories/
```

Expected: `No issues found!`

- [ ] **Step 5: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add -u
git add lib/domain/repositories/lms_repository.dart \
        lib/data/repositories/google_classroom_repository.dart
git commit -m "refactor: 未実装のコメント関連コードを削除"
```

---

## Task 1: url_launcher + pdfx を pubspec に追加

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: url_launcher と pdfx を dependencies に追加する**

`pubspec.yaml` の `dependencies` セクション、`dartz: ^0.10.1` の次の行に追加:

```yaml
  url_launcher: ^6.3.0
  pdfx: ^2.9.0
  open_file: ^3.5.10
```

- [ ] **Step 2: パッケージを取得する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
flutter pub get
```

Expected: `Got dependencies!` と表示される

- [ ] **Step 3: コミットする**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: url_launcher・pdfx・open_file を追加"
```

---

## Task 2: DB スキーマ v4

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`

既存 schema v3 に対して:
- 新テーブル: `Announcements`（id, courseId, text, creationTimeMillis, updateTimeMillis）
- `Assignments` に2カラム追加: `materialsJson TEXT nullable`, `submissionId TEXT nullable`

- [ ] **Step 1: app_database.dart を更新する**

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
  TextColumn get submissionId => text().nullable()();
  TextColumn get materialsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AnnouncementRow')
class Announcements extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()();
  TextColumn get text => text()();
  IntColumn get creationTimeMillis => integer()();
  IntColumn get updateTimeMillis => integer().nullable()();

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
  int get schemaVersion => 4;

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
```

- [ ] **Step 2: コード生成を実行する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` が再生成される

- [ ] **Step 3: analyze を通す**

```bash
dart analyze lib/data/datasources/local/app_database.dart
```

Expected: `No issues found!`

- [ ] **Step 4: コミットする**

```bash
git add lib/data/datasources/local/app_database.dart \
        lib/data/datasources/local/app_database.g.dart
git commit -m "feat: DB schema v4 — Announcements テーブル + materialsJson/submissionId カラム追加"
```

---

## Task 3: AssignmentMaterial エンティティ + Assignment 更新

**Files:**
- Create: `lib/domain/entities/assignment_material.dart`
- Modify: `lib/domain/entities/assignment.dart`
- Regenerate: `lib/domain/entities/assignment.freezed.dart`

- [ ] **Step 1: assignment_material.dart を作成する**

```dart
// lib/domain/entities/assignment_material.dart
enum AssignmentMaterialType { driveFile, youTube, link, form }

class AssignmentMaterial {
  const AssignmentMaterial({
    required this.title,
    required this.url,
    required this.type,
    this.driveFileId,
    this.mimeType,
  });

  final String title;
  final String url;
  final AssignmentMaterialType type;
  // Drive ファイルの場合のみ設定。Drive API アクセスに使用。
  final String? driveFileId;
  // Drive ファイルの MIME タイプ（Classroom API から取得できる場合のみ設定）
  final String? mimeType;

  factory AssignmentMaterial.fromJson(Map<String, dynamic> json) =>
      AssignmentMaterial(
        title: json['title'] as String,
        url: json['url'] as String,
        type: AssignmentMaterialType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AssignmentMaterialType.link,
        ),
        driveFileId: json['driveFileId'] as String?,
        mimeType: json['mimeType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type.name,
        if (driveFileId != null) 'driveFileId': driveFileId,
        if (mimeType != null) 'mimeType': mimeType,
      };

  @override
  bool operator ==(Object other) =>
      other is AssignmentMaterial &&
      other.title == title &&
      other.url == url &&
      other.type == type &&
      other.driveFileId == driveFileId;

  @override
  int get hashCode => Object.hash(title, url, type, driveFileId);
}
```

- [ ] **Step 2: assignment.dart に materials と submissionId を追加する**

`lib/domain/entities/assignment.dart` を以下に置き換える:

```dart
// lib/domain/entities/assignment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'assignment_material.dart';
part 'assignment.freezed.dart';

export 'assignment_material.dart';

enum AssignmentState { published, draft, deleted }

enum SubmissionState {
  newSubmission,
  created,
  turnedIn,
  returned,
  reclaimedByStudent,
}

@freezed
class Assignment with _$Assignment {
  const factory Assignment({
    required String id,
    required String courseId,
    required String title,
    String? description,
    DateTime? dueDate,
    @Default(AssignmentState.published) AssignmentState state,
    SubmissionState? submissionState,
    String? submissionId,
    @Default([]) List<AssignmentMaterial> materials,
  }) = _Assignment;
}
```

- [ ] **Step 3: コード生成を実行する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
dart run build_runner build --delete-conflicting-outputs
```

Expected: `assignment.freezed.dart` が再生成される

- [ ] **Step 4: 全テストを実行してリグレッションがないか確認する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 5: コミットする**

```bash
git add lib/domain/entities/assignment_material.dart \
        lib/domain/entities/assignment.dart \
        lib/domain/entities/assignment.freezed.dart
git commit -m "feat: AssignmentMaterial エンティティ追加・Assignment に materials/submissionId を追加"
```

---

## Task 4: お知らせ — API 取得・キャッシュ・Sync

**Files:**
- Modify: `lib/domain/repositories/lms_repository.dart`
- Modify: `lib/data/repositories/google_classroom_repository.dart`
- Modify: `lib/core/services/classroom_sync_service.dart`

- [ ] **Step 1: lms_repository.dart に turnIn を追加する**

Task 0 で `getComments` と `comment.dart` import は削除済み。`abstract class LmsRepository` に `turnIn` メソッドを追加する。

完成した `lms_repository.dart`:

```dart
// lib/domain/repositories/lms_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/assignment.dart';
import '../entities/announcement.dart';
import '../entities/course.dart';
import '../errors/failures.dart';

class SearchResult {
  const SearchResult({
    required this.id,
    required this.courseId,
    required this.title,
    required this.snippet,
    required this.type,
  });

  final String id;
  final String courseId;
  final String title;
  final String snippet;
  final SearchResultType type;
}

enum SearchResultType { assignment, announcement }

class AssignmentSubmission {
  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.state,
    this.submittedAt,
  });

  final String id;
  final String assignmentId;
  final SubmissionState state;
  final DateTime? submittedAt;
}

abstract class LmsRepository {
  Future<Either<Failure, List<Course>>> getCourses();
  Future<Either<Failure, List<Assignment>>> getAssignments(String courseId);
  Future<Either<Failure, List<Announcement>>> getAnnouncements(String courseId);
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({
    required Duration within,
  });
  Future<Either<Failure, List<SearchResult>>> search(String query);
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  );
  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  );
}
```

- [ ] **Step 2: google_classroom_repository.dart を全面更新する**

`lib/data/repositories/google_classroom_repository.dart` を以下に置き換える:

```dart
// lib/data/repositories/google_classroom_repository.dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../../domain/entities/announcement.dart';
import '../../domain/entities/assignment.dart';
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

  // ────────────────────── Courses ──────────────────────

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

  // ────────────────────── Assignments ──────────────────────

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

  // ────────────────────── Announcements ──────────────────────

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements(
      String courseId) async {
    final cached = await (_db.select(_db.announcements)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([(t) => OrderingTerm.desc(t.creationTimeMillis)]))
        .get();
    if (cached.isNotEmpty) {
      return Right(cached.map(_announcementRowToDomain).toList());
    }
    return _fetchAndCacheAnnouncements(courseId);
  }

  Future<Either<Failure, List<Announcement>>> refreshAnnouncements(
          String courseId) =>
      _fetchAndCacheAnnouncements(courseId);

  // ────────────────────── Stubs ──────────────────────

  @override
  Future<Either<Failure, List<SearchResult>>> search(String query) async =>
      const Right([]);

  @override
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  ) async =>
      const Right(null);

  // ────────────────────── TurnIn ──────────────────────

  @override
  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  ) async {
    try {
      await _api.courses.courseWork.studentSubmissions.turnIn(
        classroom.TurnInStudentSubmissionRequest(),
        courseId,
        assignmentId,
        submissionId,
      );
      // ローカルDBの提出状態を即時更新
      await (_db.update(_db.assignments)
            ..where((t) => t.id.equals(assignmentId)))
          .write(const AssignmentsCompanion(
        submissionState: Value('turnedIn'),
      ));
      return const Right(null);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  // ────────────────────── Private: fetch & cache ──────────────────────

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
      // 課題一覧
      final allWork = <classroom.CourseWork>[];
      String? pageToken;
      do {
        final res = await _api.courses.courseWork.list(
          courseId,
          courseWorkStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: pageToken,
        );
        allWork.addAll(res.courseWork ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      // 提出状況を一括取得（'-' で全課題対象）
      final subMap = <String, classroom.StudentSubmission>{};
      String? subPageToken;
      do {
        final subRes = await _api.courses.courseWork.studentSubmissions.list(
          courseId,
          '-',
          userId: 'me',
          pageSize: 100,
          pageToken: subPageToken,
        );
        for (final s in subRes.studentSubmissions ?? []) {
          if (s.courseWorkId != null) subMap[s.courseWorkId!] = s;
        }
        subPageToken = subRes.nextPageToken;
      } while (subPageToken != null);

      final domains = allWork
          .map((cw) => _courseWorkToDomain(cw, subMap[cw.id]))
          .toList();

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

  Future<Either<Failure, List<Announcement>>> _fetchAndCacheAnnouncements(
      String courseId) async {
    try {
      final all = <classroom.Announcement>[];
      String? pageToken;
      do {
        final res = await _api.courses.announcements.list(
          courseId,
          announcementStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: pageToken,
        );
        all.addAll(res.announcements ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      final domains = all.map(_announcementToDomain).toList();
      await _db.batch((batch) {
        batch.insertAll(
          _db.announcements,
          domains.map(_announcementToCompanion).toList(),
          mode: InsertMode.replace,
        );
      });
      return Right(domains);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  // ────────────────────── Converters: Course ──────────────────────

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

  // ────────────────────── Converters: Assignment ──────────────────────

  Assignment _courseWorkToDomain(
    classroom.CourseWork cw,
    classroom.StudentSubmission? sub,
  ) {
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

    final materials = _parseMaterials(cw.materials ?? []);
    final materialsJson = materials.isEmpty
        ? null
        : jsonEncode(materials.map((m) => m.toJson()).toList());

    return Assignment(
      id: cw.id!,
      courseId: cw.courseId!,
      title: cw.title ?? '',
      description: cw.description,
      dueDate: dueDate,
      state: _parseState(cw.state),
      submissionState: sub != null ? _parseSubmissionState(sub.state) : null,
      submissionId: sub?.id,
      materials: materials,
    );
  }

  AssignmentState _parseState(String? s) => switch (s?.toUpperCase()) {
        'PUBLISHED' => AssignmentState.published,
        'DRAFT' => AssignmentState.draft,
        'DELETED' => AssignmentState.deleted,
        _ => AssignmentState.published,
      };

  SubmissionState? _parseSubmissionState(String? s) =>
      switch (s?.toUpperCase()) {
        'TURNED_IN' => SubmissionState.turnedIn,
        'RETURNED' => SubmissionState.returned,
        'RECLAIMED_BY_STUDENT' => SubmissionState.reclaimedByStudent,
        'CREATED' => SubmissionState.created,
        'NEW_SUBMISSION_STATE' => SubmissionState.newSubmission,
        _ => null,
      };

  List<AssignmentMaterial> _parseMaterials(
      List<classroom.Material> materials) {
    final result = <AssignmentMaterial>[];
    for (final m in materials) {
      if (m.driveFile?.driveFile != null) {
        final df = m.driveFile!.driveFile!;
        // alternateLink のパターンから Google Workspace MIME を推定
        final url = df.alternateLink ?? '';
        final mimeType = _inferMimeFromDriveUrl(url);
        result.add(AssignmentMaterial(
          title: df.title ?? 'ファイル',
          url: url,
          type: AssignmentMaterialType.driveFile,
          driveFileId: df.id,
          mimeType: mimeType,
        ));
      } else if (m.youTubeVideo != null) {
        final yt = m.youTubeVideo!;
        result.add(AssignmentMaterial(
          title: yt.title ?? '動画',
          url: yt.alternateLink ?? '',
          type: AssignmentMaterialType.youTube,
        ));
      } else if (m.link != null) {
        final lk = m.link!;
        result.add(AssignmentMaterial(
          title: lk.title ?? lk.url ?? 'リンク',
          url: lk.url ?? '',
          type: AssignmentMaterialType.link,
        ));
      } else if (m.form != null) {
        final fm = m.form!;
        result.add(AssignmentMaterial(
          title: fm.title ?? 'フォーム',
          url: fm.responseUrl ?? fm.formUrl ?? '',
          type: AssignmentMaterialType.form,
        ));
      }
    }
    return result;
  }

  /// Google Drive/Docs の URL パターンから MIME タイプを推定する。
  /// Drive API を呼ばずに判定できる範囲のみ対応。
  String? _inferMimeFromDriveUrl(String url) {
    if (url.contains('docs.google.com/document')) {
      return 'application/vnd.google-apps.document';
    } else if (url.contains('docs.google.com/spreadsheets')) {
      return 'application/vnd.google-apps.spreadsheet';
    } else if (url.contains('docs.google.com/presentation')) {
      return 'application/vnd.google-apps.presentation';
    } else if (url.contains('docs.google.com/forms')) {
      return 'application/vnd.google-apps.form';
    }
    // generic Drive file → タップ時に Drive API で取得
    return null;
  }

  AssignmentsCompanion _assignmentToCompanion(Assignment a) =>
      AssignmentsCompanion.insert(
        id: a.id,
        courseId: a.courseId,
        title: a.title,
        description: Value(a.description),
        dueDateMillis: Value(a.dueDate?.millisecondsSinceEpoch),
        state: Value(a.state.name),
        submissionState: Value(a.submissionState?.name),
        submissionId: Value(a.submissionId),
        materialsJson: Value(a.materials.isEmpty
            ? null
            : jsonEncode(a.materials.map((m) => m.toJson()).toList())),
      );

  Assignment _assignmentRowToDomain(AssignmentRow r) {
    final materials = r.materialsJson != null
        ? (jsonDecode(r.materialsJson!) as List)
            .map((e) =>
                AssignmentMaterial.fromJson(e as Map<String, dynamic>))
            .toList()
        : <AssignmentMaterial>[];

    return Assignment(
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
      submissionId: r.submissionId,
      materials: materials,
    );
  }

  // ────────────────────── Converters: Announcement ──────────────────────

  Announcement _announcementToDomain(classroom.Announcement a) =>
      Announcement(
        id: a.id!,
        courseId: a.courseId!,
        text: a.text ?? '',
        creationTime: DateTime.parse(a.creationTime!),
        updateTime:
            a.updateTime != null ? DateTime.parse(a.updateTime!) : null,
      );

  AnnouncementsCompanion _announcementToCompanion(Announcement a) =>
      AnnouncementsCompanion.insert(
        id: a.id,
        courseId: a.courseId,
        text: a.text,
        creationTimeMillis: a.creationTime.millisecondsSinceEpoch,
        updateTimeMillis: Value(a.updateTime?.millisecondsSinceEpoch),
      );

  Announcement _announcementRowToDomain(AnnouncementRow r) => Announcement(
        id: r.id,
        courseId: r.courseId,
        text: r.text,
        creationTime:
            DateTime.fromMillisecondsSinceEpoch(r.creationTimeMillis),
        updateTime: r.updateTimeMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(r.updateTimeMillis!)
            : null,
      );
}
```

- [ ] **Step 3: classroom_sync_service.dart を更新してお知らせもSyncする**

`lib/core/services/classroom_sync_service.dart` の `_refreshAll` メソッドを更新する:

```dart
  Future<void> _refreshAll() async {
    await _repo.refreshCourses();
    final coursesResult = await _repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);
    await Future.wait([
      ...courses.map((c) => _repo.refreshAssignments(c.id)),
      ...courses.map((c) => _repo.refreshAnnouncements(c.id)),
    ]);
    await _syncState.set('last_sync_at', DateTime.now().toIso8601String());
  }
```

- [ ] **Step 4: analyze を通す**

```bash
dart analyze lib/data/repositories/ lib/core/services/ lib/domain/repositories/
```

Expected: `No issues found!`

- [ ] **Step 5: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/domain/repositories/lms_repository.dart \
        lib/data/repositories/google_classroom_repository.dart \
        lib/core/services/classroom_sync_service.dart
git commit -m "feat: getAnnouncements・提出状況Sync・turnIn を実装"
```

---

## Task 5: AnnouncementsViewModel + お知らせタブ UI

**Files:**
- Create: `lib/presentation/viewmodels/announcements_viewmodel.dart`
- Create: `test/presentation/viewmodels/announcements_viewmodel_test.dart`
- Modify: `lib/presentation/views/dashboard/course_detail_screen.dart`

- [ ] **Step 1: テストファイルを作成する**

`test/presentation/viewmodels/announcements_viewmodel_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:classroom_remaked/domain/entities/announcement.dart';
import 'package:classroom_remaked/domain/errors/failures.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/presentation/viewmodels/announcements_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}

void main() {
  late MockLmsRepository mockRepo;

  setUp(() {
    mockRepo = MockLmsRepository();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
      ]);

  test('お知らせ一覧を取得して返す', () async {
    final now = DateTime(2026, 5, 15, 12, 0);
    when(() => mockRepo.getAnnouncements('c1')).thenAnswer(
      (_) async => Right([
        Announcement(
          id: 'a1',
          courseId: 'c1',
          text: 'テスト連絡',
          creationTime: now,
        ),
      ]),
    );
    final container = makeContainer();
    addTearDown(container.dispose);
    final result = await container.read(
      announcementsViewModelProvider('c1').future,
    );
    expect(result.length, 1);
    expect(result.first.text, 'テスト連絡');
  });

  test('エラー時は空リストを返す', () async {
    when(() => mockRepo.getAnnouncements('c1'))
        .thenAnswer((_) async => const Left(ApiFailure('network error')));
    final container = makeContainer();
    addTearDown(container.dispose);
    final result = await container.read(
      announcementsViewModelProvider('c1').future,
    );
    expect(result, isEmpty);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/announcements_viewmodel_test.dart
```

Expected: `FAILED` — `announcementsViewModelProvider` が未定義

- [ ] **Step 3: AnnouncementsViewModel を実装する**

`lib/presentation/viewmodels/announcements_viewmodel.dart`:

```dart
// lib/presentation/viewmodels/announcements_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/announcement.dart';
part 'announcements_viewmodel.g.dart';

@riverpod
Future<List<Announcement>> announcementsViewModel(
  AnnouncementsViewModelRef ref,
  String courseId,
) async {
  final repo = ref.watch(lmsRepositoryProvider);
  final result = await repo.getAnnouncements(courseId);
  return result.getOrElse(() => []);
}
```

- [ ] **Step 4: コード生成を実行する**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `announcements_viewmodel.g.dart` が生成される

- [ ] **Step 5: テストを実行してパスを確認する**

```bash
flutter test test/presentation/viewmodels/announcements_viewmodel_test.dart
```

Expected: `+2: All tests passed!`

- [ ] **Step 6: CourseDetailScreen のお知らせタブを実装する**

`lib/presentation/views/dashboard/course_detail_screen.dart` の末尾（`_AssignmentsTab` の後）に `_AnnouncementsTab` を追加し、`CourseDetailScreen.build` 内のスタブを置き換える。

ファイル全体を以下に置き換える:

```dart
// lib/presentation/views/dashboard/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/entities/assignment.dart';
import '../../../domain/entities/announcement.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../../viewmodels/announcements_viewmodel.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  final String courseId;
  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(courseName),
          bottom: const TabBar(
            tabs: [
              Tab(text: '課題'),
              Tab(text: 'お知らせ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AssignmentsTab(courseId: courseId),
            _AnnouncementsTab(courseId: courseId),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  const _AssignmentsTab({required this.courseId});

  final String courseId;

  static final _fake = List.generate(
    3,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Assignment Title Example',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);
    final isLoading = async.isLoading;

    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }

    final all = async.valueOrNull?.assignments ?? _fake;
    final courseAssignments =
        isLoading ? _fake : all.where((a) => a.courseId == courseId).toList()
          ..sort((a, b) {
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

    return Skeletonizer(
      enabled: isLoading,
      child: courseAssignments.isEmpty
          ? const Center(child: Text('課題はありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseAssignments.length,
              itemBuilder: (context, index) {
                final a = courseAssignments[index];
                final due = a.dueDate;
                final isSubmitted =
                    a.submissionState == SubmissionState.turnedIn;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => context.go('/assignments/${a.id}'),
                    child: ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  if (due != null)
                                    Text(
                                      '締め切り: ${DateFormat('yyyy/M/d HH:mm').format(due)}',
                                      style: ShadTheme.of(context)
                                          .textTheme
                                          .muted,
                                    ),
                                ],
                              ),
                            ),
                            if (isSubmitted)
                              const ShadBadge.secondary(child: Text('提出済み')),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab({required this.courseId});

  final String courseId;

  static final _fake = List.generate(
    3,
    (i) => Announcement(
      id: 'fake_$i',
      courseId: 'fake',
      text: 'お知らせのサンプルテキストがここに表示されます。',
      creationTime: DateTime.now().subtract(Duration(days: i)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementsViewModelProvider(courseId));

    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }

    final announcements = async.valueOrNull ?? _fake;
    final isLoading = async.isLoading;

    return Skeletonizer(
      enabled: isLoading,
      child: announcements.isEmpty
          ? const Center(child: Text('お知らせはありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final a = announcements[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ShadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy/M/d HH:mm')
                                .format(a.creationTime),
                            style: ShadTheme.of(context).textTheme.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(a.text),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 7: analyze を通す**

```bash
dart analyze lib/presentation/views/dashboard/course_detail_screen.dart \
            lib/presentation/viewmodels/announcements_viewmodel.dart
```

Expected: `No issues found!`

- [ ] **Step 8: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 9: コミットする**

```bash
git add lib/presentation/viewmodels/announcements_viewmodel.dart \
        lib/presentation/viewmodels/announcements_viewmodel.g.dart \
        lib/presentation/views/dashboard/course_detail_screen.dart \
        test/presentation/viewmodels/announcements_viewmodel_test.dart
git commit -m "feat: お知らせタブを実装（AnnouncementsViewModel + _AnnouncementsTab）"
```

---

## Task 6: 添付ファイル表示 + 課題提出ボタン

**Files:**
- Modify: `lib/presentation/views/assignments/assignment_detail_screen.dart`

AssignmentDetailScreen に以下を追加する:
- 添付ファイルセクション: `assignment.materials` が空でなければ一覧表示し、タップで url_launcher でブラウザ開き
- 提出ボタン: `submissionId != null` かつ `submissionState != turnedIn` のとき表示。確認ダイアログ → `turnIn` 呼び出し

- [ ] **Step 1: assignment_detail_screen.dart を更新する**

`lib/presentation/views/assignments/assignment_detail_screen.dart` を以下に置き換える:

```dart
// lib/presentation/views/assignments/assignment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../../viewmodels/turn_in_viewmodel.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);
    final assignment = async.valueOrNull?.assignments
        .where((a) => a.id == assignmentId)
        .firstOrNull;

    if (async.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('課題が見つかりません')),
      );
    }

    final due = assignment.dueDate;
    final isSubmitted = assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    return Scaffold(
      appBar: AppBar(title: const Text('課題詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(assignment.title,
              style: ShadTheme.of(context).textTheme.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(
                due != null
                    ? DateFormat('yyyy年M月d日 HH:mm').format(due)
                    : '締め切りなし',
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isSubmitted)
            const ShadBadge.secondary(child: Text('提出済み'))
          else if (isOverdue)
            const ShadBadge(
                backgroundColor: Colors.red, child: Text('期限切れ'))
          else if (due != null)
            ShadBadge.outline(
              child: Text(
                  '締め切りまで${due.difference(DateTime.now()).inDays}日'),
            ),

          // ── 説明 ──────────────────────────────────────
          if (assignment.description != null) ...[
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            Text('説明', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            Text(assignment.description!),
          ],

          // ── 添付ファイル ───────────────────────────────
          if (assignment.materials.isNotEmpty) ...[
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            Text('添付ファイル', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            ...assignment.materials.map(
              (m) => _MaterialTile(material: m),
            ),
          ],

          // ── 提出ボタン ─────────────────────────────────
          if (!isSubmitted && assignment.submissionId != null) ...[
            const SizedBox(height: 32),
            _TurnInButton(assignment: assignment),
          ],
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});

  final AssignmentMaterial material;

  IconData get _icon => switch (material.type) {
        AssignmentMaterialType.driveFile => Icons.insert_drive_file_outlined,
        AssignmentMaterialType.youTube => Icons.play_circle_outline,
        AssignmentMaterialType.link => Icons.link,
        AssignmentMaterialType.form => Icons.assignment_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: InkWell(
          onTap: () async {
            final uri = Uri.tryParse(material.url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.open_in_new, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnInButton extends ConsumerWidget {
  const _TurnInButton({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(turnInViewModelProvider).isLoading;

    return ShadButton(
      width: double.infinity,
      onPressed: isLoading
          ? null
          : () async {
              final confirmed = await showShadDialog<bool>(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadDialog.alert(
                    radius: const BorderRadius.all(Radius.circular(12)),
                    removeBorderRadiusWhenTiny: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    useSafeArea: false,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    titleTextAlign: TextAlign.center,
                    title: const Text('課題を提出しますか？'),
                    description: const Text('提出後は取り消せません。'),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      ShadButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('提出する'),
                      ),
                    ],
                  ),
                ),
              );
              if (confirmed == true && context.mounted) {
                final result = await ref
                    .read(turnInViewModelProvider.notifier)
                    .turnIn(
                      assignment.courseId,
                      assignment.id,
                      assignment.submissionId!,
                    );
                if (!context.mounted) return;
                result.fold(
                  (failure) => ShadToaster.of(context).show(
                    ShadToast.destructive(
                      title: const Text('提出に失敗しました'),
                      description: Text(failure.message),
                    ),
                  ),
                  (_) {
                    ShadToaster.of(context).show(
                      const ShadToast(title: Text('提出しました')),
                    );
                    ref.invalidate(assignmentsViewModelProvider);
                  },
                );
              }
            },
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('提出する'),
    );
  }
}
```

- [ ] **Step 2: TurnInViewModel を作成する**

`lib/presentation/viewmodels/turn_in_viewmodel.dart`:

```dart
// lib/presentation/viewmodels/turn_in_viewmodel.dart
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/errors/failures.dart';
part 'turn_in_viewmodel.g.dart';

@riverpod
class TurnInViewModel extends _$TurnInViewModel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  ) async {
    state = const AsyncLoading();
    final repo = ref.read(lmsRepositoryProvider);
    final result =
        await repo.turnIn(courseId, assignmentId, submissionId);
    state = const AsyncData(null);
    return result;
  }
}
```

- [ ] **Step 3: コード生成を実行する**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `turn_in_viewmodel.g.dart` が生成される

- [ ] **Step 4: analyze を通す**

```bash
dart analyze lib/presentation/views/assignments/ \
            lib/presentation/viewmodels/turn_in_viewmodel.dart
```

Expected: `No issues found!`

- [ ] **Step 5: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/views/assignments/assignment_detail_screen.dart \
        lib/presentation/viewmodels/turn_in_viewmodel.dart \
        lib/presentation/viewmodels/turn_in_viewmodel.g.dart
git commit -m "feat: 添付ファイル表示と課題提出ボタンを AssignmentDetailScreen に追加"
```

---

## Task 8: Drive readonly スコープ + DriveFileService

**Files:**
- Modify: `lib/core/services/auth_service.dart`
- Create: `lib/core/services/drive_file_service.dart`
- Modify: `lib/core/di/providers.dart`

Drive ファイルをダウンロードするには `drive.readonly` スコープが必要。
`DriveFileService` は Drive API でファイルのバイト列を取得し、Google Workspace ファイル（Docs/Sheets/Slides）は PDF にエクスポートして返す。

- [ ] **Step 1: auth_service.dart に drive.readonly スコープを追加する**

`lib/core/services/auth_service.dart` の `scopes` に追加:

```dart
  static const scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.rosters.readonly',
    'https://www.googleapis.com/auth/drive.readonly',
  ];
```

**注意:** スコープ追加後は既存ユーザーが再サインインしないと Drive アクセスが許可されない。開発中はサインアウト→サインインで確認する。

- [ ] **Step 2: DriveFileService を作成する**

`lib/core/services/drive_file_service.dart`:

```dart
// lib/core/services/drive_file_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/remote/classroom_http_client.dart';
import '../../domain/entities/assignment_material.dart';

/// Google Drive がウイルススキャンできないと判断したファイルのダウンロード時にスローする。
/// ユーザーの確認を得て acknowledgeAbuse: true で再試行する。
class DriveVirusScanWarningException implements Exception {
  const DriveVirusScanWarningException(this.fileId, this.title, this.mimeType);
  final String fileId;
  final String title;
  final String mimeType;
}

/// ファイルを開く方法を表す。
enum DriveOpenAction {
  /// PDF → アプリ内ビューアへ遷移（bytes を返す）
  inAppPdf,
  /// Google Workspace → alternateLink を外部ブラウザ/アプリで開く
  externalLink,
  /// Office / 不明 → ネイティブアプリ選択ダイアログ
  nativeOpen,
}

class DriveFileService {
  DriveFileService({required GoogleSignInAccount account})
      : _api = drive.DriveApi(ClassroomHttpClient(account));

  final drive.DriveApi _api;

  static const _workspaceMimeTypes = {
    'application/vnd.google-apps.document',
    'application/vnd.google-apps.spreadsheet',
    'application/vnd.google-apps.presentation',
    'application/vnd.google-apps.form',
  };

  static const _officeMimeToExt = {
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        'docx',
    'application/msword': 'doc',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        'xlsx',
    'application/vnd.ms-excel': 'xls',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        'pptx',
    'application/vnd.ms-powerpoint': 'ppt',
  };

  /// [material] に応じた開き方を決定して実行する。
  /// PDF の場合は [DriveOpenAction.inAppPdf] を返し、bytes は
  /// [downloadPdf] で別途取得すること（遷移先で watch する設計のため）。
  Future<DriveOpenAction> resolveAndOpen(
    AssignmentMaterial material,
  ) async {
    // Google Workspace（Docs/Sheets/Slides/Forms）
    if (_isWorkspaceMime(material.mimeType)) {
      final uri = Uri.parse(material.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return DriveOpenAction.externalLink;
    }

    // Drive ファイル（fileId あり）
    final fileId = material.driveFileId;
    if (fileId != null) {
      final mimeType = material.mimeType ?? await _fetchMimeType(fileId);

      if (mimeType == 'application/pdf') {
        return DriveOpenAction.inAppPdf;
      }

      if (_officeMimeToExt.containsKey(mimeType)) {
        await _openWithNativePicker(fileId, material.title, mimeType);
        return DriveOpenAction.nativeOpen;
      }
    }

    // 汎用 URL（YouTube・リンク等）
    final uri = Uri.parse(material.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return DriveOpenAction.externalLink;
  }

  /// PDF ファイルのバイト列を取得する（FileViewerScreen の provider で使用）。
  /// Drive がウイルススキャンできない場合は [DriveVirusScanWarningException] をスロー。
  Future<Uint8List> downloadPdf(String fileId) =>
      _rawDownload(fileId, acknowledgeAbuse: false);

  /// ユーザーが確認済みの場合に acknowledgeAbuse=true で再ダウンロードする。
  Future<Uint8List> downloadPdfWithAcknowledge(String fileId) =>
      _rawDownload(fileId, acknowledgeAbuse: true);

  /// [DriveVirusScanWarningException] に対してユーザーが承認済みの場合に
  /// acknowledgeAbuse=true で再試行する（非 PDF ファイル用）。
  Future<void> openWithAcknowledge(DriveVirusScanWarningException e) =>
      _openWithNativePickerAcknowledged(e.fileId, e.title, e.mimeType);

  Future<Uint8List> _rawDownload(
    String fileId, {
    required bool acknowledgeAbuse,
  }) async {
    try {
      final media = await _api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
        acknowledgeAbuse: acknowledgeAbuse,
      ) as drive.Media;
      return _readStream(media.stream);
    } on Exception catch (e) {
      if (!acknowledgeAbuse &&
          e.toString().contains('cannotDownloadAbusiveFile')) {
        throw DriveVirusScanWarningException(fileId, '', 'application/pdf');
      }
      rethrow;
    }
  }

  Future<String> _fetchMimeType(String fileId) async {
    final meta = await _api.files.get(
      fileId,
      $fields: 'mimeType',
    ) as drive.File;
    return meta.mimeType ?? 'application/octet-stream';
  }

  Future<void> _openWithNativePicker(
    String fileId,
    String title,
    String mimeType,
  ) async {
    try {
      final media = await _api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = await _readStream(media.stream);
      final ext = _officeMimeToExt[mimeType] ?? 'bin';
      final safeName = title.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$safeName.$ext');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } on Exception catch (e) {
      if (e.toString().contains('cannotDownloadAbusiveFile')) {
        throw DriveVirusScanWarningException(fileId, title, mimeType);
      }
      rethrow;
    }
  }

  Future<void> _openWithNativePickerAcknowledged(
    String fileId,
    String title,
    String mimeType,
  ) async {
    final media = await _api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
      acknowledgeAbuse: true,
    ) as drive.Media;
    final bytes = await _readStream(media.stream);
    final ext = _officeMimeToExt[mimeType] ?? 'bin';
    final safeName = title.replaceAll(RegExp(r'[^\w\s.-]'), '_');
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$safeName.$ext');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  Future<Uint8List> _readStream(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  static bool _isWorkspaceMime(String? mime) =>
      mime != null && _workspaceMimeTypes.contains(mime);
}
```

- [ ] **Step 3: providers.dart に driveFileServiceProvider と fileViewerProvider を追加する**

`lib/core/di/providers.dart` の末尾に追加:

```dart
import 'dart:typed_data';
import '../services/drive_file_service.dart';
```

import ブロックに追加した上で、末尾に以下を追加:

```dart
@riverpod
DriveFileService driveFileService(DriveFileServiceRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  if (account == null) throw StateError('Not signed in');
  return DriveFileService(account: account);
}

@riverpod
Future<Uint8List> fileViewer(FileViewerRef ref, String fileId) {
  return ref.watch(driveFileServiceProvider).downloadPdf(fileId);
}
```

- [ ] **Step 4: コード生成を実行する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: analyze を通す**

```bash
dart analyze lib/core/services/drive_file_service.dart lib/core/di/providers.dart
```

Expected: `No issues found!`

- [ ] **Step 6: コミットする**

```bash
git add lib/core/services/auth_service.dart \
        lib/core/services/drive_file_service.dart \
        lib/core/di/providers.dart \
        lib/core/di/providers.g.dart
git commit -m "feat: drive.readonly スコープ + DriveFileService を追加"
```

---

## Task 9: FileViewerScreen + ルーター + _MaterialTile 更新

**Files:**
- Create: `lib/presentation/views/shared/file_viewer_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/presentation/views/assignments/assignment_detail_screen.dart`

Drive ファイルのタップ時に `FileViewerScreen` へ遷移し、PDF を pdfx でネイティブ表示する。
Drive 以外のリンク（YouTube・Web リンク）は引き続き url_launcher でブラウザ開き。

- [ ] **Step 1: FileViewerScreen を作成する**

`lib/presentation/views/shared/file_viewer_screen.dart`:

```dart
// lib/presentation/views/shared/file_viewer_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/drive_file_service.dart';

class FileViewerScreen extends ConsumerStatefulWidget {
  const FileViewerScreen({
    super.key,
    required this.fileId,
    required this.title,
  });

  final String fileId;
  final String title;

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> {
  PdfController? _controller;
  // ウイルス確認後にユーザーが承認した場合の bytes（provider をバイパス）
  Uint8List? _acknowledgedBytes;
  bool _acknowledgeLoading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _downloadWithAcknowledge() async {
    setState(() => _acknowledgeLoading = true);
    try {
      final bytes = await ref
          .read(driveFileServiceProvider)
          .downloadPdfWithAcknowledge(widget.fileId);
      if (!mounted) return;
      setState(() {
        _acknowledgedBytes = bytes;
        _controller = PdfController(document: PdfDocument.openData(bytes));
        _acknowledgeLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _acknowledgeLoading = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('ダウンロードに失敗しました'),
          description: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ウイルス確認後のバイトが手元にある場合はそちらを表示
    if (_acknowledgedBytes != null && _controller != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: PdfView(
          controller: _controller!,
          scrollDirection: Axis.vertical,
        ),
      );
    }

    final async = ref.watch(fileViewerProvider(widget.fileId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e is DriveVirusScanWarningException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'このファイルはウイルススキャンができませんでした。\nダウンロードを続けますか？',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: _acknowledgeLoading
                          ? null
                          : _downloadWithAcknowledge,
                      child: _acknowledgeLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ダウンロードする'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '読み込みに失敗しました\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (bytes) {
          _controller ??= PdfController(
            document: PdfDocument.openData(bytes),
          );
          return PdfView(
            controller: _controller!,
            scrollDirection: Axis.vertical,
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: app_router.dart に `/viewer/:fileId` ルートを追加する**

`lib/core/router/app_router.dart` を読んで、`GoRouter` の `routes` リスト（`StatefulShellRoute` の外）にトップレベルルートを追加する:

```dart
GoRoute(
  path: '/viewer/:fileId',
  builder: (_, state) => FileViewerScreen(
    fileId: state.pathParameters['fileId']!,
    title: state.uri.queryParameters['title'] ?? 'ファイル',
  ),
),
```

import を追加:

```dart
import '../../presentation/views/shared/file_viewer_screen.dart';
```

- [ ] **Step 3: assignment_detail_screen.dart の _MaterialTile を更新する**

`_MaterialTile` を `ConsumerWidget` に変更し、`onTap` で `resolveAndOpen` を呼び、PDF の場合のみ `/viewer/:fileId` へ遷移する。

`lib/presentation/views/assignments/assignment_detail_screen.dart` の `_MaterialTile` クラス全体を以下に置き換える:

import を追加:

```dart
import 'package:go_router/go_router.dart';
import '../../../core/services/drive_file_service.dart';
import '../../../core/di/providers.dart';
```

`_MaterialTile` クラス全体:

```dart
class _MaterialTile extends ConsumerWidget {
  const _MaterialTile({required this.material});

  final AssignmentMaterial material;

  IconData get _icon => switch (material.type) {
        AssignmentMaterialType.driveFile => Icons.insert_drive_file_outlined,
        AssignmentMaterialType.youTube => Icons.play_circle_outline,
        AssignmentMaterialType.link => Icons.link,
        AssignmentMaterialType.form => Icons.assignment_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: InkWell(
          onTap: () async {
            final service = ref.read(driveFileServiceProvider);
            try {
              final action = await service.resolveAndOpen(material);
              if (action == DriveOpenAction.inAppPdf &&
                  material.driveFileId != null &&
                  context.mounted) {
                context.push(
                  '/viewer/${material.driveFileId}'
                  '?title=${Uri.encodeComponent(material.title)}',
                );
              }
            } on DriveVirusScanWarningException catch (e) {
              if (!context.mounted) return;
              final confirmed = await showShadDialog<bool>(
                context: context,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadDialog.alert(
                    radius: const BorderRadius.all(Radius.circular(12)),
                    removeBorderRadiusWhenTiny: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    useSafeArea: false,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    titleTextAlign: TextAlign.center,
                    title: const Text('ウイルススキャン不可'),
                    description: const Text(
                        'このファイルはウイルススキャンができませんでした。自己責任でダウンロードしますか？'),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      ShadButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('ダウンロード'),
                      ),
                    ],
                  ),
                ),
              );
              if (confirmed == true && context.mounted) {
                try {
                  // acknowledgeAbuse=true で再試行
                  await service.openWithAcknowledge(e);
                } on Exception catch (err) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('ダウンロードに失敗しました'),
                        description: Text(err.toString()),
                      ),
                    );
                  }
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.open_in_new, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: コード生成 + analyze**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/presentation/views/shared/ \
            lib/core/router/ \
            lib/presentation/views/assignments/
```

Expected: `No issues found!`

- [ ] **Step 5: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/views/shared/file_viewer_screen.dart \
        lib/core/router/app_router.dart \
        lib/core/router/app_router.g.dart \
        lib/presentation/views/assignments/assignment_detail_screen.dart
git commit -m "feat: Drive ファイルをアプリ内 PDF ビューアで表示"
```

---

## Task 10: 全テスト実行 + PR 更新

- [ ] **Step 1: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`（66件以上）

- [ ] **Step 2: analyze を通す**

```bash
dart analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 3: PR を更新する**

```bash
gh pr edit 21 --body "$(cat <<'EOF'
## 変更内容

### Phase 3a: 非表示機能
- HiddenItems drift テーブル（schema v2）・非表示フィルタリング

### 通知・設定
- スヌーズを通知バーボタンから設定画面の間隔設定に変更
- 初回オンボーディング・CanDisableLazyModeUseCase
- 通知後の期限切れ課題への通知を抑制

### 検索機能
- SearchViewModel（TDD）・SearchScreen・BottomNav 4タブ化

### 詳細画面
- CourseDetailScreen（課題タブ）・AssignmentDetailScreen

### お知らせ・提出・添付ファイル・PDF ビューア
- コメント関連の死にコードを削除
- DB schema v4: Announcements テーブル + materialsJson/submissionId カラム
- お知らせ API 取得・キャッシュ・コース詳細タブに表示
- 提出状況を API から取得しDBに同期（studentSubmissions.list）
- 添付ファイル一覧表示: Drive ファイルはアプリ内 PDF ビューアで開く
- Google Workspace ファイル（Docs/Sheets/Slides）は PDF エクスポートして表示
- AssignmentDetailScreen: 「提出する」ボタン（確認ダイアログ付き）

## テスト

- `flutter test`: All passed
- `dart analyze lib/`: No issues

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## スコープ外

| 機能 | 理由 |
|------|------|
| コメント（師生間 private） | Classroom API v1 は private submission comments を REST で公開していない |
| ファイルの直接ダウンロード | Google Drive API 認証が別途必要。url_launcher で代替 |
| 添付ファイルのアップロード | Classroom API の student submission attachments は複雑な OAuth フロー要 |
| お知らせへの返信 | API で書き込みは student 権限では非対応 |
