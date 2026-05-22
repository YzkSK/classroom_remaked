// lib/domain/entities/assignment_material.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assignment_material.freezed.dart';

enum AssignmentMaterialType { driveFile, youTube, link, form }

@freezed
class AssignmentMaterial with _$AssignmentMaterial {
  const AssignmentMaterial._();

  const factory AssignmentMaterial({
    required String title,
    required String url,
    required AssignmentMaterialType type,
    String? driveFileId,
    String? mimeType,
  }) = _AssignmentMaterial;

  static AssignmentMaterial fromJson(Map<String, dynamic> json) =>
      AssignmentMaterial(
        title: json['title'] as String,
        url: json['url'] as String,
        type: AssignmentMaterialType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AssignmentMaterialType.link,
        ),
        driveFileId: json['driveFileId'] as String?,
        mimeType: json['mimeType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type.name,
        if (driveFileId != null) 'driveFileId': driveFileId,
        if (mimeType != null) 'mimeType': mimeType,
      };
}
