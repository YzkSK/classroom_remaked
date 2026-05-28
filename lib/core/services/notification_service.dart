// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/assignment.dart';

const _channelId = 'deadlines';
const _channelName = '締め切り通知';
const _newAssignmentChannelId = 'new_assignments';
const _newAssignmentChannelName = '新着課題';

class NotificationService {
  const NotificationService();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<bool> isPermissionGranted() async {
    final androidGranted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
    if (androidGranted) return true;
    final iosPermissions = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    return iosPermissions?.isEnabled ?? false;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showPush(RemoteMessage message) async {
    final title = message.notification?.title ?? '新しいお知らせ';
    final body = message.notification?.body ?? '';
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      message.messageId.hashCode.abs() % 0x7FFFFFFF,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> showTest() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      999,
      'テスト通知',
      'デバッグ画面から送信されたテスト通知です',
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> showNewAssignment({
    required String assignmentId,
    required String title,
    required String courseName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _newAssignmentChannelId,
      _newAssignmentChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.show(
      assignmentId.hashCode.abs() % 0x7FFFFFFF,
      title,
      courseName,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: assignmentId,
    );
  }

  Future<void> show(Assignment assignment) async {
    final notifId = assignment.id.hashCode.abs() % 0x7FFFFFFF;
    final due = assignment.dueDate!;
    final hoursLeft = due.difference(DateTime.now()).inHours;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      notifId,
      '締め切りまで$hoursLeft時間',
      assignment.title,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: assignment.id,
    );
  }

  static Future<bool> canScheduleExactAlarms() async {
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.canScheduleExactNotifications() ??
        true;
  }

  static Future<void> requestExactAlarmsPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDeadline(
      Assignment assignment, DateTime notifyAt) async {
    final notifId = assignment.id.hashCode.abs() % 0x7FFFFFFF;
    final due = assignment.dueDate!;
    final hoursLeft = due.difference(notifyAt).inHours;
    final effectiveAt = notifyAt.isAfter(DateTime.now())
        ? notifyAt
        : DateTime.now().add(const Duration(seconds: 10));

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.cancel(notifId);
    await _plugin.zonedSchedule(
      notifId,
      '締め切りまで$hoursLeft時間',
      assignment.title,
      tz.TZDateTime.from(effectiveAt, tz.getLocation('Asia/Tokyo')),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: assignment.id,
    );
  }
}
