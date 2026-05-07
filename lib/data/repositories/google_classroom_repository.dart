// lib/data/repositories/google_classroom_repository.dart
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../../domain/entities/announcement.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/course.dart';
import '../../domain/errors/failures.dart';
import '../../domain/repositories/lms_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/classroom_http_client.dart';

class GoogleClassroomRepository implements LmsRepository {
  GoogleClassroomRepository({
    required AppDatabase database,
    required GoogleSignInAccount account,
  })  : _db = database,
        _api = classroom.ClassroomApi(ClassroomHttpClient(account));

  GoogleClassroomRepository.withApi({
    required AppDatabase database,
    required classroom.ClassroomApi api,
  })  : _db = database,
        _api = api;

  final AppDatabase _db;
  final classroom.ClassroomApi _api;

  @override
  Future<Either<Failure, List<Course>>> getCourses() async {
    final cached = await _db.select(_db.courses).get();
    if (cached.isNotEmpty) {
      return Right(cached.map(_courseRowToDomain).toList());
    }
    return _fetchAndCacheCourses();
  }

  Future<Either<Failure, List<Course>>> refreshCourses() =>
      _fetchAndCacheCourses();

  @override
  Future<Either<Failure, List<Assignment>>> getAssignments(
      String courseId) async {
    final cached = await (_db.select(_db.assignments)
          ..where((t) => t.courseId.equals(courseId)))
        .get();
    if (cached.isNotEmpty) {
      return Right(cached.map(_assignmentRowToDomain).toList());
    }
    return _fetchAndCacheAssignments(courseId);
  }

  Future<Either<Failure, List<Assignment>>> refreshAssignments(
          String courseId) =>
      _fetchAndCacheAssignments(courseId);

  @override
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({
    required Duration within,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final limit = DateTime.now().add(within).millisecondsSinceEpoch;

      final rows = await (_db.select(_db.assignments)
            ..where((t) =>
                t.dueDateMillis.isBiggerOrEqualValue(now) &
                t.dueDateMillis.isSmallerOrEqualValue(limit) &
                (t.submissionState.isNull() |
                    t.submissionState.equals('turnedIn').not()))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDateMillis)]))
          .get();

      return Right(rows.map(_assignmentRowToDomain).toList());
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements(
          String courseId) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<SearchResult>>> search(String query) async =>
      const Right([]);

  @override
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<Comment>>> getComments(
    String courseId,
    String itemId, {
    CommentVisibility? filterBy,
  }) async =>
      const Right([]);

  Future<Either<Failure, List<Course>>> _fetchAndCacheCourses() async {
    try {
      final all = <classroom.Course>[];
      String? pageToken;
      do {
        final res = await _api.courses.list(
          courseStates: ['ACTIVE'],
          pageSize: 50,
          pageToken: pageToken,
        );
        all.addAll(res.courses ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      final domains = all.map(_courseToDomain).toList();
      await _db.batch((batch) {
        batch.insertAll(
          _db.courses,
          domains.map(_courseToCompanion).toList(),
          mode: InsertMode.replace,
        );
      });
      return Right(domains);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Assignment>>> _fetchAndCacheAssignments(
      String courseId) async {
    try {
      final all = <classroom.CourseWork>[];
      String? pageToken;
      do {
        final res = await _api.courses.courseWork.list(
          courseId,
          courseWorkStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: pageToken,
        );
        all.addAll(res.courseWork ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      final domains = all.map(_courseWorkToDomain).toList();
      await _db.batch((batch) {
        batch.insertAll(
          _db.assignments,
          domains.map(_assignmentToCompanion).toList(),
          mode: InsertMode.replace,
        );
      });
      return Right(domains);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  Course _courseToDomain(classroom.Course c) => Course(
        id: c.id!,
        name: c.name ?? '',
        description: c.description,
        section: c.section,
        room: c.room,
        ownerId: c.ownerId,
        courseState: c.courseState ?? 'ACTIVE',
      );

  CoursesCompanion _courseToCompanion(Course c) => CoursesCompanion.insert(
        id: c.id,
        name: c.name,
        description: Value(c.description),
        section: Value(c.section),
        room: Value(c.room),
        ownerId: Value(c.ownerId),
        courseState: Value(c.courseState),
      );

  Course _courseRowToDomain(CourseRow r) => Course(
        id: r.id,
        name: r.name,
        description: r.description,
        section: r.section,
        room: r.room,
        ownerId: r.ownerId,
        courseState: r.courseState,
      );

  Assignment _courseWorkToDomain(classroom.CourseWork cw) {
    DateTime? dueDate;
    if (cw.dueDate != null) {
      dueDate = DateTime(
        cw.dueDate!.year!,
        cw.dueDate!.month!,
        cw.dueDate!.day!,
        cw.dueTime?.hours ?? 23,
        cw.dueTime?.minutes ?? 59,
      );
    }
    return Assignment(
      id: cw.id!,
      courseId: cw.courseId!,
      title: cw.title ?? '',
      description: cw.description,
      dueDate: dueDate,
      state: _parseState(cw.state),
    );
  }

  AssignmentState _parseState(String? s) => switch (s?.toUpperCase()) {
        'PUBLISHED' => AssignmentState.published,
        'DRAFT' => AssignmentState.draft,
        'DELETED' => AssignmentState.deleted,
        _ => AssignmentState.published,
      };

  AssignmentsCompanion _assignmentToCompanion(Assignment a) =>
      AssignmentsCompanion.insert(
        id: a.id,
        courseId: a.courseId,
        title: a.title,
        description: Value(a.description),
        dueDateMillis: Value(a.dueDate?.millisecondsSinceEpoch),
        state: Value(a.state.name),
        submissionState: Value(a.submissionState?.name),
      );

  Assignment _assignmentRowToDomain(AssignmentRow r) => Assignment(
        id: r.id,
        courseId: r.courseId,
        title: r.title,
        description: r.description,
        dueDate: r.dueDateMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!)
            : null,
        state: AssignmentState.values.firstWhere(
          (e) => e.name == r.state,
          orElse: () => AssignmentState.published,
        ),
        submissionState: r.submissionState != null
            ? SubmissionState.values.firstWhere(
                (e) => e.name == r.submissionState,
                orElse: () => SubmissionState.newSubmission,
              )
            : null,
      );
}
