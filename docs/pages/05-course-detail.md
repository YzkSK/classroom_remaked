# CourseDetailScreen

## 概要

コースの詳細を表示する画面。ユーザーのロール（教師 / 生徒）によってタブ構成が変わる。

## ルート

```
/dashboard/courses/:courseId?name=コース名
```

パスパラメータ `courseId` と、クエリパラメータ `name`（AppBar のタイトルに使用）を受け取る。

## ソースファイル

`lib/presentation/views/dashboard/course_detail_screen.dart`

## UI 構成

### 生徒の場合（2タブ）

```
┌──────────────────────────────────┐
│  AppBar: コース名                 │
│  [   課題   ] [  お知らせ  ]      │
├──────────────────────────────────┤
│  タブコンテンツ                   │
└──────────────────────────────────┘
```

### 教師の場合（3タブ）

```
┌──────────────────────────────────┐
│  AppBar: コース名                 │
│  [ 課題 ] [ お知らせ ] [ 提出状況 ] │
├──────────────────────────────────┤
│  タブコンテンツ                   │
└──────────────────────────────────┘
```

ロール判定は `courseRoleProvider(courseId)` で行い、ロード中は `CircularProgressIndicator` を表示。

---

## タブ詳細

### 課題タブ（`_AssignmentsTab`）

- `assignmentsViewModelProvider` の全課題から `courseId` に一致するものをフィルタ
- 締め切り昇順ソート（`null` は末尾）
- `Skeletonizer` でローディング中はフェイクカード表示
- `AssignmentCard`（variant: compact）を表示
- カードタップで `/assignments/:assignmentId` へ遷移

### お知らせタブ（`_AnnouncementsTab`）

- `announcementsViewModelProvider(courseId)` でコース別のお知らせを取得
- 各アイテムの `isMaterial` フラグで2種類のカードを使い分け

| カード種別 | 条件 | 表示内容 |
|-----------|------|----------|
| `_AnnouncementCard` | `isMaterial == false` | 投稿日時 + 本文 |
| `_MaterialCard` | `isMaterial == true` | 資料アイコン + タイトル + 本文 + 添付ファイルタイル |

**添付ファイルタイル（`_CourseMaterialTile`）**

| 素材タイプ | アイコン |
|-----------|---------|
| `driveFile` | `Icons.insert_drive_file_outlined` |
| `youTube` | `Icons.play_circle_outline` |
| `link` | `Icons.link` |
| `form` | `Icons.assignment_outlined` |

タップすると `DriveFileService.resolveAndOpen()` を呼び出し：
- PDF → アプリ内 `/viewer/:fileId` へ遷移
- その他 → 外部アプリで開く

### 提出状況タブ（`_TeacherSubmissionsTab`、教師のみ）

- `teacherSubmissionCountsProvider(courseId)` — 課題ごとの提出件数 `Map<assignmentId, int>`
- `teacherStudentCountProvider(courseId)` — コースの総生徒数
- 各課題を締め切り昇順で表示し、`提出件数 / 生徒数 件提出` バッジ付きカードを表示
- `RefreshIndicator` でプル更新可能

エラー時はエラーメッセージ + プル更新を促す。

---

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移元 | `/dashboard` | コースカードタップ |
| 遷移先 | `/assignments/:assignmentId` | 課題タブのカードタップ |
| 遷移先 | `/viewer/:fileId` | 添付ファイルが PDF の場合 |

## 依存

- `courseRoleProvider(courseId)` — ロール判定
- `assignmentsViewModelProvider` — 課題データ
- `announcementsViewModelProvider(courseId)` — お知らせデータ
- `teacherSubmissionCountsProvider(courseId)` — 提出数（教師のみ）
- `teacherStudentCountProvider(courseId)` — 生徒数（教師のみ）
- `driveFileServiceProvider` — ファイルオープン処理
- `skeletonizer`、`shadcn_ui`、`go_router`
