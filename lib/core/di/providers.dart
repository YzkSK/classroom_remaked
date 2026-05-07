// lib/core/di/providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
import '../services/classroom_sync_service.dart';
import '../services/pubsub_service.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/course_order_datasource.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
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
PubSubService pubSubService(PubSubServiceRef ref) {
  final account = ref.watch(authViewModelProvider).valueOrNull;
  if (account == null) throw StateError('Not signed in');
  return PubSubService(
    account: account,
    syncState: ref.watch(syncStateDataSourceProvider),
  );
}

@riverpod
ClassroomSyncService classroomSyncService(ClassroomSyncServiceRef ref) =>
    ClassroomSyncService(
      pubSubService: ref.watch(pubSubServiceProvider),
      repository: ref.watch(googleClassroomRepositoryProvider),
    );
