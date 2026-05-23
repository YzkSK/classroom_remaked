// lib/core/di/providers.dart
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
import '../services/drive_file_service.dart';
import '../services/classroom_sync_service.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/course_order_datasource.dart';
import '../../data/datasources/local/hidden_items_datasource.dart';
import '../../data/datasources/local/error_log_datasource.dart';
import '../../data/datasources/local/notification_logs_datasource.dart';
import '../../data/datasources/local/snoozed_items_datasource.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
import '../../data/datasources/local/user_preferences_datasource.dart';
import '../../data/repositories/google_classroom_repository.dart';
import '../../domain/repositories/lms_repository.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
part 'providers.g.dart';


@riverpod
AuthService authService(AuthServiceRef ref) => AuthService();

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
SyncStateDataSource syncStateDataSource(SyncStateDataSourceRef ref) =>
    SyncStateDataSource(ref.watch(appDatabaseProvider));

@riverpod
CourseOrderDataSource courseOrderDataSource(CourseOrderDataSourceRef ref) =>
    CourseOrderDataSource(ref.watch(appDatabaseProvider));

@riverpod
HiddenItemsDataSource hiddenItemsDataSource(HiddenItemsDataSourceRef ref) =>
    HiddenItemsDataSource(ref.watch(appDatabaseProvider));

@riverpod
UserPreferencesDataSource userPreferencesDataSource(
        UserPreferencesDataSourceRef ref) =>
    UserPreferencesDataSource(ref.watch(appDatabaseProvider));

@riverpod
NotificationLogsDataSource notificationLogsDataSource(
        NotificationLogsDataSourceRef ref) =>
    NotificationLogsDataSource(ref.watch(appDatabaseProvider));

@riverpod
SnoozedItemsDataSource snoozedItemsDataSource(
        SnoozedItemsDataSourceRef ref) =>
    SnoozedItemsDataSource(ref.watch(appDatabaseProvider));

@riverpod
GoogleClassroomRepository googleClassroomRepository(
    GoogleClassroomRepositoryRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  if (account == null) throw StateError('Not signed in');
  return GoogleClassroomRepository(
    database: ref.watch(appDatabaseProvider),
    account: account,
  );
}

@riverpod
LmsRepository lmsRepository(LmsRepositoryRef ref) =>
    ref.watch(googleClassroomRepositoryProvider);

@riverpod
ClassroomSyncService classroomSyncService(ClassroomSyncServiceRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  return ClassroomSyncService(
    syncState: ref.watch(syncStateDataSourceProvider),
    repository: ref.watch(googleClassroomRepositoryProvider),
    userId: account?.id ?? '',
  );
}

@riverpod
DriveFileService driveFileService(DriveFileServiceRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  if (account == null) throw StateError('Not signed in');
  return DriveFileService(account: account);
}

@riverpod
Future<Uint8List> fileViewer(FileViewerRef ref, String fileId) {
  return ref.watch(driveFileServiceProvider).downloadPdf(fileId);
}

final errorLogDataSourceProvider = Provider<ErrorLogDataSource>(
  (ref) => ErrorLogDataSource(ref.watch(appDatabaseProvider)),
);

