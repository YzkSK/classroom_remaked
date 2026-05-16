// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/auth_service.dart';
import 'core/services/background_notification_task.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'app.dart';

/// バックグラウンド・terminated 状態で FCM push を受け取るハンドラー。
/// トップレベル関数である必要がある。
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  await NotificationService.showPush(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await AuthService().initialize();
  await NotificationService.initialize();
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    notificationTaskUniqueName,
    notificationTaskName,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  runApp(const ProviderScope(child: App()));
}
