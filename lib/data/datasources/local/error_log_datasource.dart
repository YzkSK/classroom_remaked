// lib/data/datasources/local/error_log_datasource.dart
import 'dart:convert';
import 'app_database.dart';

class ErrorLogEntry {
  ErrorLogEntry({
    required this.timestamp,
    required this.source,
    required this.message,
    this.stackTrace,
  });

  final DateTime timestamp;
  final String source;
  final String message;
  final String? stackTrace;

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'src': source,
        'msg': message,
        if (stackTrace != null) 'st': stackTrace,
      };

  factory ErrorLogEntry.fromJson(Map<String, dynamic> j) => ErrorLogEntry(
        timestamp: DateTime.parse(j['ts'] as String),
        source: j['src'] as String,
        message: j['msg'] as String,
        stackTrace: j['st'] as String?,
      );
}

class ErrorLogDataSource {
  ErrorLogDataSource(this._db);

  final AppDatabase _db;
  static const _key = 'debug_error_logs';
  static const _maxEntries = 100;

  Future<List<ErrorLogEntry>> getAll() async {
    final row = await (_db.select(_db.userPreferences)
          ..where((t) => t.key.equals(_key)))
        .getSingleOrNull();
    if (row == null) return [];
    try {
      final list = jsonDecode(row.value) as List;
      return list
          .map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add({
    required String source,
    required String message,
    String? stackTrace,
  }) async {
    final entries = await getAll();
    entries.insert(
      0,
      ErrorLogEntry(
        timestamp: DateTime.now(),
        source: source,
        message: message,
        stackTrace: stackTrace,
      ),
    );
    final trimmed = entries.take(_maxEntries).toList();
    await _db.into(_db.userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion.insert(
        key: _key,
        value: jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      ),
    );
  }

  Future<void> clear() async {
    await (_db.delete(_db.userPreferences)
          ..where((t) => t.key.equals(_key)))
        .go();
  }
}
