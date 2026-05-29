# SettingsScreen

## 概要

通知タイミング・スヌーズ間隔・怠惰人間モードを設定し、サインアウトを行う画面。
ボトムナビゲーションの4番目のタブ。

## ルート

```
/settings
```

## ソースファイル

`lib/presentation/views/settings/settings_screen.dart`

## UI 構成

```
┌──────────────────────────────────────┐
│  AppBar: "設定"                       │
├──────────────────────────────────────┤
│  [警告] 通知が許可されていません        │  ← 条件付き
│  [警告] 正確な通知タイミングが未許可   │  ← Android のみ・条件付き
│  [警告] バッテリー最適化が有効         │  ← Android のみ・条件付き
│                                       │
│  通知タイミング                        │
│  締め切りの X 時間前                   │
│  ├──────●──────┤  (24h ～ 168h)      │
│                                       │
│  スヌーズ間隔                          │
│  X 時間後に再通知                      │
│  ├──●──────────┤  (1h ～ 12h)        │
│                                       │
│  怠惰人間モード           [Toggle]    │
│  ONのときスヌーズは1時間固定           │
│  OFFにするには期限内の課題をすべて提出   │
│                                       │
│  ────────────────────────────────── │
│  [          サインアウト          ]    │
│                                       │
│         Classroom Remaked            │  ← バージョン表示 (デバッグタップ)
└──────────────────────────────────────┘
```

---

## 権限警告カード

`WidgetsBindingObserver` でアプリがフォアグラウンドに戻るたびに権限状態を再チェックする。

| カード | 表示条件 | ボタン |
|--------|---------|-------|
| 通知未許可 | `!_permissionGranted` | "許可する" → `NotificationService.requestPermission()` |
| Exact alarm 未許可 | Android かつ `!_exactAlarmsGranted` | "許可する" → `NotificationService.requestExactAlarmsPermission()` |
| バッテリー最適化有効 | Android かつ `_batteryOptimized` | "解除" → `MethodChannel('com.classroomremaked/battery')` → `requestIgnoreBatteryOptimizations` |

---

## 通知タイミング スライダー

- 範囲：24 ～ 168（`divisions: 6`、24h 刻み）
- ドラッグ中は `_notifyHoursDraft` に一時保存してラベルに反映
- `onChangeEnd` で `notifier.setNotifyBeforeHours(h)` を呼び出して永続化

---

## スヌーズ間隔 スライダー

- 範囲：1 ～ 12（`divisions: 11`、1h 刻み）
- **怠惰人間モード ON のとき無効化**（スライダーが操作不可になる）
- `onChangeEnd` で `notifier.setSnoozeHours(h)` を呼び出して永続化

---

## 怠惰人間モード（`ShadSwitch`）

### ON にするとき
1. `ShadDialog.alert` で確認
   - "スヌーズが1時間固定になります"
   - "OFFに戻すには、設定した通知タイミング以内に締め切りがある課題をすべて提出するまで無効にできません"
2. 確認後：`notifier.enableLazyMode()`

### OFF にするとき
1. `assignmentsViewModelProvider` から現在の全課題を取得
2. `notifier.tryDisableLazyMode(assignments)` を呼び出す
3. 無効化できない場合：`ShadToast` で "あと N 件提出するとOFFにできます" を表示
   - N は `CanDisableLazyModeUseCase.countBlockingAssignments()` で算出

---

## サインアウト

`ShadButton.outline` — タップで `authViewModelProvider.notifier.signOut()` を呼び出す。
処理中はローディングインジケータ表示でボタン無効化。

---

## デバッグモードへの隠しアクセス

画面最下部の "Classroom Remaked" テキスト（フェード表示）をタップするごとにカウントが増加。

| タップ数 | 動作 |
|---------|------|
| 4 回目以降 | "あとN回でデバッグモード" トースト表示 |
| 7 回 | `/settings/debug` へ遷移 |
| 2秒間タップなし | カウントリセット |

---

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移先 | `/settings/debug` | バージョンを7回タップ |
| 遷移先 | `/sign-in` | サインアウト成功（Router redirect で制御） |

## 依存

- `settingsViewModelProvider` — 設定値の読み書き・怠惰人間モード制御
- `authViewModelProvider` — サインアウト
- `assignmentsViewModelProvider` — 怠惰モード解除判定用の課題リスト
- `NotificationService` — 通知許可チェック・リクエスト
- `CanDisableLazyModeUseCase` — 怠惰モード解除可否算出
- `MethodChannel('com.classroomremaked/battery')` — Android バッテリー最適化制御
- `WidgetsBindingObserver` — アプリ復帰時の権限再チェック
- `shadcn_ui` — `ShadCard`、`ShadSwitch`、`ShadButton`、`ShadDialog`、`ShadToaster`
