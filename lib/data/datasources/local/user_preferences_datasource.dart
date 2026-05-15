// lib/data/datasources/local/user_preferences_datasource.dart
import 'app_database.dart';

class UserPreferencesDataSource {
  UserPreferencesDataSource(this._db);

  final AppDatabase _db;

  static const _keyNotifyBeforeHours = 'notifyBeforeHours';
  static const _keyLazyModeEnabled = 'lazyModeEnabled';
  static const _keySnoozeHours = 'snoozeHours';
  static const _keyOnboardingDone = 'notificationOnboardingDone';

  Future<String?> _get(String key) async {
    final row = await (_db.select(_db.userPreferences)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) async {
    await _db.into(_db.userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion.insert(key: key, value: value),
    );
  }

  Future<int> getNotifyBeforeHours() async {
    final v = await _get(_keyNotifyBeforeHours);
    return v != null ? int.parse(v) : 24;
  }

  Future<void> setNotifyBeforeHours(int hours) =>
      _set(_keyNotifyBeforeHours, hours.toString());

  Future<int> getSnoozeHours() async {
    final v = await _get(_keySnoozeHours);
    return v != null ? int.parse(v) : 1;
  }

  Future<void> setSnoozeHours(int hours) =>
      _set(_keySnoozeHours, hours.toString());

  Future<bool> getLazyModeEnabled() async {
    final v = await _get(_keyLazyModeEnabled);
    return v == 'true';
  }

  Future<void> setLazyModeEnabled(bool enabled) =>
      _set(_keyLazyModeEnabled, enabled.toString());

  Future<bool> getOnboardingDone() async {
    final v = await _get(_keyOnboardingDone);
    return v == 'true';
  }

  Future<void> setOnboardingDone(bool done) =>
      _set(_keyOnboardingDone, done.toString());
}
