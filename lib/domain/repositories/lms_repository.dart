// lib/domain/repositories/lms_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/assignment.dart';
import '../entities/announcement.dart';
import '../entities/comment.dart';
import '../entities/course.dart';
import '../errors/failures.dart';

class SearchResult {
  const SearchResult({
    required this.id,
    required this.courseId,
    required this.title,
    required this.snippet,
    required this.type,
  });

  final String id;
  final String courseId;
  final String title;
  final String snippet;
  final SearchResultType type;
}

enum SearchResultType { assignment, announcement }

class AssignmentSubmission {
  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.state,
    this.submittedAt,
  });

  final String id;
  final String assignmentId;
  final SubmissionState state;
  final DateTime? submittedAt;
}

abstract class LmsRepository {
  Future<Either<Failure, List<Course>>> getCourses();
  Future<Either<Failure, List<Assignment>>> getAssignments(String courseId);
  Future<Either<Failure, List<Announcement>>> getAnnouncements(String courseId);
  Future<Either<Failure, List<Assignment>>> getUpcomingDeadlines({
    required Duration within,
  });
  Future<Either<Failure, List<SearchResult>>> search(String query);
  Future<Either<Failure, AssignmentSubmission?>> getSubmission(
    String courseId,
    String assignmentId,
  );
  Future<Either<Failure, List<Comment>>> getComments(
    String courseId,
    String itemId, {
    CommentVisibility? filterBy,
  });
}
