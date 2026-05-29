# ページドキュメント一覧

このディレクトリには Classroom Remaked の各画面（ページ）の詳細ドキュメントが含まれています。

## 画面一覧

| ファイル | 画面名 | ルート | 説明 |
|---------|-------|--------|------|
| [01-splash.md](01-splash.md) | SplashScreen | `/splash` | アプリ起動中のローディング画面 |
| [02-sign-in.md](02-sign-in.md) | SignInScreen | `/sign-in` | Google サインイン画面 |
| [03-notification-setup.md](03-notification-setup.md) | NotificationSetupScreen | `/notification-setup` | 初回オンボーディング・通知設定 |
| [04-dashboard.md](04-dashboard.md) | DashboardScreen | `/dashboard` | ホーム画面（締め切り + コース一覧） |
| [05-course-detail.md](05-course-detail.md) | CourseDetailScreen | `/dashboard/courses/:courseId` | コース詳細（課題・お知らせ・提出状況） |
| [06-assignments.md](06-assignments.md) | AssignmentsScreen | `/assignments` | 全課題一覧（フィルタ・非表示対応） |
| [07-assignment-detail.md](07-assignment-detail.md) | AssignmentDetailScreen | `/assignments/:assignmentId` | 課題詳細・提出・取り消し |
| [08-search.md](08-search.md) | SearchScreen | `/search` | 課題名ローカル検索 |
| [09-settings.md](09-settings.md) | SettingsScreen | `/settings` | 通知・スヌーズ・怠惰人間モード設定 |
| [10-debug.md](10-debug.md) | DebugScreen | `/settings/debug` | 開発者向けデバッグ画面（隠し） |
| [11-file-viewer.md](11-file-viewer.md) | FileViewerScreen | `/viewer/:fileId` | Google Drive PDF インラインビューアー |

## ナビゲーション構造

```
/splash
  ↓ (認証状態解決)
/sign-in ────────────────────────── 未認証
  ↓ (サインイン成功)
/notification-setup ─────────────── オンボーディング未完了
  ↓ (完了 / スキップ)

StatefulShellRoute（BottomNavigationBar）
├── /dashboard
│     └── /dashboard/courses/:courseId
│           └── (push) /viewer/:fileId
├── /assignments
│     └── /assignments/:assignmentId
│           └── (push) /viewer/:fileId
├── /search
└── /settings
      └── /settings/debug

(push) /viewer/:fileId  ← assignments / course-detail から
```

## ドキュメントの読み方

各ページドキュメントには以下が含まれます：
- **ルートパス** と **パスパラメータ**
- **ソースファイルパス**
- **UI 構成の概略図**
- **インタラクション一覧**（タップ・スワイプ・ダイアログ）
- **状態管理**（使用する ViewModel / Provider）
- **遷移元 / 遷移先マップ**
- **依存パッケージ**
