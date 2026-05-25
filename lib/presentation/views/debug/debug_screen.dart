// lib/presentation/views/debug/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/di/providers.dart';
import '../../../data/datasources/local/app_database.dart';
import '../../../data/datasources/local/error_log_datasource.dart';
import '../../viewmodels/debug_viewmodel.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debugViewModelProvider);
    final notifier = ref.read(debugViewModelProvider.notifier);
    final db = ref.read(appDatabaseProvider);

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
              child: _DbTable(
                rowCounts: state.rowCounts,
                onTapTable: (tableName) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        _TableDetailPage(tableName: tableName, db: db),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '同期',
              child: _SyncSection(
                lastSyncAt: state.lastSyncAt,
                lastBgSyncAt: state.lastBgSyncAt,
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
                onBlockingTap: state.lazyModeBlockingCount > 0
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _BlockingAssignmentsPage(
                              db: db,
                              notifyBeforeHours: state.notifyBeforeHours,
                            ),
                          ),
                        )
                    : null,
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
  const _DbTable({required this.rowCounts, required this.onTapTable});
  final Map<String, int> rowCounts;
  final void Function(String tableName) onTapTable;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: rowCounts.entries
              .map((e) => InkWell(
                    onTap: () => onTapTable(e.key),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right,
                                  size: 14,
                                  color:
                                      Theme.of(context).colorScheme.outline),
                            ],
                          ),
                          Text('${e.value} 件',
                              style: ShadTheme.of(context).textTheme.muted),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── 同期状態 ────────────────────────────────────────────────

class _SyncSection extends StatefulWidget {
  const _SyncSection({
    required this.lastSyncAt,
    required this.lastBgSyncAt,
    required this.onForceRefresh,
  });
  final String? lastSyncAt;
  final String? lastBgSyncAt;
  final Future<void> Function() onForceRefresh;

  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    String fmt(String? raw) {
      final dt = raw != null ? DateTime.tryParse(raw) : null;
      return dt != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dt.toLocal())
          : 'なし';
    }

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最終同期（FG）',
                    style: ShadTheme.of(context).textTheme.muted),
                Text(fmt(widget.lastSyncAt)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最終同期（BG）',
                    style: ShadTheme.of(context).textTheme.muted),
                Text(fmt(widget.lastBgSyncAt)),
              ],
            ),
            const SizedBox(height: 12),
            ShadButton.outline(
              width: double.infinity,
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await widget.onForceRefresh();
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('強制リフレッシュ'),
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
    this.onBlockingTap,
  });
  final bool enabled;
  final int blockingCount;
  final int notifyBeforeHours;
  final VoidCallback? onBlockingTap;

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
            InkWell(
              onTap: onBlockingTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('OFFブロック中の課題',
                        style: ShadTheme.of(context).textTheme.muted),
                    Row(
                      children: [
                        Text(
                          '$blockingCount 件',
                          style: TextStyle(
                            color: blockingCount > 0
                                ? Theme.of(context).colorScheme.error
                                : null,
                            fontWeight: blockingCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (onBlockingTap != null) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right,
                              size: 14,
                              color: Theme.of(context).colorScheme.error),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
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

// ── DB テーブル詳細ページ ────────────────────────────────────

class _TableDetailPage extends StatefulWidget {
  const _TableDetailPage({required this.tableName, required this.db});
  final String tableName;
  final AppDatabase db;

  @override
  State<_TableDetailPage> createState() => _TableDetailPageState();
}

class _TableDetailPageState extends State<_TableDetailPage> {
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, String>>> _load() async {
    final db = widget.db;
    switch (widget.tableName) {
      case 'courses':
        final rows = await db.select(db.courses).get();
        return rows
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'section': r.section ?? '-',
                  'room': r.room ?? '-',
                  'state': r.courseState,
                })
            .toList();

      case 'assignments':
        final rows = await db.select(db.assignments).get();
        return rows
            .map((r) => {
                  'id': r.id,
                  'title': r.title,
                  'courseId': r.courseId,
                  'dueDate': r.dueDateMillis != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!)
                              .toLocal())
                      : '-',
                  'state': r.state,
                  'submissionState': r.submissionState ?? '-',
                  'submissionId': r.submissionId ?? '-',
                })
            .toList();

      case 'announcements':
        final rows = await db.select(db.announcements).get();
        return rows
            .map((r) => {
                  'id': r.id,
                  'courseId': r.courseId,
                  'title': r.title ?? '-',
                  'body': r.body.length > 80
                      ? '${r.body.substring(0, 80)}…'
                      : r.body,
                  'isMaterial': r.isMaterial.toString(),
                  'createdAt': DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(r.creationTimeMillis)
                          .toLocal()),
                })
            .toList();

      case 'notification_logs':
        final rows = await db.select(db.notificationLogs).get();
        return rows
            .map((r) => {
                  'assignmentId': r.assignmentId,
                  'notifiedAt': DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(r.notifiedAt.toLocal()),
                })
            .toList();

      case 'snoozed_items':
        final rows = await db.select(db.snoozedItems).get();
        return rows
            .map((r) => {
                  'assignmentId': r.assignmentId,
                  'snoozedUntil': DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(r.snoozedUntil.toLocal()),
                })
            .toList();

      case 'hidden_items':
        final rows = await db.select(db.hiddenItems).get();
        return rows
            .map((r) => {
                  'itemId': r.itemId,
                  'type': r.type,
                  'hiddenAt': DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(r.hiddenAt.toLocal()),
                })
            .toList();

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableName,
            style: const TextStyle(fontFamily: 'monospace')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _load()),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
              child: Text('データなし',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _RowCard(index: i, fields: rows[i]),
          );
        },
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.index, required this.fields});
  final int index;
  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${index + 1}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 6),
            ...fields.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ブロック中の課題詳細ページ ──────────────────────────────

class _BlockingAssignmentsPage extends StatefulWidget {
  const _BlockingAssignmentsPage(
      {required this.db, required this.notifyBeforeHours});
  final AppDatabase db;
  final int notifyBeforeHours;

  @override
  State<_BlockingAssignmentsPage> createState() =>
      _BlockingAssignmentsPageState();
}

class _BlockingAssignmentsPageState extends State<_BlockingAssignmentsPage> {
  late Future<List<AssignmentRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AssignmentRow>> _load() async {
    final cutoff =
        DateTime.now().add(Duration(hours: widget.notifyBeforeHours));
    final rows = await widget.db.select(widget.db.assignments).get();
    return rows.where((r) {
      if (r.submissionId == null) return false;
      if (r.submissionState == 'turnedIn') return false;
      if (r.dueDateMillis == null) return false;
      final due = DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!);
      return due.isAfter(DateTime.now()) && due.isBefore(cutoff);
    }).toList()
      ..sort((a, b) => a.dueDateMillis!.compareTo(b.dueDateMillis!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ブロック中の課題 (${widget.notifyBeforeHours}h以内)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _load()),
          ),
        ],
      ),
      body: FutureBuilder<List<AssignmentRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
              child: Text('ブロック中の課題なし',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              final due = r.dueDateMillis != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!)
                          .toLocal())
                  : '-';
              return _RowCard(
                index: i,
                fields: {
                  'id': r.id,
                  'title': r.title,
                  'courseId': r.courseId,
                  'dueDate': due,
                  'submissionState': r.submissionState ?? '-',
                  'submissionId': r.submissionId ?? '-',
                },
              );
            },
          );
        },
      ),
    );
  }
}
