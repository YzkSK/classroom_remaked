// lib/presentation/views/shared/fake_fixtures.dart
import '../../../domain/entities/assignment.dart';
import '../../../domain/entities/course.dart';

abstract final class FakeFixtures {
  static final assignments = List.generate(
    5,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Assignment Title Example Long',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  static final deadlines = List.generate(
    3,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Sample Assignment Title',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );

  static final courses = List.generate(
    4,
    (i) => Course(id: 'fake_$i', name: 'Course Name Example'),
  );

  static final courseAssignments = List.generate(
    3,
    (i) => Assignment(
      id: 'fake_$i',
      courseId: 'fake',
      title: 'Assignment Title Example',
      dueDate: DateTime.now().add(Duration(days: i + 1)),
    ),
  );
}
