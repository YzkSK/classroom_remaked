// lib/domain/repositories/lms_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/assignment.dart';
import '../entities/announcement.dart';
import '../entities/course.dart';
import '../errors/failures.dart';

abstract class LmsRepository {
  Future<Either<Failure, List<Course>>> getCourses();
  Future<Either<Failure, List<Assignment>>> getAssignments(String courseId);
  Future<Either<Failure, List<Announcement>>> getAnnouncements(String courseId);
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({
    required Duration within,
  });
  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  );
  Future<Either<Failure, void>> addAttachment(
    String courseId,
    String courseWorkId,
    String submissionId,
    String driveFileId,
  );
  Future<Either<Failure, void>> reclaimSubmission(
    String courseId,
    String assignmentId,
    String submissionId,
  );
}
