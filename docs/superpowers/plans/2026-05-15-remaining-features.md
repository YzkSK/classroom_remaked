# Classroom Remaked — 残機能実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** テスト修正・設定画面サインアウト・検索画面・コース詳細・課題詳細の実装でアプリを完成させる。

**Architecture:** Clean Architecture + MVVM。新規画面はすべて既存パターン（ConsumerWidget + AsyncNotifier + drift）に従う。検索はDBのLIKEクエリでローカル実行。

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_riverpod 2.6, drift 2.20, go_router 14.x, shadcn_ui 0.54, skeletonizer 2.1

---

## 現状サマリー

### ✅ 実装済み
| 機能 | ファイル |
|------|---------|
| 認証（Google Sign-In 7.x） | `auth_service.dart`, `auth_viewmodel.dart`, `sign_in_screen.dart` |
| ダッシュボード（コース一覧・直近締め切り・並び替え・非表示） | `dashboard_screen.dart`, `course_list.dart`, `deadline_widget.dart`, `dashboard_viewmodel.dart` |
| 課題一覧（締め切り順・フィルター・非表示） | `assignments_screen.dart`, `assignments_viewmodel.dart` |
| 設定画面（通知タイミング・スヌーズ間隔・怠惰モード） | `settings_screen.dart`, `settings_viewmodel.dart` |
| 初回オンボーディング | `notification_setup_screen.dart` |
| バックグラウンド通知（workmanager・自動スヌーズ） | `background_notification_task.dart`, `notification_service.dart` |
| ローカルDB（drift） | `app_database.dart` + 各 datasource |
| CanDisableLazyModeUseCase | `can_disable_lazy_mode_usecase.dart` |

### ❌ 未実装 / 壊れている
| 問題 | 内容 |
|------|------|
| **テスト失敗** | `settings_viewmodel_test.dart` 6件：`getSnoozeHours` スタブ未登録 |
| **サインアウト** | ダッシュボードのAppBarにしかない、設定画面に移動すべき |
| **検索** | `SearchScreen` 未作成、`search()` はスタブ（常に空リスト） |
| **コース詳細** | `CourseDetailScreen` 未作成（課題タブ・お知らせタブ） |
| **課題詳細** | `AssignmentDetailScreen` 未作成 |

---

## ファイルマップ

| ファイル | 操作 | 役割 |
|---------|------|------|
| `test/presentation/viewmodels/settings_viewmodel_test.dart` | Modify | `getSnoozeHours` / `setSnoozeHours` スタブ追加 |
| `lib/presentation/views/settings/settings_screen.dart` | Modify | サインアウトボタン追加 |
| `lib/presentation/views/dashboard/dashboard_screen.dart` | Modify | AppBarのサインアウトボタン削除 |
| `lib/data/datasources/local/app_database.dart` | Modify | `searchAssignments()` クエリ追加（スキーマ変更なし） |
| `lib/presentation/viewmodels/search_viewmodel.dart` | Create | `SearchViewModel` (AsyncNotifier) |
| `lib/presentation/views/search/search_screen.dart` | Create | 検索UI |
| `lib/presentation/views/shared/scaffold_with_nav.dart` | Modify | 検索タブを4つ目に追加 |
| `lib/core/router/app_router.dart` | Modify | `/search`, `/courses/:id`, `/assignments/:id` ルートを追加 |
| `lib/presentation/views/dashboard/course_detail_screen.dart` | Create | コース詳細（課題タブ・お知らせスタブ） |
| `lib/presentation/views/assignments/assignment_detail_screen.dart` | Create | 課題詳細（タイトル・締め切り・提出状況） |
| `test/presentation/viewmodels/search_viewmodel_test.dart` | Create | SearchViewModel テスト |

---

## Task 1: settings_viewmodel_test のテスト修正

**Files:**
- Modify: `test/presentation/viewmodels/settings_viewmodel_test.dart`

`getSnoozeHours` と `setSnoozeHours` がスタブ未登録で6件失敗している。

