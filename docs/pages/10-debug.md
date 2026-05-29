# DebugScreen

## 概要

開発・デバッグ用の内部情報確認画面。本番ユーザーには隠されており、設定画面のバージョン表記を7回タップすることで表示される。

## ルート

```
/settings/debug
```

## ソースファイル

`lib/presentation/views/debug/debug_screen.dart`

## アクセス方法

`SettingsScreen` の "Classroom Remaked" テキストを2秒以内に7回タップする（詳細は [設定画面ドキュメント](09-settings.md) 参照）。

## UI セクション

`debugViewModelProvider` から `DebugState` を取得し、以下のセクションを `ListView` で表示。AppBarにリロードボタン（`Icons.refresh`）あり。

---

### 1. データベース（`_DbTable`）

`schema v{バージョン}` とともに全テーブルの行数を表示。

各行をタップすると `_TableDetailPage` に遷移（`MaterialPageRoute` でプッシュ）。

`_TableDetailPage` で閲覧可能なテーブル:

| テーブル名 | 表示カラム |
|-----------|-----------|
| `courses` | id, name, section, room, state |
| `assignments` | id, title, courseId, dueDate, state, submissionState, submissionId |
| `announcements` | id, courseId, title, body（80字）, isMaterial, createdAt |
| `notification_logs` | assignmentId, notifiedAt |
| `snoozed_items` | assignmentId, snoozedUntil |
| `hidden_items` | itemId, type, hiddenAt |

---

### 2. 同期（`_SyncSection`）

| 項目 | 説明 |
|------|------|
| 最終同期（FG） | フォアグラウンド同期の最終実行時刻 |
| 最終同期（BG） | バックグラウンド同期の最終実行時刻 |
| 強制リフレッシュ | `notifier.forceRefresh()` を実行 |

---

### 3. 怠惰人間モード（`_LazyModeSection`）

| 項目 | 説明 |
|------|------|
| モード | ON / OFF |
| 通知タイミング | 設定値（時間数） |
| OFFブロック中の課題 | 未提出で通知ウィンドウ内にある課題の件数 |

件数が 0 より大きいとき赤色表示 + タップで `_BlockingAssignmentsPage` へ遷移（タイムリミット内の未提出課題一覧）。

---

### 4. 権限（`_PermissionsSection`）

| 項目 | OK | NG |
|------|----|----|
| 通知 | ✓ 許可 | ✗ 未許可 |
| Exact alarm | ✓ 許可 | ✗ 未許可 |
| バッテリー最適化免除 | ✓ 許可 | ✗ 未許可 |

---

### 5. プッシュ通知（`_PushPollSection`）

`今すぐポーリング` ボタンで `notifier.pollNow(asTeacher: bool)` を手動実行。
「教師コースで実行」トグルで実行モードを切り替えられる。実行結果（成功 / エラー）をその場に表示。

---

### 6. 通知ログ（`_NotificationLogsSection`）

スケジュール済み通知の一覧。各ログに以下を表示：
- 課題タイトル + ID
- 登録日時
- 発火予定時刻 または 発火済みフラグ + 残り時間

**操作ボタン**:

| ボタン | 処理 |
|-------|------|
| ログをクリア | `notifier.clearNotificationLogs()` |
| 即時通知 | `notifier.sendTestNotification()` |
| 15秒後テスト | `notifier.sendTestScheduledNotification()`（発火予定時刻を表示） |
| 今すぐスケジュール | `notifier.runNotificationTaskNow()` |

---

### 7. エラーログ（`_ErrorLogsSection`）

`ErrorLogEntry` のリスト。各エントリはタップで展開され、スタックトレースを表示。

- ソース・メッセージ・タイムスタンプを表示
- "エラーログをクリア" ボタン（ログが存在するときのみ表示）

---

### 8. 危険ゾーン

`ShadButton.destructive` — "全データ削除"

確認ダイアログ後に `notifier.clearAllData()` を実行（DB 全テーブルをクリア、アプリ再起動が必要）。

---

## サブページ

### `_TableDetailPage`

特定テーブルの全行をカード形式（`_RowCard`）で表示。各カードにフィールド名・値をモノスペースフォントで表示。
AppBar にリロードボタンあり。

### `_BlockingAssignmentsPage`

怠惰人間モードのOFFをブロックしている課題（通知ウィンドウ内の未提出・期限内課題）を一覧表示。
AppBar タイトルに `notifyBeforeHours` を表示。

---

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移元 | `/settings` | 7回タップ |
| サブページ | `_TableDetailPage` | DBテーブル行タップ |
| サブページ | `_BlockingAssignmentsPage` | ブロック課題件数タップ |

## 依存

- `debugViewModelProvider` — デバッグ状態管理・操作
- `appDatabaseProvider` — DB直接アクセス（テーブル詳細表示用）
- `shadcn_ui` — `ShadCard`、`ShadButton`、`ShadSwitch`、`ShadDialog`
