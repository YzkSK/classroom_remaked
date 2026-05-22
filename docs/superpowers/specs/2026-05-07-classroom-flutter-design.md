# Classroom Remaked — Flutter App 設計書

**作成日:** 2026-05-07  
**対象:** iOS + Android  
**状態:** 承認済み

---

## Context

Google Classroom のモバイルアプリは以下の点で使いづらい：

- 課題の締め切りが見落としやすく、通知も不十分
- コース横断での教材・お知らせ検索ができない
- 課題一覧が締め切り順に整理されていない
- 提出状況の確認が多ステップ必要

本アプリはこれらを解決するモバイルクライアントを Flutter で構築する。  
将来的に Canvas・Moodle 等の他 LMS にも対応できるよう抽象化レイヤーを設ける。

---

## アーキテクチャ：Clean Architecture + MVVM

依存の方向: `presentation` → `domain` ← `data`

```
lib/
├── domain/                        # 外部依存ゼロ
│   ├── entities/
│   │   ├── course.dart
│   │   ├── assignment.dart
│   │   └── announcement.dart
│   ├── repositories/
│   │   ├── lms_repository.dart         # 抽象インターフェース
│   │   └── user_preferences_repository.dart
│   ├── usecases/
│   │   ├── get_courses.dart
│   │   ├── get_assignments.dart
│   │   ├── get_upcoming_deadlines.dart
│   │   ├── search_content.dart
│   │   ├── hide_item.dart
│   │   ├── reorder_courses.dart
│   │   └── snooze_notification.dart
│   └── errors/
│       └── failures.dart
│
├── data/
│   ├── models/                    # JSON ↔ Entity 変換
│   │   ├── course_model.dart
│   │   ├── assignment_model.dart
│   │   └── announcement_model.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── classroom_remote_datasource.dart
│   │   └── local/
│   │       ├── classroom_local_datasource.dart    # Isar キャッシュ
│   │       ├── hidden_items_datasource.dart       # 非表示リスト
│   │       └── user_preferences_datasource.dart   # 通知設定・怠惰人間モード
│   └── repositories/
│       ├── google_classroom_repository.dart       # LmsRepository 実装
│       └── user_preferences_repository_impl.dart
│
├── presentation/
│   ├── viewmodels/
│   │   ├── auth_viewmodel.dart
│   │   ├── courses_viewmodel.dart
│   │   ├── assignments_viewmodel.dart
│   │   ├── search_viewmodel.dart
│   │   └── settings_viewmodel.dart
│   └── views/
│       ├── splash/
│       ├── auth/
│       ├── dashboard/
│       ├── assignments/
│       ├── search/
│       ├── settings/              # 通知設定・怠惰人間モード
│       └── shared/
│
└── core/
    ├── di/                        # Riverpod DI 設定
    ├── router/                    # go_router
    ├── errors/
    └── services/
        ├── auth_service.dart
        └── notification_service.dart
```

---

## LmsRepository インターフェース

```dart
abstract class LmsRepository {
  Future<Either<Failure, List<Course>>> getCourses();
  Future<Either<Failure, List<Assignment>>> getAssignments(String courseId);
  Future<Either<Failure, List<Announcement>>> getAnnouncements(String courseId);
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({int withinDays = 7});
  Future<Either<Failure, List<SearchResult>>> search(String query);
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  );
  Future<Either<Failure, List<Comment>>> getComments(
    String courseId,
    String itemId, {
    required CommentVisibility? filterBy, // null = 全件
  });
}
```

---

## パッケージ構成

```yaml
dependencies:
  # 認証
  google_sign_in: ^7.0.0

  # Google Classroom API
  googleapis: ^13.0.0
  http: ^1.2.0

  # UI（shadcn/ui Flutter 移植版）
  shadcn_ui: ^0.54.0

  # ローディングスケルトン
  skeletonizer: ^2.1.3           # 既存ウィジェットを wrap するだけで自動 skeleton 化

  # 状態管理
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0

  # ナビゲーション
  go_router: ^14.0.0

  # ローカルキャッシュ・設定
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0

  # 通知
  flutter_local_notifications: ^18.0.0
  workmanager: ^0.5.2

  # ユーティリティ
  freezed_annotation: ^2.4.0
  dartz: ^0.10.1
  intl: ^0.19.0
  envied: ^0.5.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  isar_generator: ^3.1.0
  mocktail: ^1.0.0
  riverpod_test: ^2.0.0
```