- [ ] **Step 1: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/settings_viewmodel_test.dart
```

Expected: `+0 -6: Some tests failed.` / `type 'Null' is not a subtype of type 'Future<int>'`

- [ ] **Step 2: setUp にスタブを追加する**

`test/presentation/viewmodels/settings_viewmodel_test.dart` の `setUp` ブロックに以下2行を追加する：

```dart
when(() => mockPrefs.getSnoozeHours()).thenAnswer((_) async => 1);
when(() => mockPrefs.setSnoozeHours(any())).thenAnswer((_) async {});
```

また、`build 時に UserPreferences から設定を読み込む` テストに `snoozeHours` のアサーションを追加する：

```dart
expect(state.snoozeHours, 1);
```

- [ ] **Step 3: setSnoozeHours テストを追加する**

既存テストの末尾（`tryDisableLazyMode` テストの後）に追加：

```dart
test('setSnoozeHours で状態と datasource が更新される', () async {
  final container = makeContainer();
  addTearDown(container.dispose);
  await container.read(settingsViewModelProvider.future);
  await container.read(settingsViewModelProvider.notifier).setSnoozeHours(3);
  verify(() => mockPrefs.setSnoozeHours(3)).called(1);
  final state = container.read(settingsViewModelProvider).value!;
  expect(state.snoozeHours, 3);
});

test('setSnoozeHours(0) は無視される', () async {
  final container = makeContainer();
  addTearDown(container.dispose);
  await container.read(settingsViewModelProvider.future);
  await container.read(settingsViewModelProvider.notifier).setSnoozeHours(0);
  verifyNever(() => mockPrefs.setSnoozeHours(any()));
});
```

- [ ] **Step 4: テストを実行してすべてパスすることを確認する**

```bash
flutter test test/presentation/viewmodels/settings_viewmodel_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 5: 全テストを実行する**

```bash
flutter test
```

Expected: `Some tests failed.` が消え `All tests passed!` になること

- [ ] **Step 6: コミットする**

```bash
git add test/presentation/viewmodels/settings_viewmodel_test.dart
git commit -m "test: settings_viewmodel_test に snoozeHours スタブを追加"
```

---

## Task 2: サインアウトを設定画面に移動

**Files:**
- Modify: `lib/presentation/views/settings/settings_screen.dart`
- Modify: `lib/presentation/views/dashboard/dashboard_screen.dart`

- [ ] **Step 1: 設定画面の ListView に ShadSeparator + サインアウトボタンを追加する**

`lib/presentation/views/settings/settings_screen.dart` の `ListView` の `children` 末尾に追加：

```dart
const SizedBox(height: 32),
const ShadSeparator.horizontal(),
const SizedBox(height: 16),
ShadButton.outline(
  width: double.infinity,
  onPressed: () =>
      ref.read(authViewModelProvider.notifier).signOut(),
  child: const Text('サインアウト'),
),
```

また、import に `auth_viewmodel.dart` を追加する：

```dart
import '../../viewmodels/auth_viewmodel.dart';
```

- [ ] **Step 2: ダッシュボードの AppBar からサインアウトアイコンを削除する**

`lib/presentation/views/dashboard/dashboard_screen.dart` の `AppBar` の `actions` を削除し、import も整理する：

```dart
appBar: AppBar(
  title: const Text('Classroom Remaked'),
),
```

`import '../../viewmodels/auth_viewmodel.dart';` も合わせて削除する。

- [ ] **Step 3: コミットする**

```bash
git add lib/presentation/views/settings/settings_screen.dart \
        lib/presentation/views/dashboard/dashboard_screen.dart
git commit -m "feat: サインアウトをダッシュボードから設定画面に移動"
```

---

## Task 3: 検索 DB クエリを追加

**Files:**
- Modify: `lib/data/datasources/local/app_database.dart`

スキーマ変更なし。drift の `customSelect` でタイトルに対して LIKE 検索を追加する。

- [ ] **Step 1: `AppDatabase` に `searchAssignments` メソッドを追加する**

