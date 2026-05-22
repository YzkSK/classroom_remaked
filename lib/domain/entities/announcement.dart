// lib/domain/entities/announcement.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'assignment_material.dart';
part 'announcement.freezed.dart';

@freezed
class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String courseId,
    required String text,
    required DateTime creationTime,
    DateTime? updateTime,
    String? title,
    @Default(false) bool isMaterial,
    @Default([]) List<AssignmentMaterial> materials,
  }) = _Announcement;
}
