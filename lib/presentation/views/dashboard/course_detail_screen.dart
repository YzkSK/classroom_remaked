// lib/presentation/views/dashboard/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/entities/announcement.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../../viewmodels/announcements_viewmodel.dart';
import '../shared/assignment_card.dart';
import '../shared/fake_fixtures.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  final String courseId;
  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(courseName),
          bottom: const TabBar(
            tabs: [
              Tab(text: '課題'),
              Tab(text: 'お知らせ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AssignmentsTab(courseId: courseId),
            _AnnouncementsTab(courseId: courseId),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  const _AssignmentsTab({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);
    final isLoading = async.isLoading;

    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }

    final all = async.valueOrNull?.assignments ?? FakeFixtures.courseAssignments;
    final courseAssignments = isLoading
        ? FakeFixtures.courseAssignments
        : all
            .where((a) => a.courseId == courseId)
            .where((a) => !isOverdue(a))
            .toList()
          ..sort((a, b) {
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

    return Skeletonizer(
      enabled: isLoading,
      child: courseAssignments.isEmpty
          ? const Center(child: Text('課題はありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseAssignments.length,
              itemBuilder: (context, index) => AssignmentCard(
                assignment: courseAssignments[index],
                variant: AssignmentCardVariant.compact,
              ),
            ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab({required this.courseId});

  final String courseId;

  static final _fake = List.generate(
    3,
    (i) => Announcement(
      id: 'fake_$i',
      courseId: 'fake',
      text: 'お知らせのサンプルテキストがここに表示されます。',
      creationTime: DateTime.now().subtract(Duration(days: i)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementsViewModelProvider(courseId));

    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }

    final announcements = async.valueOrNull ?? _fake;
    final isLoading = async.isLoading;

    return Skeletonizer(
      enabled: isLoading,
      child: announcements.isEmpty
          ? const Center(child: Text('お知らせはありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final a = announcements[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ShadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy/M/d HH:mm')
                                .format(a.creationTime),
                            style: ShadTheme.of(context).textTheme.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(a.text),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
