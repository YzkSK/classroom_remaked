// lib/presentation/views/assignments/assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  static final _fakeAssignments = List.generate(
    5,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Assignment Title Example Long',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('課題')),
      body: Column(
        children: [
          _FilterBar(
              filter:
                  async.valueOrNull?.filter ?? AssignmentsFilter.all),
          Expanded(child: _buildList(async)),
        ],
      ),
    );
  }

  Widget _buildList(AsyncValue<AssignmentsState> async) {
    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }
    final isLoading = async.isLoading;
    final assignments =
        async.valueOrNull?.filteredAssignments ?? _fakeAssignments;

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: assignments.length,
        itemBuilder: (context, index) =>
            _AssignmentCard(assignment: assignments[index]),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});
  final AssignmentsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: AssignmentsFilter.values.map((f) {
          final isSelected = f == filter;
          final label =
              f == AssignmentsFilter.all ? 'すべて' : '未提出';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isSelected
                ? ShadButton(
                    onPressed: () {},
                    child: Text(label),
                  )
                : ShadButton.outline(
                    onPressed: () => ref
                        .read(assignmentsViewModelProvider.notifier)
                        .setFilter(f),
                    child: Text(label),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final isSubmitted =
        assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (due != null)
                      Text(
                        '締め切り: ${DateFormat('yyyy/M/d HH:mm').format(due)}',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSubmitted)
                const ShadBadge.secondary(child: Text('提出済み'))
              else if (isOverdue)
                const ShadBadge(
                    backgroundColor: Colors.red,
                    child: Text('期限切れ'))
              else if (due != null)
                ShadBadge.outline(
                  child: Text(
                      '${due.difference(DateTime.now()).inDays}日後'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
