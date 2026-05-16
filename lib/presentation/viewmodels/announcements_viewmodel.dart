// lib/presentation/viewmodels/announcements_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/announcement.dart';
part 'announcements_viewmodel.g.dart';

@riverpod
Future<List<Announcement>> announcementsViewModel(
  AnnouncementsViewModelRef ref,
  String courseId,
) async {
  final repo = ref.watch(lmsRepositoryProvider);
  final result = await repo.getAnnouncements(courseId);
  return result.getOrElse(() => []);
}
