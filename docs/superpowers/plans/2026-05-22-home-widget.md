# ホーム画面ウィジェット 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iOS・Android のホーム画面に、未提出課題と当日締切課題を表示するウィジェットを追加する。

**Architecture:** `home_widget` パッケージが Flutter↔ネイティブ間のデータ共有層を担い、Flutter側は `WidgetDataService` でDBからデータを読み出しJSONとして保存する。Androidは AppWidgetProvider でRemoteViews を構築し、iOSはWidgetKit ExtensionのTimelineProviderがApp Group UserDefaultsを読む。バックグラウンド更新はAndroidのWorkManager（既存タスク拡張）で行い、iOSはアプリ起動時更新とWidgetKitの自律リフレッシュに委ねる。

**Tech Stack:** Flutter (Dart), `home_widget ^0.7.0`, `workmanager ^0.9.0`（既存）, Kotlin (Android AppWidget), Swift (iOS WidgetKit)

---

## ファイル構成

**新規作成:**
```
lib/core/services/widget_data_service.dart
test/core/services/widget_data_service_test.dart
android/app/src/main/kotlin/com/classroomremaked/classroom_remaked/widget/AssignmentWidgetProvider.kt
android/app/src/main/res/xml/assignment_widget_info.xml
android/app/src/main/res/layout/widget_layout.xml
ios/WidgetExtension/WidgetExtension.swift
ios/WidgetExtension/Info.plist
ios/WidgetExtension/WidgetExtension.entitlements
```

**変更:**
```
pubspec.yaml                                              # home_widget 追加
lib/core/services/background_notification_task.dart      # ウィジェット更新呼び出し追加
lib/main.dart                                             # アプリ起動時ウィジェット更新
android/app/src/main/AndroidManifest.xml                  # AppWidgetProvider 登録
```

---

## Task 1: `home_widget` パッケージ追加

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml に home_widget を追加**

`dependencies:` セクションに以下を追加する（`workmanager:` の下あたり）:

```yaml
  home_widget: ^0.7.0
```

- [ ] **Step 2: パッケージ取得**

```bash
flutter pub get
```

Expected: `home_widget` がダウンロードされ、`pubspec.lock` が更新される。

- [ ] **Step 3: コミット**

```bash
git checkout -b feature/home-widget
git add pubspec.yaml pubspec.lock
git commit -m "chore: home_widget パッケージを追加"
```

---

## Task 2: `WidgetDataService` をTDDで実装

**Files:**
- Create: `test/core/services/widget_data_service_test.dart`
- Create: `lib/core/services/widget_data_service.dart`

### 2-A: テストを書いて失敗させる

- [ ] **Step 1: テストファイルを作成**

