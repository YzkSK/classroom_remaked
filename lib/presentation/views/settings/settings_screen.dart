// lib/presentation/views/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late TextEditingController _hoursController;
  late TextEditingController _snoozeController;
  late FocusNode _hoursFocusNode;
  late FocusNode _snoozeFocusNode;
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController();
    _snoozeController = TextEditingController();
    _hoursFocusNode = FocusNode()..addListener(_onHoursFocusChange);
    _snoozeFocusNode = FocusNode()..addListener(_onSnoozeFocusChange);
    _checkPermission();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _snoozeController.dispose();
    _hoursFocusNode.dispose();
    _snoozeFocusNode.dispose();
    super.dispose();
  }

  void _onHoursFocusChange() {
    if (!_hoursFocusNode.hasFocus) _onEditingComplete();
  }

  void _onSnoozeFocusChange() {
    if (!_snoozeFocusNode.hasFocus) {
      final h = int.tryParse(_snoozeController.text) ?? 1;
      final clamped = h < 1 ? 1 : h;
      _snoozeController.text = clamped.toString();
      ref.read(settingsViewModelProvider.notifier).setSnoozeHours(clamped);
    }
  }

  Future<void> _checkPermission() async {
    final granted = await const NotificationService().isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  void _onEditingComplete() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    if (hours < 24) {
      _hoursController.text = '24';
      ShadToaster.of(context).show(
        const ShadToast(title: Text('最低24時間以上を設定してください')),
      );
      ref.read(settingsViewModelProvider.notifier).setNotifyBeforeHours(24);
    } else {
      ref.read(settingsViewModelProvider.notifier).setNotifyBeforeHours(hours);
    }
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

    if (settings != null && _hoursController.text.isEmpty) {
      _hoursController.text = settings.notifyBeforeHours.toString();
    }
    if (settings != null && _snoozeController.text.isEmpty) {
      _snoozeController.text = settings.snoozeHours.toString();
    }

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
          const SizedBox(height: 8),
          Row(
            children: [
              Text('締め切りの', style: ShadTheme.of(context).textTheme.muted),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: ShadInput(
                  controller: _hoursController,
                  focusNode: _hoursFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onEditingComplete: _onEditingComplete,
                ),
              ),
              const SizedBox(width: 8),
              Text('時間前に通知', style: ShadTheme.of(context).textTheme.muted),
            ],
          ),
          const SizedBox(height: 24),
          Text('スヌーズ間隔', style: ShadTheme.of(context).textTheme.h4),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('通知の', style: ShadTheme.of(context).textTheme.muted),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: ShadInput(
                  controller: _snoozeController,
                  focusNode: _snoozeFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !(settings?.lazyModeEnabled ?? false),
                  onEditingComplete: () {
                    final h = int.tryParse(_snoozeController.text) ?? 1;
                    final clamped = h < 1 ? 1 : h;
                    _snoozeController.text = clamped.toString();
                    ref
                        .read(settingsViewModelProvider.notifier)
                        .setSnoozeHours(clamped);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('時間後に再通知', style: ShadTheme.of(context).textTheme.muted),
            ],
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
            onPressed: () =>
                ref.read(authViewModelProvider.notifier).signOut(),
            child: const Text('サインアウト'),
          ),
        ],
      ),
    );
  }
}