### shadcn_ui 使用コンポーネント一覧

| コンポーネント | 使用箇所 |
|--------------|---------|
| `ShadButton` | サインインボタン・アクションボタン |
| `ShadCard` | コースカード・課題カード |
| `ShadBadge` | 締め切りラベル・提出状況バッジ |
| `ShadAvatar` | ユーザーアイコン |
| `ShadTabs` | CourseDetailScreen（課題/お知らせ切り替え） |
| `ShadInput` | 検索フィールド |
| `ShadSelect` | 課題フィルター・スヌーズ時間選択 |
| `ShadSheet` | 課題詳細ボトムシート |
| `ShadSonner` | API エラー・通知許可トースト |
| `ShadSeparator` | リスト区切り |
| `ShadProgress` | 課題完了率インジケーター |
| `ShadSwitch` | 怠惰人間モード ON/OFF |
| `ShadContextMenu` | 長押しメニュー（非表示・スヌーズ） |

> **スケルトン:** `Skeletonizer(enabled: isLoading, child: ...)` で wrap するだけ。  
> shadcn_ui の `ShadCard` / `ShadBadge` も shimmer 対象になる。

---

## google_sign_in 7.x 認証設計

### 重要な API 変更点（6.x との差分）

| 6.x | 7.x |
|-----|-----|
| `GoogleSignIn(scopes: [...])` コンストラクタ | `GoogleSignIn.instance` シングルトン |
| `signIn()` | `authenticate(scopeHint: scopes)` |
| `signInSilently()` | `attemptLightweightAuthentication()` |
| `account.authentication.accessToken` | `account.authorizationClient.authorizationForScopes(scopes).accessToken` |
| コンストラクタでスコープ指定 | `authorizationForScopes()` 呼び出し時に指定 |
| `account.authHeaders` でヘッダー取得 | `authorizationClient.authorizationHeaders` |

### AuthService

```dart
// core/services/auth_service.dart
class AuthService {
  static const _scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.rosters.readonly', // プライベートコメント取得用
  ];

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(clientId: Env.googleClientId);
    GoogleSignIn.instance.authenticationEvents.listen(_handleAuthEvent);
    await GoogleSignIn.instance.attemptLightweightAuthentication();
  }

  Future<GoogleSignInAccount> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthFailure('platform_not_supported');
    }
    return GoogleSignIn.instance.authenticate(scopeHint: _scopes);
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();
}
```

### googleapis 用 HTTP クライアント

```dart
// data/datasources/remote/classroom_http_client.dart
class ClassroomHttpClient extends http.BaseClient {
  ClassroomHttpClient(this._authClient);

  final GoogleSignInAuthorizationClient _authClient;
  final _inner = http.Client();
  static const _scopes = AuthService._scopes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final auth = await _authClient.authorizationForScopes(_scopes)
                 ?? await _authClient.authorizeScopes(_scopes);
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

---

## 画面構成

```
SplashScreen
  └─ attemptLightweightAuthentication() → 成功: Dashboard / 失敗: SignIn

SignInScreen
  └─ authenticate() → Dashboard

MainShell（BottomNavigationBar）
  ├─ DashboardScreen     # コース一覧（非表示済みを除外） + 直近締め切り
  ├─ AssignmentsScreen   # 締め切り順ソート・未提出フィルター・非表示済みを除外
  └─ SearchScreen        # コース横断全文検索

DashboardScreen
  └─ CourseDetailScreen
       ├─ [課題タブ] AssignmentDetailScreen（読み取り・提出状況表示）
       └─ [お知らせタブ]

SettingsScreen（設定アイコンから遷移）
  ├─ 通知設定（通知タイミング・スヌーズ間隔）
  ├─ 怠惰人間モード ON/OFF
  └─ サインアウト
