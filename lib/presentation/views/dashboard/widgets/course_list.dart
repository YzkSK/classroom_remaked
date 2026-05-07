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

    final courses = async.value!.orderedCourses;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) => ref
          .read(dashboardViewModelProvider.notifier)
          .reorderCourses(oldIndex, newIndex),
      itemCount: courses.length,
      itemBuilder: (context, index) =>
          _CourseCard(key: ValueKey(courses[index].id), course: courses[index]),
    );
  }

  Widget _buildStaticList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) =>
          _CourseCard(key: ValueKey(courses[index].id), course: courses[index]),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({super.key, required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              const Icon(Icons.drag_handle_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
