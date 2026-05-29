# AssignmentsScreen

## 概要

全コースの課題を一覧表示する画面。フィルタ・非表示・スワイプ操作が可能。ボトムナビゲーションの2番目のタブ。

## ルート

```
/assignments
```

## ソースファイル

`lib/presentation/views/assignments/assignments_screen.dart`

## UI 構成

```
┌──────────────────────────────────┐
│  AppBar: "課題"                   │
├──────────────────────────────────┤
│  [すべて] [未提出] [期限切れ]      │  ← FilterBar
├──────────────────────────────────┤
│  課題カード（full variant）        │
│  課題カード（full variant）        │
│  ...                              │
└──────────────────────────────────┘
```

---

## フィルタバー（`_FilterBar`）

`AssignmentsFilter` の各値に対応する `FilterChip` を横並びで表示。

| フィルタ | ラベル | 対象 |
|---------|-------|------|
| `all` | すべて | 全課題 |
| `unsubmitted` | 未提出 | 未提出の課題のみ |
| `overdue` | 期限切れ | 締め切りを過ぎた未提出課題 |

選択中のチップは `selectedColor: primaryContainer`、非選択は `outline` ボーダー。
チップタップで `assignmentsViewModelProvider.notifier.setFilter(f)` を呼び出す。

---

## 課題カード（`_AssignmentCard`）

`AssignmentCard`（variant: full）をラップしたウィジェット。

### スワイプ操作（`Dismissible`）

| 方向 | 閾値 | アクション |
|------|------|-----------|
| 左→右（`startToEnd`） | 25% | 非表示解除（`isHidden == true` のときのみ有効） |
| 右→左（`endToStart`） | 25% | 非表示化（`isHidden == false` のときのみ有効） |

スワイプしてもカードは実際には消えない（`confirmDismiss` が `false` を返す）。

**非表示時のトースト**：
- 非表示化 → "課題を非表示にしました" + "元に戻す" アクションボタン
- 非表示解除 → "非表示を解除しました"

### ロングプレス

ボトムシートを表示：
- 非表示の場合："非表示を解除"
- 表示中の場合："非表示にする"

### 表示状態

- `isHidden == true` のとき `opacity: 0.4`
- `isHidden == false` のとき `opacity: 1.0`

### タップ

`context.go('/assignments/:assignmentId')` でそのまま詳細へ遷移。

---

## 空状態（`_EmptyState`）

フィルタ結果が0件のときに表示。フィルタに応じてアイコンとメッセージが変わる。

| フィルタ | アイコン | メッセージ |
|---------|---------|----------|
| `unsubmitted` | `Icons.check_circle_outline_rounded` | "すべて提出済みです" |
| `overdue` | `Icons.celebration_rounded` | "期限切れの課題はありません" |
| `all` | `Icons.assignment_outlined` | "課題はありません" |

---

## エラー状態

`async.hasError` の場合:
- `Icons.sync_problem_outlined` アイコン
- "同期に失敗しました" テキスト
- "再試行" ボタン（`notifier.refresh()` を呼び出す）

---

## プルリフレッシュ

`RefreshIndicator` — 下に引くと `assignmentsViewModelProvider.notifier.refresh()` を実行。

ローディング中は `Skeletonizer` でフェイクカードを表示。

---

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移先 | `/assignments/:assignmentId` | 課題カードタップ |

## 依存

- `assignmentsViewModelProvider` — 課題データ・フィルタ・非表示管理
- `skeletonizer` — スケルトンローディング
- `shadcn_ui` — `ShadToaster`
- `go_router` — 画面遷移
