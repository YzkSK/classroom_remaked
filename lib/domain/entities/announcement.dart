// lib/domain/entities/announcement.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'announcement.freezed.dart';

@freezed
class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String courseId,
    required String text,
    required DateTime creationTime,
    DateTime? updateTime,
  }) = _Announcement;
}
