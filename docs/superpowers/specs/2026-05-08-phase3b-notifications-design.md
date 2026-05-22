# Phase 3b: 通知機能 設計ドキュメント

## 概要

締め切り前通知・スヌーズ・怠惰人間モード・初回オンボーディング・設定画面を実装する。バックグラウンド実行は workmanager + flutter_local_notifications で行い、状態は drift DB に一元管理する。

---

## アーキテクチャ

```
[workmanager 1h periodic]
  → callbackDispatcher (top-level fn)
    → drift DB を直接開く (NativeDatabase)
    → UserPreferences から notifyBeforeHours / lazyModeEnabled 取得
    → Assignments から対象課題を絞り込む
      (dueDate in [now, now+notifyBefore] AND submissionState != turnedIn)
    → NotificationLogs・SnoozedItems で除外
    → flutter_local_notifications で発火
    → NotificationLogs に記録

[通知アクションタップ (background)]
  → onDidReceiveBackgroundNotificationResponse (top-level fn)
    → drift DB を開く
    → SnoozedItems.upsert(assignmentId, now + snoozeDuration)
```

---

## DBスキーマ追加（schemaVersion: 3）

```dart
// UserPreferences — KVストア (既存 SyncStates と同構造、用途分離のため別テーブル)
// key: String PK, value: String
// 使用キー:
//   'notifyBeforeHours' → デフォルト "24"
//   'lazyModeEnabled'   → デフォルト "false"
//   'notificationOnboardingDone' → デフォルト "false"

// NotificationLogs — 通知済み記録（重複防止）
// assignmentId: String PK
// notifiedAt: DateTime

// SnoozedItems — スヌーズ中の課題
// assignmentId: String PK
// snoozedUntil: DateTime
```

マイグレーション: `onUpgrade` で `from < 3` の場合に3テーブルを追加。

---

## 新規ファイルマップ

| ファイル | 役割 |
|---------|------|
| `lib/data/datasources/local/user_preferences_datasource.dart` | notifyBeforeHours / lazyMode / onboardingDone の読み書き |
| `lib/data/datasources/local/notification_logs_datasource.dart` | 通知済みID の記録・取得 |
| `lib/data/datasources/local/snoozed_items_datasource.dart` | スヌーズ状態の upsert・期限切れ削除 |
| `lib/core/services/notification_service.dart` | flutter_local_notifications ラッパー（初期化・チャネル設定・発火・パーミッション要求） |
| `lib/core/services/background_notification_task.dart` | workmanager callbackDispatcher (top-level)・通知発火ロジック |
| `lib/domain/usecases/can_disable_lazy_mode_usecase.dart` | notifyBefore以内の未提出課題数を返す |
| `lib/presentation/viewmodels/settings_viewmodel.dart` | 設定画面の状態管理 |
| `lib/presentation/views/notification_setup/notification_setup_screen.dart` | 初回オンボーディング画面 |
| `lib/presentation/views/settings/settings_screen.dart` | 設定画面 |

---

## 通知アクション仕様

### lazyModeEnabled == false
通知ボタン: **[確認]** **[30分]** **[1時間]** **[3時間]**

action IDs: `confirm`, `snooze_30min`, `snooze_1h`, `snooze_3h`

### lazyModeEnabled == true
通知ボタン: **[確認]** **[1時間]**

action IDs: `confirm`, `snooze_1h`

### スヌーズ処理
`onDidReceiveBackgroundNotificationResponse` (top-level):
- `snooze_30min` → `SnoozedItems.upsert(id, now + 30min)`
- `snooze_1h`    → `SnoozedItems.upsert(id, now + 1h)`
- `snooze_3h`    → `SnoozedItems.upsert(id, now + 3h)`

スヌーズ再通知は workmanager の次の1時間ティックで自然に発火（`snoozedUntil < now` になったら除外解除）。最大遅延 +1時間は許容範囲。

---

## 怠惰人間モード仕様

### ON にする際
`ShadDialog` で確認:
```
怠惰人間モードを有効にしますか？

・スヌーズが1時間固定になります
・OFFに戻すには、設定した通知タイミング以内に
  締め切りがある課題をすべて提出するまで
  無効にできません

[キャンセル]   [有効にする]
```

### OFF にする際
`CanDisableLazyModeUseCase` を実行:
- notifyBefore以内の締め切り + 未提出課題数 > 0 → OFFにできない
  → `ShadToast`: 「あとN件提出するとOFFにできます」
- 未提出課題数 == 0 → OFFに切り替え

`CanDisableLazyModeUseCase` は domain 層に置き、`AppDatabase` に直接依存せず `AssignmentsDataSource` と `UserPreferencesDataSource` を通じてデータを取得する。

---

## 初回オンボーディング画面（`/notification-setup`）

### ルーティング
go_router の redirect に追加:
```
サインイン済み + onboardingDone == false → /notification-setup
サインイン済み + onboardingDone == true  → ShellRoute へ
```

`/notification-setup` は ShellRoute の外側（BottomNav なし）。

### 画面レイアウト
```
┌─────────────────────────────┐
│ 通知を設定しましょう            │
│                             │
│ 締め切りの何時間前に通知しますか？ │
│ [  24  ] 時間前               │
│ (最低24時間・数値入力)          │
│                             │
│ 怠惰人間モード         [OFF]  │
│ ONのときスヌーズは1時間固定      │
│                             │
│  [通知を許可して開始する]        │
│  後でスキップ                  │
└─────────────────────────────┘
```

- 「通知を許可して開始する」→ `NotificationService.requestPermission()` → 設定保存 → `onboardingDone = true` → `/dashboard`
- 「後でスキップ」→ `onboardingDone = true` → `/dashboard`（通知は設定されるが権限は未取得）
- 怠惰人間モードを ON にしようとした場合、確認ダイアログを表示（設定画面と同じ動作）

---

## 設定画面（`/settings`）

### レイアウト
```
┌─────────────────────────────┐
│ 設定                         │
├─────────────────────────────┤
│ [通知未許可バナー（許可済みなら非表示）] │
├─────────────────────────────┤
│ 通知タイミング                 │
│ [  24  ] 時間前に通知          │
├─────────────────────────────┤
│ 怠惰人間モード          [ON]  │
│ ONのときスヌーズは1時間固定      │
└─────────────────────────────┘
```

- `ShadInput` (keyboardType: number) + フォーカスを外したタイミングで保存・バリデーション（< 24 なら `ShadToast` エラー）
- `ShadSwitch` でモード切替（ON時: 確認ダイアログ、OFF時: CanDisableLazyModeUseCase）
- 変更はリアルタイムで `UserPreferencesDataSource` に書き込み

---

## BottomNavigationBar 変更

既存の `ScaffoldWithNav` に設定タブを追加:
```dart
BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '設定')
```

`app_router.dart` の `StatefulShellRoute` に3番目のブランチ `/settings` を追加。

---

## テスト方針

| テスト対象 | 内容 |
|-----------|------|
| `UserPreferencesDataSource` | notifyBefore・lazyMode・onboardingDone の read/write |
| `NotificationLogsDataSource` | 通知ログ記録・取得 |
| `SnoozedItemsDataSource` | upsert・期限切れ除外 |
| `CanDisableLazyModeUseCase` | 未提出課題あり→false、なし→true |
| `SettingsViewModel` | 各設定の変更・lazyModeのOFF拒否ロジック |

`NotificationService`・`background_notification_task` は flutter_local_notifications / workmanager の実機依存が強いため、単体テスト対象外（integration_test で検証）。
