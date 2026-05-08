import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../../core/services/notification_service.dart';

class NotificationSetupScreen extends ConsumerStatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  ConsumerState<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState
    extends ConsumerState<NotificationSetupScreen> {
  late TextEditingController _hoursController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '24');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _complete({required bool requestPermission}) async {
    final hours = int.tryParse(_hoursController.text) ?? 24;
    final notifier = ref.read(settingsViewModelProvider.notifier);
    await notifier.setNotifyBeforeHours(hours < 24 ? 24 : hours);
    if (requestPermission) {
      await const NotificationService().requestPermission();
    }
    await notifier.completeOnboarding();
    if (mounted) context.go('/dashboard');
  }

  Future<void> _onLazyModeToggle(bool value) async {
    if (value) {
      // Turning ON: confirm dialog
      final confirmed = await showShadDialog<bool>(
        context: context,
        builder: (context) => ShadDialog.alert(
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
      );
      if (confirmed == true) {
        await ref.read(settingsViewModelProvider.notifier).enableLazyMode();
      }
    } else {
      // Turning OFF: no assignments to check on this screen
      await ref.read(settingsViewModelProvider.notifier).tryDisableLazyMode([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsViewModelProvider);
    final lazyMode = settingsAsync.valueOrNull?.lazyModeEnabled ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                '通知を設定しましょう',
                style: ShadTheme.of(context).textTheme.h3,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Text('締め切りの', style: ShadTheme.of(context).textTheme.muted),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: ShadInput(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('時間前に通知', style: ShadTheme.of(context).textTheme.muted),
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
                    value: lazyMode,
                    onChanged: (v) => _onLazyModeToggle(v),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () => _complete(requestPermission: true),
                  child: const Text('通知を許可して開始する'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ShadButton.ghost(
                  onPressed: () => _complete(requestPermission: false),
                  child: const Text('後でスキップ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
