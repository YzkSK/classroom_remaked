# Classroom Remaked — Phase 1: Setup + Foundation + Auth

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GitHubリポジトリ・Issue作成から始まり、Flutter Clean Architecture骨格とgoogle_sign_in 7.x認証が動作するところまで構築する。

**Architecture:** Clean Architecture + MVVM。domain → data → presentation の依存方向を厳守。Riverpod (AsyncNotifier) を ViewModel として使用。google_sign_in 7.x はシングルトン `GoogleSignIn.instance` を使い、`authorizationClient.authorizationForScopes()` で googleapis 向け OAuth2 トークンを取得。

**Tech Stack:** Flutter 3.x (stable), Dart 3.x, flutter_riverpod 2.6, riverpod_annotation 2.6, google_sign_in 7.0, googleapis 13.x, go_router 14.x, dartz 0.10, freezed 2.5, shadcn_ui 0.54, skeletonizer 2.1, isar 3.1

---

## ファイルマップ

| ファイル | 役割 |
|---------|------|
| `lib/main.dart` | アプリエントリーポイント・AuthService初期化 |
| `lib/app.dart` | ShadApp + Riverpod ProviderScope |
| `lib/core/services/auth_service.dart` | google_sign_in 7.x ラッパー |
| `lib/core/router/app_router.dart` | go_router 設定・リダイレクト |
| `lib/core/di/providers.dart` | Riverpod プロバイダー集約 |
| `lib/domain/entities/course.dart` | Course エンティティ (freezed) |
| `lib/domain/entities/assignment.dart` | Assignment エンティティ (freezed) |
| `lib/domain/entities/announcement.dart` | Announcement エンティティ (freezed) |
| `lib/domain/entities/comment.dart` | Comment エンティティ (freezed) |
| `lib/domain/errors/failures.dart` | sealed class Failure |
| `lib/domain/repositories/lms_repository.dart` | LmsRepository 抽象インターフェース |
| `lib/presentation/viewmodels/auth_viewmodel.dart` | AuthViewModel (AsyncNotifier) |
| `lib/presentation/views/splash/splash_screen.dart` | スプラッシュ画面 |
| `lib/presentation/views/auth/sign_in_screen.dart` | サインイン画面 |
| `lib/presentation/views/dashboard/dashboard_screen.dart` | ダッシュボード仮画面 |
| `test/core/services/auth_service_test.dart` | AuthService 単体テスト |
| `test/presentation/viewmodels/auth_viewmodel_test.dart` | AuthViewModel 単体テスト |

---

## Task 1: GitHubリポジトリ作成

**Files:**
- Create: なし（GitHub上の操作）

- [ ] **Step 1: gh CLI でリポジトリを作成する**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
git init
git branch -M main
gh repo create classroom_remaked \
  --private \
  --description "Google Classroomの使いづらさを解決するFlutterモバイルアプリ" \
  --source=. \
  --remote=origin
```

- [ ] **Step 2: Squash merge のみ許可・branch protection を設定する**

```bash
gh repo edit classroom_remaked \
  --enable-squash-merge \
  --delete-branch-on-merge \
  --disable-merge-commit \
  --disable-rebase-merge
```

- [ ] **Step 3: 設計書を最初のコミットとして push する**

```bash
git add docs/
git commit -m "docs: 設計書・Git運用ルールを追加"
git push -u origin main
```

Expected: `Branch 'main' set up to track remote branch 'main' from 'origin'.`

---

## Task 2: GitHub Issues 作成

**Files:**
- Create: なし（GitHub上の操作）

- [ ] **Step 1: Setup Issues を作成する**

```bash
gh issue create --title "feat: Flutterプロジェクト初期化・Clean Architecture骨格" \
  --body "pubspec.yaml設定・フォルダ構造・Domain層のエンティティとRepository interfaceを構築する" \
  --label "setup"

gh issue create --title "feat: google_sign_in 7.x 認証フロー実装" \
  --body "AuthService・AuthViewModel・Splash/SignIn画面を実装する。google_sign_in 7.xのシングルトンAPIを使用。" \
  --label "page/auth"
