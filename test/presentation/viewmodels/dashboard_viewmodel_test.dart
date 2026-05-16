// test/presentation/viewmodels/dashboard_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/core/services/classroom_sync_service.dart';
import 'package:classroom_remaked/data/datasources/local/course_order_datasource.dart';
import 'package:classroom_remaked/data/datasources/local/hidden_items_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/dashboard_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}
class MockClassroomSyncService extends Mock implements ClassroomSyncService {}
class MockCourseOrderDataSource extends Mock implements CourseOrderDataSource {}
class MockHiddenItemsDataSource extends Mock implements HiddenItemsDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(days: 7));
  });

  late MockLmsRepository mockRepo;
  late MockClassroomSyncService mockSync;
  late MockCourseOrderDataSource mockOrder;
  late MockHiddenItemsDataSource mockHidden;

  final fakeCourses = [
    const Course(id: 'c1', name: 'Math'),
    const Course(id: 'c2', name: 'Science'),
  ];

  ProviderContainer makeContainer({Set<String> hiddenIds = const {}}) {
    when(() => mockSync.fullSync()).thenAnswer((_) async {});
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getUpcomingDeadlines(within: any(named: 'within')))
        .thenAnswer((_) async => const Right(<Assignment>[]));
    when(() => mockOrder.getOrderedIds())
        .thenAnswer((_) async => ['c1', 'c2']);
    when(() => mockOrder.initializeNewCourses(any()))
        .thenAnswer((_) async {});
    when(() => mockHidden.getHiddenIds('course'))
        .thenAnswer((_) async => hiddenIds);
    when(() => mockHidden.hide(any(), any())).thenAnswer((_) async {});
    when(() => mockHidden.unhide(any())).thenAnswer((_) async {});

    return ProviderContainer(
      overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
        classroomSyncServiceProvider.overrideWithValue(mockSync),
        courseOrderDataSourceProvider.overrideWithValue(mockOrder),
        hiddenItemsDataSourceProvider.overrideWithValue(mockHidden),
      ],
    );
  }

  setUp(() {
    mockRepo = MockLmsRepository();
    mockSync = MockClassroomSyncService();
    mockOrder = MockCourseOrderDataSource();
    mockHidden = MockHiddenItemsDataSource();
  });

  test('build時にfullSyncを呼びDashboardStateを返す', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.future);
    final state = container.read(dashboardViewModelProvider);

    verify(() => mockSync.fullSync()).called(1);
    expect(state.value!.visibleCourses.length, 2);
    expect(state.value!.visibleCourses.first.id, 'c1');
  });

  test('非表示コースは visibleCourses に含まれない', () async {
    final container = makeContainer(hiddenIds: {'c1'});
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.future);
    final state = container.read(dashboardViewModelProvider);

    expect(state.value!.visibleCourses.length, 1);
    expect(state.value!.visibleCourses.first.id, 'c2');
  });

  test('toggleShowHidden で非表示コースが表示される', () async {
    final container = makeContainer(hiddenIds: {'c1'});
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.future);
    container.read(dashboardViewModelProvider.notifier).toggleShowHidden();
    final state = container.read(dashboardViewModelProvider);

    expect(state.value!.showHidden, isTrue);
    expect(state.value!.visibleCourses.length, 2);
  });

  test('hideItem が HiddenItemsDataSource.hide を呼ぶ', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.future);
    await container
        .read(dashboardViewModelProvider.notifier)
        .hideItem('c1');

    verify(() => mockHidden.hide('c1', 'course')).called(1);
  });

  test('unhideItem が HiddenItemsDataSource.unhide を呼び visibleCourses に戻る', () async {
    final container = makeContainer(hiddenIds: {'c1'});
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.future);
    // c1 は非表示なので visibleCourses に含まれない
    expect(container.read(dashboardViewModelProvider).value!.visibleCourses.length, 1);

    await container
        .read(dashboardViewModelProvider.notifier)
        .unhideItem('c1');

    verify(() => mockHidden.unhide('c1')).called(1);
    // 解除後は visibleCourses に c1 が戻る
    expect(container.read(dashboardViewModelProvider).value!.visibleCourses.length, 2);
  });

  test('reorderCourses で並び順が更新される', () async {
    when(() => mockOrder.updateOrder(any())).thenAnswer((_) async {});
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.future);
    await container
        .read(dashboardViewModelProvider.notifier)
        .reorderCourses(0, 2);

    verify(() => mockOrder.updateOrder(['c2', 'c1'])).called(1);
  });
}
