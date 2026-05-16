// test/presentation/viewmodels/settings_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/data/datasources/local/user_preferences_datasource.dart';
import 'package:classroom_remaked/domain/entities/assignment.dart';
import 'package:classroom_remaked/presentation/viewmodels/settings_viewmodel.dart';

class MockUserPreferencesDataSource extends Mock
    implements UserPreferencesDataSource {}

void main() {
  late MockUserPreferencesDataSource mockPrefs;

  setUp(() {
    mockPrefs = MockUserPreferencesDataSource();
    when(() => mockPrefs.getNotifyBeforeHours()).thenAnswer((_) async => 24);
    when(() => mockPrefs.getLazyModeEnabled()).thenAnswer((_) async => false);
    when(() => mockPrefs.setNotifyBeforeHours(any()))
        .thenAnswer((_) async {});
    when(() => mockPrefs.setLazyModeEnabled(any())).thenAnswer((_) async {});
    when(() => mockPrefs.getOnboardingDone()).thenAnswer((_) async => false);
    when(() => mockPrefs.setOnboardingDone(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        userPreferencesDataSourceProvider.overrideWithValue(mockPrefs),
      ]);

  test('build 時に UserPreferences から設定を読み込む', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    final state = container.read(settingsViewModelProvider).value!;
    expect(state.notifyBeforeHours, 24);
    expect(state.lazyModeEnabled, false);
  });

  test('setNotifyBeforeHours で状態と datasource が更新される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setNotifyBeforeHours(48);
    verify(() => mockPrefs.setNotifyBeforeHours(48)).called(1);
    final state = container.read(settingsViewModelProvider).value!;
    expect(state.notifyBeforeHours, 48);
  });

  test('setNotifyBeforeHours(23) は無視される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setNotifyBeforeHours(23);
    verifyNever(() => mockPrefs.setNotifyBeforeHours(any()));
  });

  test('enableLazyMode で状態と datasource が更新される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    await container.read(settingsViewModelProvider.notifier).enableLazyMode();
    verify(() => mockPrefs.setLazyModeEnabled(true)).called(1);
    final state = container.read(settingsViewModelProvider).value!;
    expect(state.lazyModeEnabled, true);
  });

  test('tryDisableLazyMode — 未提出課題あり → false を返す', () async {
    when(() => mockPrefs.getLazyModeEnabled()).thenAnswer((_) async => true);
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    final now = DateTime.now();
    final blocking = [
      Assignment(
        id: 'a1',
        courseId: 'c1',
        title: 'A',
        dueDate: now.add(const Duration(hours: 12)),
      ),
    ];
    final result = await container
        .read(settingsViewModelProvider.notifier)
        .tryDisableLazyMode(blocking);
    expect(result, false);
    verifyNever(() => mockPrefs.setLazyModeEnabled(any()));
  });

  test('tryDisableLazyMode — 未提出課題なし → true を返し OFF に切り替わる', () async {
    when(() => mockPrefs.getLazyModeEnabled()).thenAnswer((_) async => true);
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(settingsViewModelProvider.future);
    final result = await container
        .read(settingsViewModelProvider.notifier)
        .tryDisableLazyMode([]);
    expect(result, true);
    verify(() => mockPrefs.setLazyModeEnabled(false)).called(1);
  });
}
