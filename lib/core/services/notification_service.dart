// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
import '../../domain/entities/assignment.dart';

const _channelId = 'deadlines';
const _channelName = '締め切り通知';
const _categoryFull = 'deadline_full';
const _categoryLazy = 'deadline_lazy';

class NotificationService {
  const NotificationService();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryFull,
          actions: [
            DarwinNotificationAction.plain('snooze_30min', '30分'),
            DarwinNotificationAction.plain('snooze_1h', '1時間'),
            DarwinNotificationAction.plain('snooze_3h', '3時間'),
          ],
        ),
        DarwinNotificationCategory(
          _categoryLazy,
          actions: [
            DarwinNotificationAction.plain('snooze_1h', '1時間'),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
    );
  }

  static void _onForegroundTap(NotificationResponse details) {}

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

  Future<void> show(Assignment assignment, {required bool lazyMode}) async {
    final notifId = assignment.id.hashCode.abs() % 0x7FFFFFFF;
    final due = assignment.dueDate!;
    final hoursLeft = due.difference(DateTime.now()).inHours;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      actions: lazyMode
          ? const [AndroidNotificationAction('snooze_1h', '1時間')]
          : const [
              AndroidNotificationAction('snooze_30min', '30分'),
              AndroidNotificationAction('snooze_1h', '1時間'),
              AndroidNotificationAction('snooze_3h', '3時間'),
            ],
    );

    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: lazyMode ? _categoryLazy : _categoryFull,
    );

    await _plugin.show(
      notifId,
      '締め切りまで$hoursLeft時間',
      assignment.title,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: assignment.id,
    );
  }
}

@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse details) async {
  final assignmentId = details.payload;
  if (assignmentId == null || details.actionId == null) return;
  if (details.actionId == 'confirm') return;

  Duration snooze;
  switch (details.actionId) {
    case 'snooze_30min':
      snooze = const Duration(minutes: 30);
    case 'snooze_1h':
      snooze = const Duration(hours: 1);
    case 'snooze_3h':
      snooze = const Duration(hours: 3);
    default:
      return;
  }

  final db = await AppDatabase.openBackground();
  await SnoozedItemsDataSource(db).upsert(
    assignmentId,
    DateTime.now().add(snooze),
  );
  await db.close();
}
