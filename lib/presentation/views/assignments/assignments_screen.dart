// lib/presentation/views/assignments/assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../shared/assignment_card.dart';
import '../shared/fake_fixtures.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('課題')),
      body: Column(
        children: [
          _FilterBar(
            filter: async.valueOrNull?.filter ?? AssignmentsFilter.all,
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
        async.valueOrNull?.visibleAssignments ?? FakeFixtures.assignments;
    final state = async.valueOrNull;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(assignmentsViewModelProvider.notifier).refresh(),
      child: Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          key: const PageStorageKey('assignments_list'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            final isHidden = state?.isHidden(assignment.id) ?? false;
            return _AssignmentCard(
              key: ValueKey(assignment.id),
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
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final AssignmentsFilter filter;

  String _label(AssignmentsFilter f) => switch (f) {
        AssignmentsFilter.all => 'すべて',
        AssignmentsFilter.unsubmitted => '未提出',
        AssignmentsFilter.overdue => '期限切れ',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignmentsViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: AssignmentsFilter.values.map((f) {
          final isSelected = f == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isSelected
                ? ShadButton(
                    onPressed: () {},
                    child: Text(_label(f)),
                  )
                : ShadButton.outline(
                    onPressed: () => notifier.setFilter(f),
                    child: Text(_label(f)),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    super.key,
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
        direction: isHidden
            ? DismissDirection.startToEnd
            : DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.25,
          DismissDirection.startToEnd: 0.25,
        },
        background: isHidden
            ? Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.visibility,
                    color: Theme.of(context).colorScheme.primary),
              )
            : Container(color: Colors.transparent),
        secondaryBackground: !isHidden
            ? Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Icon(Icons.visibility_off,
                    color: Theme.of(context).colorScheme.error),
              )
            : Container(color: Colors.transparent),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd && isHidden) {
            onUnhide();
            if (context.mounted) {
              ShadToaster.of(context).show(
                const ShadToast(title: Text('非表示を解除しました')),
              );
            }
          } else if (direction == DismissDirection.endToStart && !isHidden) {
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
            child: AssignmentCard(
              assignment: assignment,
              variant: AssignmentCardVariant.full,
            ),
          ),
        ),
      ),
    );
  }
}

