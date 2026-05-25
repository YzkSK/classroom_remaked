// lib/presentation/views/dashboard/widgets/deadline_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../shared/assignment_card.dart';
import '../../shared/fake_fixtures.dart';

class DeadlineWidget extends ConsumerWidget {
  const DeadlineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardViewModelProvider);
    final isLoading = async.isLoading;
    final deadlines =
        async.valueOrNull?.upcomingDeadlines ?? FakeFixtures.deadlines;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('直近の締め切り（7日以内）',
              style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 8),
          if (!isLoading && deadlines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    '7日以内に締め切りの課題はありません',
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ],
              ),
            )
          else
            Skeletonizer(
              enabled: isLoading,
              child: Column(
                children: deadlines
                    .map((a) => AssignmentCard(
                          assignment: a,
                          variant: AssignmentCardVariant.tile,
                          onTap: () => context.push('/assignments/${a.id}'),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
