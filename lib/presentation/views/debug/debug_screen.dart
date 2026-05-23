// lib/presentation/views/debug/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/datasources/local/app_database.dart';
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
              title: '通知ログ (${state.notificationLogs.length}件)',
              child: _NotificationLogsSection(
                logs: state.notificationLogs,
                onClear: notifier.clearNotificationLogs,
                onTest: notifier.sendTestNotification,
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
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
                                    style: ShadTheme.of(context)
                                        .textTheme
                                        .muted,
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
                onPressed: onClear,
                child: const Text('ログをクリア'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ShadButton.outline(
                onPressed: onTest,
                child: const Text('テスト通知'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
