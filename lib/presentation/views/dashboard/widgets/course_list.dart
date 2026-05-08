// lib/presentation/views/dashboard/widgets/course_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../domain/entities/course.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';

class CourseList extends ConsumerWidget {
  const CourseList({super.key});

  static final _fakeCourses = List.generate(
    4,
    (i) => Course(id: 'fake_$i', name: 'Course Name Example'),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardViewModelProvider);

    if (async.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: _buildStaticList(context, _fakeCourses),
      );
    }

    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }

    final dashState = async.value!;
    final courses = dashState.visibleCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HiddenToggleRow(),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) => ref
              .read(dashboardViewModelProvider.notifier)
              .reorderCourses(oldIndex, newIndex),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final isHidden = dashState.isHidden(course.id);
            return _CourseCard(
              key: ValueKey(course.id),
              course: course,
              isHidden: isHidden,
              index: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStaticList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) => _CourseCard(
        key: ValueKey(courses[index].id),
        course: courses[index],
        isHidden: false,
        index: index,
      ),
    );
  }
}

class _HiddenToggleRow extends ConsumerWidget {
  const _HiddenToggleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHidden =
        ref.watch(dashboardViewModelProvider).valueOrNull?.showHidden ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadButton.ghost(
            onPressed: () => ref
                .read(dashboardViewModelProvider.notifier)
                .toggleShowHidden(),
            child: Row(
              children: [
                Icon(
                  showHidden ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(showHidden ? '非表示を隠す' : '非表示も表示'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({
    super.key,
    required this.course,
    required this.isHidden,
    required this.index,
  });

  final Course course;
  final bool isHidden;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);

    return Opacity(
      opacity: isHidden ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ShadContextMenu(
          items: [
            if (isHidden)
              ShadContextMenuItem(
                leading: const Icon(Icons.visibility, size: 16),
                onPressed: () => notifier.unhideItem(course.id),
                child: const Text('非表示を解除'),
              )
            else
              ShadContextMenuItem(
                leading: const Icon(Icons.visibility_off, size: 16),
                onPressed: () => notifier.hideItem(course.id),
                child: const Text('非表示にする'),
              ),
          ],
          child: ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (course.section != null)
                          Text(course.section!,
                              style: ShadTheme.of(context).textTheme.muted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
