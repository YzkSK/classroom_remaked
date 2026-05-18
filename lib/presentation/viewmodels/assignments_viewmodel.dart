// lib/presentation/viewmodels/assignments_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
part 'assignments_viewmodel.g.dart';

bool isOverdue(Assignment a) =>
    a.dueDate != null &&
    a.dueDate!.isBefore(DateTime.now()) &&
    a.submissionState != SubmissionState.turnedIn;

enum AssignmentsFilter { all, unsubmitted, overdue }

class AssignmentsState {
  const AssignmentsState({
    required this.assignments,
    required this.hiddenAssignmentIds,
    this.filter = AssignmentsFilter.all,
  });

  final List<Assignment> assignments;
  final Set<String> hiddenAssignmentIds;
  final AssignmentsFilter filter;

  List<Assignment> get visibleAssignments {
    switch (filter) {
      case AssignmentsFilter.all:
        return assignments.where((a) => !isOverdue(a)).toList();
      case AssignmentsFilter.unsubmitted:
        return assignments
            .where((a) => !isOverdue(a))
            .where((a) => !hiddenAssignmentIds.contains(a.id))
            .where((a) => a.submissionState != SubmissionState.turnedIn)
            .toList();
      case AssignmentsFilter.overdue:
        return assignments.where(isOverdue).toList();
    }
  }

  bool isHidden(String assignmentId) =>
      hiddenAssignmentIds.contains(assignmentId);

  AssignmentsState copyWith({
    List<Assignment>? assignments,
    Set<String>? hiddenAssignmentIds,
    AssignmentsFilter? filter,
  }) =>
      AssignmentsState(
        assignments: assignments ?? this.assignments,
        hiddenAssignmentIds: hiddenAssignmentIds ?? this.hiddenAssignmentIds,
        filter: filter ?? this.filter,
      );
}

@riverpod
class AssignmentsViewModel extends _$AssignmentsViewModel {
  @override
  Future<AssignmentsState> build() async {
    final repo = ref.watch(lmsRepositoryProvider);
    final hiddenDs = ref.watch(hiddenItemsDataSourceProvider);

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

    final hiddenIds = await hiddenDs.getHiddenIds('assignment');

    return AssignmentsState(
      assignments: all,
      hiddenAssignmentIds: hiddenIds,
    );
  }

  void setFilter(AssignmentsFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(classroomSyncServiceProvider).forceRefresh();
    ref.invalidateSelf();
  }

  Future<void> hideItem(String assignmentId) async {
    await ref
        .read(hiddenItemsDataSourceProvider)
        .hide(assignmentId, 'assignment');
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      hiddenAssignmentIds: {...current.hiddenAssignmentIds, assignmentId},
    ));
  }

  Future<void> unhideItem(String assignmentId) async {
    await ref.read(hiddenItemsDataSourceProvider).unhide(assignmentId);
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = Set<String>.from(current.hiddenAssignmentIds)
      ..remove(assignmentId);
    state = AsyncData(current.copyWith(hiddenAssignmentIds: updated));
  }

  void markTurnedIn(String assignmentId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.assignments
        .map((a) => a.id == assignmentId
            ? a.copyWith(submissionState: SubmissionState.turnedIn)
            : a)
        .toList();
    state = AsyncData(current.copyWith(assignments: updated));
  }
}
