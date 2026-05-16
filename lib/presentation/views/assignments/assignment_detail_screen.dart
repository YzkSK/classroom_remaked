// lib/presentation/views/assignments/assignment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/drive_file_service.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../../viewmodels/turn_in_viewmodel.dart';

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

          // ── 説明 ──────────────────────────────────────
          if (assignment.description != null) ...[
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            Text('説明', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            Text(assignment.description!),
          ],

          // ── 添付ファイル ───────────────────────────────
          if (assignment.materials.isNotEmpty) ...[
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            Text('添付ファイル', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            ...assignment.materials.map(
              (m) => _MaterialTile(material: m),
            ),
          ],

          // ── 提出ボタン ─────────────────────────────────
          if (!isSubmitted && assignment.submissionId != null) ...[
            const SizedBox(height: 32),
            _TurnInButton(assignment: assignment),
          ],
        ],
      ),
    );
  }
}

class _MaterialTile extends ConsumerWidget {
  const _MaterialTile({required this.material});

  final AssignmentMaterial material;

  IconData get _icon => switch (material.type) {
        AssignmentMaterialType.driveFile => Icons.insert_drive_file_outlined,
        AssignmentMaterialType.youTube => Icons.play_circle_outline,
        AssignmentMaterialType.link => Icons.link,
        AssignmentMaterialType.form => Icons.assignment_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: InkWell(
          onTap: () async {
            final service = ref.read(driveFileServiceProvider);
            try {
              final action = await service.resolveAndOpen(material);
              if (action == DriveOpenAction.inAppPdf &&
                  material.driveFileId != null &&
                  context.mounted) {
                context.push(
                  '/viewer/${material.driveFileId}'
                  '?title=${Uri.encodeComponent(material.title)}',
                );
              }
            } on DriveVirusScanWarningException catch (e) {
              if (!context.mounted) return;
              final confirmed = await showShadDialog<bool>(
                context: context,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadDialog.alert(
                    radius: const BorderRadius.all(Radius.circular(12)),
                    removeBorderRadiusWhenTiny: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    useSafeArea: false,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    titleTextAlign: TextAlign.center,
                    title: const Text('ウイルススキャン不可'),
                    description: const Text(
                        'このファイルはウイルススキャンができませんでした。自己責任でダウンロードしますか？'),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      ShadButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('ダウンロード'),
                      ),
                    ],
                  ),
                ),
              );
              if (confirmed == true && context.mounted) {
                try {
                  await service.openWithAcknowledge(e);
                } on Exception catch (err) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('ダウンロードに失敗しました'),
                        description: Text(err.toString()),
                      ),
                    );
                  }
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.open_in_new, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnInButton extends ConsumerWidget {
  const _TurnInButton({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(turnInViewModelProvider).isLoading;

    return ShadButton(
      width: double.infinity,
      onPressed: isLoading
          ? null
          : () async {
              final confirmed = await showShadDialog<bool>(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadDialog.alert(
                    radius: const BorderRadius.all(Radius.circular(12)),
                    removeBorderRadiusWhenTiny: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    useSafeArea: false,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    titleTextAlign: TextAlign.center,
                    title: const Text('課題を提出しますか？'),
                    description: const Text('提出後は取り消せません。'),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      ShadButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('提出する'),
                      ),
                    ],
                  ),
                ),
              );
              if (confirmed == true && context.mounted) {
                final result = await ref
                    .read(turnInViewModelProvider.notifier)
                    .turnIn(
                      assignment.courseId,
                      assignment.id,
                      assignment.submissionId!,
                    );
                if (!context.mounted) return;
                result.fold(
                  (failure) => ShadToaster.of(context).show(
                    ShadToast.destructive(
                      title: const Text('提出に失敗しました'),
                      description: Text(failure.message),
                    ),
                  ),
                  (_) {
                    ShadToaster.of(context).show(
                      const ShadToast(title: Text('提出しました')),
                    );
                    ref.invalidate(assignmentsViewModelProvider);
                  },
                );
              }
            },
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('提出する'),
    );
  }
}
