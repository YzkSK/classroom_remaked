// lib/presentation/viewmodels/debug_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/local/app_database.dart';

class DebugState {
  const DebugState({
    required this.schemaVersion,
    required this.rowCounts,
    required this.lastSyncAt,
    required this.notificationLogs,
  });

  final int schemaVersion;
  final Map<String, int> rowCounts;
  final String? lastSyncAt;
  final List<NotificationLogRow> notificationLogs;
}

class DebugViewModel extends AsyncNotifier<DebugState> {
  @override
  Future<DebugState> build() => _load();

  Future<DebugState> _load() async {
    final db = ref.read(appDatabaseProvider);
    final syncDs = ref.read(syncStateDataSourceProvider);

    final courses = await db.select(db.courses).get();
    final assignments = await db.select(db.assignments).get();
    final announcements = await db.select(db.announcements).get();
    final logs = await db.select(db.notificationLogs).get()
      ..sort((a, b) => b.notifiedAt.compareTo(a.notifiedAt));
    final snoozed = await db.select(db.snoozedItems).get();
    final hidden = await db.select(db.hiddenItems).get();
    final lastSync = await syncDs.get('last_sync_at');

    return DebugState(
      schemaVersion: db.schemaVersion,
      rowCounts: {
        'courses': courses.length,
        'assignments': assignments.length,
        'announcements': announcements.length,
        'notification_logs': logs.length,
        'snoozed_items': snoozed.length,
        'hidden_items': hidden.length,
      },
      lastSyncAt: lastSync,
      notificationLogs: logs,
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> forceRefresh() async {
    await ref.read(classroomSyncServiceProvider).forceRefresh();
    await reload();
  }

  Future<void> clearNotificationLogs() async {
    final db = ref.read(appDatabaseProvider);
    await db.delete(db.notificationLogs).go();
    await reload();
  }

  Future<void> clearAllData() async {
    final db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      await db.delete(db.courses).go();
      await db.delete(db.assignments).go();
      await db.delete(db.announcements).go();
      await db.delete(db.notificationLogs).go();
      await db.delete(db.snoozedItems).go();
      await db.delete(db.hiddenItems).go();
      await db.delete(db.syncStates).go();
    });
    await reload();
  }

  Future<void> sendTestNotification() => NotificationService.showTest();
}

final debugViewModelProvider =
    AsyncNotifierProvider<DebugViewModel, DebugState>(DebugViewModel.new);
