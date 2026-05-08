// lib/presentation/viewmodels/settings_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/usecases/can_disable_lazy_mode_usecase.dart';
part 'settings_viewmodel.g.dart';

class SettingsState {
  const SettingsState({
    required this.notifyBeforeHours,
    required this.lazyModeEnabled,
  });

  final int notifyBeforeHours;
  final bool lazyModeEnabled;

  SettingsState copyWith({int? notifyBeforeHours, bool? lazyModeEnabled}) =>
      SettingsState(
        notifyBeforeHours: notifyBeforeHours ?? this.notifyBeforeHours,
        lazyModeEnabled: lazyModeEnabled ?? this.lazyModeEnabled,
      );
}

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  Future<SettingsState> build() async {
    final prefs = ref.watch(userPreferencesDataSourceProvider);
    final hours = await prefs.getNotifyBeforeHours();
    final lazy = await prefs.getLazyModeEnabled();
    return SettingsState(notifyBeforeHours: hours, lazyModeEnabled: lazy);
  }

  Future<void> setNotifyBeforeHours(int hours) async {
    if (hours < 24) return;
    await ref.read(userPreferencesDataSourceProvider).setNotifyBeforeHours(hours);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(notifyBeforeHours: hours));
  }

  Future<void> enableLazyMode() async {
    await ref.read(userPreferencesDataSourceProvider).setLazyModeEnabled(true);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(lazyModeEnabled: true));
  }

  Future<bool> tryDisableLazyMode(List<Assignment> assignments) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final count = const CanDisableLazyModeUseCase().countBlockingAssignments(
      assignments: assignments,
      notifyBefore: Duration(hours: current.notifyBeforeHours),
      now: DateTime.now(),
    );
    if (count > 0) return false;
    await ref.read(userPreferencesDataSourceProvider).setLazyModeEnabled(false);
    state = AsyncData(current.copyWith(lazyModeEnabled: false));
    return true;
  }

  Future<void> completeOnboarding() async {
    await ref.read(userPreferencesDataSourceProvider).setOnboardingDone(true);
  }
}
