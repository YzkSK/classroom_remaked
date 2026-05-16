// lib/presentation/viewmodels/turn_in_viewmodel.dart
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/errors/failures.dart';
part 'turn_in_viewmodel.g.dart';

@riverpod
class TurnInViewModel extends _$TurnInViewModel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> turnIn(
    String courseId,
    String assignmentId,
    String submissionId,
  ) async {
    state = const AsyncLoading();
    final repo = ref.read(lmsRepositoryProvider);
    final result =
        await repo.turnIn(courseId, assignmentId, submissionId);
    state = const AsyncData(null);
    return result;
  }
}
