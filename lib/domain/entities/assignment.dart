// lib/domain/entities/assignment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'assignment.freezed.dart';

enum AssignmentState { published, draft, deleted }

enum SubmissionState {
  newSubmission,
  created,
  turnedIn,
  returned,
  reclaimedByStudent,
}

@freezed
class Assignment with _$Assignment {
  const factory Assignment({
    required String id,
    required String courseId,
    required String title,
    String? description,
    DateTime? dueDate,
    @Default(AssignmentState.published) AssignmentState state,
    SubmissionState? submissionState,
  }) = _Assignment;
}