```dart
// test/core/services/widget_data_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/core/services/widget_data_service.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';

void main() {
  group('WidgetDataService.filterAssignments', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 22, 10, 0, 0);
    });

    AssignmentRow _row({
      required String id,
      required String courseId,
      required String title,
      required int dueDateMillis,
      String? submissionState,
    }) {
      return AssignmentRow(
        id: id,
        courseId: courseId,
        title: title,
        dueDateMillis: dueDateMillis,
        submissionState: submissionState,
        state: 'published',
        description: null,
        submissionId: null,
        materialsJson: null,
        submissionAttachmentsJson: null,
      );
    }

    CourseRow _course(String id, String name) => CourseRow(
          id: id,
          name: name,
          description: null,
          section: null,
          room: null,
          ownerId: null,
          courseState: 'ACTIVE',
        );

    test('未提出の将来課題のみ返す', () {
      final todayEnd = DateTime(2026, 5, 22, 23, 59, 59);
      final tomorrow = DateTime(2026, 5, 23, 23, 59, 59);
      final rows = [
        _row(
          id: 'a1',
          courseId: 'c1',
          title: '今日締切',
          dueDateMillis: todayEnd.millisecondsSinceEpoch,
        ),
        _row(
          id: 'a2',
          courseId: 'c1',
          title: '明日締切',
          dueDateMillis: tomorrow.millisecondsSinceEpoch,
        ),
        _row(
          id: 'a3',
          courseId: 'c1',
          title: '提出済み',
          dueDateMillis: tomorrow.millisecondsSinceEpoch,
          submissionState: 'TURNED_IN',
        ),
        _row(
          id: 'a4',
          courseId: 'c1',
          title: '期限切れ',
          dueDateMillis: DateTime(2026, 5, 21).millisecondsSinceEpoch,
        ),
      ];
      final courses = [_course('c1', 'コース1')];

      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: courses,
        now: now,
      );

      expect(result.length, 2);
      expect(result.map((e) => e['id']), containsAll(['a1', 'a2']));
    });

    test('今日締切の課題は is_today=true', () {
      final todayEnd = DateTime(2026, 5, 22, 23, 59, 59);
      final rows = [
        _row(
          id: 'a1',
          courseId: 'c1',
          title: '今日締切',
          dueDateMillis: todayEnd.millisecondsSinceEpoch,
        ),
      ];
      final courses = [_course('c1', 'コース1')];

      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: courses,
        now: now,
      );

      expect(result.first['is_today'], true);
    });

    test('明日以降の課題は is_today=false', () {
      final tomorrow = DateTime(2026, 5, 23, 23, 59, 59);
      final rows = [
        _row(
          id: 'a1',
          courseId: 'c1',
          title: '明日締切',
          dueDateMillis: tomorrow.millisecondsSinceEpoch,
        ),
      ];
      final courses = [_course('c1', 'コース1')];

      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: courses,
        now: now,
      );

      expect(result.first['is_today'], false);
    });

    test('期限昇順でソートされる', () {
      final t1 = DateTime(2026, 5, 23, 10, 0);
      final t2 = DateTime(2026, 5, 22, 23, 59);
      final rows = [
        _row(id: 'a1', courseId: 'c1', title: '後', dueDateMillis: t1.millisecondsSinceEpoch),
        _row(id: 'a2', courseId: 'c1', title: '先', dueDateMillis: t2.millisecondsSinceEpoch),
      ];
      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: [_course('c1', 'c')],
        now: now,
      );

      expect(result.first['id'], 'a2');
    });

    test('最大5件に切り詰める', () {
      final due = DateTime(2026, 5, 23, 10, 0).millisecondsSinceEpoch;
      final rows = List.generate(
        8,
        (i) => _row(id: 'a$i', courseId: 'c1', title: 'T$i', dueDateMillis: due + i),
      );
      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: [_course('c1', 'c')],
        now: now,
      );

      expect(result.length, 5);
    });

    test('コース名が埋め込まれる', () {
      final rows = [
        _row(
          id: 'a1',
          courseId: 'c1',
          title: '課題',
          dueDateMillis: DateTime(2026, 5, 23).millisecondsSinceEpoch,
        ),
      ];
      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: [_course('c1', '数学')],
        now: now,
      );

      expect(result.first['course_name'], '数学');
    });
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認**

```bash
flutter test test/core/services/widget_data_service_test.dart
```

Expected: `Error: uri 'package:classroom_remaked/core/services/widget_data_service.dart' not found`

### 2-B: 実装して通過させる

- [ ] **Step 3: `WidgetDataService` を実装**

```dart
// lib/core/services/widget_data_service.dart
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../../data/datasources/local/app_database.dart';

const _widgetDataKey = 'widget_assignments';
const _appGroupId = 'group.com.classroomremaked.classroomRemaked';
const _iOSWidgetName = 'AssignmentWidget'; // Swift の kind = "AssignmentWidget" と一致させる
const _androidWidgetName = 'AssignmentWidgetProvider';
const _androidQualifiedName =
    'com.classroomremaked.classroom_remaked.widget.AssignmentWidgetProvider';

class WidgetDataService {
  const WidgetDataService();

  Future<void> updateWidget(AppDatabase db) async {
    await HomeWidget.setAppGroupId(_appGroupId);

    final now = DateTime.now();
    final assignmentRows = await db.select(db.assignments).get();
    final courseRows = await db.select(db.courses).get();

    final filtered = filterAssignments(
      assignmentRows: assignmentRows,
      courseRows: courseRows,
      now: now,
    );

    final payload = {
      'updated_at': now.toIso8601String(),
      'assignments': filtered,
    };

    await HomeWidget.saveWidgetData<String>(_widgetDataKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
      qualifiedAndroidName: _androidQualifiedName,
    );
  }

