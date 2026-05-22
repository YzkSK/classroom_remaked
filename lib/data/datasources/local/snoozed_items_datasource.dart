import 'package:drift/drift.dart';
import 'app_database.dart';

class SnoozedItemsDataSource {
  SnoozedItemsDataSource(this._db);

  final AppDatabase _db;

  Future<void> upsert(String assignmentId, DateTime snoozedUntil) async {
    await _db.into(_db.snoozedItems).insertOnConflictUpdate(
      SnoozedItemsCompanion.insert(
        assignmentId: assignmentId,
        snoozedUntil: snoozedUntil,
      ),
    );
  }

  Future<Map<String, DateTime>> getActiveSnoozed(DateTime now) async {
    final rows = await (_db.select(_db.snoozedItems)
          ..where((t) => t.snoozedUntil.isBiggerThanValue(now)))
        .get();
    return {for (final r in rows) r.assignmentId: r.snoozedUntil};
  }

  Future<Set<String>> getExpiredIds(DateTime now) async {
    final rows = await (_db.select(_db.snoozedItems)
          ..where((t) => t.snoozedUntil.isSmallerOrEqualValue(now)))
        .get();
    return rows.map((r) => r.assignmentId).toSet();
  }

  Future<void> delete(String assignmentId) async {
    await (_db.delete(_db.snoozedItems)
          ..where((t) => t.assignmentId.equals(assignmentId)))
        .go();
  }
}
