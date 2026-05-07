// test/data/repositories/google_classroom_repository_test.dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/repositories/google_classroom_repository.dart';

class MockClassroomApi extends Mock implements classroom.ClassroomApi {}
class MockCoursesResource extends Mock implements classroom.CoursesResource {}
class MockCoursesCourseWorkResource extends Mock
    implements classroom.CoursesCourseWorkResource {}

void main() {
  late AppDatabase db;
  late MockClassroomApi mockApi;
  late GoogleClassroomRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockApi = MockClassroomApi();
    repository =
        GoogleClassroomRepository.withApi(database: db, api: mockApi);
  });

  tearDown(() async => db.close());

  group('getCourses (cache-first)', () {
    test('キャッシュが空の場合はAPIから取得してキャッシュする', () async {
      final mockCourses = MockCoursesResource();
      when(() => mockApi.courses).thenReturn(mockCourses);
      when(() => mockCourses.list(
                courseStates: any(named: 'courseStates'),
                pageSize: any(named: 'pageSize'),
              ))
          .thenAnswer((_) async => classroom.ListCoursesResponse(
                courses: [
                  classroom.Course(id: 'c1', name: 'Math'),
                ],
              ));

      final result = await repository.getCourses();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).first.name, 'Math');
      final cached = await db.select(db.courses).get();
      expect(cached.length, 1);
    });

    test('キャッシュがある場合はAPIを呼ばずにキャッシュを返す', () async {
      await db.into(db.courses).insert(
        CoursesCompanion.insert(id: 'c1', name: 'Cached'),
      );

      final result = await repository.getCourses();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []).first.name, 'Cached');
      verifyNever(() => mockApi.courses);
    });

    test('refreshCourses はキャッシュがあってもAPIを呼ぶ', () async {
      await db.into(db.courses).insert(
        CoursesCompanion.insert(id: 'c1', name: 'Old'),
      );

      final mockCourses = MockCoursesResource();
      when(() => mockApi.courses).thenReturn(mockCourses);
      when(() => mockCourses.list(
                courseStates: any(named: 'courseStates'),
                pageSize: any(named: 'pageSize'),
              ))
          .thenAnswer((_) async => classroom.ListCoursesResponse(
                courses: [classroom.Course(id: 'c1', name: 'Updated')],
              ));

      final result = await repository.refreshCourses();

      expect(result.getOrElse(() => []).first.name, 'Updated');
    });
  });

  group('getUpcomingDeadlines', () {
    test('driftキャッシュから今後7日以内の未提出課題を返す', () async {
      final now = DateTime.now();

      await db.batch((batch) {
        batch.insertAll(db.assignments, [
          AssignmentsCompanion.insert(
            id: 'a1', courseId: 'c1', title: '明日',
            dueDateMillis: Value(
                now.add(const Duration(days: 1)).millisecondsSinceEpoch),
          ),
          AssignmentsCompanion.insert(
            id: 'a2', courseId: 'c1', title: '10日後（範囲外）',
            dueDateMillis: Value(
                now.add(const Duration(days: 10)).millisecondsSinceEpoch),
          ),
          AssignmentsCompanion.insert(
            id: 'a3', courseId: 'c1', title: '提出済み',
            dueDateMillis: Value(
                now.add(const Duration(days: 2)).millisecondsSinceEpoch),
            submissionState: const Value('turnedIn'),
          ),
        ]);
      });

      final result = await repository.getUpcomingDeadlines(
          within: const Duration(days: 7));

      expect(result.isRight(), true);
      final deadlines = result.getOrElse(() => []);
      expect(deadlines.length, 1);
      expect(deadlines.first.title, '明日');
    });
  });
}