  static List<Map<String, dynamic>> filterAssignments({
    required List<AssignmentRow> assignmentRows,
    required List<CourseRow> courseRows,
    required DateTime now,
    int maxCount = 5,
  }) {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final courseNames = {for (final c in courseRows) c.id: c.name};

    final filtered = assignmentRows
        .where((r) =>
            r.submissionState != 'TURNED_IN' && r.dueDateMillis != null)
        .map((r) {
          final due = DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!);
          return MapEntry(r, due);
        })
        .where((e) => e.value.isAfter(now))
        .map((e) => <String, dynamic>{
              'id': e.key.id,
              'course_id': e.key.courseId,
              'title': e.key.title,
              'course_name': courseNames[e.key.courseId] ?? '',
              'due_millis': e.key.dueDateMillis,
              'is_today': !e.value.isAfter(endOfToday),
            })
        .toList();

    filtered.sort(
        (a, b) => (a['due_millis'] as int).compareTo(b['due_millis'] as int));
    return filtered.take(maxCount).toList();
  }
}
```

- [ ] **Step 4: テストを再実行して全パス確認**

```bash
flutter test test/core/services/widget_data_service_test.dart
```

Expected: `All tests passed.`

- [ ] **Step 5: コミット**

```bash
git add lib/core/services/widget_data_service.dart test/core/services/widget_data_service_test.dart
git commit -m "feat: WidgetDataService を追加（ウィジェット用課題データ抽出・JSON化）"
```

---

## Task 3: アプリ起動時 + WorkManager バックグラウンドでウィジェット更新

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/core/services/background_notification_task.dart`

- [ ] **Step 1: `background_notification_task.dart` の `execute()` にウィジェット更新を追加**

`execute()` メソッド末尾（`return true;` の直前）に以下を追加する:

```dart
// lib/core/services/background_notification_task.dart の先頭 import に追加
import 'widget_data_service.dart';
```

`execute()` 内の `return true;` の直前に:

```dart
    await const WidgetDataService().updateWidget(db);
```

変更後の `execute()` 末尾はこうなる:

```dart
    for (final assignment in candidates) {
      await notifService.show(assignment);
      await logsDs.log(assignment.id);
      await snoozeDs.upsert(assignment.id, now.add(snooze));
    }

    await const WidgetDataService().updateWidget(db);

    return true;
```

- [ ] **Step 2: `main.dart` のアプリ起動フローにウィジェット更新を追加**

`main.dart` の先頭 import に追加:

```dart
import 'core/services/widget_data_service.dart';
import 'data/datasources/local/app_database.dart';
```

`runApp(...)` の直前に追加:

```dart
  // ウィジェットデータをアプリ起動時に更新（DBから直接読む）
  final db = AppDatabase();
  try {
    await const WidgetDataService().updateWidget(db);
  } finally {
    await db.close();
  }
```

- [ ] **Step 3: ビルドが通ることを確認**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: コミット**

```bash
git add lib/main.dart lib/core/services/background_notification_task.dart
git commit -m "feat: アプリ起動時・WorkManager タスクでウィジェットデータを更新"
```

---

## Task 4: Android ウィジェット XML リソース

**Files:**
- Create: `android/app/src/main/res/xml/assignment_widget_info.xml`
- Create: `android/app/src/main/res/layout/widget_layout.xml`

- [ ] **Step 1: `res/xml/` ディレクトリを作成してウィジェットメタデータを追加**

```bash
mkdir -p android/app/src/main/res/xml
```

```xml
<!-- android/app/src/main/res/xml/assignment_widget_info.xml -->
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="900000"
    android:initialLayout="@layout/widget_layout"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
```

- [ ] **Step 2: ウィジェットレイアウトを作成**

