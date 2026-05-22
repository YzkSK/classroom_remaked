// lib/core/services/background_notification_task.dart
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/notification_logs_datasource.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';
import '../../domain/entities/assignment.dart';
import 'notification_service.dart';

const notificationTaskName = 'checkDeadlines';
const notificationTaskUniqueName = 'notificationTask';

class BackgroundNotificationTask {
  const BackgroundNotificationTask();

  Future<bool> execute(AppDatabase db) async {
    final now = DateTime.now();

    final prefsDs = UserPreferencesDataSource(db);
    final logsDs = NotificationLogsDataSource(db);
    final snoozeDs = SnoozedItemsDataSource(db);

    final notifyBeforeHours = await prefsDs.getNotifyBeforeHours();
    final lazyMode = await prefsDs.getLazyModeEnabled();
    final configuredSnooze = await prefsDs.getSnoozeHours();
    final snooze = Duration(hours: lazyMode ? 1 : configuredSnooze);
    final notifyBefore = Duration(hours: notifyBeforeHours);

    final rows = await db.select(db.assignments).get();
    final assignments = rows
        .where((r) =>
            r.state == 'published' &&
            r.submissionState != 'TURNED_IN' &&
            r.dueDateMillis != null)
        .map((r) => Assignment(
              id: r.id,
              courseId: r.courseId,
              title: r.title,
              dueDate: DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!),
            ))
        .toList();

    final notifiedIds = await logsDs.getLoggedIds();
    final snoozedUntilMap = await snoozeDs.getActiveSnoozed(now);
    final expiredSnoozeIds = await snoozeDs.getExpiredIds(now);

    final candidates = filterCandidates(
      assignments: assignments,
      notifiedIds: notifiedIds,
      snoozedUntilMap: snoozedUntilMap,
      expiredSnoozeIds: expiredSnoozeIds,
      notifyBefore: notifyBefore,
      now: now,
    );

    for (final id in expiredSnoozeIds) {
      if (candidates.any((a) => a.id == id)) {
        await snoozeDs.delete(id);
      }
    }

    const notifService = NotificationService();
    for (final assignment in candidates) {
      await notifService.show(assignment);
      await logsDs.log(assignment.id);
      await snoozeDs.upsert(assignment.id, now.add(snooze));
    }

    return true;
  }

  static List<Assignment> filterCandidates({
    required List<Assignment> assignments,
    required Set<String> notifiedIds,
    required Map<String, DateTime> snoozedUntilMap,
    required Set<String> expiredSnoozeIds,
    required Duration notifyBefore,
    required DateTime now,
  }) {
    final cutoff = now.add(notifyBefore);
    return assignments.where((a) {
      if (a.submissionState == SubmissionState.turnedIn) return false;
      if (a.dueDate == null) return false;
      if (!a.dueDate!.isAfter(now)) return false;
      if (!a.dueDate!.isBefore(cutoff)) return false;

      // アクティブなスヌーズ中 → 候補外
      if (snoozedUntilMap.containsKey(a.id)) return false;

      // スヌーズ期限切れ → 再通知候補
      if (expiredSnoozeIds.contains(a.id)) return true;

      // 通知済みでスヌーズ記録なし → 候補外
      if (notifiedIds.contains(a.id)) return false;

      return true;
    }).toList();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.initialize();
    final db = await AppDatabase.openBackground();
    try {
      return await const BackgroundNotificationTask().execute(db);
    } finally {
      await db.close();
    }
  });
}
