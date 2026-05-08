// lib/data/datasources/local/sync_state_datasource.dart
import 'app_database.dart';

class SyncStateDataSource {
  SyncStateDataSource(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (
      _db.select(_db.syncStates)..where((t) => t.key.equals(key))
    ).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await _db.into(_db.syncStates).insertOnConflictUpdate(
      SyncStatesCompanion.insert(key: key, value: value),
    );
  }

  Future<void> delete(String key) async {
    await (_db.delete(_db.syncStates)..where((t) => t.key.equals(key))).go();
  }
}
