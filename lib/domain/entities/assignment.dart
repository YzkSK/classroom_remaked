// lib/domain/entities/assignment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'assignment_material.dart';

export 'assignment_material.dart';

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
    String? submissionId,
    @Default([]) List<AssignmentMaterial> materials,
  }) = _Assignment;
}
