// lib/presentation/views/debug/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/datasources/local/app_database.dart';
import '../../../data/datasources/local/error_log_datasource.dart';
import '../../viewmodels/debug_viewmodel.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debugViewModelProvider);
    final notifier = ref.read(debugViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.reload,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'データベース (schema v${state.schemaVersion})',
              child: _DbTable(rowCounts: state.rowCounts),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '同期',
              child: _SyncSection(
                lastSyncAt: state.lastSyncAt,
                onForceRefresh: notifier.forceRefresh,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '怠惰人間モード',
              child: _LazyModeSection(
                enabled: state.lazyModeEnabled,
                blockingCount: state.lazyModeBlockingCount,
                notifyBeforeHours: state.notifyBeforeHours,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'FCMトークン',
              child: _FcmTokenSection(token: state.fcmToken),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '通知ログ (${state.notificationLogs.length}件)',
              child: _NotificationLogsSection(
                logs: state.notificationLogs,
                onClear: notifier.clearNotificationLogs,
                onTest: notifier.sendTestNotification,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'エラーログ (${state.errorLogs.length}件)',
              child: _ErrorLogsSection(
                logs: state.errorLogs,
                onClear: notifier.clearErrorLogs,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '危険ゾーン',
              child: ShadButton.destructive(
                width: double.infinity,
                onPressed: () => _confirmClearAll(context, notifier),
                child: const Text('全データ削除'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(
      BuildContext context, DebugViewModel notifier) async {
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
          title: const Text('全データを削除しますか？'),
          description: const Text('DBの全テーブルが空になります。\nアプリを再起動してください。'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            ShadButton.destructive(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('削除する'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await notifier.clearAllData();
  }
}

// ── 共通セクションヘッダー ──────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ShadTheme.of(context).textTheme.h4),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ── DB行数テーブル ──────────────────────────────────────────

class _DbTable extends StatelessWidget {
  const _DbTable({required this.rowCounts});
  final Map<String, int> rowCounts;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: rowCounts.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13)),
                        Text('${e.value} 件',
                            style: ShadTheme.of(context).textTheme.muted),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── 同期状態 ────────────────────────────────────────────────

class _SyncSection extends StatelessWidget {
  const _SyncSection(
      {required this.lastSyncAt, required this.onForceRefresh});
  final String? lastSyncAt;
  final Future<void> Function() onForceRefresh;

  @override
  Widget build(BuildContext context) {
    final dt = lastSyncAt != null ? DateTime.tryParse(lastSyncAt!) : null;
    final label = dt != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dt.toLocal())
        : 'なし';

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最終同期',
                    style: ShadTheme.of(context).textTheme.muted),
                Text(label),
              ],
            ),
            const SizedBox(height: 12),
            ShadButton.outline(
              width: double.infinity,
              onPressed: onForceRefresh,
              child: const Text('強制リフレッシュ'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 怠惰モード ──────────────────────────────────────────────

class _LazyModeSection extends StatelessWidget {
  const _LazyModeSection({
    required this.enabled,
    required this.blockingCount,
    required this.notifyBeforeHours,
  });
  final bool enabled;
  final int blockingCount;
  final int notifyBeforeHours;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _Row(
              label: 'モード',
              value: enabled ? 'ON' : 'OFF',
              valueColor: enabled
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 4),
            _Row(
              label: '通知タイミング',
              value: '$notifyBeforeHours 時間前',
            ),
            const SizedBox(height: 4),
            _Row(
              label: 'OFFブロック中の課題',
              value: '$blockingCount 件',
              valueColor: blockingCount > 0
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── FCMトークン ─────────────────────────────────────────────

class _FcmTokenSection extends StatelessWidget {
  const _FcmTokenSection({required this.token});
  final String? token;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (token == null)
              Text('取得できませんでした',
                  style: ShadTheme.of(context).textTheme.muted)
            else ...[
              Text(
                token!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ShadButton.outline(
                width: double.infinity,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token!));
                  ShadToaster.of(context).show(
                    const ShadToast(title: Text('FCMトークンをコピーしました')),
                  );
                },
                child: const Text('コピー'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 通知ログ ────────────────────────────────────────────────

class _NotificationLogsSection extends StatelessWidget {
  const _NotificationLogsSection({
    required this.logs,
    required this.onClear,
    required this.onTest,
  });
  final List<NotificationLogRow> logs;
  final Future<void> Function() onClear;
  final Future<void> Function() onTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShadCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: logs.isEmpty
                ? Text('ログなし',
                    style: ShadTheme.of(context).textTheme.muted)
                : Column(
                    children: logs
                        .map((log) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.assignmentId,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MM/dd HH:mm')
                                        .format(log.notifiedAt.toLocal()),
                                    style:
                                        ShadTheme.of(context).textTheme.muted,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ShadButton.outline(
                  onPressed: onClear, child: const Text('ログをクリア')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ShadButton.outline(
                  onPressed: onTest, child: const Text('テスト通知')),
            ),
          ],
        ),
      ],
    );
  }
}

// ── エラーログ ──────────────────────────────────────────────

class _ErrorLogsSection extends StatelessWidget {
  const _ErrorLogsSection({required this.logs, required this.onClear});
  final List<ErrorLogEntry> logs;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShadCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: logs.isEmpty
                ? Text('エラーなし',
                    style: ShadTheme.of(context).textTheme.muted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: logs.map((e) => _ErrorLogTile(entry: e)).toList(),
                  ),
          ),
        ),
        if (logs.isNotEmpty) ...[
          const SizedBox(height: 8),
          ShadButton.outline(
            width: double.infinity,
            onPressed: onClear,
            child: const Text('エラーログをクリア'),
          ),
        ],
      ],
    );
  }
}

class _ErrorLogTile extends StatefulWidget {
  const _ErrorLogTile({required this.entry});
  final ErrorLogEntry entry;

  @override
  State<_ErrorLogTile> createState() => _ErrorLogTileState();
}

class _ErrorLogTileState extends State<_ErrorLogTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${e.source}] ${e.message}',
                        style: const TextStyle(fontSize: 11),
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm:ss')
                            .format(e.timestamp.toLocal()),
                        style: ShadTheme.of(context)
                            .textTheme
                            .muted
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_expanded && e.stackTrace != null) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.stackTrace!,
                  style: const TextStyle(
                      fontSize: 9, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 汎用行 ──────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ShadTheme.of(context).textTheme.muted),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight:
                valueColor != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
