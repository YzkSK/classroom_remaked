import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/presentation/viewmodels/search_viewmodel.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MockAppDatabase mockDb;

  setUp(() {
    mockDb = MockAppDatabase();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(mockDb),
      ]);

  test('初期状態はクエリ空・結果空', () {
    final container = makeContainer();
    addTearDown(container.dispose);
    final state = container.read(searchViewModelProvider);
    expect(state.query, '');
    expect(state.results, isEmpty);
  });

  test('search でキーワードにマッチする課題が返る', () async {
    when(() => mockDb.searchAssignments('数学')).thenAnswer(
      (_) async => [
        AssignmentRow(
          id: 'a1',
          courseId: 'c1',
          title: '数学レポート',
          description: null,
          dueDateMillis: null,
          state: 'published',
          submissionState: null,
        ),
      ],
    );
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(searchViewModelProvider.notifier).search('数学');
    final state = container.read(searchViewModelProvider);
    expect(state.query, '数学');
    expect(state.results.length, 1);
    expect(state.results.first.title, '数学レポート');
  });

  test('クエリ空では検索せず結果を空にする', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(searchViewModelProvider.notifier).search('');
    verifyNever(() => mockDb.searchAssignments(any()));
    expect(container.read(searchViewModelProvider).results, isEmpty);
  });
}
