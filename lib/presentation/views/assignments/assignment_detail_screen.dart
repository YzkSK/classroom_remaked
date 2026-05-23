// lib/presentation/views/assignments/assignment_detail_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

    final hasSubmit = !isSubmitted && assignment.submissionId != null;
    final hasSubmitted = isSubmitted && assignment.submissionId != null;

    return Scaffold(
      appBar: AppBar(
          title: Text(assignment.title,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
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
            ShadBadge(
                backgroundColor: Theme.of(context).colorScheme.error,
                child: const Text('期限切れ'))
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

          // ── 添付ファイル（教師から） ────────────────────
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

          // ── 提出済みセクション ──────────────────────────
          if (hasSubmitted) ...[
            const SizedBox(height: 32),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 16),
            _SubmittedSection(assignment: assignment),
          ],

        ],
      ),
      // ── 提出パネル（下部固定） ────────────────────────
      bottomNavigationBar: hasSubmit
          ? _SubmitBottomPanel(assignment: assignment)
          : null,
    );
  }
}

/// 提出済み：添付ファイル一覧 + 取り消しボタン
class _SubmittedSection extends ConsumerWidget {
  const _SubmittedSection({required this.assignment});
  final Assignment assignment;

  Future<void> _reclaim(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: ShadDialog.alert(
          radius: const BorderRadius.all(Radius.circular(12)),
          removeBorderRadiusWhenTiny: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          useSafeArea: false,
          crossAxisAlignment: CrossAxisAlignment.center,
          titleTextAlign: TextAlign.center,
          title: const Text('提出を取り消しますか？'),
          description: const Text('取り消し後は再提出できます。'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            ShadButton.destructive(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('取り消す'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(turnInViewModelProvider.notifier).reclaim(
          assignment.courseId,
          assignment.id,
          assignment.submissionId!,
        );

    if (!context.mounted) return;
    result.fold(
      (failure) => ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('取り消しに失敗しました'),
          description: Text(failure.message),
        ),
      ),
      (_) {
        ShadToaster.of(context)
            .show(const ShadToast(title: Text('提出を取り消しました')));
        ref
            .read(assignmentsViewModelProvider.notifier)
            .markReclaimedByStudent(assignment.id);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(turnInViewModelProvider).isLoading;
    final attachments = assignment.submissionAttachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('提出内容', style: ShadTheme.of(context).textTheme.h4),
        const SizedBox(height: 12),
        if (attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('添付ファイルなし',
                style: ShadTheme.of(context).textTheme.muted),
          )
        else ...[
          ...attachments.map((att) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _MaterialTile(material: att),
              )),
          const SizedBox(height: 8),
        ],
        ShadButton.outline(
          width: double.infinity,
          onPressed: isLoading ? null : () => _reclaim(context, ref),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('提出を取り消す'),
        ),
      ],
    );
  }
}

// 提出前の添付ファイルリストを共有する AutoDispose provider
final _submitAttachmentsProvider = StateProvider.autoDispose<
    List<({String name, String fileId})>>((ref) => []);
final _submitUploadingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// 添付ファイル管理 + 提出ボタン（下部固定パネル）
class _SubmitBottomPanel extends ConsumerWidget {
  const _SubmitBottomPanel({required this.assignment});
  final Assignment assignment;

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final result =
        await FilePicker.pickFiles(allowMultiple: true, withData: false);
    if (result == null || result.files.isEmpty) return;

    ref.read(_submitUploadingProvider.notifier).state = true;
    try {
      final service = ref.read(driveFileServiceProvider);
      for (final pf in result.files) {
        if (pf.path == null) continue;
        final uploaded = await service.uploadFile(File(pf.path!));
        ref
            .read(_submitAttachmentsProvider.notifier)
            .update((s) => [...s, uploaded]);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('アップロード失敗'),
            description: Text(e.toString()),
          ),
        );
      }
    } finally {
      ref.read(_submitUploadingProvider.notifier).state = false;
    }
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: ShadDialog.alert(
          radius: const BorderRadius.all(Radius.circular(12)),
          removeBorderRadiusWhenTiny: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          useSafeArea: false,
          crossAxisAlignment: CrossAxisAlignment.center,
          titleTextAlign: TextAlign.center,
          title: const Text('課題を提出しますか？'),
          description: const Text('提出後も「提出を取り消す」から取り消せます。'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            ShadButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('提出する'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final attachments = ref.read(_submitAttachmentsProvider);
    final repo = ref.read(lmsRepositoryProvider);

    for (final att in attachments) {
      final r = await repo.addAttachment(
        assignment.courseId,
        assignment.id,
        assignment.submissionId!,
        att.fileId,
      );
      if (r.isLeft() && context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: Text('${att.name} の添付に失敗しました'),
          ),
        );
        return;
      }
    }

    final result = await ref
        .read(turnInViewModelProvider.notifier)
        .turnIn(assignment.courseId, assignment.id, assignment.submissionId!);

    if (!context.mounted) return;
    result.fold(
      (failure) => ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('提出に失敗しました'),
          description: Text(failure.message),
        ),
      ),
      (_) {
        ShadToaster.of(context)
            .show(const ShadToast(title: Text('提出しました')));
        final attachmentMaterials = attachments
            .map((att) => AssignmentMaterial(
                  title: att.name,
                  url: '',
                  type: AssignmentMaterialType.driveFile,
                  driveFileId: att.fileId,
                ))
            .toList();
        ref.read(assignmentsViewModelProvider.notifier).markTurnedIn(
              assignment.id,
              attachments: attachmentMaterials,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(_submitAttachmentsProvider);
    final isUploading = ref.watch(_submitUploadingProvider);
    final isTurningIn = ref.watch(turnInViewModelProvider).isLoading;
    final isLoading = isUploading || isTurningIn;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachments.isNotEmpty) ...[
              ...attachments.map((att) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(att.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(_submitAttachmentsProvider.notifier)
                                  .update(
                                      (s) => s.where((a) => a != att).toList()),
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: isLoading
                        ? null
                        : () => _pickAndUpload(context, ref),
                    child: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.attach_file, size: 16),
                              SizedBox(width: 6),
                              Text('添付'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ShadButton(
                    onPressed:
                        isLoading ? null : () => _submit(context, ref),
                    child: isTurningIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('提出する'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialTile extends ConsumerStatefulWidget {
  const _MaterialTile({required this.material});

  final AssignmentMaterial material;

  @override
  ConsumerState<_MaterialTile> createState() => _MaterialTileState();
}

class _MaterialTileState extends ConsumerState<_MaterialTile> {
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
    } on DriveVirusScanWarningException catch (e) {
      if (!mounted) return;
      final confirmed = await showShadDialog<bool>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: ShadDialog.alert(
            radius: const BorderRadius.all(Radius.circular(12)),
            removeBorderRadiusWhenTiny: false,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
      if (confirmed == true && mounted) {
        try {
          await service.openWithAcknowledge(e);
        } on Exception catch (err) {
          if (mounted) {
            ShadToaster.of(context).show(
              ShadToast.destructive(
                title: const Text('ダウンロードに失敗しました'),
                description: Text(err.toString()),
              ),
            );
          }
        }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _open,
        child: ShadCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.open_in_new, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
