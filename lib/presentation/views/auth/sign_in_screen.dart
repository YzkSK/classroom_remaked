import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.school_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Classroom Remaked',
                style: theme.textTheme.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Google Classroomをもっと使いやすく',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ShadButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(authViewModelProvider.notifier)
                              .signIn();
                        } catch (e) {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                title: const Text('サインインに失敗しました'),
                                description: Text(e.toString()),
                              ),
                            );
                          }
                        }
                      },
                child: authState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Google でサインイン'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
