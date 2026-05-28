// lib/presentation/viewmodels/debug_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/error_log_datasource.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';

class DebugState {
  const DebugState({
    required this.schemaVersion,
    required this.rowCounts,
    required this.lastSyncAt,
    required this.lastBgSyncAt,
    required this.notificationLogs,
    required this.lazyModeEnabled,
    required this.lazyModeBlockingCount,
    required this.notifyBeforeHours,
    required this.errorLogs,
  });

  final int schemaVersion;
  final Map<String, int> rowCounts;
  final String? lastSyncAt;
  final String? lastBgSyncAt;
  final List<NotificationLogRow> notificationLogs;
  final bool lazyModeEnabled;
  final int lazyModeBlockingCount;
  final int notifyBeforeHours;
  final List<ErrorLogEntry> errorLogs;
}

class DebugViewModel extends AsyncNotifier<DebugState> {
  @override
  Future<DebugState> build() => _load();

  Future<DebugState> _load() async {
    final db = ref.read(appDatabaseProvider);
    final syncDs = ref.read(syncStateDataSourceProvider);
    final prefsDs = UserPreferencesDataSource(db);
    final errorDs = ErrorLogDataSource(db);

    final courses = await db.select(db.courses).get();
    final assignments = await db.select(db.assignments).get();
    final announcements = await db.select(db.announcements).get();
    final logs = await db.select(db.notificationLogs).get()
      ..sort((a, b) => b.notifiedAt.compareTo(a.notifiedAt));
    final snoozed = await db.select(db.snoozedItems).get();
    final hidden = await db.select(db.hiddenItems).get();

    final lastSync = await syncDs.get('last_sync_at');
    final lastBgSync = await syncDs.get('last_bg_sync_at');
    final lazyMode = await prefsDs.getLazyModeEnabled();
    final notifyBeforeHours = await prefsDs.getNotifyBeforeHours();
    final errorLogs = await errorDs.getAll();

    // 怠惰モードのブロック対象数（CanDisableLazyModeUseCaseと同条件）
    final cutoff = DateTime.now().add(Duration(hours: notifyBeforeHours));
    final blockingCount = assignments.where((r) {
      if (r.submissionId == null) return false;
      if (r.submissionState == 'turnedIn') return false;
      if (r.dueDateMillis == null) return false;
      final due = DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!);
      return due.isAfter(DateTime.now()) && due.isBefore(cutoff);
    }).length;

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
      lastBgSyncAt: lastBgSync,
      notificationLogs: logs,
      lazyModeEnabled: lazyMode,
      lazyModeBlockingCount: blockingCount,
      notifyBeforeHours: notifyBeforeHours,
      errorLogs: errorLogs,
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

  Future<void> clearErrorLogs() async {
    await ErrorLogDataSource(ref.read(appDatabaseProvider)).clear();
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

  Future<void> pollNow({required bool asTeacher}) =>
      ref.read(backendServiceProvider).debugPollNow(asTeacher: asTeacher);
}

final debugViewModelProvider =
    AsyncNotifierProvider<DebugViewModel, DebugState>(DebugViewModel.new);
