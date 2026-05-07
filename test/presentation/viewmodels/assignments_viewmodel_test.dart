// test/presentation/viewmodels/assignments_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/assignments_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}

void main() {
  late MockLmsRepository mockRepo;
  late ProviderContainer container;

  final fakeCourses = [const Course(id: 'c1', name: 'Math')];
  final fakeAssignments = [
    Assignment(id: 'a1', courseId: 'c1', title: 'Early',
        dueDate: DateTime(2026, 6, 1)),
    Assignment(id: 'a2', courseId: 'c1', title: 'Late',
        dueDate: DateTime(2026, 6, 10)),
    Assignment(id: 'a3', courseId: 'c1', title: 'Submitted',
        dueDate: DateTime(2026, 6, 5),
        submissionState: SubmissionState.turnedIn),
  ];

  setUp(() {
    mockRepo = MockLmsRepository();
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getAssignments(any()))
        .thenAnswer((_) async => Right(fakeAssignments));

    container = ProviderContainer(
      overrides: [lmsRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('締め切り順に並ぶ', () async {
    await container.read(assignmentsViewModelProvider.future);
    final assignments =
        container.read(assignmentsViewModelProvider).value!.filteredAssignments;
    expect(assignments[0].title, 'Early');
    expect(assignments[1].title, 'Submitted');
    expect(assignments[2].title, 'Late');
  });

  test('未提出フィルターで提出済みを除外する', () async {
    await container.read(assignmentsViewModelProvider.future);
    container.read(assignmentsViewModelProvider.notifier)
        .setFilter(AssignmentsFilter.unsubmitted);
    final assignments =
        container.read(assignmentsViewModelProvider).value!.filteredAssignments;
    expect(assignments.length, 2);
    expect(assignments.any((a) => a.title == 'Submitted'), false);
  });
}
