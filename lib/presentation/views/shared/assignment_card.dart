// lib/presentation/views/shared/assignment_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/assignment.dart';

enum AssignmentCardVariant {
  /// フル版：バッジあり（課題一覧で使用）
  full,

  /// コンパクト版：提出バッジのみ（コース詳細で使用）
  compact,

  /// 検索版：バッジなし（検索画面で使用）
  search,

  /// タイル版：横並び + 日付バッジ（ダッシュボードで使用）
  tile,
}

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.assignment,
    this.variant = AssignmentCardVariant.full,
  });

  final Assignment assignment;
  final AssignmentCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.go('/assignments/${assignment.id}'),
        child: variant == AssignmentCardVariant.tile
            ? _TileContent(assignment: assignment)
            : _CardContent(assignment: assignment, variant: variant),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.assignment, required this.variant});

  final Assignment assignment;
  final AssignmentCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final isSubmitted = assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    Widget? badge;
    if (variant == AssignmentCardVariant.full ||
        variant == AssignmentCardVariant.compact) {
      if (isSubmitted) {
        badge = const ShadBadge.secondary(child: Text('提出済み'));
      } else if (isOverdue && variant == AssignmentCardVariant.full) {
        badge = ShadBadge(
          backgroundColor: Theme.of(context).colorScheme.error,
          child: const Text('期限切れ'),
        );
      } else if (due != null && variant == AssignmentCardVariant.full) {
        badge = ShadBadge.outline(child: Text(_dueBadgeLabel(due)));
      }
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(assignment.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (due != null)
          Text(
            '締め切り: ${DateFormat('yyyy/M/d HH:mm').format(due)}',
            style: ShadTheme.of(context).textTheme.muted,
          ),
      ],
    );

    if (badge == null) {
      return ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      );
    }

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: content),
            const SizedBox(width: 8),
            badge,
          ],
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    final daysLeft = due?.difference(DateTime.now()).inDays;

    return ShadCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(assignment.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (due != null)
            ShadBadge(
              backgroundColor: daysLeft != null && daysLeft <= 1
                  ? Theme.of(context).colorScheme.error
                  : null,
              child: Text(DateFormat('M/d HH:mm').format(due)),
            ),
        ],
      ),
    );
  }
}

String _dueBadgeLabel(DateTime due) {
  final diff = due.difference(DateTime.now());
  if (diff.inHours < 24) return '今日 ${DateFormat('HH:mm').format(due)}';
  if (diff.inHours < 48) return '明日 ${DateFormat('HH:mm').format(due)}';
  return '${diff.inDays}日後';
}
