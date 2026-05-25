# classroom_remaked

Google Classroom の公式アプリの使いづらさを補完する Flutter 製モバイルアプリ。締め切り管理・バックグラウンド通知・教師向け提出状況確認などを提供する。

## 主な機能

- **課題一覧・詳細** — 締め切り順ソート、提出状況の表示、課題へのファイル提出
- **締め切りウィジェット** — ダッシュボードに今日〜近日の締め切りを表示
- **コース詳細** — 課題・お知らせ・資料を一覧表示。教師ロールでは提出状況タブを追加表示（提出数/受講生数）
- **バックグラウンド通知** — WorkManager による定期同期で新着課題・締め切りをローカル通知
- **ホーム画面ウィジェット** — Android/iOS 対応。締め切りが近い課題を表示
- **怠惰人間モード** — 未提出課題が一定数以下になるまで他機能をロック
- **非表示・並び替え** — コースを非表示にしたりドラッグで並び替え
- **コース役割表示** — コースごとに教師/生徒バッジを表示。教師コースは通知対象外
- **PDF / Drive ファイルビューアー** — アプリ内で PDF を表示、Drive ファイルを開く
- **デバッグ画面** — DB テーブル内容・通知ログ・エラーログ・同期時刻を確認（アプリ名を7回タップで表示）

## 技術スタック

| カテゴリ | ライブラリ |
|---|---|
| フレームワーク | Flutter / Dart |
| 状態管理 | Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| ナビゲーション | go_router |
| UI コンポーネント | shadcn_ui, skeletonizer |
| ローカル DB | Drift (SQLite) |
| 認証 | Google Sign-In, Firebase Auth |
| API | Google Classroom API, Google Drive API (`googleapis`) |
| 通知 | flutter_local_notifications, WorkManager, Firebase Messaging |
| ホームウィジェット | home_widget |
| ファイル表示 | pdfx, open_file |
| イミュータブルモデル | freezed |
| 関数型エラー処理 | dartz |
| テスト | flutter_test, mocktail |

## アーキテクチャ

```
lib/
├── core/
│   ├── di/           # Riverpod プロバイダー定義
│   ├── router/       # go_router 設定
│   └── services/     # AuthService / NotificationService / SyncService 等
├── data/
│   ├── datasources/local/  # Drift DB・各テーブルのデータソース
│   └── repositories/       # Google Classroom API との通信・キャッシュ
├── domain/
│   └── entities/     # freezed イミュータブルエンティティ
└── presentation/
    ├── viewmodels/   # Riverpod AsyncNotifier / FutureProvider
    └── views/        # 各画面・ウィジェット
```

Repository がローカル DB への読み書きと API 呼び出しを担い、ViewModel が UI へのデータ変換を担う。依存の方向は Domain → Data → Presentation の一方向。

## セットアップ

### 前提条件

- Flutter SDK（`pubspec.yaml` の `environment.sdk` 参照）
- Google Cloud プロジェクト（Classroom API・Drive API 有効化済み）
- Firebase プロジェクト（Authentication・Cloud Messaging）

### 手順

```bash
# 依存パッケージのインストール
flutter pub get

# コード生成（freezed / Riverpod / Drift）
dart run build_runner build --delete-conflicting-outputs

# 実行
flutter run
```

### Firebase 設定

`google-services.json`（Android）と `GoogleService-Info.plist`（iOS）をそれぞれ配置する。`.gitignore` で除外されているため、Firebase コンソールからダウンロードして配置する。

### Google OAuth 設定

`lib/core/services/auth_service.dart` の `serverClientId` と iOS の `Info.plist` 内 `GIDClientID` を自分のプロジェクトのものに書き換える。

## バックグラウンド同期

WorkManager で 1 時間ごとにバックグラウンド同期を実行する。

- 新着課題を検出してローカル通知を送信（重複通知はID永続化で防止）
- 締め切りが近い未提出課題を通知（教師ロールのコース・提出済みは除外）
- ホーム画面ウィジェットのデータを更新

**iOS の注意**: BGTaskScheduler の制約により、ユーザーが最低1回アプリを起動しないとバックグラウンドタスクが登録されない。実行頻度は OS が制御するため 1 時間ごとの実行は保証されない。

## DB スキーマ

Drift で管理。現在のスキーマバージョンは **v7**。マイグレーションは `lib/data/datasources/local/app_database.dart` で定義。

主なテーブル:

| テーブル | 内容 |
|---|---|
| `courses` | コース一覧・役割（teacher/student） |
| `assignments` | 課題・提出状況 |
| `announcements` | お知らせ・資料 |
| `notification_logs` | 締め切り通知済み課題 ID |
| `snoozed_items` | スヌーズ中の課題 |
| `hidden_items` | 非表示コース |
| `course_order` | コース並び順 |
| `sync_states` | 最終同期時刻 |
| `user_preferences` | 各種設定・通知済み新着課題 ID |