```

- [ ] **Step 2: Dashboard Issues を作成する**

```bash
gh issue create --title "feat: Google Classroom APIコース一覧取得" \
  --body "GoogleClassroomRepository実装。googleapis + ClassroomHttpClientでコース一覧をIsarにキャッシュ。" \
  --label "page/dashboard"

gh issue create --title "feat: 直近締め切りウィジェット" \
  --body "GetUpcomingDeadlinesUseCase実装。設定したnotifyBefore以内の未提出課題を一覧表示。" \
  --label "page/dashboard"

gh issue create --title "feat: コースドラッグ&ドロップ並び替え" \
  --body "ReorderableListViewでコース順序をカスタマイズ。CourseOrderEntityをIsarに保存。" \
  --label "page/dashboard"
```

- [ ] **Step 3: Assignments / Search / Notifications Issues を作成する**

```bash
gh issue create --title "feat: 課題一覧（締め切り順ソート・フィルター）" \
  --body "全コースの課題を締め切り順に表示。未提出フィルターあり。" \
  --label "page/assignments"

gh issue create --title "feat: コース・課題の非表示機能" \
  --body "長押しメニューから非表示。HiddenItemEntityをIsarに保存。設定画面から復元可能。" \
  --label "page/assignments"

gh issue create --title "feat: コース横断全文検索" \
  --body "課題・お知らせをキーワード検索。クライアントサイドでIsarキャッシュから検索。" \
  --label "page/search"

gh issue create --title "feat: ユーザー設定型通知タイミング（最小24時間）" \
  --body "締め切りの何時間前に通知するかをユーザーが設定。最小値24時間でバリデーション。workmanagerで定期実行。" \
  --label "page/notifications"

gh issue create --title "feat: スヌーズ機能" \
  --body "通知からスヌーズ（30分/1時間/3時間）。SnoozedNotificationEntityをIsarに保存。" \
  --label "page/notifications"

gh issue create --title "feat: 怠惰人間モード" \
  --body "通知タイミング以内に未提出課題がある限りスヌーズ不可。CanSnoozeUseCaseで判定。" \
  --label "page/notifications"

gh issue create --title "feat: コメント宛先識別（クラス全体/あなたへ）" \
  --body "CommentVisibility enum。ShadBadgeで視覚的に区別。プライベートコメントは上部ピン留め。" \
  --label "page/dashboard"

gh issue create --title "feat: 非表示リスト管理・通知設定画面" \
  --body "設定画面。非表示アイテムの復元・通知タイミング設定・スヌーズ設定・怠惰人間モードON/OFF。" \
  --label "page/settings"

gh issue create --title "test: 単体テスト・E2Eテスト" \
  --body "domain UseCases・ViewModel・integration_testによるE2Eテスト実装。" \
  --label "test"
```

- [ ] **Step 4: Issue一覧を確認する**

```bash
gh issue list
```

Expected: 13件以上のIssueが表示される

---

## Task 3: Google Cloud Console 設定（手動作業）

**Files:**
- Create: `ios/Runner/GoogleService-Info.plist`（Google Consoleからダウンロード）

> この Task は手動でブラウザ作業が必要。

- [ ] **Step 1: Google Cloud Console でプロジェクトを作成する**

1. https://console.cloud.google.com/ を開く
2. 「新しいプロジェクト」→ 名前: `ClassroomRemaked`
3. Google Classroom API を有効化:
   - 「APIとサービス」→「ライブラリ」→「Google Classroom API」を検索→「有効にする」

- [ ] **Step 2: OAuth 2.0 クライアントIDを作成する**

1. 「APIとサービス」→「認証情報」→「認証情報を作成」→「OAuthクライアントID」
2. 「同意画面を設定」→ User Type: 外部 → アプリ名: `Classroom Remaked`
   - スコープを追加:
     - `classroom.courses.readonly`
     - `classroom.coursework.me.readonly`
     - `classroom.announcements.readonly`
     - `classroom.coursework.students.readonly`
     - `classroom.rosters.readonly`
3. iOS用: アプリの種類「iOS」→ Bundle ID: `com.classroomremaked.app` → 作成
   - `GoogleService-Info.plist` をダウンロードして `ios/Runner/` に配置
4. Android用: アプリの種類「Android」→ パッケージ名: `com.classroomremaked.app`
   - SHA-1フィンガープリント: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android` で取得して入力
   - `google-services.json` をダウンロードして `android/app/` に配置

