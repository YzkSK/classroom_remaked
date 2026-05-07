// test/presentation/viewmodels/dashboard_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/core/services/classroom_sync_service.dart';
import 'package:classroom_remaked/data/datasources/local/course_order_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/dashboard_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}
class MockClassroomSyncService extends Mock implements ClassroomSyncService {}
class MockCourseOrderDataSource extends Mock implements CourseOrderDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(days: 7));
  });

  late MockLmsRepository mockRepo;
  late MockClassroomSyncService mockSync;
  late MockCourseOrderDataSource mockOrder;
  late ProviderContainer container;

  final fakeCourses = [
    const Course(id: 'c1', name: 'Math'),
    const Course(id: 'c2', name: 'Science'),
  ];

  setUp(() {
    mockRepo = MockLmsRepository();
    mockSync = MockClassroomSyncService();
    mockOrder = MockCourseOrderDataSource();

    when(() => mockSync.fullSync()).thenAnswer((_) async {});
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getUpcomingDeadlines(within: any(named: 'within')))
        .thenAnswer((_) async => Right(<Assignment>[]));
    when(() => mockOrder.getOrderedIds())
        .thenAnswer((_) async => ['c1', 'c2']);
    when(() => mockOrder.initializeNewCourses(any()))
        .thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
        classroomSyncServiceProvider.overrideWithValue(mockSync),
        courseOrderDataSourceProvider.overrideWithValue(mockOrder),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build時にfullSyncを呼びDashboardStateを返す', () async {
    await container.read(dashboardViewModelProvider.future);
    final state = container.read(dashboardViewModelProvider);

    verify(() => mockSync.fullSync()).called(1);
    expect(state.value!.courses.length, 2);
    expect(state.value!.orderedCourses.first.id, 'c1');
  });

  test('reorderCourses で並び順が更新される', () async {
    when(() => mockOrder.updateOrder(any())).thenAnswer((_) async {});

    await container.read(dashboardViewModelProvider.future);
    await container
        .read(dashboardViewModelProvider.notifier)
        .reorderCourses(0, 2);

    verify(() => mockOrder.updateOrder(['c2', 'c1'])).called(1);
  });
}
