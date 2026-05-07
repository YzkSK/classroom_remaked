// lib/presentation/views/dashboard/widgets/deadline_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../domain/entities/assignment.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';

class DeadlineWidget extends ConsumerWidget {
  const DeadlineWidget({super.key});

  static final _fakeDeadlines = List.generate(
    3,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Sample Assignment Title',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardViewModelProvider);
    final isLoading = async.isLoading;
    final deadlines =
        async.valueOrNull?.upcomingDeadlines ?? _fakeDeadlines;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('直近の締め切り（7日以内）',
              style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 8),
          if (!isLoading && deadlines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('締め切りが近い課題はありません'),
            )
          else
            Skeletonizer(
              enabled: isLoading,
              child: Column(
                children:
                    deadlines.map((a) => _DeadlineTile(assignment: a)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final daysLeft = due?.difference(DateTime.now()).inDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(assignment.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (due != null)
              ShadBadge(
                backgroundColor:
                    daysLeft != null && daysLeft <= 1 ? Colors.red : null,
                child: Text(DateFormat('M/d').format(due)),
              ),
          ],
        ),
      ),
    );
  }
}
