# NotificationSetupScreen

## 概要

初回サインイン後のオンボーディング画面。通知の許可とタイミング・怠惰人間モードを初期設定する。

## ルート

```
/notification-setup
```

## ソースファイル

`lib/presentation/views/notification_setup/notification_setup_screen.dart`

## 表示条件

認証済みかつ `userPreferences.onboardingDone == false` のとき、Router の `redirect` がこの画面に誘導する。

## UI

```
┌─────────────────────────────────────┐
│                                     │
│  通知を設定しましょう                │
│                                     │
│  締め切りの [24] 時間前に通知        │
│                                     │
│  怠惰人間モード    ────  [Toggle]   │
│  ONのときスヌーズは1時間固定         │
│                                     │
│              ···                    │
│                                     │
│  [   通知を許可して開始する   ]      │
│  [        後でスキップ        ]      │
│                                     │
└─────────────────────────────────────┘
```

| 要素 | 説明 |
|------|------|
| タイトル | "通知を設定しましょう" |
| 時間入力 | `ShadInput`（数値のみ、デフォルト 24）— 通知タイミング（時間数） |
| 怠惰人間モード | `ShadSwitch` — ONにすると確認ダイアログを表示 |
| 開始ボタン | `ShadButton` — 通知許可を求めてオンボーディング完了 |
| スキップボタン | `ShadButton.ghost` — 通知許可なしでオンボーディング完了 |

## 怠惰人間モード確認ダイアログ

ONに切り替えると `ShadDialog.alert` が表示される。

- **内容**：スヌーズ1時間固定になること、OFFにするための条件を説明
- **キャンセル**：トグルを元に戻す（`pop(false)`）
- **有効にする**：`settingsViewModelProvider.notifier.enableLazyMode()` を実行

OFFへの切り替えはこの画面では課題リストが存在しないため `tryDisableLazyMode([])` を渡す（常に成功）。

## 完了処理（`_complete`）

```
1. hours 入力値をパース（最小 24 時間に補正）
2. notifier.setNotifyBeforeHours(hours)
3. requestPermission == true なら NotificationService.requestPermission()
4. notifier.completeOnboarding()
5. context.go('/dashboard')
```

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移元 | `/sign-in` 成功後 | オンボーディング未完了 |
| 遷移先 | `/dashboard` | 完了またはスキップ |

## 依存

- `settingsViewModelProvider` — 設定保存・怠惰人間モード制御
- `NotificationService` — OS通知許可リクエスト
- `shadcn_ui` — `ShadInput`、`ShadSwitch`、`ShadButton`、`ShadDialog`
