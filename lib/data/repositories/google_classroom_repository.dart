// lib/data/repositories/google_classroom_repository.dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../../domain/entities/announcement.dart';
import '../../domain/entities/assignment.dart';
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

  // ────────────────────── Courses ──────────────────────

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

  // ────────────────────── Assignments ──────────────────────

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

  // ────────────────────── Announcements ──────────────────────

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements(
      String courseId) async {
    final cached = await (_db.select(_db.announcements)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([(t) => OrderingTerm.desc(t.creationTimeMillis)]))
        .get();
    if (cached.isNotEmpty) {
      return Right(cached.map(_announcementRowToDomain).toList());
    }
    return _fetchAndCacheAnnouncements(courseId);
  }

  Future<Either<Failure, List<Announcement>>> refreshAnnouncements(
          String courseId) =>
      _fetchAndCacheAnnouncements(courseId);

  // ────────────────────── TurnIn ──────────────────────

  @override
  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  ) async {
    try {
      await _api.courses.courseWork.studentSubmissions.turnIn(
        classroom.TurnInStudentSubmissionRequest(),
        courseId,
        assignmentId,
        submissionId,
      );
      await (_db.update(_db.assignments)
            ..where((t) => t.id.equals(assignmentId)))
          .write(const AssignmentsCompanion(
        submissionState: Value('turnedIn'),
      ));
      return const Right(null);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAttachment(
    String courseId,
    String courseWorkId,
    String submissionId,
    String driveFileId,
  ) async {
    try {
      await _api.courses.courseWork.studentSubmissions.modifyAttachments(
        classroom.ModifyAttachmentsRequest(
          addAttachments: [
            classroom.Attachment(
              driveFile: classroom.DriveFile(id: driveFileId),
            ),
          ],
        ),
        courseId,
        courseWorkId,
        submissionId,
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reclaimSubmission(
    String courseId,
    String assignmentId,
    String submissionId,
  ) async {
    try {
      await _api.courses.courseWork.studentSubmissions.reclaim(
        classroom.ReclaimStudentSubmissionRequest(),
        courseId,
        assignmentId,
        submissionId,
      );
      await (_db.update(_db.assignments)
            ..where((t) => t.id.equals(assignmentId)))
          .write(const AssignmentsCompanion(
        submissionState: Value('reclaimedByStudent'),
      ));
      return const Right(null);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  // ────────────────────── Private: fetch & cache ──────────────────────

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
      final allWork = <classroom.CourseWork>[];
      String? pageToken;
      do {
        final res = await _api.courses.courseWork.list(
          courseId,
          courseWorkStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: pageToken,
        );
        allWork.addAll(res.courseWork ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      final subMap = <String, classroom.StudentSubmission>{};
      String? subPageToken;
      do {
        final subRes = await _api.courses.courseWork.studentSubmissions.list(
          courseId,
          '-',
          userId: 'me',
          pageSize: 100,
          pageToken: subPageToken,
        );
        for (final s in subRes.studentSubmissions ?? []) {
          if (s.courseWorkId != null) subMap[s.courseWorkId!] = s;
        }
        subPageToken = subRes.nextPageToken;
      } while (subPageToken != null);

      final domains = allWork
          .map((cw) => _courseWorkToDomain(cw, subMap[cw.id]))
          .toList();

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

  Future<Either<Failure, List<Announcement>>> _fetchAndCacheAnnouncements(
      String courseId) async {
    try {
      // お知らせ
      final allAnnouncements = <classroom.Announcement>[];
      String? pageToken;
      do {
        final res = await _api.courses.announcements.list(
          courseId,
          announcementStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: pageToken,
        );
        allAnnouncements.addAll(res.announcements ?? []);
        pageToken = res.nextPageToken;
      } while (pageToken != null);

      // 資料
      final allMaterials = <classroom.CourseWorkMaterial>[];
      String? matPageToken;
      do {
        final res = await _api.courses.courseWorkMaterials.list(
          courseId,
          courseWorkMaterialStates: ['PUBLISHED'],
          pageSize: 50,
          pageToken: matPageToken,
        );
        allMaterials.addAll(res.courseWorkMaterial ?? []);
        matPageToken = res.nextPageToken;
      } while (matPageToken != null);

      final domains = [
        ...allAnnouncements.map(_announcementToDomain),
        ...allMaterials.map(_materialToDomain),
      ]..sort((a, b) => b.creationTime.compareTo(a.creationTime));

      await _db.batch((batch) {
        batch.insertAll(
          _db.announcements,
          domains.map(_announcementToCompanion).toList(),
          mode: InsertMode.replace,
        );
      });
      return Right(domains);
    } on Exception catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  Announcement _materialToDomain(classroom.CourseWorkMaterial m) {
    final materials = _parseMaterials(m.materials ?? []);
    return Announcement(
      id: m.id!,
      courseId: m.courseId!,
      text: m.description ?? '',
      title: m.title,
      isMaterial: true,
      materials: materials,
      creationTime: DateTime.parse(m.creationTime!),
      updateTime:
          m.updateTime != null ? DateTime.parse(m.updateTime!) : null,
    );
  }

  // ────────────────────── Converters: Course ──────────────────────

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

  // ────────────────────── Converters: Assignment ──────────────────────

  Assignment _courseWorkToDomain(
    classroom.CourseWork cw,
    classroom.StudentSubmission? sub,
  ) {
    DateTime? dueDate;
    if (cw.dueDate != null) {
      // dueTime が存在する場合は hours/minutes のデフォルトを 0 にする。
      // proto3 JSON はデフォルト値(0)のフィールドを省略するため
      // `?.hours ?? 23` だと hours=0 が 23 に化ける。
      final hasTime = cw.dueTime != null;
      dueDate = DateTime.utc(
        cw.dueDate!.year!,
        cw.dueDate!.month!,
        cw.dueDate!.day!,
        hasTime ? (cw.dueTime!.hours ?? 0) : 23,
        hasTime ? (cw.dueTime!.minutes ?? 0) : 59,
      ).toLocal();
    }

    final materials = _parseMaterials(cw.materials ?? []);
    final submissionAttachments = _parseAttachments(
        sub?.assignmentSubmission?.attachments ?? []);

    return Assignment(
      id: cw.id!,
      courseId: cw.courseId!,
      title: cw.title ?? '',
      description: cw.description,
      dueDate: dueDate,
      state: _parseState(cw.state),
      submissionState: sub != null ? _parseSubmissionState(sub.state) : null,
      submissionId: sub?.id,
      materials: materials,
      submissionAttachments: submissionAttachments,
    );
  }

  AssignmentState _parseState(String? s) => switch (s?.toUpperCase()) {
        'PUBLISHED' => AssignmentState.published,
        'DRAFT' => AssignmentState.draft,
        'DELETED' => AssignmentState.deleted,
        _ => AssignmentState.published,
      };

  SubmissionState? _parseSubmissionState(String? s) =>
      switch (s?.toUpperCase()) {
        'TURNED_IN' => SubmissionState.turnedIn,
        'RETURNED' => SubmissionState.returned,
        'RECLAIMED_BY_STUDENT' => SubmissionState.reclaimedByStudent,
        'CREATED' => SubmissionState.created,
        'NEW_SUBMISSION_STATE' => SubmissionState.newSubmission,
        _ => null,
      };

  List<AssignmentMaterial> _parseMaterials(
      List<classroom.Material> materials) {
    final result = <AssignmentMaterial>[];
    for (final m in materials) {
      if (m.driveFile?.driveFile != null) {
        final df = m.driveFile!.driveFile!;
        final url = df.alternateLink ?? '';
        result.add(AssignmentMaterial(
          title: df.title ?? 'ファイル',
          url: url,
          type: AssignmentMaterialType.driveFile,
          driveFileId: df.id,
          mimeType: _inferMimeFromDriveUrl(url),
        ));
      } else if (m.youtubeVideo != null) {
        final yt = m.youtubeVideo!;
        result.add(AssignmentMaterial(
          title: yt.title ?? '動画',
          url: yt.alternateLink ?? '',
          type: AssignmentMaterialType.youTube,
        ));
      } else if (m.link != null) {
        final lk = m.link!;
        result.add(AssignmentMaterial(
          title: lk.title ?? lk.url ?? 'リンク',
          url: lk.url ?? '',
          type: AssignmentMaterialType.link,
        ));
      } else if (m.form != null) {
        final fm = m.form!;
        result.add(AssignmentMaterial(
          title: fm.title ?? 'フォーム',
          url: fm.responseUrl ?? fm.formUrl ?? '',
          type: AssignmentMaterialType.form,
        ));
      }
    }
    return result;
  }

  List<AssignmentMaterial> _parseAttachments(
      List<classroom.Attachment> attachments) {
    final result = <AssignmentMaterial>[];
    for (final a in attachments) {
      if (a.driveFile != null) {
        final df = a.driveFile!;
        final url = df.alternateLink ?? '';
        result.add(AssignmentMaterial(
          title: df.title ?? 'ファイル',
          url: url,
          type: AssignmentMaterialType.driveFile,
          driveFileId: df.id,
          mimeType: _inferMimeFromDriveUrl(url),
        ));
      } else if (a.youTubeVideo != null) {
        final yt = a.youTubeVideo!;
        result.add(AssignmentMaterial(
          title: yt.title ?? '動画',
          url: yt.alternateLink ?? '',
          type: AssignmentMaterialType.youTube,
        ));
      } else if (a.link != null) {
        final lk = a.link!;
        result.add(AssignmentMaterial(
          title: lk.title ?? lk.url ?? 'リンク',
          url: lk.url ?? '',
          type: AssignmentMaterialType.link,
        ));
      } else if (a.form != null) {
        final fm = a.form!;
        result.add(AssignmentMaterial(
          title: fm.title ?? 'フォーム',
          url: fm.responseUrl ?? fm.formUrl ?? '',
          type: AssignmentMaterialType.form,
        ));
      }
    }
    return result;
  }

  String? _inferMimeFromDriveUrl(String url) {
    if (url.contains('docs.google.com/document')) {
      return 'application/vnd.google-apps.document';
    } else if (url.contains('docs.google.com/spreadsheets')) {
      return 'application/vnd.google-apps.spreadsheet';
    } else if (url.contains('docs.google.com/presentation')) {
      return 'application/vnd.google-apps.presentation';
    } else if (url.contains('docs.google.com/forms')) {
      return 'application/vnd.google-apps.form';
    }
    return null;
  }

  AssignmentsCompanion _assignmentToCompanion(Assignment a) =>
      AssignmentsCompanion.insert(
        id: a.id,
        courseId: a.courseId,
        title: a.title,
        description: Value(a.description),
        dueDateMillis: Value(a.dueDate?.millisecondsSinceEpoch),
        state: Value(a.state.name),
        submissionState: Value(a.submissionState?.name),
        submissionId: Value(a.submissionId),
        materialsJson: Value(a.materials.isEmpty
            ? null
            : jsonEncode(a.materials.map((m) => m.toJson()).toList())),
        submissionAttachmentsJson: Value(a.submissionAttachments.isEmpty
            ? null
            : jsonEncode(
                a.submissionAttachments.map((m) => m.toJson()).toList())),
      );

  Assignment _assignmentRowToDomain(AssignmentRow r) {
    final materials = r.materialsJson != null
        ? (jsonDecode(r.materialsJson!) as List)
            .map((e) =>
                AssignmentMaterial.fromJson(e as Map<String, dynamic>))
            .toList()
        : <AssignmentMaterial>[];

    return Assignment(
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
      submissionId: r.submissionId,
      materials: materials,
      submissionAttachments: r.submissionAttachmentsJson != null
          ? (jsonDecode(r.submissionAttachmentsJson!) as List)
              .map((e) =>
                  AssignmentMaterial.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // ────────────────────── Converters: Announcement ──────────────────────

  Announcement _announcementToDomain(classroom.Announcement a) =>
      Announcement(
        id: a.id!,
        courseId: a.courseId!,
        text: a.text ?? '',
        creationTime: DateTime.parse(a.creationTime!),
        updateTime:
            a.updateTime != null ? DateTime.parse(a.updateTime!) : null,
      );

  AnnouncementsCompanion _announcementToCompanion(Announcement a) =>
      AnnouncementsCompanion.insert(
        id: a.id,
        courseId: a.courseId,
        body: a.text,
        creationTimeMillis: a.creationTime.millisecondsSinceEpoch,
        updateTimeMillis: Value(a.updateTime?.millisecondsSinceEpoch),
        title: Value(a.title),
        isMaterial: Value(a.isMaterial),
        materialsJson: Value(a.materials.isEmpty
            ? null
            : jsonEncode(a.materials.map((m) => m.toJson()).toList())),
      );

  Announcement _announcementRowToDomain(AnnouncementRow r) {
    final materials = r.materialsJson != null
        ? (jsonDecode(r.materialsJson!) as List)
            .map((e) => AssignmentMaterial.fromJson(e as Map<String, dynamic>))
            .toList()
        : <AssignmentMaterial>[];
    return Announcement(
      id: r.id,
      courseId: r.courseId,
      text: r.body,
      creationTime: DateTime.fromMillisecondsSinceEpoch(r.creationTimeMillis),
      updateTime: r.updateTimeMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(r.updateTimeMillis!)
          : null,
      title: r.title,
      isMaterial: r.isMaterial,
      materials: materials,
    );
  }

  // ────────────────────── Pub/Sub Registrations ──────────────────────

  static const _pubsubTopic =
      'projects/core-phoenix-489602-b1/topics/classroom-notifications';

  /// 各コースの COURSE_WORK_CHANGES を Classroom Pub/Sub に登録する。
  /// 登録済みのコースは 409 が返るのでスキップする。
  Future<void> registerPubSubFeeds(List<String> courseIds) async {
    for (final courseId in courseIds) {
      try {
        await _api.registrations.create(
          classroom.Registration(
            feed: classroom.Feed(
              feedType: 'COURSE_WORK_CHANGES',
              courseWorkChangesInfo:
                  classroom.CourseWorkChangesInfo(courseId: courseId),
            ),
            cloudPubsubTopic:
                classroom.CloudPubsubTopic(topicName: _pubsubTopic),
          ),
        );
      } catch (e) {
        if (!e.toString().contains('409') &&
            !e.toString().contains('already exists')) {
          rethrow;
        }
      }
    }
  }
}
