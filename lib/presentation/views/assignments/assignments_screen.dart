// lib/presentation/views/assignments/assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class _AssignmentCard extends StatefulWidget {
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
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  double _offset = 0;

  static const double _threshold = 0.25;

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isHidden)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('非表示を解除'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onUnhide();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('非表示にする'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onHide();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final w = MediaQuery.of(context).size.width;
    setState(() {
      _offset += d.delta.dx;
      _offset = widget.isHidden
          ? _offset.clamp(0.0, w)   // 非表示→右スワイプのみ
          : _offset.clamp(-w, 0.0); // 通常→左スワイプのみ
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final threshold = MediaQuery.of(context).size.width * _threshold;
    if (_offset.abs() >= threshold) {
      if (!widget.isHidden) {
        widget.onHide();
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('課題を非表示にしました'),
            action: ShadButton.outline(
              onPressed: widget.onUndoHide,
              child: const Text('元に戻す'),
            ),
          ),
        );
      } else {
        widget.onUnhide();
        ShadToaster.of(context).show(
          const ShadToast(title: Text('非表示を解除しました')),
        );
      }
    }
    setState(() => _offset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final draggingLeft = _offset < 0;
    final draggingRight = _offset > 0;

    return Opacity(
      opacity: widget.isHidden ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: () => context.go('/assignments/${widget.assignment.id}'),
        onLongPress: _showMenu,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            // 背景色（カードの下に描画）
            if (draggingLeft)
              Positioned.fill(
                child: Container(
                    color: Theme.of(context).colorScheme.errorContainer),
              ),
            if (draggingRight)
              Positioned.fill(
                child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer),
              ),
            // カード本体（スライド）
            Transform.translate(
              offset: Offset(_offset, 0),
              child: AssignmentCard(
                assignment: widget.assignment,
                variant: AssignmentCardVariant.full,
                onTap: null,
              ),
            ),
            // アイコン（カードの上に描画 → 必ず見える）
            if (draggingLeft)
              Positioned(
                right: 20,
                top: 0,
                bottom: 8,
                child: Center(
                  child: Icon(Icons.visibility_off, size: 28,
                      color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (draggingRight)
              Positioned(
                left: 20,
                top: 0,
                bottom: 8,
                child: Center(
                  child: Icon(Icons.visibility, size: 28,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

