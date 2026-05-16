import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/usecases/can_disable_lazy_mode_usecase.dart';

void main() {
  const uc = CanDisableLazyModeUseCase();
  final now = DateTime(2026, 5, 8, 12, 0);
  const window = Duration(hours: 24);

  Assignment makeAssignment({
    required String id,
    required DateTime dueDate,
    SubmissionState? submissionState,
  }) =>
      Assignment(
        id: id,
        courseId: 'c1',
        title: 'Title',
        dueDate: dueDate,
        submissionState: submissionState,
      );

  test('期限内の未提出課題がある場合はカウント > 0', () {
    final assignments = [
      makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 12))),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 1);
  });

  test('提出済み課題はカウントしない', () {
    final assignments = [
      makeAssignment(
        id: 'a1',
        dueDate: now.add(const Duration(hours: 12)),
        submissionState: SubmissionState.turnedIn,
      ),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 0);
  });

  test('期限外の課題はカウントしない', () {
    final assignments = [
      makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 48))),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 0);
  });

  test('期限なしの課題はカウントしない', () {
    final assignments = [
      const Assignment(id: 'a1', courseId: 'c1', title: 'No due'),
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 0);
  });

  test('混在するケースで正しくカウントする', () {
    final assignments = [
      makeAssignment(id: 'a1', dueDate: now.add(const Duration(hours: 6))),   // blocking
      makeAssignment(id: 'a2', dueDate: now.add(const Duration(hours: 30))),  // outside window
      makeAssignment(
        id: 'a3',
        dueDate: now.add(const Duration(hours: 10)),
        submissionState: SubmissionState.turnedIn,
      ), // submitted
    ];
    final count = uc.countBlockingAssignments(
      assignments: assignments,
      notifyBefore: window,
      now: now,
    );
    expect(count, 1);
  });
}
