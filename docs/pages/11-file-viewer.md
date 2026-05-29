# FileViewerScreen

## 概要

Google Drive のファイルをアプリ内で PDF として閲覧する画面。Drive ファイルの `fileId` を受け取り、バイトデータをダウンロードしてインラインレンダリングする。

## ルート

```
/viewer/:fileId?title=ファイル名
```

- `fileId`：Google Drive ファイル ID（パスパラメータ）
- `title`：AppBar に表示するファイル名（クエリパラメータ、省略時は "ファイル"）

## ソースファイル

`lib/presentation/views/shared/file_viewer_screen.dart`

## 遷移元

以下の画面から `context.push` で開かれる:
- `AssignmentDetailScreen` — 添付ファイルが PDF の場合
- `CourseDetailScreen` → お知らせタブ / 資料タブの `_CourseMaterialTile`

## UI 構成

### 通常表示（PDF レンダリング成功）

```
┌──────────────────────────────────┐
│  AppBar: ファイル名               │
├──────────────────────────────────┤
│                                   │
│   PdfView（縦スクロール）          │
│                                   │
└──────────────────────────────────┘
```

`pdfx` パッケージの `PdfView` で PDF をレンダリング。`scrollDirection: Axis.vertical`。

---

### ローディング状態

```
AppBar + 中央 CircularProgressIndicator
```

`fileViewerProvider(fileId)` が `AsyncLoading` の間表示。

---

### ウイルススキャン警告（`DriveVirusScanWarningException`）

```
┌──────────────────────────────────┐
│  AppBar: ファイル名               │
├──────────────────────────────────┤
│                                   │
│  ⚠️                               │
│  このファイルはウイルススキャンが   │
│  できませんでした。                 │
│  ダウンロードを続けますか？         │
│                                   │
│  [ ダウンロードする ]              │
│                                   │
└──────────────────────────────────┘
```

`DriveFileService.downloadPdfWithAcknowledge(fileId)` でダウンロードし、成功すると `_acknowledgedBytes` を保持して `PdfController` を直接初期化（`fileViewerProvider` を迂回する）。

---

### その他エラー

```
AppBar + 中央に "読み込みに失敗しました\n{エラー内容}"
```

---

## 状態管理

`fileViewerProvider(fileId)`（`FutureProvider.autoDispose.family`）が PDF バイトデータ（`Uint8List`）を提供する。

ウイルス警告ケースのみ、ローカル状態（`_acknowledgedBytes`、`_acknowledgeLoading`）で再ダウンロードを管理。

`PdfController` は `dispose()` でメモリを解放する（`StatefulWidget.dispose` でコール）。

---

## 遷移元 / 遷移先

| 方向 | 画面 |
|------|------|
| 遷移元 | `AssignmentDetailScreen`（添付が PDF） |
| 遷移元 | `CourseDetailScreen` お知らせタブ（素材が PDF） |
| 遷移先 | なし（戻るのみ） |

## 依存

- `fileViewerProvider` — PDF バイトデータ取得
- `driveFileServiceProvider` — ウイルス警告後の再ダウンロード
- `pdfx` — `PdfController`、`PdfView`、`PdfDocument`
- `shadcn_ui` — `ShadToaster`
