# ホーム画面ウィジェット設計書

**Date:** 2026-05-22  
**Status:** Approved

---

## 概要

iOS・Android のホーム画面に、未提出課題と当日締切課題を表示するウィジェットを追加する。`home_widget` パッケージを介してFlutter↔ネイティブ間でデータを共有し、WorkManager（Android）/ BGTaskScheduler（iOS）で定期バックグラウンド更新を行う。

---

## アーキテクチャ

```
Flutter (Dart)
  ├─ WidgetDataService        ← 課題データをJSONに変換してSharedStorageへ書き込む
  └─ WorkManager background   ← バックグラウンドでClassroom APIを叩き、WidgetDataServiceを呼ぶ

iOS (Swift)
  └─ WidgetKit Extension
       └─ TimelineProvider    ← App Group UserDefaultsからデータを読み込んでUIを描画

Android (Kotlin)
  └─ AppWidgetProvider
       └─ RemoteViewsService  ← SharedPreferencesからデータを読み込んでRemoteViewsを構築
```

---

## データフロー

1. アプリ起動 or WorkManager/BGTask のバックグラウンドタスクが実行される
2. `ClassroomSyncService` 経由で Google Classroom API から課題データを取得
3. `WidgetDataService` がデータをフィルタリング（未提出 & 当日締切）してJSONにシリアライズ
4. `home_widget` の `HomeWidget.saveWidgetData()` で SharedStorage に書き込む
5. `HomeWidget.updateWidget()` で OS にウィジェットの再描画をリクエスト
6. OSがウィジェットを表示するタイミングでネイティブが SharedStorage を読み出し、UIを描画

---

## ウィジェット仕様

### 表示内容

- **未提出課題リスト**（期限昇順、最大5件）
  - 課題名
  - コース名
  - 期限日時（当日の場合は「今日 HH:mm」、それ以外は「M/d」形式）
- **当日締切の課題**はハイライト（背景色変更）

### サイズ

| プラットフォーム | サイズ |
|---|---|
| iOS | `.systemSmall`（2件まで）/ `.systemMedium`（5件まで） |
| Android | `2×2`（2件まで）/ `4×2`（5件まで） |

### タップ動作

- ウィジェット全体タップ → アプリを起動し、ダッシュボードの課題タブへ遷移
- 個別課題タップ（medium/4×2のみ） → 該当課題の詳細画面へディープリンク（`/dashboard/courses/{courseId}/assignments/{assignmentId}`）

### 更新頻度

- **15分間隔**（WorkManager / BGTask の推奨最小間隔）
- アプリ起動時にも即時更新

---

## SharedStorage のデータ形式

`home_widget` のキー: `widget_assignments`

```json
{
  "updated_at": "2026-05-22T10:00:00Z",
  "assignments": [
    {
      "id": "assignment_id",
      "course_id": "course_id",
      "title": "課題タイトル",
      "course_name": "コース名",
      "due_date": "2026-05-22T23:59:00Z",
      "is_today": true
    }
  ]
}
```

---

## 追加パッケージ

| パッケージ | バージョン | 用途 |
|---|---|---|
| `home_widget` | ^0.7.0 | Flutter↔ネイティブ間のデータ共有・ウィジェット更新通知 |
| `workmanager` | ^0.9.0 | バックグラウンド定期タスク（pubspec.yaml に既存、再有効化） |

---

## ファイル構成

### 新規ファイル

```
lib/core/services/widget_data_service.dart
ios/WidgetExtension/
  ├─ WidgetExtension.swift          # TimelineProvider & WidgetView
  ├─ Info.plist
  └─ WidgetExtension.entitlements
android/app/src/main/kotlin/com/example/classroom_remaked/widget/
  ├─ AssignmentWidgetProvider.kt    # AppWidgetProvider
  ├─ AssignmentWidgetService.kt     # RemoteViewsService
  └─ AssignmentRemoteViewsFactory.kt
android/app/src/main/res/xml/
  └─ assignment_widget_info.xml     # AppWidget メタデータ
android/app/src/main/res/layout/
  ├─ widget_assignment_list.xml
  └─ widget_assignment_item.xml
```

### 変更ファイル

```
pubspec.yaml                             # home_widget 追加、workmanager 再有効化
lib/core/di/providers.dart              # WidgetDataService をDI登録
lib/core/services/background_notification_task.dart  # ウィジェット更新タスク追加
android/app/src/main/AndroidManifest.xml  # AppWidgetProvider & Service 登録
ios/Runner/Info.plist                    # BGTask 許可エントリ追加
```

---

## エラーハンドリング

- API取得失敗時: 前回の SharedStorage データをそのまま表示（古いデータ表示）
- データが空の場合: ウィジェットに「課題なし」を表示
- 未サインイン時: ウィジェットに「アプリを開いてサインイン」を表示

---

## git 運用

- ブランチ: `feature/home-widget`
- コミット分割:
  1. `feat: Flutter WidgetDataService と home_widget パッケージ統合`
  2. `feat: Android AppWidgetProvider 実装`
  3. `feat: iOS WidgetKit Extension 実装`
  4. `feat: WorkManager バックグラウンド更新統合`
- PR: `feature/home-widget` → `main`

---

## 未対応事項（スコープ外）

- ウィジェットのカスタムカラー設定
- ダークモード対応（OS デフォルトに従う）
- iPad 向け `.systemLarge` サイズ
