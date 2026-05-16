import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:classroom_remaked/domain/entities/announcement.dart';
import 'package:classroom_remaked/domain/errors/failures.dart';
import 'package:classroom_remaked/domain/repositories/lms_repository.dart';
import 'package:classroom_remaked/core/di/providers.dart';
import 'package:classroom_remaked/presentation/viewmodels/announcements_viewmodel.dart';

class MockLmsRepository extends Mock implements LmsRepository {}

void main() {
  late MockLmsRepository mockRepo;

  setUp(() {
    mockRepo = MockLmsRepository();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        lmsRepositoryProvider.overrideWithValue(mockRepo),
      ]);

  test('お知らせ一覧を取得して返す', () async {
    final now = DateTime(2026, 5, 15, 12, 0);
    when(() => mockRepo.getAnnouncements('c1')).thenAnswer(
      (_) async => Right([
        Announcement(
          id: 'a1',
          courseId: 'c1',
          text: 'テスト連絡',
          creationTime: now,
        ),
      ]),
    );
    final container = makeContainer();
    addTearDown(container.dispose);
    final result = await container.read(
      announcementsViewModelProvider('c1').future,
    );
    expect(result.length, 1);
    expect(result.first.text, 'テスト連絡');
  });

  test('エラー時は空リストを返す', () async {
    when(() => mockRepo.getAnnouncements('c1'))
        .thenAnswer((_) async => const Left(ApiFailure('network error')));
    final container = makeContainer();
    addTearDown(container.dispose);
    final result = await container.read(
      announcementsViewModelProvider('c1').future,
    );
    expect(result, isEmpty);
  });
}