`lib/data/datasources/local/app_database.dart` の `AppDatabase` クラス末尾（`openBackground` の前）に追加：

```dart
Future<List<AssignmentRow>> searchAssignments(String query) {
  final q = '%${query.toLowerCase()}%';
  return (select(assignments)
        ..where((t) =>
            t.title.lower().like(q) |
            t.description.lower().like(q)))
      .get();
}
```

- [ ] **Step 2: analyze を通す**

```bash
dart analyze lib/data/datasources/local/app_database.dart
```

Expected: `No issues found!`

- [ ] **Step 3: コミットする**

```bash
git add lib/data/datasources/local/app_database.dart
git commit -m "feat: AppDatabase に searchAssignments クエリを追加"
```

---

## Task 4: SearchViewModel (TDD)

**Files:**
- Create: `test/presentation/viewmodels/search_viewmodel_test.dart`
- Create: `lib/presentation/viewmodels/search_viewmodel.dart`

- [ ] **Step 1: テストファイルを作成する**

`test/presentation/viewmodels/search_viewmodel_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/presentation/viewmodels/search_viewmodel.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MockAppDatabase mockDb;

  setUp(() {
    mockDb = MockAppDatabase();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(mockDb),
      ]);

  test('初期状態はクエリ空・結果空', () {
    final container = makeContainer();
    addTearDown(container.dispose);
    final state = container.read(searchViewModelProvider);
    expect(state.query, '');
    expect(state.results, isEmpty);
  });

  test('search でキーワードにマッチする課題が返る', () async {
    when(() => mockDb.searchAssignments('数学')).thenAnswer(
      (_) async => [
        AssignmentRow(
          id: 'a1',
          courseId: 'c1',
          title: '数学レポート',
          description: null,
          dueDateMillis: null,
          state: 'published',
          submissionState: null,
        ),
      ],
    );
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(searchViewModelProvider.notifier).search('数学');
    final state = container.read(searchViewModelProvider);
    expect(state.query, '数学');
    expect(state.results.length, 1);
    expect(state.results.first.title, '数学レポート');
  });

  test('クエリ空では検索せず結果を空にする', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(searchViewModelProvider.notifier).search('');
    verifyNever(() => mockDb.searchAssignments(any()));
    expect(container.read(searchViewModelProvider).results, isEmpty);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/search_viewmodel_test.dart
```

Expected: `FAILED` — `searchViewModelProvider` が未定義

- [ ] **Step 3: SearchViewModel を実装する**

`lib/presentation/viewmodels/search_viewmodel.dart`:

```dart
// lib/presentation/viewmodels/search_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
part 'search_viewmodel.g.dart';

class SearchState {
  const SearchState({this.query = '', this.results = const []});
  final String query;
  final List<Assignment> results;
}

@riverpod
class SearchViewModel extends _$SearchViewModel {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    final rows = await ref.read(appDatabaseProvider).searchAssignments(query);
    state = SearchState(
      query: query,
      results: rows
          .map((r) => Assignment(
                id: r.id,
                courseId: r.courseId,
                title: r.title,
                description: r.description,
                dueDate: r.dueDateMillis != null
                    ? DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!)
                    : null,
              ))
          .toList(),
    );
  }

  void clear() => state = const SearchState();
}
```

`lib/core/di/providers.dart` に `appDatabaseProvider` が未登録の場合は追加：

```dart
@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) => AppDatabase();
```

- [ ] **Step 4: コード生成を実行する**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `search_viewmodel.g.dart` が生成される

- [ ] **Step 5: テストを実行してパスすることを確認する**

```bash
flutter test test/presentation/viewmodels/search_viewmodel_test.dart
```

Expected: `+3: All tests passed!`

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/viewmodels/search_viewmodel.dart \
        lib/presentation/viewmodels/search_viewmodel.g.dart \
        test/presentation/viewmodels/search_viewmodel_test.dart \
        lib/core/di/providers.dart lib/core/di/providers.g.dart
