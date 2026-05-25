// lib/core/services/background_notification_task.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/error_log_datasource.dart';
import '../../data/datasources/local/notification_logs_datasource.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';
import '../../data/repositories/google_classroom_repository.dart';
import '../../domain/entities/assignment.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';
import 'widget_data_service.dart';

const notificationTaskName = 'checkDeadlines';
const notificationTaskUniqueName = 'notificationTask';

class BackgroundNotificationTask {
  const BackgroundNotificationTask();

  Future<bool> execute(AppDatabase db, {GoogleSignInAccount? account}) async {
    final errorDs = ErrorLogDataSource(db);

    // Step 1: Classroom API から同期して新着課題を通知
    if (account != null) {
      try {
        await _syncAndNotifyNew(db, account, errorDs);
      } catch (e, st) {
        await errorDs.add(
          source: 'BackgroundSync',
          message: '$e',
          stackTrace: st.toString(),
        );
      }
    }

    // Step 2: 締め切り通知（既存ロジック）
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

    final courseRows = await db.select(db.courses).get();
    final teacherCourseIds =
        courseRows.where((c) => c.role == 'teacher').map((c) => c.id).toSet();

    // 提出済み課題の通知ログ・スヌーズをクリーンアップ
    for (final r in rows.where((r) => r.submissionState == 'turnedIn')) {
      await logsDs.delete(r.id);
      await snoozeDs.delete(r.id);
    }

    final assignments = rows
        .where((r) =>
            r.state == 'published' &&
            r.submissionState != 'turnedIn' &&
            r.dueDateMillis != null &&
            !teacherCourseIds.contains(r.courseId))
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
      try {
        await notifService.show(assignment);
        await logsDs.log(assignment.id);
        await snoozeDs.upsert(assignment.id, now.add(snooze));
      } catch (e, st) {
        await errorDs.add(
          source: 'BackgroundNotificationTask',
          message: '通知送信失敗: ${assignment.title} — $e',
          stackTrace: st.toString(),
        );
      }
    }

    await const WidgetDataService().updateWidget(db);

    return true;
  }

  Future<void> _syncAndNotifyNew(
    AppDatabase db,
    GoogleSignInAccount account,
    ErrorLogDataSource errorDs,
  ) async {
    // 同期前のIDセットを記録
    final knownIds =
        (await db.select(db.assignments).get()).map((r) => r.id).toSet();

    final repo = GoogleClassroomRepository(database: db, account: account);

    // コースを同期
    final coursesResult = await repo.refreshCourses();
    final courses = coursesResult.getOrElse(() => []);
    if (courses.isEmpty) return;

    // コースIDとコース名のマップ
    final courseNameMap = {for (final c in courses) c.id: c.name};

    // 全コースの課題を同期
    await Future.wait(courses.map((c) => repo.refreshAssignments(c.id)));

    // 同期後のIDセットと差分を求める
    final allRows = await db.select(db.assignments).get();
    final newRows = allRows.where((r) => !knownIds.contains(r.id)).toList();

    for (final row in newRows) {
      // 提出不要・非公開・期限なし課題は除外
      if (row.state != 'published') continue;
      final courseName = courseNameMap[row.courseId] ?? row.courseId;
      try {
        await NotificationService.showNewAssignment(
          assignmentId: row.id,
          title: row.title,
          courseName: courseName,
        );
      } catch (e, st) {
        await errorDs.add(
          source: 'BackgroundSync.showNewAssignment',
          message: '新着通知送信失敗: ${row.title} — $e',
          stackTrace: st.toString(),
        );
      }
    }
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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.initialize();

    // サイレントサインインで OAuth トークンを取得
    GoogleSignInAccount? account;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '184568296872-7079toktlo42fe5etcbke4mkue9l7ua7.apps.googleusercontent.com',
      );
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future != null) account = await future;
    } catch (_) {
      // サインインできなければ同期なしで締め切り通知のみ実行
    }

    final db = await AppDatabase.openBackground();
    try {
      return await const BackgroundNotificationTask().execute(db, account: account);
    } finally {
      await db.close();
    }
  });
}