```

---

## コースの並び替え機能

ダッシュボードのコース一覧は長押しでドラッグ＆ドロップによる並び替えが可能。  
Flutter 標準の `ReorderableListView` を使用（追加パッケージ不要）。

```dart
// domain/entities/course_order.dart
@Collection()
class CourseOrderEntity {
  Id id = Isar.autoIncrement;
  late String courseId;
  late int sortIndex;
}
```

- カスタム順序は `CourseOrderEntity` として Isar に保存
- API から新しいコースが追加された場合は末尾に追加
- 並び替えモードへの切り替えは右上の「並び替え」ボタン or 長押しで開始

---

## コース・課題の非表示機能

長押し（`ShadContextMenu`）→「非表示にする」で Isar の `HiddenItemEntity` に保存。  
非表示にしたアイテムはダッシュボード・課題一覧・検索結果から除外される。

```dart
// domain/entities/hidden_item.dart
@Collection()
class HiddenItemEntity {
  Id id = Isar.autoIncrement;
  late String itemId;        // courseId または assignmentId
  late String type;          // 'course' | 'assignment'
  late DateTime hiddenAt;
}
```

- 非表示アイテムはキャッシュには残す（API 無駄打ち防止）
- 非表示リスト管理UIは実装しない（フィルターで非表示にできるだけ）

---

## 通知システム（強化版）

### ユーザー設定

```dart
// domain/entities/notification_settings.dart
class NotificationSettings {
  final Duration notifyBefore;   // 締め切り何時間前に通知（最小: 24h・任意値・デフォルト: 24h）
  final int snoozeHours;         // 再通知間隔（時間単位・設定画面で自由入力・デフォルト: 1h）
  final bool lazyModeEnabled;    // 怠惰人間モード（ONのとき snoozeHours は 1h 固定）
}
```

設定可能な通知タイミング: **締め切り24時間前以上**・任意の値を入力可能（時間単位で自由入力）  
例: 24h / 36h / 48h / 72h / ... — 下限は24時間でバリデーション

### 通知フロー

```
workmanager 定期タスク（バックグラウンド）
  ↓
GetUpcomingDeadlinesUseCase.execute(within: notifyBefore)
  ↓
Isar で「通知済み・スヌーズ中」を除外
  ↓
flutter_local_notifications で通知発火
  ↓
Isar に snoozeHours 後まで再通知抑制を記録
```

### スヌーズ機能

- 通知バーにスヌーズボタンは置かない
- 通知を表示した直後、設定画面で指定した `snoozeHours` 後まで再通知を自動抑制
- 怠惰人間モード ON 時は `snoozeHours` を 1h に固定
- 抑制状態は `SnoozedNotificationEntity` として Isar に保存

```dart
@Collection()
class SnoozedNotificationEntity {
  Id id = Isar.autoIncrement;
  late String assignmentId;
  late DateTime snoozedUntil;
}
```

---

## 怠惰人間モード

**コンセプト:** スヌーズを無効化するには、設定した通知タイミング以内に締め切りがある  
未提出の課題をすべて提出するまでスヌーズボタンが使えない。

### ロジック

```
怠惰人間モード OFF（通常）
  → スヌーズボタン: 常に押せる

怠惰人間モード ON
  → スヌーズ可能か判定:
       提出期限が notifyBefore 以内の未提出課題数 == 0
         → スヌーズ可（全部出したご褒美）
       提出期限が notifyBefore 以内の未提出課題数 > 0
         → スヌーズ不可（課題が残っているため）
         → 通知に「あと N 件提出するとスヌーズできます」を表示
```

### 実装ポイント

- `CanDisableLazyModeUseCase` が怠惰モード解除条件を判定
- 通知バーにスヌーズボタンは表示しない（スヌーズは自動）
- 設定画面の ON/OFF スイッチは `ShadSwitch` を使用
- 怠惰モード ON 時は設定画面のスヌーズ間隔入力を無効化（1h 固定表示）
- モードを有効にするときに確認ダイアログを表示（`ShadDialog`）

---

## コメントの宛先識別

Google Classroom のコメントには2種類ある：
- **クラスコメント** — 課題・お知らせに紐づく、クラス全員に見える
- **プライベートコメント** — 教師 ↔ 特定生徒間のみ（課題に紐づく）

### エンティティ

```dart
enum CommentVisibility { classWide, private }