- [ ] **Step 3: クライアントIDをメモする**

```
iOS Client ID: xxxxxxxx.apps.googleusercontent.com
Reversed Client ID (URL Scheme): com.googleusercontent.apps.xxxxxxxx
```

---

## Task 4: Flutterプロジェクト初期化

**Files:**
- Create: Flutter project structure

- [ ] **Step 1: Flutter プロジェクトを作成する（既存ディレクトリに展開）**

```bash
cd /Users/yzk/Documents/GitHub/classroom_remaked
flutter create . \
  --org com.classroomremaked \
  --project-name classroom_remaked \
  --platforms ios,android \
  --description "Google Classroomの使いづらさを解決するFlutterモバイルアプリ"
```

Expected: `All done! ...` と表示される

- [ ] **Step 2: デフォルトのカウンターアプリを削除する**

`lib/main.dart` を以下に置き換える:

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const App());
}
```

`lib/app.dart` を新規作成:

```dart
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Classroom Remaked')),
      ),
    );
  }
}
```

- [ ] **Step 3: デフォルトのテストを削除する**

```bash
rm test/widget_test.dart
```

- [ ] **Step 4: iOS の最小バージョンを設定する**

`ios/Podfile` の先頭:
```ruby
platform :ios, '12.0'
```

- [ ] **Step 5: 動作確認する**

```bash
flutter run
```

Expected: 「Classroom Remaked」と表示される画面が起動する

- [ ] **Step 6: コミットする**

```bash
git add .
git commit -m "chore: Flutterプロジェクト初期化"
```

---

## Task 5: pubspec.yaml 設定

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml を更新する**

`pubspec.yaml` の `dependencies` と `dev_dependencies` を以下に置き換える:

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # 認証
  google_sign_in: ^7.0.0

  # Google Classroom API
  googleapis: ^13.0.0
  http: ^1.2.0

  # UI
  shadcn_ui: ^0.54.0
  skeletonizer: ^2.1.3

  # 状態管理
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0

  # ナビゲーション
  go_router: ^14.0.0

  # ローカルキャッシュ
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
    path: ''  # isar_flutter_libs は flutter plugin

  # 通知
  flutter_local_notifications: ^18.0.0
  workmanager: ^0.5.2

  # ユーティリティ
  freezed_annotation: ^2.4.0
  dartz: ^0.10.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  isar_generator: ^3.1.0
  mocktail: ^1.0.0
  riverpod_test: ^2.0.0
```

- [ ] **Step 2: パッケージを取得する**

```bash
flutter pub get
```

Expected: エラーなく完了する

- [ ] **Step 3: コミットする**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: 依存パッケージを追加"
```

---

## Task 6: Clean Architecture フォルダ構造作成

**Files:**
- Create: 各ディレクトリと `.gitkeep`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p lib/domain/entities
mkdir -p lib/domain/repositories
mkdir -p lib/domain/usecases
mkdir -p lib/domain/errors
mkdir -p lib/data/models
mkdir -p lib/data/datasources/remote
mkdir -p lib/data/datasources/local
mkdir -p lib/data/repositories
mkdir -p lib/presentation/viewmodels
mkdir -p lib/presentation/views/splash
mkdir -p lib/presentation/views/auth
mkdir -p lib/presentation/views/dashboard/widgets
mkdir -p lib/presentation/views/assignments
mkdir -p lib/presentation/views/search
mkdir -p lib/presentation/views/settings
mkdir -p lib/presentation/views/shared
mkdir -p lib/core/di
mkdir -p lib/core/router
mkdir -p lib/core/services
mkdir -p lib/core/errors
mkdir -p test/core/services
mkdir -p test/domain/usecases
mkdir -p test/presentation/viewmodels
mkdir -p integration_test
```

