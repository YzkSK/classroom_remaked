// lib/core/services/classroom_sync_service.dart
import '../../data/repositories/google_classroom_repository.dart';
import 'pubsub_service.dart';

class ClassroomSyncService {
  ClassroomSyncService({
    required PubSubService pubSubService,
    required GoogleClassroomRepository repository,
  })  : _pubSub = pubSubService,
        _repo = repository;

  final PubSubService _pubSub;
  final GoogleClassroomRepository _repo;

  Future<void> fullSync() async {
    await _pubSub.ensureSetup();

    final coursesResult = await _repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);

    await Future.wait(
      courses.map((c) => _pubSub.ensureRegistration(c.id)),
    );

    final changedIds = await _pubSub.pullChangedCourseIds();

    if (changedIds.isNotEmpty) {
      await Future.wait(
        changedIds.map((id) => _repo.refreshAssignments(id)),
      );
    }
  }

  Future<void> forceRefresh() async {
    await _repo.refreshCourses();
    final coursesResult = await _repo.getCourses();
    final courses = coursesResult.getOrElse(() => []);
    await Future.wait(courses.map((c) => _repo.refreshAssignments(c.id)));
  }
}