class Comment {
  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final CommentVisibility visibility;
}
```

### UI での識別

`ShadBadge` で視覚的に明示し、一覧で即座に判別できるようにする：

| 種別 | バッジ | アイコン | 色 |
|------|--------|---------|---|
| クラス全体 | `クラス` | `Icons.group` | muted（グレー） |
| あなたへ | `あなたへ` | `Icons.person` | primary（アクセントカラー） |

- コース詳細・課題詳細のコメントリストで各コメントカードに常に表示
- 「あなたへ」のプライベートコメントは上部にピン留め表示
- ダッシュボードの通知バッジにも未読プライベートコメント数を別表示

---

## エラーハンドリング

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure { const NetworkFailure(super.message); }
class AuthFailure extends Failure    { const AuthFailure(super.message); }
class ApiFailure extends Failure     { const ApiFailure(super.message); }
class CacheFailure extends Failure   { const CacheFailure(super.message); }
```

- Repository は `Either<Failure, T>` を返す
- ViewModel は `AsyncError` として Riverpod に渡す
- View は `AsyncValue.when(error: ...)` で統一表示

---

## テスト方針

| 層 | 対象 | ツール |
|----|------|-------|
| domain | UseCase（`CanSnoozeUseCase` 含む）| `flutter_test` + mock |
| data | Model 変換・Repository | `mocktail` |
| presentation | ViewModel の状態変化 | `riverpod_test` |
| E2E | サインイン → 課題一覧 → 通知設定 → 怠惰人間モード | `integration_test` |

---

## 実装スコープ（フェーズ分け）

| フェーズ | 内容 |
|---------|------|
| 1 | プロジェクト初期化・Clean Architecture 骨格・google_sign_in 7.x 認証 |
| 2 | GoogleClassroomRepository 実装・ダッシュボード・課題一覧・非表示機能 |
| 3 | 通知強化（ユーザー設定タイミング・スヌーズ・怠惰人間モード） |
| 4 | 検索・設定画面 |
| 5 | テスト（unit / widget / E2E） |

---

## Git 運用ルール

### ブランチ戦略：ページ集約型 GitHub Flow

```
main
├── page/dashboard          # ダッシュボードページブランチ
│   ├── feature/12-course-list-ui
│   ├── feature/13-deadline-widget
│   └── feature/14-course-reorder
├── page/assignments        # 課題一覧ページブランチ
│   ├── feature/21-assignment-sort
│   └── feature/22-hide-assignment
├── page/search             # 検索ページブランチ
│   └── feature/31-cross-course-search
├── page/notifications      # 通知・設定ブランチ
│   ├── feature/41-notify-timing-setting
│   ├── feature/42-snooze
│   └── feature/43-lazy-mode
└── page/auth               # 認証ブランチ
    └── feature/51-google-signin-7x
```

**フロー:**
1. ページブランチ（`page/*`）を main から作成
2. 機能ブランチ（`feature/*`）をページブランチから作成
3. 機能完成 → 機能ブランチを **ページブランチへ** Squash merge
4. ページ内の機能がすべて揃ったら → ページブランチを **main へ** Squash merge

- `main` への直接 push 禁止
- ブランチはマージ後も削除しない（履歴参照のため残す）

### ブランチ命名規則

```
page/dashboard
page/assignments
feature/12-course-list-ui
fix/34-notification-snooze-bug
chore/56-update-dependencies
```

形式:
- ページブランチ: `page/ページ名`
- 機能ブランチ: `種別/Issue番号-kebab-case-説明`

### コミットメッセージ：Conventional Commits

```
feat: Google Sign-In 7.x 認証フロー実装
fix: スヌーズ通知が重複する不具合を修正
chore: pubspec.yml パッケージバージョン更新
refactor: LmsRepository インターフェースを domain 層に移動
test: CoursesViewModel の状態変化テストを追加
docs: 設計書に git 運用ルールを追記
```

形式: `種別: 日本語で何をしたか（動詞で終わる）`

対応する種別:

| 種別 | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `chore` | ビルド・設定・依存関係 |
| `refactor` | 機能変更を伴わない構造改善 |
| `test` | テスト追加・修正 |
| `docs` | ドキュメントのみ |
| `style` | フォーマット・lint |

### PR・マージルール

- マージ方法: **Squash merge**（main の履歴を綺麗に保つ）
- PR タイトルは Conventional Commits 形式に合わせる
- セルフレビューで diff を確認してからマージ

---

## 将来の拡張ポイント

- `LmsRepository` の新実装を追加するだけで Canvas / Moodle 対応可能
- 課題提出機能は `LmsRepository.submitAssignment()` を追加する形で拡張