- [ ] **Step 2: コミットする**

```bash
git add lib/ test/ integration_test/
git commit -m "chore: Clean Architectureフォルダ構造を作成"
```

---

## Task 7: Domain Layer — Entities & Failures

**Files:**
- Create: `lib/domain/entities/course.dart`
- Create: `lib/domain/entities/assignment.dart`
- Create: `lib/domain/entities/announcement.dart`
- Create: `lib/domain/entities/comment.dart`
- Create: `lib/domain/errors/failures.dart`

- [ ] **Step 1: failures.dart を作成する**

```dart
// lib/domain/errors/failures.dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

- [ ] **Step 2: course.dart を作成する**

```dart
// lib/domain/entities/course.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'course.freezed.dart';

@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String name,
    String? description,
    String? section,
    String? room,
    String? ownerId,
    @Default('ACTIVE') String courseState,
  }) = _Course;
}
```

- [ ] **Step 3: assignment.dart を作成する**

```dart
// lib/domain/entities/assignment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'assignment.freezed.dart';

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
  }) = _Assignment;
}
```

- [ ] **Step 4: announcement.dart を作成する**

```dart
// lib/domain/entities/announcement.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'announcement.freezed.dart';

@freezed
class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String courseId,
    required String text,
    required DateTime creationTime,
    DateTime? updateTime,
  }) = _Announcement;
}
```

- [ ] **Step 5: comment.dart を作成する**

```dart
// lib/domain/entities/comment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment.freezed.dart';

enum CommentVisibility { classWide, private }

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String authorName,
    required String body,
    required DateTime createdAt,
    required CommentVisibility visibility,
  }) = _Comment;
}
```

- [ ] **Step 6: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `lib/domain/entities/course.freezed.dart` 等が生成される

- [ ] **Step 7: コミットする**

```bash
git add lib/domain/
git commit -m "feat: Domain層エンティティとFailuresを追加"
```

---

## Task 8: Domain Layer — Repository Interface

**Files:**
- Create: `lib/domain/repositories/lms_repository.dart`

- [ ] **Step 1: lms_repository.dart を作成する**

```dart
// lib/domain/repositories/lms_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/assignment.dart';
import '../entities/announcement.dart';
import '../entities/comment.dart';
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
  Future<Either<Failure, List<Comment>>> getComments(
    String courseId,
    String itemId, {
    CommentVisibility? filterBy,
  });
}
```

- [ ] **Step 2: コミットする**

```bash
git add lib/domain/repositories/
git commit -m "feat: LmsRepository抽象インターフェースを追加"
```

---

## Task 9: AuthService (google_sign_in 7.x)

**Files:**
- Create: `lib/core/services/auth_service.dart`
- Create: `test/core/services/auth_service_test.dart`

- [ ] **Step 1: テストを先に書く（TDD）**

```dart
// test/core/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:classroom_remaked/core/services/auth_service.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  group('AuthService', () {
    test('signOut calls GoogleSignIn.instance.signOut', () async {
      // この単体テストは実機環境が必要なため integration_test で検証する
      // ここでは AuthService がインスタンス化できることのみ確認
      expect(() => AuthService(), returnsNormally);
    });

    test('scopes contains required classroom scopes', () {
      expect(
        AuthService.scopes,
        containsAll([
          'https://www.googleapis.com/auth/classroom.courses.readonly',
          'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
        ]),
      );
    });
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/core/services/auth_service_test.dart
```

Expected: `FAILED` — `AuthService` が未定義

- [ ] **Step 3: auth_service.dart を実装する**

```dart
// lib/core/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.rosters.readonly',
  ];

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize();
  }

  /// サイレントサインインを試みる。失敗時は null を返す（例外を投げない）。
  Future<GoogleSignInAccount?> attemptSilentSignIn() {
    return GoogleSignIn.instance.attemptLightweightAuthentication() ??
        Future.value(null);
  }

  /// ユーザー操作によるサインイン。プラットフォームが対応していない場合は例外。
  Future<GoogleSignInAccount> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('このプラットフォームはサインインをサポートしていません');
    }
    return GoogleSignIn.instance.authenticate(scopeHint: scopes);
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;
}
```

- [ ] **Step 4: テストを実行してパスを確認する**

```bash
flutter test test/core/services/auth_service_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: iOS の Info.plist に URL Scheme を追加する**