```xml
<!-- android/app/src/main/res/layout/widget_layout.xml -->
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="12dp"
    android:background="@android:color/white">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="未提出の課題"
        android:textSize="12sp"
        android:textColor="#666666"
        android:layout_marginBottom="4dp" />

    <TextView
        android:id="@+id/widget_item_0"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="13sp"
        android:textColor="#111111"
        android:maxLines="1"
        android:ellipsize="end"
        android:visibility="gone" />

    <TextView
        android:id="@+id/widget_item_1"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="13sp"
        android:textColor="#111111"
        android:maxLines="1"
        android:ellipsize="end"
        android:visibility="gone" />

    <TextView
        android:id="@+id/widget_item_2"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="13sp"
        android:textColor="#111111"
        android:maxLines="1"
        android:ellipsize="end"
        android:visibility="gone" />

    <TextView
        android:id="@+id/widget_item_3"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="13sp"
        android:textColor="#111111"
        android:maxLines="1"
        android:ellipsize="end"
        android:visibility="gone" />

    <TextView
        android:id="@+id/widget_item_4"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="13sp"
        android:textColor="#111111"
        android:maxLines="1"
        android:ellipsize="end"
        android:visibility="gone" />

    <TextView
        android:id="@+id/widget_empty"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="課題なし"
        android:textSize="13sp"
        android:textColor="#999999"
        android:visibility="gone" />

</LinearLayout>
```

- [ ] **Step 3: コミット**

```bash
git add android/app/src/main/res/
git commit -m "feat: Android ウィジェット XML リソースを追加"
```

---

## Task 5: Android AppWidgetProvider + AndroidManifest 登録

**Files:**
- Create: `android/app/src/main/kotlin/com/classroomremaked/classroom_remaked/widget/AssignmentWidgetProvider.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: `widget/` ディレクトリを作成し AppWidgetProvider を実装**

```bash
mkdir -p android/app/src/main/kotlin/com/classroomremaked/classroom_remaked/widget
```

```kotlin
// android/app/src/main/kotlin/com/classroomremaked/classroom_remaked/widget/AssignmentWidgetProvider.kt
package com.classroomremaked.classroom_remaked.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import com.classroomremaked.classroom_remaked.R

class AssignmentWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        val widgetData = HomeWidgetPlugin.getData(context)
        val json = widgetData.getString("widget_assignments", null)

        val itemIds = listOf(
            R.id.widget_item_0,
            R.id.widget_item_1,
            R.id.widget_item_2,
            R.id.widget_item_3,
            R.id.widget_item_4,
        )

        itemIds.forEach { views.setViewVisibility(it, View.GONE) }
        views.setViewVisibility(R.id.widget_empty, View.GONE)

        if (json == null) {
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        } else {
            val obj = JSONObject(json)
            val assignments = obj.optJSONArray("assignments")

            if (assignments == null || assignments.length() == 0) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            } else {
                for (i in 0 until minOf(assignments.length(), itemIds.size)) {
                    val a = assignments.getJSONObject(i)
                    val title = a.optString("title", "")
                    val courseName = a.optString("course_name", "")
                    val isToday = a.optBoolean("is_today", false)
                    val dueSuffix = if (isToday) "【今日】" else ""
                    views.setTextViewText(itemIds[i], "$dueSuffix$title  $courseName")
                    views.setViewVisibility(itemIds[i], View.VISIBLE)
                }
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
```

- [ ] **Step 2: タップ時にアプリを起動する PendingIntent を追加**

`updateWidget` 内の `appWidgetManager.updateAppWidget(...)` の直前に以下を追加:

```kotlin
        // ウィジェットタップでアプリを起動
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(android.R.id.content, pendingIntent)
        }
```

> `android.R.id.content` はルートビューに相当しないため、`widget_layout.xml` のルート `LinearLayout` に `android:id="@+id/widget_root"` を追加し、`R.id.widget_root` を使うこと。

`widget_layout.xml` のルート要素に属性を追加:
```xml
android:id="@+id/widget_root"
```

- [ ] **Step 3: AndroidManifest.xml に AppWidgetProvider を登録**

`</application>` タグの直前（`</activity>` の後）に以下を追加する:

```xml
        <receiver
            android:name=".widget.AssignmentWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/assignment_widget_info" />
        </receiver>
