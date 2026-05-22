// lib/presentation/views/dashboard/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/drive_file_service.dart';
import '../../../domain/entities/announcement.dart';
import '../../../domain/entities/assignment_material.dart';
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
                return a.isMaterial
                    ? _MaterialCard(item: a)
                    : _AnnouncementCard(item: a);
              },
            ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('yyyy/M/d HH:mm').format(item.creationTime),
                style: ShadTheme.of(context).textTheme.muted,
              ),
              const SizedBox(height: 4),
              Text(item.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialCard extends ConsumerWidget {
  const _MaterialCard({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.library_books_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('資料',
                      style: ShadTheme.of(context)
                          .textTheme
                          .muted
                          .copyWith(
                              color: Theme.of(context).colorScheme.primary)),
                  const Spacer(),
                  Text(
                    DateFormat('yyyy/M/d HH:mm').format(item.creationTime),
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ],
              ),
              if (item.title != null) ...[
                const SizedBox(height: 6),
                Text(item.title!,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
              if (item.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.text),
              ],
              if (item.materials.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...item.materials.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _CourseMaterialTile(material: m),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseMaterialTile extends ConsumerStatefulWidget {
  const _CourseMaterialTile({required this.material});
  final AssignmentMaterial material;

  @override
  ConsumerState<_CourseMaterialTile> createState() =>
      _CourseMaterialTileState();
}

class _CourseMaterialTileState extends ConsumerState<_CourseMaterialTile> {
  bool _isLoading = false;

  IconData get _icon => switch (widget.material.type) {
        AssignmentMaterialType.driveFile => Icons.insert_drive_file_outlined,
        AssignmentMaterialType.youTube => Icons.play_circle_outline,
        AssignmentMaterialType.link => Icons.link,
        AssignmentMaterialType.form => Icons.assignment_outlined,
      };

  Future<void> _open() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final service = ref.read(driveFileServiceProvider);
    try {
      final action = await service.resolveAndOpen(widget.material);
      if (action == DriveOpenAction.inAppPdf &&
          widget.material.driveFileId != null &&
          mounted) {
        context.push(
          '/viewer/${widget.material.driveFileId}'
          '?title=${Uri.encodeComponent(widget.material.title)}',
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('ファイルを開けませんでした'),
            description: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(_icon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.material.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.open_in_new, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
