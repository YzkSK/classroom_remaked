# DashboardScreen

## 概要

アプリのホーム画面。直近の締め切りとコース一覧を表示する。ボトムナビゲーションの最初のタブ。

## ルート

```
/dashboard
```

## ソースファイル

`lib/presentation/views/dashboard/dashboard_screen.dart`
`lib/presentation/views/dashboard/widgets/deadline_widget.dart`
`lib/presentation/views/dashboard/widgets/course_list.dart`

## UI 構成

```
┌───────────────────────────────┐
│  AppBar: "Classroom Remaked"  │
├───────────────────────────────┤
│  直近の締め切り（7日以内）     │  ← DeadlineWidget
│  ┌──────────────────────┐    │
│  │ 課題カード (tile)     │    │
│  │ 課題カード (tile)     │    │
│  └──────────────────────┘    │
│                               │
│  コース                        │  ← CourseList
│  [非表示も表示] ボタン          │
│  ┌──────────────────────┐    │
│  │ コースカード          │    │
│  │ コースカード          │    │
│  └──────────────────────┘    │
├───────────────────────────────┤
│  BottomNavigationBar          │
└───────────────────────────────┘
```

`RefreshIndicator` で画面を下に引くと `dashboardViewModelProvider.notifier.refresh()` が実行される。

---

## DeadlineWidget

`lib/presentation/views/dashboard/widgets/deadline_widget.dart`

**表示内容**：締め切りが7日以内の未提出課題。`dashboardViewModelProvider` の `upcomingDeadlines` を参照。

| 状態 | 表示 |
|------|------|
| ローディング | `Skeletonizer`（フェイクデータで骨格表示） |
| 締め切りあり | `AssignmentCard`（variant: tile）のリスト |
| 締め切りなし | "7日以内に締め切りの課題はありません" |

課題カードをタップすると `/assignments/:assignmentId` へ遷移。

---

## CourseList

`lib/presentation/views/dashboard/widgets/course_list.dart`

**表示内容**：`dashboardViewModelProvider` の `visibleCourses`（非表示フィルタ適用済み）。

### コースカード（`_CourseCard`）

| 要素 | 詳細 |
|------|------|
| コース名 | 1行省略（`TextOverflow.ellipsis`） |
| ロールバッジ | 教師: `ShadBadge`（primary色）/ 生徒: `ShadBadge.secondary` |
| セクション | muted テキストで表示 |
| ドラッグハンドル | `ReorderableDelayedDragStartListener` — 長押しで並び替え |
| メニューボタン | `Icons.more_vert` — ボトムシート表示 |

**タップ**：`/dashboard/courses/:courseId?name=コース名` へ遷移

**ロングプレス / メニューボタン**：ボトムシートを表示
- "コース詳細を開く" → `/dashboard/courses/:courseId`
- 非表示 / 非表示解除（`dashboardViewModelProvider.notifier.hideItem` / `unhideItem`）

**ドラッグ並び替え**：`ReorderableListView.builder` → `notifier.reorderCourses(oldIndex, newIndex)`

### 非表示トグル（`_HiddenToggleRow`）

コースリスト右上に表示される `ShadButton.ghost`。
- "非表示も表示" / "非表示を隠す" でトグル
- `dashboardViewModelProvider.notifier.toggleShowHidden()` を呼び出す
- 非表示コースは `opacity: 0.4` で薄く表示

---

## 状態管理

`dashboardViewModelProvider`（`AsyncNotifier`）

| 状態フィールド | 説明 |
|--------------|------|
| `visibleCourses` | 非表示フィルタ適用済みコース一覧 |
| `upcomingDeadlines` | 7日以内締め切りの未提出課題 |
| `showHidden` | 非表示コースを表示するかどうかのフラグ |
| `isHidden(id)` | 特定コースが非表示かどうかの判定 |

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移先 | `/dashboard/courses/:courseId` | コースカードタップ |
| 遷移先 | `/assignments/:assignmentId` | 締め切りウィジェットの課題タップ |

## 依存

- `dashboardViewModelProvider` — コース・締め切りデータ
- `skeletonizer` — スケルトンローディング UI
- `shadcn_ui` — カード・バッジ・ボタン
- `go_router` — 画面遷移
