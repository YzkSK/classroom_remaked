# Phase 3a: コース・課題の非表示機能 設計書

**作成日:** 2026-05-08
**状態:** 承認済み

---

## Goal

ダッシュボード（コース一覧）と課題一覧から、不要なコース・課題を非表示にできるようにする。非表示にしたアイテムはフィルタートグルで再表示・解除が可能。

## アーキテクチャ方針

アプローチ A: **ViewModel クライアントサイドフィルタリング**

DB から全件取得し、ViewModel が非表示 ID セットを保持してフィルタリング。`showHidden: bool` を ViewModel の状態として管理する。コース・課題数は数十件程度なので SQL 最適化は不要。

---

## データ層

### drift テーブル追加: `HiddenItems`

`app_database.dart` に追加。`schemaVersion` を 1 → 2 に上げ、`MigrationStrategy.onCreate` + `onUpgrade` で `CREATE TABLE` を実行する。

```dart
@DataClassName('HiddenItemRow')
class HiddenItems extends Table {
  TextColumn get itemId => text()();       // courseId または assignmentId
  TextColumn get type => text()();         // 'course' | 'assignment'
  DateTimeColumn get hiddenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}
```

### HiddenItemsDataSource

**ファイル:** `lib/data/datasources/local/hidden_items_datasource.dart`

```dart
class HiddenItemsDataSource {
  HiddenItemsDataSource(this._db);
  final AppDatabase _db;

  Future<Set<String>> getHiddenIds(String type) async {
    final rows = await (_db.select(_db.hiddenItems)
          ..where((t) => t.type.equals(type)))
        .get();
    return rows.map((r) => r.itemId).toSet();
  }

  Future<void> hide(String itemId, String type) async {
    await _db.into(_db.hiddenItems).insertOnConflictUpdate(
      HiddenItemsCompanion.insert(
        itemId: itemId,
        type: type,
        hiddenAt: DateTime.now(),
      ),
    );
  }

  Future<void> unhide(String itemId) async {
    await (_db.delete(_db.hiddenItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }
}
```

---

## ドメイン層

UseCase は2つ。DB 書き込み失敗は例外伝播で十分なので `Either` は使わない。

**ファイル:** `lib/domain/usecases/hide_item.dart`

```dart
class HideItemUseCase {
  HideItemUseCase(this._dataSource);
  final HiddenItemsDataSource _dataSource;

  Future<void> execute(String itemId, String type) =>
      _dataSource.hide(itemId, type);
}
```

**ファイル:** `lib/domain/usecases/unhide_item.dart`

```dart
class UnhideItemUseCase {
  UnhideItemUseCase(this._dataSource);
  final HiddenItemsDataSource _dataSource;

  Future<void> execute(String itemId) => _dataSource.unhide(itemId);
}
```

---

## プレゼンテーション層

### ViewModel 変更

`DashboardViewModel` と `AssignmentsViewModel` それぞれに以下を追加する。

**追加する状態:**

```dart
bool showHidden = false;
```

**`build()` 内のフィルタリング:**

```dart
final hiddenIds = await ref.watch(hiddenItemsDataSourceProvider)
    .getHiddenIds('course'); // or 'assignment'

final filtered = showHidden
    ? courses.map((c) => (course: c, isHidden: hiddenIds.contains(c.id))).toList()
    : courses.where((c) => !hiddenIds.contains(c.id))
        .map((c) => (course: c, isHidden: false)).toList();
```

**追加するメソッド:**

```dart
void toggleShowHidden()
Future<void> hideItem(String id)
Future<void> unhideItem(String id)
```

### UI 操作一覧

| 操作 | 動作 |
|------|------|
| 長押し（通常表示のアイテム） | `ShadContextMenu` →「非表示にする」→ `hideItem()` |
| 左スワイプ | `Dismissible` → `hideItem()` → `ShadSonner` で「元に戻す」トースト（3秒） |
| 右上フィルタートグル | `showHidden` を反転。非表示アイテムはグレーアウト（`opacity: 0.4`）で表示 |
| 長押し（グレーアウトのアイテム） | `ShadContextMenu` →「非表示を解除」→ `unhideItem()` |

### 新規ファイル

- `lib/data/datasources/local/hidden_items_datasource.dart`
- `lib/domain/usecases/hide_item.dart`
- `lib/domain/usecases/unhide_item.dart`

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `lib/data/datasources/local/app_database.dart` | `HiddenItems` テーブル追加、schemaVersion 2、MigrationStrategy |
| `lib/data/datasources/local/app_database.g.dart` | 再生成 |
| `lib/core/di/providers.dart` | `hiddenItemsDataSourceProvider`、UseCase プロバイダー追加 |
| `lib/presentation/viewmodels/dashboard_viewmodel.dart` | `showHidden`、`hideItem`、`unhideItem`、`toggleShowHidden` 追加 |
| `lib/presentation/viewmodels/assignments_viewmodel.dart` | 同上 |
| `lib/presentation/views/dashboard/widgets/course_list.dart` | `Dismissible` + 長押し `ShadContextMenu` + フィルタートグル |
| `lib/presentation/views/assignments/assignments_screen.dart` | 同上（課題カード） |

---

## テスト方針

| 対象 | 内容 |
|------|------|
| `HideItemUseCase` | `hide()` が呼ばれることを検証 |
| `UnhideItemUseCase` | `unhide()` が呼ばれることを検証 |
| `DashboardViewModel` | `hideItem()` 後に該当コースがリストから消えること、`toggleShowHidden()` 後に非表示アイテムが現れることを検証 |
| `AssignmentsViewModel` | 同上（課題） |
