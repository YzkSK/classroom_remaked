// lib/data/datasources/local/notification_logs_datasource.dart
import 'app_database.dart';

class NotificationLogsDataSource {
  NotificationLogsDataSource(this._db);

  final AppDatabase _db;

  Future<void> log(String assignmentId) async {
    await _db.into(_db.notificationLogs).insertOnConflictUpdate(
      NotificationLogsCompanion.insert(
        assignmentId: assignmentId,
        notifiedAt: DateTime.now(),
      ),
    );
  }

  Future<Set<String>> getLoggedIds() async {
    final rows = await _db.select(_db.notificationLogs).get();
    return rows.map((r) => r.assignmentId).toSet();
  }

  Future<void> delete(String assignmentId) async {
    await (_db.delete(_db.notificationLogs)
          ..where((t) => t.assignmentId.equals(assignmentId)))
        .go();
  }
}
