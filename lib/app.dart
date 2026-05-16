// lib/app.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
part 'app.g.dart';

/// 通知タップ時のナビゲーション先を保持する。
/// null = 通常起動、非 null = 通知から起動されたルート。
@riverpod
class PendingNotificationRoute extends _$PendingNotificationRoute {
  @override
  String? build() => null;

  void set(String route) => state = route;
  void clear() => state = null;
}

String? _routeFromMessage(RemoteMessage message) {
  final courseId = message.data['courseId'];
  if (courseId != null && courseId.isNotEmpty) {
    return '/dashboard/courses/$courseId';
  }
  return '/assignments';
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // フォアグラウンド: ローカル通知として表示
    FirebaseMessaging.onMessage.listen(NotificationService.showPush);

    // バックグラウンドから通知タップで復帰
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = _routeFromMessage(message);
      if (route != null) {
        ref.read(pendingNotificationRouteProvider.notifier).set(route);
      }
    });

    // Terminated 状態から通知タップで起動
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final route = _routeFromMessage(message);
        if (route != null) {
          ref.read(pendingNotificationRouteProvider.notifier).set(route);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return ShadApp.router(
      title: 'Classroom Remaked',
      routerConfig: router,
    );
  }
}