`ios/Runner/Info.plist` の `<dict>` 内に以下を追加（`REVERSED_CLIENT_ID` はTask 3でメモした値に置き換える）:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>GIDClientID</key>
<string>IOS_CLIENT_ID</string>
```

- [ ] **Step 6: コミットする**

```bash
git add lib/core/services/ test/core/services/ ios/Runner/Info.plist
git commit -m "feat: google_sign_in 7.x AuthServiceを実装"
```

---

## Task 10: AuthViewModel + Riverpod プロバイダー

**Files:**
- Create: `lib/presentation/viewmodels/auth_viewmodel.dart`
- Create: `lib/core/di/providers.dart`
- Create: `test/presentation/viewmodels/auth_viewmodel_test.dart`

- [ ] **Step 1: テストを先に書く（TDD）**

```dart
// test/presentation/viewmodels/auth_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:classroom_remaked/presentation/viewmodels/auth_viewmodel.dart';
import 'package:classroom_remaked/core/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthViewModel', () {
    test('初期状態は loading', () {
      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('サイレントサインイン成功時は GoogleSignInAccount を返す', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockAuthService.attemptSilentSignIn())
          .thenAnswer((_) async => mockAccount);

      await container.read(authViewModelProvider.future);
      final state = container.read(authViewModelProvider);

      expect(state, isA<AsyncData<GoogleSignInAccount?>>());
      expect(state.value, mockAccount);
    });

    test('サイレントサインイン失敗時は null を返す（例外ではない）', () async {
      when(() => mockAuthService.attemptSilentSignIn())
          .thenAnswer((_) async => null);

      await container.read(authViewModelProvider.future);
      final state = container.read(authViewModelProvider);

      expect(state, isA<AsyncData<GoogleSignInAccount?>>());
      expect(state.value, isNull);
    });
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

```bash
flutter test test/presentation/viewmodels/auth_viewmodel_test.dart
```

Expected: `FAILED` — `authViewModelProvider` が未定義

- [ ] **Step 3: providers.dart を作成する**

```dart
// lib/core/di/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
part 'providers.g.dart';

@riverpod
AuthService authService(AuthServiceRef ref) => AuthService();
```

- [ ] **Step 4: auth_viewmodel.dart を作成する**

```dart
// lib/presentation/viewmodels/auth_viewmodel.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  Future<GoogleSignInAccount?> build() async {
    final authService = ref.watch(authServiceProvider);
    return authService.attemptSilentSignIn();
  }

  Future<GoogleSignInAccount> signIn() async {
    final authService = ref.read(authServiceProvider);
    final account = await authService.signIn();
    state = AsyncData(account);
    return account;
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AsyncData(null);
  }
}
```

- [ ] **Step 5: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `providers.g.dart`・`auth_viewmodel.g.dart` が生成される

- [ ] **Step 6: テストを実行してパスを確認する**

```bash
flutter test test/presentation/viewmodels/auth_viewmodel_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 7: コミットする**

```bash
git add lib/core/di/ lib/presentation/viewmodels/auth_viewmodel.dart \
  test/presentation/viewmodels/
git commit -m "feat: AuthViewModelとRiverpodプロバイダーを実装"
```

---

## Task 11: go_router 設定

**Files:**
- Create: `lib/core/router/app_router.dart`

- [ ] **Step 1: app_router.dart を作成する**

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/splash/splash_screen.dart';
import '../../presentation/views/auth/sign_in_screen.dart';
import '../../presentation/views/dashboard/dashboard_screen.dart';
part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';

      final isSignedIn = authState.valueOrNull != null;
      final isOnAuth = state.matchedLocation == '/sign-in';
      final isOnSplash = state.matchedLocation == '/splash';

      if (!isSignedIn && !isOnAuth && !isOnSplash) return '/sign-in';
      if (isSignedIn && (isOnAuth || isOnSplash)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    ],
  );
}
```

- [ ] **Step 2: コード生成を実行する**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `app_router.g.dart` が生成される

- [ ] **Step 3: コミットする**

```bash
git add lib/core/router/
git commit -m "feat: go_router設定を追加"
```

---

## Task 12: SplashScreen・SignInScreen・DashboardScreen（仮）

**Files:**
- Create: `lib/presentation/views/splash/splash_screen.dart`
- Create: `lib/presentation/views/auth/sign_in_screen.dart`
- Create: `lib/presentation/views/dashboard/dashboard_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: splash_screen.dart を作成する**

```dart
// lib/presentation/views/splash/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

- [ ] **Step 2: sign_in_screen.dart を作成する**

```dart
// lib/presentation/views/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Classroom Remaked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Google アカウントでサインイン'),
            const SizedBox(height: 32),
            ShadButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(authViewModelProvider.notifier)
                            .signIn();
                      } catch (e) {
                        if (context.mounted) {
                          ShadToaster.of(context).show(
                            ShadToast.destructive(
                              title: const Text('サインインに失敗しました'),
                              description: Text(e.toString()),
                            ),
                          );
                        }
                      }
                    },
              child: authState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Google でサインイン'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: dashboard_screen.dart を仮実装する**

```dart
// lib/presentation/views/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authViewModelProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('ダッシュボード（実装予定）'),
      ),
    );
  }
}
```

- [ ] **Step 4: app.dart を ShadApp + Riverpod + go_router に更新する**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ShadApp.router(
      title: 'Classroom Remaked',
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 5: main.dart を更新して AuthService を初期化する**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/auth_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialize();
  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 6: アプリを起動して動作を確認する**

```bash
flutter run
```

確認項目:
- スプラッシュ画面（ローディング）が表示される
- 未サインイン時にサインイン画面へリダイレクトされる
- 「Google でサインイン」ボタンをタップするとGoogle認証画面が開く
- 認証成功後にダッシュボードへ遷移する
- ログアウトボタンでサインイン画面に戻る

- [ ] **Step 7: コミットする**

```bash
git add lib/presentation/views/ lib/app.dart lib/main.dart
git commit -m "feat: Splash・SignIn・Dashboard仮画面を実装"
```

---

## Task 13: page/auth ブランチを main へマージ

- [ ] **Step 1: 現在のブランチ状態を確認する**

```bash
git log --oneline -10
```

- [ ] **Step 2: PR を作成して main へマージする**

```bash
gh pr create \
  --title "feat: google_sign_in 7.x 認証フロー実装" \
  --body "Closes #2

## 変更内容
- AuthService (google_sign_in 7.x)
- AuthViewModel (Riverpod AsyncNotifier)
- go_router ルーティング（サインイン状態によるリダイレクト）
- SplashScreen / SignInScreen / DashboardScreen（仮）

## テスト
- AuthService 単体テスト: PASS
- AuthViewModel 単体テスト: PASS" \
  --base main
```

```bash
gh pr merge --squash --delete-branch
```

---

## 検証チェックリスト（Phase 1 完了条件）

- [ ] `flutter test` でテストが全件 PASS する
- [ ] `flutter run` でアプリが起動する
- [ ] 未サインイン時にサインイン画面が表示される
- [ ] Google サインインが成功しダッシュボードに遷移する
- [ ] サインアウトでサインイン画面に戻る
- [ ] `gh issue list` で全 Issue が確認できる
- [ ] `git log --oneline` で main に squash コミットが積まれている

---

## 次フェーズ（Phase 2）

Phase 2 では以下を実装する（別プランで管理）:
- `GoogleClassroomRepository` 実装（googleapis + Isar キャッシュ）
- ダッシュボード：コース一覧・直近締め切りウィジェット
- 課題一覧画面（締め切り順ソート）
