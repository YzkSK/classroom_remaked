// lib/domain/entities/assignment_material.dart
enum AssignmentMaterialType { driveFile, youTube, link, form }

class AssignmentMaterial {
  const AssignmentMaterial({
    required this.title,
    required this.url,
    required this.type,
    this.driveFileId,
    this.mimeType,
  });

  final String title;
  final String url;
  final AssignmentMaterialType type;
  final String? driveFileId;
  final String? mimeType;

  factory AssignmentMaterial.fromJson(Map<String, dynamic> json) =>
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

  @override
  bool operator ==(Object other) =>
      other is AssignmentMaterial &&
      other.title == title &&
      other.url == url &&
      other.type == type &&
      other.driveFileId == driveFileId;

  @override
  int get hashCode => Object.hash(title, url, type, driveFileId);
}
