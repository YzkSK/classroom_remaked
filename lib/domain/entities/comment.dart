// lib/domain/entities/comment.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment.freezed.dart';

enum CommentVisibility { classWide, private }

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String authorName,
    required String body,
    required DateTime createdAt,
    required CommentVisibility visibility,
  }) = _Comment;
}