```

- [ ] **Step 4: Android ビルドが通ることを確認**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 5: コミット**

```bash
git add android/
git commit -m "feat: Android AssignmentWidgetProvider を実装・登録"
```

---

## Task 6: iOS — Xcode で WidgetExtension ターゲットを追加（手動操作）

> **⚠️ このタスクは Xcode GUI での操作が必要です。**

- [ ] **Step 1: Xcode でプロジェクトを開く**

```bash
open ios/Runner.xcworkspace
```

- [ ] **Step 2: Widget Extension ターゲットを追加**

1. メニュー: **File > New > Target...**
2. 「Widget Extension」を選択 → **Next**
3. Product Name: `WidgetExtension`
4. Bundle Identifier が `com.classroomremaked.classroomRemaked.WidgetExtension` になっていることを確認
5. 「Include Configuration Intent」は **チェックしない**
6. **Finish** → 「Activate "WidgetExtension" scheme?」に **Cancel**（Runner スキームを維持するため）

- [ ] **Step 3: Runner と WidgetExtension に App Group を追加**

1. プロジェクトナビゲーターで **Runner** ターゲットを選択
2. **Signing & Capabilities** タブ → **+ Capability** → **App Groups**
3. **+** ボタンで `group.com.classroomremaked.classroomRemaked` を追加

4. 同様に **WidgetExtension** ターゲットでも:
   - **Signing & Capabilities** → **+ Capability** → **App Groups**
   - `group.com.classroomremaked.classroomRemaked` を追加

- [ ] **Step 4: 自動生成された Swift ファイルを確認**

`ios/WidgetExtension/` に以下が生成されていることを確認:
- `WidgetExtension.swift`
- `WidgetExtensionBundle.swift`（または `WidgetExtension.swift` 内に `@main` がある）
- `Info.plist`
- `WidgetExtension.entitlements`

- [ ] **Step 5: WidgetExtension.entitlements の App Group を確認**

`ios/WidgetExtension/WidgetExtension.entitlements` に以下が含まれていることを確認（なければ追加）:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.classroomremaked.classroomRemaked</string>
    </array>
</dict>
</plist>
```

> Runner.entitlements にも同じ App Group が追加されているはず（Xcodeが自動追加する）。

- [ ] **Step 6: コミット**

```bash
git add ios/
git commit -m "feat: iOS WidgetExtension ターゲットを追加・App Group 設定"
```

---

## Task 7: iOS WidgetKit Swift コードを実装

**Files:**
- Modify: `ios/WidgetExtension/WidgetExtension.swift`（Xcode が生成したファイルを上書き）

- [ ] **Step 1: Xcode が生成したファイルを整理する**

Xcode が `WidgetExtensionBundle.swift`（`@main` を持つ）と `WidgetExtension.swift` を両方生成した場合、`@main` が重複してビルドエラーになる。その場合 `WidgetExtensionBundle.swift` を削除し、`WidgetExtension.swift` の `@main` のみを残す。

- [ ] **Step 2: `WidgetExtension.swift` を実装**

Xcode の自動生成ファイルを以下の内容で置き換える:

```swift
// ios/WidgetExtension/WidgetExtension.swift
import WidgetKit
import SwiftUI
import Foundation

// MARK: - データモデル

struct WidgetAssignment: Identifiable {
    let id: String
    let title: String
    let courseName: String
    let dueDateMillis: Int64
    let isToday: Bool

    var dueLabel: String {
        let date = Date(timeIntervalSince1970: Double(dueDateMillis) / 1000)
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            return "今日 \(fmt.string(from: date))"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "M/d"
            return fmt.string(from: date)
        }
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let assignments: [WidgetAssignment]
}

// MARK: - TimelineProvider

struct AssignmentTimelineProvider: TimelineProvider {
    private let appGroupId = "group.com.classroomremaked.classroomRemaked"
    private let dataKey = "widget_assignments"

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), assignments: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> WidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        guard
            let json = defaults?.string(forKey: dataKey),
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let arr = obj["assignments"] as? [[String: Any]]
        else {
            return WidgetEntry(date: Date(), assignments: [])
        }

        let assignments: [WidgetAssignment] = arr.compactMap { dict in
            guard
                let id = dict["id"] as? String,
                let title = dict["title"] as? String,
                let courseName = dict["course_name"] as? String,
                let dueDateMillis = dict["due_millis"] as? Int64,
                let isToday = dict["is_today"] as? Bool
            else { return nil }
            return WidgetAssignment(
                id: id,
                title: title,
                courseName: courseName,
                dueDateMillis: dueDateMillis,
                isToday: isToday
            )
        }

        return WidgetEntry(date: Date(), assignments: assignments)
    }
}

// MARK: - Widget Views

struct AssignmentRowView: View {
    let assignment: WidgetAssignment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(assignment.title)
                    .font(.system(size: 13, weight: assignment.isToday ? .semibold : .regular))
                    .lineLimit(1)
                    .foregroundColor(assignment.isToday ? .red : .primary)
                Text(assignment.courseName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(assignment.dueLabel)
                .font(.system(size: 11))
                .foregroundColor(assignment.isToday ? .red : .secondary)
        }
    }
}

struct AssignmentWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("未提出の課題")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            if entry.assignments.isEmpty {
                Spacer()
                Text("課題なし")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ForEach(entry.assignments) { a in
                    AssignmentRowView(assignment: a)
                    if a.id != entry.assignments.last?.id {
                        Divider()
                    }
                }
                Spacer()
            }
        }
        .padding(12)
    }
}

// MARK: - Widget Definition

@main
struct AssignmentWidget: Widget {
    let kind = "AssignmentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AssignmentTimelineProvider()) { entry in
            AssignmentWidgetView(entry: entry)
        }
        .configurationDisplayName("未提出の課題")
        .description("未提出・当日締切の課題を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
```

