// test/data/datasources/local/user_preferences_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/user_preferences_datasource.dart';

void main() {
  late AppDatabase db;
  late UserPreferencesDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = UserPreferencesDataSource(db);
  });

  tearDown(() async => db.close());

  test('getNotifyBeforeHours はデフォルト 24 を返す', () async {
    final hours = await ds.getNotifyBeforeHours();
    expect(hours, 24);
  });

  test('setNotifyBeforeHours で値が保存される', () async {
    await ds.setNotifyBeforeHours(48);
    final hours = await ds.getNotifyBeforeHours();
    expect(hours, 48);
  });

  test('getLazyModeEnabled はデフォルト false を返す', () async {
    final enabled = await ds.getLazyModeEnabled();
    expect(enabled, false);
  });

  test('setLazyModeEnabled(true) で値が保存される', () async {
    await ds.setLazyModeEnabled(true);
    final enabled = await ds.getLazyModeEnabled();
    expect(enabled, true);
  });

  test('getOnboardingDone はデフォルト false を返す', () async {
    final done = await ds.getOnboardingDone();
    expect(done, false);
  });

  test('setOnboardingDone(true) で値が保存される', () async {
    await ds.setOnboardingDone(true);
    final done = await ds.getOnboardingDone();
    expect(done, true);
  });
}
