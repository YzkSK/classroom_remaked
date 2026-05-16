// lib/presentation/views/assignments/assignment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignmentsViewModelProvider);
    final assignment = async.valueOrNull?.assignments
        .where((a) => a.id == assignmentId)
        .firstOrNull;

    if (async.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('課題が見つかりません')),
      );
    }

    final due = assignment.dueDate;
    final isSubmitted = assignment.submissionState == SubmissionState.turnedIn;
    final isOverdue =
        due != null && due.isBefore(DateTime.now()) && !isSubmitted;

    return Scaffold(
      appBar: AppBar(title: const Text('課題詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(assignment.title,
              style: ShadTheme.of(context).textTheme.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(
                due != null
                    ? DateFormat('yyyy年M月d日 HH:mm').format(due)
                    : '締め切りなし',
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isSubmitted)
            const ShadBadge.secondary(child: Text('提出済み'))
          else if (isOverdue)
            const ShadBadge(
                backgroundColor: Colors.red, child: Text('期限切れ'))
          else if (due != null)
            ShadBadge.outline(
              child: Text(
                  '締め切りまで${due.difference(DateTime.now()).inDays}日'),
            ),
          if (assignment.description != null) ...[
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            Text('説明', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            Text(assignment.description!),
          ],
        ],
      ),
    );
  }
}
