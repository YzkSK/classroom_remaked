// test/presentation/viewmodels/assignments_viewmodel_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/data/datasources/local/hidden_items_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/domain/entities/course.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/presentation/viewmodels/assignments_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}
class MockHiddenItemsDataSource extends Mock implements HiddenItemsDataSource {}

void main() {
  late MockLmsRepository mockRepo;
  late MockHiddenItemsDataSource mockHidden;

  final fakeCourses = [const Course(id: 'c1', name: 'Math')];
  final fakeAssignments = [
    Assignment(
      id: 'a1',
      courseId: 'c1',
      title: 'Assignment 1',
      dueDate: DateTime(2026, 6, 1),
    ),
    Assignment(
      id: 'a2',
      courseId: 'c1',
      title: 'Assignment 2',
      dueDate: DateTime(2026, 6, 2),
    ),
  ];

  ProviderContainer makeContainer({Set<String> hiddenIds = const {}}) {
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => const Right([]));
    when(() => mockRepo.getCourses())
        .thenAnswer((_) async => Right(fakeCourses));
    when(() => mockRepo.getAssignments(any()))
        .thenAnswer((_) async => Right(fakeAssignments));
    when(() => mockHidden.getHiddenIds('assignment'))
        .thenAnswer((_) async => hiddenIds);
    when(() => mockHidden.hide(any(), any())).thenAnswer((_) async {});
    when(() => mockHidden.unhide(any())).thenAnswer((_) async {});

    return ProviderContainer(
      overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
        hiddenItemsDataSourceProvider.overrideWithValue(mockHidden),
      ],
    );
  }

  setUp(() {
    mockRepo = MockLmsRepository();
    mockHidden = MockHiddenItemsDataSource();
  });

  test('build時に課題一覧を締め切り順で返す', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(assignmentsViewModelProvider.future);
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.visibleAssignments.length, 2);
    expect(state.value!.visibleAssignments.first.id, 'a1');
  });

  test('非表示課題は visibleAssignments に含まれない', () async {
    final container = makeContainer(hiddenIds: {'a1'});
    addTearDown(container.dispose);

    await container.read(assignmentsViewModelProvider.future);
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.visibleAssignments.length, 1);
    expect(state.value!.visibleAssignments.first.id, 'a2');
  });

  test('toggleShowHidden で非表示課題が表示される', () async {
    final container = makeContainer(hiddenIds: {'a1'});
    addTearDown(container.dispose);

    await container.read(assignmentsViewModelProvider.future);
    container.read(assignmentsViewModelProvider.notifier).toggleShowHidden();
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.showHidden, isTrue);
    expect(state.value!.visibleAssignments.length, 2);
  });

  test('hideItem が HiddenItemsDataSource.hide を呼ぶ', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(assignmentsViewModelProvider.future);
    await container
        .read(assignmentsViewModelProvider.notifier)
        .hideItem('a1');

    verify(() => mockHidden.hide('a1', 'assignment')).called(1);
  });

  test('unhideItem が HiddenItemsDataSource.unhide を呼び visibleAssignments に戻る', () async {
    final container = makeContainer(hiddenIds: {'a1'});
    addTearDown(container.dispose);

    await container.read(assignmentsViewModelProvider.future);
    expect(container.read(assignmentsViewModelProvider).value!.visibleAssignments.length, 1);

    await container
        .read(assignmentsViewModelProvider.notifier)
        .unhideItem('a1');

    verify(() => mockHidden.unhide('a1')).called(1);
    expect(container.read(assignmentsViewModelProvider).value!.visibleAssignments.length, 2);
  });

  test('setFilter で未提出のみ絞り込める', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(assignmentsViewModelProvider.future);
    container
        .read(assignmentsViewModelProvider.notifier)
        .setFilter(AssignmentsFilter.unsubmitted);
    final state = container.read(assignmentsViewModelProvider);

    expect(state.value!.filter, AssignmentsFilter.unsubmitted);
  });
}