タップ動作を追加するには `AssignmentWidgetView` の `body` 末尾（`.padding(12)` の後）に:

```swift
        .widgetURL(URL(string: "classroomremaked://assignments"))
```

> これにより、ウィジェットタップでアプリが起動しダッシュボードに遷移する（`go_router` 側に `/assignments` ルートが未実装の場合はルートURL `"classroomremaked://"` でも可）。

- [ ] **Step 3: Xcode でビルドが通ることを確認**

Xcode で **Runner** スキームを選択し、シミュレーターでビルド:

```
Product > Build (⌘B)
```

Expected: ビルドエラーなし。

- [ ] **Step 4: コミット**

```bash
git add ios/WidgetExtension/
git commit -m "feat: iOS WidgetKit Extension (TimelineProvider + SwiftUI View) を実装"
```

---

## Task 8: 動作確認 + PR 作成

- [ ] **Step 1: テストを全件実行**

```bash
flutter test
```

Expected: `All tests passed.`

- [ ] **Step 2: Android エミュレーターで動作確認**

1. `flutter run` でアプリを起動してサインイン・同期
2. ホーム画面でウィジェットを追加（長押し → ウィジェット → "classroom_remaked" → "未提出の課題"）
3. 未提出課題がウィジェットに表示されることを確認

- [ ] **Step 3: iOS シミュレーターで動作確認**

1. Xcode の Runner スキームで `flutter run` でアプリを起動してサインイン・同期
2. シミュレーターのホーム画面で長押し → ウィジェット追加 → "未提出の課題"
3. 未提出課題が表示されることを確認

- [ ] **Step 4: PR を作成**

```bash
git push -u origin feature/home-widget
gh pr create \
  --title "feat: iOS/Android ホーム画面ウィジェット追加" \
  --body "$(cat <<'EOF'
## Summary
- `home_widget` パッケージを使ってiOS・Android両対応のホーム画面ウィジェットを追加
- 未提出課題・当日締切課題を最大5件表示（期限昇順、今日分はハイライト）
- Androidはアプリ起動時 + WorkManagerバックグラウンドタスクでデータ更新
- iOSはアプリ起動時更新 + WidgetKitの自律タイムラインリフレッシュ（15分ごと）

## Test plan
- [ ] `flutter test` が全パスすること
- [ ] Androidエミュレーターでウィジェット追加 → 課題が表示される
- [ ] iOSシミュレーターでウィジェット追加 → 課題が表示される
- [ ] 提出済み課題はウィジェットに表示されない
- [ ] 課題が0件のとき「課題なし」と表示される

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## 補足: `due_millis` の型について

`dict["due_millis"] as? Int64` は Swift では動作しない場合がある（JSONは`NSNumber`として届くため）。動作しない場合は `dict["due_millis"] as? Int` または `(dict["due_millis"] as? NSNumber)?.int64Value` に変更する。
