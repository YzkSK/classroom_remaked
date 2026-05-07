// lib/presentation/viewmodels/dashboard_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/course.dart';
part 'dashboard_viewmodel.g.dart';

class DashboardState {
  const DashboardState({
    required this.courses,
    required this.orderedCourseIds,
    required this.upcomingDeadlines,
  });

  final List<Course> courses;
  final List<String> orderedCourseIds;
  final List<Assignment> upcomingDeadlines;

  List<Course> get orderedCourses {
    if (orderedCourseIds.isEmpty) return courses;
    final map = {for (final c in courses) c.id: c};
    final ordered = orderedCourseIds
        .map((id) => map[id])
        .whereType<Course>()
        .toList();
    final orderedSet = orderedCourseIds.toSet();
    final rest = courses.where((c) => !orderedSet.contains(c.id));
    return [...ordered, ...rest];
  }

  DashboardState copyWith({
    List<Course>? courses,
    List<String>? orderedCourseIds,
    List<Assignment>? upcomingDeadlines,
  }) =>
      DashboardState(
        courses: courses ?? this.courses,
        orderedCourseIds: orderedCourseIds ?? this.orderedCourseIds,
        upcomingDeadlines: upcomingDeadlines ?? this.upcomingDeadlines,
      );
}

@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  Future<DashboardState> build() async {
    final sync = ref.watch(classroomSyncServiceProvider);
    final repo = ref.watch(lmsRepositoryProvider);
    final orderDs = ref.watch(courseOrderDataSourceProvider);

    await sync.fullSync();

    final coursesResult = await repo.getCourses();
    final deadlinesResult =
        await repo.getUpcomingDeadlines(within: const Duration(days: 7));

    final courses = coursesResult.getOrElse(() => []);
    final deadlines = deadlinesResult.getOrElse(() => []);

    await orderDs.initializeNewCourses(courses.map((c) => c.id).toList());
    final orderedIds = await orderDs.getOrderedIds();

    return DashboardState(
      courses: courses,
      orderedCourseIds: orderedIds,
      upcomingDeadlines: deadlines,
    );
  }

  Future<void> reorderCourses(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final ids = List<String>.from(current.orderedCourses.map((c) => c.id));
    if (newIndex > oldIndex) newIndex--;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);

    await ref.read(courseOrderDataSourceProvider).updateOrder(ids);
    state = AsyncData(current.copyWith(orderedCourseIds: ids));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(classroomSyncServiceProvider).forceRefresh();
    ref.invalidateSelf();
  }
}