git commit -m "feat: SearchViewModel を TDD で実装"
```

---

## Task 5: SearchScreen + BottomNav 4タブ化

**Files:**
- Create: `lib/presentation/views/search/search_screen.dart`
- Modify: `lib/presentation/views/shared/scaffold_with_nav.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: SearchScreen を実装する**

`lib/presentation/views/search/search_screen.dart`:

```dart
// lib/presentation/views/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/search_viewmodel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final notifier = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('検索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShadInput(
              controller: _controller,
              placeholder: const Text('課題名で検索...'),
              leading: const Icon(Icons.search, size: 16),
              trailing: state.query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _controller.clear();
                        notifier.clear();
                      },
                      child: const Icon(Icons.close, size: 16),
                    )
                  : null,
              onChanged: (q) => notifier.search(q),
            ),
          ),
          Expanded(
            child: state.query.isEmpty
                ? const Center(child: Text('キーワードを入力してください'))
                : state.results.isEmpty
                    ? Center(child: Text('「${state.query}」に一致する課題はありません'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.results.length,
                        itemBuilder: (context, index) =>
                            _ResultCard(assignment: state.results[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
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
      ),
    );
  }
}
```

- [ ] **Step 2: BottomNav に検索タブを追加する**

`lib/presentation/views/shared/scaffold_with_nav.dart` の `items` に追加：

```dart
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
    icon: Icon(Icons.search_rounded),
    label: '検索',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.settings_rounded),
    label: '設定',
  ),
],
```

- [ ] **Step 3: app_router.dart に `/search` ブランチを追加する**

`lib/core/router/app_router.dart` の `StatefulShellRoute` に 3番目のブランチとして追加（settings を4番目にずらす）：

```dart
StatefulShellBranch(routes: [
  GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
]),
StatefulShellBranch(routes: [
  GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
]),
```

import も追加：

```dart
import '../../presentation/views/search/search_screen.dart';
```

- [ ] **Step 4: コード生成を実行する**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: analyze を通す**

```bash
dart analyze lib/presentation/views/search/ lib/presentation/views/shared/ lib/core/router/
```

Expected: `No issues found!`

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/views/search/ \
        lib/presentation/views/shared/scaffold_with_nav.dart \
        lib/core/router/app_router.dart \
        lib/core/router/app_router.g.dart
git commit -m "feat: 検索画面を実装・BottomNav を4タブに変更"
```

---

## Task 6: CourseDetailScreen

**Files:**
- Create: `lib/presentation/views/dashboard/course_detail_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/presentation/views/dashboard/widgets/course_list.dart`

コース詳細には課題タブ（そのコースの課題一覧・締め切り順）とお知らせタブ（スタブ）を表示する。

- [ ] **Step 1: CourseDetailScreen を実装する**

`lib/presentation/views/dashboard/course_detail_screen.dart`:

```dart
// lib/presentation/views/dashboard/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';

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
            const Center(child: Text('お知らせ（未実装）')),
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
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 2: app_router.dart に `/courses/:courseId` ルートを追加する**

`StatefulShellBranch` の dashboard ブランチを以下に変更（ネストルート）：

```dart
StatefulShellBranch(routes: [
  GoRoute(
    path: '/dashboard',
    builder: (_, __) => const DashboardScreen(),
    routes: [
      GoRoute(
        path: 'courses/:courseId',
        builder: (_, state) => CourseDetailScreen(
          courseId: state.pathParameters['courseId']!,
          courseName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
    ],
  ),
]),
```

import を追加：

```dart
import '../../presentation/views/dashboard/course_detail_screen.dart';
```

- [ ] **Step 3: CourseCard にタップナビゲーションを追加する**

`lib/presentation/views/dashboard/widgets/course_list.dart` の `ShadCard` を `GestureDetector` で包む：

```dart
GestureDetector(
  onTap: () => context.go(
    '/dashboard/courses/${course.id}?name=${Uri.encodeComponent(course.name)}',
  ),
  child: ShadCard( ... ),  // 既存の ShadCard
),
```

