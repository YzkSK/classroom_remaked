import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Remaked'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'サインアウト',
            onPressed: () =>
                ref.read(authViewModelProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: ShadCard(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction_rounded, size: 48),
                SizedBox(height: 16),
                Text('ダッシュボード'),
                Text('（Phase 2 で実装予定）'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
