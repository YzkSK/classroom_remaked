// lib/presentation/viewmodels/assignments_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
part 'assignments_viewmodel.g.dart';

enum AssignmentsFilter { all, unsubmitted }

class AssignmentsState {
  const AssignmentsState({
    required this.assignments,
    this.filter = AssignmentsFilter.all,
  });

  final List<Assignment> assignments;
  final AssignmentsFilter filter;

  List<Assignment> get filteredAssignments {
    if (filter == AssignmentsFilter.all) return assignments;
    return assignments
        .where((a) => a.submissionState != SubmissionState.turnedIn)
        .toList();
  }

  AssignmentsState copyWith(
          {List<Assignment>? assignments, AssignmentsFilter? filter}) =>
      AssignmentsState(
        assignments: assignments ?? this.assignments,
        filter: filter ?? this.filter,
      );
}

@riverpod
class AssignmentsViewModel extends _$AssignmentsViewModel {
  @override
  Future<AssignmentsState> build() async {
    final repo = ref.watch(lmsRepositoryProvider);
    final coursesResult = await repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);

    final results =
        await Future.wait(courses.map((c) => repo.getAssignments(c.id)));

    final all = results
        .expand((r) => r.getOrElse(() => []))
        .where((a) => a.state == AssignmentState.published)
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    return AssignmentsState(assignments: all);
  }

  void setFilter(AssignmentsFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }
}
