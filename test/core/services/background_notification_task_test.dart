// test/core/services/background_notification_task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/core/services/background_notification_task.dart';

void main() {
  final now = DateTime(2026, 5, 8, 12, 0);
  const window = Duration(hours: 24);

  Assignment makeAssignment({
    required String id,
    DateTime? dueDate,
    SubmissionState? submissionState,
  }) =>
      Assignment(
        id: id,
        courseId: 'c1',
        title: id,
        dueDate: dueDate,
        submissionState: submissionState,
      );

  test('期限内の未提出課題が候補になる', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result.map((a) => a.id), ['a1']);
  });

  test('期限外の課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 48))),
      ],
      notifiedIds: {},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('提出済み課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(
          id: 'a1',
          dueDate: now.add(const Duration(hours: 12)),
          submissionState: SubmissionState.turnedIn,
        ),
      ],
      notifiedIds: {},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('通知済みでスヌーズなしの課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('アクティブなスヌーズ中の課題は候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {'a1': now.add(const Duration(hours: 1))},
      expiredSnoozeIds: {},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });

  test('スヌーズ期限切れの課題は再通知候補になる', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {},
      expiredSnoozeIds: {'a1'},
      notifyBefore: window,
      now: now,
    );
    expect(result.map((a) => a.id), ['a1']);
  });

  test('期限切れ済みの課題はスヌーズ期限切れでも候補にならない', () {
    final result = BackgroundNotificationTask.filterCandidates(
      assignments: [
        makeAssignment(id: 'a1', dueDate: now.subtract(const Duration(hours: 1))),
      ],
      notifiedIds: {'a1'},
      snoozedUntilMap: {},
      expiredSnoozeIds: {'a1'},
      notifyBefore: window,
      now: now,
    );
    expect(result, isEmpty);
  });
}
