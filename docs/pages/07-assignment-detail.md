# AssignmentDetailScreen

## 概要

課題の詳細情報を表示し、ファイル添付・提出・提出取り消しを行う画面。

## ルート

```
/assignments/:assignmentId
```

パスパラメータ `assignmentId` で課題を特定する。

## ソースファイル

`lib/presentation/views/assignments/assignment_detail_screen.dart`

## UI 構成

```
┌──────────────────────────────────┐
│  AppBar: 課題タイトル（省略あり）  │
├──────────────────────────────────┤
│  課題タイトル（h3）               │
│  📅 締め切り日時 or "締め切りなし" │
│  [バッジ: 提出済み / 期限切れ / 残日数] │
│                                   │
│  説明（存在する場合）              │
│  ────────────────────────────── │
│  添付ファイル（教師からの素材）     │
│  ────────────────────────────── │
│  提出内容（提出済みの場合）        │
│    ファイル一覧                   │
│    [提出を取り消す]               │
├──────────────────────────────────┤
│  [添付] [      提出する      ]   │  ← 提出前のみ表示
└──────────────────────────────────┘
```

---

## 締め切りバッジ

| 状態 | バッジ種別 | 内容 |
|------|-----------|------|
| 提出済み | `ShadBadge.secondary` | "提出済み" |
| 期限切れ（未提出） | `ShadBadge`（error色） | "期限切れ" |
| 締め切りまで余裕あり | `ShadBadge.outline` | "締め切りまでX日" |

---

## 添付ファイルタイル（`_MaterialTile`）

教師が作成した課題の素材 / 提出済みの自分の添付を共通で表示するウィジェット。

| 素材タイプ | アイコン |
|-----------|---------|
| `driveFile` | `Icons.insert_drive_file_outlined` |
| `youTube` | `Icons.play_circle_outline` |
| `link` | `Icons.link` |
| `form` | `Icons.assignment_outlined` |

タップで `DriveFileService.resolveAndOpen()` を呼び出す。

**ウイルススキャン警告（`DriveVirusScanWarningException`）**:
確認ダイアログを表示し、ユーザーが同意した場合のみ `service.openWithAcknowledge(e)` でダウンロード。

---

## 提出済みセクション（`_SubmittedSection`）

`isSubmitted && submissionId != null` のとき本文下部に表示。

- 提出に含まれるファイル一覧（`_MaterialTile` で表示）
- "提出を取り消す" ボタン

**取り消しフロー**:
1. `ShadDialog.alert` で確認（"取り消す" / "キャンセル"）
2. `turnInViewModelProvider.notifier.reclaim(courseId, assignmentId, submissionId)` を呼び出す
3. 成功時：トースト表示 + `assignmentsViewModelProvider.notifier.markReclaimedByStudent(assignmentId)`
4. 失敗時：`ShadToast.destructive` でエラー表示

---

## 提出パネル（`_SubmitBottomPanel`）

`!isSubmitted && submissionId != null` のとき `bottomNavigationBar` として表示。

### 添付ファイル追加（`_pickAndUpload`）

1. `FilePicker.pickFiles(allowMultiple: true)` でファイル選択
2. `DriveFileService.uploadFile(File)` でファイルを Google Drive にアップロード
3. アップロード成功したファイルを `_submitAttachmentsProvider` に追加
4. 失敗時はエラートースト

`_submitAttachmentsProvider`（`StateProvider.autoDispose`）で添付リストを管理。アイコン横の `×` ボタンで個別削除可能。

### 提出（`_submit`）

1. `ShadDialog.alert` で確認（"提出する" / "キャンセル"）
2. `_submitAttachmentsProvider` の各ファイルを `lmsRepository.addAttachment()` でサーバーに紐付け
3. `turnInViewModelProvider.notifier.turnIn(...)` で提出
4. 成功時：トースト + `markTurnedIn(assignmentId, attachments: ...)` でローカル状態更新

| ボタン | 状態 |
|-------|------|
| 添付ボタン | アップロード中は無効化 + インジケータ |
| 提出ボタン | turnIn 中は無効化 + インジケータ |

---

## ローディング / エラー状態

| 状態 | 表示 |
|------|------|
| データロード中 | 全画面 `CircularProgressIndicator` |
| 課題が見つからない | "課題が見つかりません" |

---

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移元 | `/assignments` / `/dashboard` / 通知タップ | — |
| 遷移先 | `/viewer/:fileId` | 添付が PDF の場合 |

## 依存

- `assignmentsViewModelProvider` — 課題データ・状態更新
- `turnInViewModelProvider` — 提出・取り消し処理
- `driveFileServiceProvider` — ファイルオープン・アップロード
- `lmsRepositoryProvider` — 添付ファイル紐付け API
- `file_picker` — ローカルファイル選択
- `shadcn_ui` — `ShadBadge`、`ShadCard`、`ShadButton`、`ShadDialog`、`ShadToaster`
