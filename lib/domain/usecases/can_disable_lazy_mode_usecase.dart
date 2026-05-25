import '../entities/assignment.dart';

class CanDisableLazyModeUseCase {
  const CanDisableLazyModeUseCase();

  int countBlockingAssignments({
    required List<Assignment> assignments,
    required Duration notifyBefore,
    required DateTime now,
  }) {
    final cutoff = now.add(notifyBefore);
    return assignments.where((a) {
      if (a.submissionId == null) return false; // 提出不可能な課題は除外
      if (a.submissionState == SubmissionState.turnedIn) return false;
      if (a.dueDate == null) return false;
      if (!a.dueDate!.isAfter(now)) return false;
      return a.dueDate!.isBefore(cutoff);
    }).length;
  }
}
