// lib/presentation/views/settings/settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/assignments_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/usecases/can_disable_lazy_mode_usecase.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double? _notifyHoursDraft;
  double? _snoozeHoursDraft;
  bool _permissionGranted = true;
  bool _signingOut = false;
  int _debugTapCount = 0;
  Timer? _debugTapTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _debugTapTimer?.cancel();
    super.dispose();
  }

  void _onVersionTap() {
    _debugTapTimer?.cancel();
    _debugTapTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _debugTapCount = 0);
    });
    setState(() => _debugTapCount++);

    if (_debugTapCount >= 7) {
      setState(() => _debugTapCount = 0);
      context.go('/settings/debug');
    } else if (_debugTapCount >= 4) {
      ShadToaster.of(context).show(
        ShadToast(title: Text('あと${7 - _debugTapCount}回でデバッグモード')),
      );
    }
  }

  Future<void> _checkPermission() async {
    final granted = await const NotificationService().isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _onLazyModeToggle(bool value) async {
    if (value) {
      final confirmed = await showShadDialog<bool>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: ShadDialog.alert(
            radius: const BorderRadius.all(Radius.circular(12)),
            removeBorderRadiusWhenTiny: false,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            useSafeArea: false,
            crossAxisAlignment: CrossAxisAlignment.center,
            titleTextAlign: TextAlign.center,
            title: const Text('怠惰人間モードを有効にしますか？'),
            description: const Text(
              '・スヌーズが1時間固定になります\n'
              '・OFFに戻すには、設定した通知タイミング以内に\n'
              '  締め切りがある課題をすべて提出するまで\n'
              '  無効にできません',
            ),
            actions: [
              ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ShadButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('有効にする'),
              ),
            ],
          ),
        ),
      );
      if (confirmed == true) {
        await ref.read(settingsViewModelProvider.notifier).enableLazyMode();
      }
    } else {
      final assignments =
          ref.read(assignmentsViewModelProvider).valueOrNull?.assignments ?? [];
      final canDisable = await ref
          .read(settingsViewModelProvider.notifier)
          .tryDisableLazyMode(assignments);
      if (!canDisable && mounted) {
        final settings = ref.read(settingsViewModelProvider).valueOrNull;
        final blocked = settings == null
            ? 0
            : const CanDisableLazyModeUseCase().countBlockingAssignments(
                assignments: assignments,
                notifyBefore: Duration(hours: settings.notifyBeforeHours),
                now: DateTime.now(),
              );
        ShadToaster.of(context).show(
          ShadToast(title: Text('あと$blocked件提出するとOFFにできます')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsViewModelProvider);
    final settings = settingsAsync.valueOrNull;

    final notifier = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_permissionGranted) ...[
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('通知が許可されていません')),
                    ShadButton.outline(
                      onPressed: () async {
                        await const NotificationService().requestPermission();
                        await _checkPermission();
                      },
                      child: const Text('許可する'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('通知タイミング', style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 4),
          Text(
            '締め切りの ${_notifyHoursDraft?.round() ?? settings?.notifyBeforeHours ?? 24} 時間前',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          Slider(
            value: _notifyHoursDraft ??
                settings?.notifyBeforeHours.toDouble() ?? 24.0,
            min: 24,
            max: 168,
            divisions: 6,
            label:
                '${_notifyHoursDraft?.round() ?? settings?.notifyBeforeHours ?? 24}時間前',
            onChanged: settings != null
                ? (v) => setState(() => _notifyHoursDraft = v)
                : null,
            onChangeEnd: settings != null
                ? (v) {
                    final h = v.round();
                    setState(() => _notifyHoursDraft = null);
                    notifier.setNotifyBeforeHours(h);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('24時間前', style: ShadTheme.of(context).textTheme.muted),
                Text('1週間前', style: ShadTheme.of(context).textTheme.muted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('スヌーズ間隔', style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 4),
          Text(
            '${_snoozeHoursDraft?.round() ?? settings?.snoozeHours ?? 1} 時間後に再通知',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          Slider(
            value: _snoozeHoursDraft ??
                settings?.snoozeHours.toDouble() ?? 1.0,
            min: 1,
            max: 12,
            divisions: 11,
            label:
                '${_snoozeHoursDraft?.round() ?? settings?.snoozeHours ?? 1}時間後',
            onChanged: (settings != null && !(settings.lazyModeEnabled))
                ? (v) => setState(() => _snoozeHoursDraft = v)
                : null,
            onChangeEnd: (settings != null && !(settings.lazyModeEnabled))
                ? (v) {
                    final h = v.round();
                    setState(() => _snoozeHoursDraft = null);
                    notifier.setSnoozeHours(h);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1時間後', style: ShadTheme.of(context).textTheme.muted),
                Text('12時間後', style: ShadTheme.of(context).textTheme.muted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('怠惰人間モード',
                      style: ShadTheme.of(context).textTheme.p),
                  Text('ONのときスヌーズは1時間固定',
                      style: ShadTheme.of(context).textTheme.muted),
                  Text('OFFにするには期限内の課題をすべて提出',
                      style: ShadTheme.of(context).textTheme.muted),
                ],
              ),
              ShadSwitch(
                value: settings?.lazyModeEnabled ?? false,
                onChanged: settings != null
                    ? (v) => _onLazyModeToggle(v)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const ShadSeparator.horizontal(),
          const SizedBox(height: 16),
          ShadButton.outline(
            width: double.infinity,
            onPressed: _signingOut
                ? null
                : () async {
                    setState(() => _signingOut = true);
                    try {
                      await ref.read(authViewModelProvider.notifier).signOut();
                    } finally {
                      if (mounted) setState(() => _signingOut = false);
                    }
                  },
            child: _signingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('サインアウト'),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _onVersionTap,
            child: Center(
              child: Text(
                'Classroom Remaked',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

