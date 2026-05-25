// lib/core/services/classroom_sync_service.dart
import '../../data/datasources/local/error_log_datasource.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
import '../../data/repositories/google_classroom_repository.dart';
import 'fcm_token_service.dart';

class ClassroomSyncService {
  ClassroomSyncService({
    required SyncStateDataSource syncState,
    required GoogleClassroomRepository repository,
    required String userId,
    ErrorLogDataSource? errorLog,
  })  : _syncState = syncState,
        _repo = repository,
        _userId = userId,
        _errorLog = errorLog;

  final SyncStateDataSource _syncState;
  final GoogleClassroomRepository _repo;
  final String _userId;
  final ErrorLogDataSource? _errorLog;

  static const _cacheValidDuration = Duration(hours: 1);

  /// 起動時・フォアグラウンド復帰時に呼ぶ。
  /// 最終同期から1時間以内ならキャッシュをそのまま使い API を呼ばない。
  Future<void> fullSync() async {
    final lastSyncStr = await _syncState.get('last_sync_at');
    final shouldRefresh = lastSyncStr == null ||
        DateTime.now().difference(DateTime.parse(lastSyncStr)) >
            _cacheValidDuration;

    if (!shouldRefresh) return;

    await _refreshAll();
  }

  /// Pull-to-refresh 用: 常に API から取り直す。
  Future<void> forceRefresh() => _refreshAll();

  Future<void> _refreshAll() async {
    await _repo.refreshCourses();
    final coursesResult = await _repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);
    await Future.wait([
      ...courses.map((c) => _repo.refreshAssignments(c.id)),
      ...courses.map((c) => _repo.refreshAnnouncements(c.id)),
    ]);
    await _syncState.set('last_sync_at', DateTime.now().toIso8601String());

    final courseIds = courses.map((c) => c.id).toList();

    // UI をブロックしないようバックグラウンドで実行
    const FcmTokenService()
        .register(userId: _userId, courseIds: courseIds, errorLog: _errorLog)
        .catchError((e, st) {
      _errorLog?.add(
        source: 'FcmTokenService.register',
        message: '$e',
        stackTrace: st.toString(),
      );
    });
    _repo.registerPubSubFeeds(courseIds).catchError((e, st) {
      _errorLog?.add(
        source: 'PubSubRegistration',
        message: '$e',
        stackTrace: st.toString(),
      );
    });
  }
}
