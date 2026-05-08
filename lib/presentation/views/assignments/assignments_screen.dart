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
            filter: async.valueOrNull?.filter ?? AssignmentsFilter.all,
            showHidden: async.valueOrNull?.showHidden ?? false,
          ),
          Expanded(child: _buildList(context, ref, async)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AssignmentsState> async,
  ) {
    if (async.hasError) {
      return Center(child: Text('エラー: ${async.error}'));
    }
    final isLoading = async.isLoading;
    final assignments =
        async.valueOrNull?.visibleAssignments ?? _fakeAssignments;
    final state = async.valueOrNull;

    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          final isHidden = state?.isHidden(assignment.id) ?? false;
          return _AssignmentCard(
            assignment: assignment,
            isHidden: isHidden,
            onHide: () => ref
                .read(assignmentsViewModelProvider.notifier)
                .hideItem(assignment.id),
            onUnhide: () => ref
                .read(assignmentsViewModelProvider.notifier)
                .unhideItem(assignment.id),
            onUndoHide: () => ref
                .read(assignmentsViewModelProvider.notifier)
                .unhideItem(assignment.id),
          );
        },
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter, required this.showHidden});

  final AssignmentsFilter filter;
  final bool showHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignmentsViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...AssignmentsFilter.values.map((f) {
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
                      onPressed: () => notifier.setFilter(f),
                      child: Text(label),
                    ),
            );
          }),
          const Spacer(),
          ShadButton.ghost(
            onPressed: () => notifier.toggleShowHidden(),
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

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.isHidden,
    required this.onHide,
    required this.onUnhide,
    required this.onUndoHide,
  });

  final Assignment assignment;
  final bool isHidden;
  final VoidCallback onHide;
  final VoidCallback onUnhide;
  final VoidCallback onUndoHide;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isHidden ? 0.4 : 1.0,
      child: Dismissible(
        key: ValueKey('dismiss_${assignment.id}'),
        direction:
            isHidden ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.red.shade100,
          child: const Icon(Icons.visibility_off, color: Colors.red),
        ),
        confirmDismiss: (_) async {
          onHide();
          if (context.mounted) {
            ShadToaster.of(context).show(
              ShadToast(
                title: const Text('課題を非表示にしました'),
                action: ShadButton.outline(
                  onPressed: onUndoHide,
                  child: const Text('元に戻す'),
                ),
              ),
            );
          }
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShadContextMenu(
            items: [
              if (isHidden)
                ShadContextMenuItem(
                  leading: const Icon(Icons.visibility, size: 16),
                  onPressed: onUnhide,
                  child: const Text('非表示を解除'),
                )
              else
                ShadContextMenuItem(
                  leading: const Icon(Icons.visibility_off, size: 16),
                  onPressed: onHide,
                  child: const Text('非表示にする'),
                ),
            ],
            child: _AssignmentCardContent(assignment: assignment),
          ),
        ),
      ),
    );
  }
}

class _AssignmentCardContent extends StatelessWidget {
  const _AssignmentCardContent({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final isSubmitted =
        assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    return ShadCard(
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
                  backgroundColor: Colors.red, child: Text('期限切れ'))
            else if (due != null)
              ShadBadge.outline(
                child: Text('${due.difference(DateTime.now()).inDays}日後'),
              ),
          ],
        ),
      ),
    );
  }
}