import に `go_router` を追加：

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 4: コード生成 + analyze**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/presentation/views/dashboard/ lib/core/router/
```

Expected: `No issues found!`

- [ ] **Step 5: コミットする**

```bash
git add lib/presentation/views/dashboard/course_detail_screen.dart \
        lib/core/router/app_router.dart \
        lib/core/router/app_router.g.dart \
        lib/presentation/views/dashboard/widgets/course_list.dart
git commit -m "feat: コース詳細画面を実装（課題タブ・お知らせスタブ）"
```

---

## Task 7: AssignmentDetailScreen

**Files:**
- Create: `lib/presentation/views/assignments/assignment_detail_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/presentation/views/assignments/assignments_screen.dart`
- Modify: `lib/presentation/views/dashboard/course_detail_screen.dart`

- [ ] **Step 1: AssignmentDetailScreen を実装する**

`lib/presentation/views/assignments/assignment_detail_screen.dart`:

```dart
// lib/presentation/views/assignments/assignment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';

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
          if (assignment.description != null) ...[
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            Text('説明', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            Text(assignment.description!),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: app_router.dart に `/assignments/:assignmentId` ルートを追加する**

assignments ブランチを以下に変更：

```dart
StatefulShellBranch(routes: [
  GoRoute(
    path: '/assignments',
    builder: (_, __) => const AssignmentsScreen(),
    routes: [
      GoRoute(
        path: ':assignmentId',
        builder: (_, state) => AssignmentDetailScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
    ],
  ),
]),
```

import を追加：

```dart
import '../../presentation/views/assignments/assignment_detail_screen.dart';
```

- [ ] **Step 3: assignments_screen.dart の _AssignmentCardContent にタップ遷移を追加する**

`_AssignmentCard` の `ShadContextMenu` の `child` を `GestureDetector` で包む：

```dart
GestureDetector(
  onTap: () => context.go('/assignments/${assignment.id}'),
  child: _AssignmentCardContent(assignment: assignment),
),
```

`_AssignmentCard` の `build` で `context` が必要になるため、`StatelessWidget` の `build(BuildContext context)` を使うよう確認する（既にそうなっているはず）。

import に go_router を追加：

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 4: course_detail_screen.dart の課題カードにもタップ遷移を追加する**

`_AssignmentsTab` の課題カードを `GestureDetector` で包む：

```dart
GestureDetector(
  onTap: () => context.go('/assignments/${a.id}'),
  child: ShadCard( ... ),
),
```

import に go_router を追加：

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 5: コード生成 + analyze**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/presentation/views/assignments/ lib/core/router/
```

Expected: `No issues found!`

- [ ] **Step 6: コミットする**

```bash
git add lib/presentation/views/assignments/assignment_detail_screen.dart \
        lib/core/router/app_router.dart \
        lib/core/router/app_router.g.dart \
        lib/presentation/views/assignments/assignments_screen.dart \
        lib/presentation/views/dashboard/course_detail_screen.dart
git commit -m "feat: 課題詳細画面を実装・一覧からタップで遷移"
```

---

## Task 8: 全テスト実行 + PR 作成

- [ ] **Step 1: 全テストを実行する**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 2: PR を作成する**

```bash
gh pr create \
  --title "feat: 検索・コース詳細・課題詳細・テスト修正" \
  --body "$(cat <<'EOF'
## 変更内容
- settings_viewmodel_test: snoozeHours スタブ追加（6件修正）
- サインアウトをダッシュボードから設定画面に移動
- 検索画面実装（ローカルDB LIKE クエリ・4タブ化）
- コース詳細画面（課題タブ・お知らせスタブ）
- 課題詳細画面（タイトル・締め切り・提出状況・説明）

## テスト
- flutter test: All passed
EOF
)" \
  --base main
```

---

## スコープ外（将来対応）

| 機能 | 理由 |
|------|------|
| お知らせ取得・表示 | DBにAnnouncementsテーブルが未存在、APIフェッチロジックも未実装 |
| コメント宛先識別バッジ | 課題詳細のUI拡張として別タスクで対応 |
| E2Eテスト | integration_test は別フェーズ |
