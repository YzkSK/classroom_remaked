// lib/data/datasources/local/hidden_items_datasource.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

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
