// lib/presentation/viewmodels/dashboard_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/course.dart';
part 'dashboard_viewmodel.g.dart';

class DashboardState {
  const DashboardState({
    required this.courses,
    required this.hiddenCourseIds,
    required this.orderedCourseIds,
    required this.upcomingDeadlines,
    this.showHidden = false,
  });

  final List<Course> courses;
  final Set<String> hiddenCourseIds;
  final List<String> orderedCourseIds;
  final List<Assignment> upcomingDeadlines;
  final bool showHidden;

  List<Course> get _orderedCourses {
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

  List<Course> get visibleCourses {
    if (showHidden) return _orderedCourses;
    return _orderedCourses
        .where((c) => !hiddenCourseIds.contains(c.id))
        .toList();
  }

  bool isHidden(String courseId) => hiddenCourseIds.contains(courseId);

  DashboardState copyWith({
    List<Course>? courses,
    Set<String>? hiddenCourseIds,
    List<String>? orderedCourseIds,
    List<Assignment>? upcomingDeadlines,
    bool? showHidden,
  }) =>
      DashboardState(
        courses: courses ?? this.courses,
        hiddenCourseIds: hiddenCourseIds ?? this.hiddenCourseIds,
        orderedCourseIds: orderedCourseIds ?? this.orderedCourseIds,
        upcomingDeadlines: upcomingDeadlines ?? this.upcomingDeadlines,
        showHidden: showHidden ?? this.showHidden,
      );
}

@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  Future<DashboardState> build() async {
    final sync = ref.watch(classroomSyncServiceProvider);
    final repo = ref.watch(lmsRepositoryProvider);
    final orderDs = ref.watch(courseOrderDataSourceProvider);
    final hiddenDs = ref.watch(hiddenItemsDataSourceProvider);

    await sync.fullSync();

    final coursesResult = await repo.getCourses();
    final deadlinesResult =
        await repo.getUpcomingDeadlines(within: const Duration(days: 7));

    final courses = coursesResult.getOrElse(() => []);
    final deadlines = deadlinesResult.getOrElse(() => []);

    await orderDs.initializeNewCourses(courses.map((c) => c.id).toList());
    final orderedIds = await orderDs.getOrderedIds();
    final hiddenIds = await hiddenDs.getHiddenIds('course');

    return DashboardState(
      courses: courses,
      hiddenCourseIds: hiddenIds,
      orderedCourseIds: orderedIds,
      upcomingDeadlines: deadlines,
    );
  }

  Future<void> reorderCourses(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final ids =
        List<String>.from(current.visibleCourses.map((c) => c.id));
    if (newIndex > oldIndex) newIndex--;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);

    await ref.read(courseOrderDataSourceProvider).updateOrder(ids);
    state = AsyncData(current.copyWith(orderedCourseIds: ids));
  }

  Future<void> hideItem(String courseId) async {
    await ref.read(hiddenItemsDataSourceProvider).hide(courseId, 'course');
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      hiddenCourseIds: {...current.hiddenCourseIds, courseId},
    ));
  }

  Future<void> unhideItem(String courseId) async {
    await ref.read(hiddenItemsDataSourceProvider).unhide(courseId);
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = Set<String>.from(current.hiddenCourseIds)
      ..remove(courseId);
    state = AsyncData(current.copyWith(hiddenCourseIds: updated));
  }

  void toggleShowHidden() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(showHidden: !current.showHidden));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(classroomSyncServiceProvider).forceRefresh();
    ref.invalidateSelf();
  }
}
