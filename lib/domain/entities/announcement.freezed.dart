// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'announcement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Announcement {
  String get id => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  DateTime get creationTime => throw _privateConstructorUsedError;
  DateTime? get updateTime => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  bool get isMaterial => throw _privateConstructorUsedError;
  List<AssignmentMaterial> get materials => throw _privateConstructorUsedError;

  /// Create a copy of Announcement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnnouncementCopyWith<Announcement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnnouncementCopyWith<$Res> {
  factory $AnnouncementCopyWith(
    Announcement value,
    $Res Function(Announcement) then,
  ) = _$AnnouncementCopyWithImpl<$Res, Announcement>;
  @useResult
  $Res call({
    String id,
    String courseId,
    String text,
    DateTime creationTime,
    DateTime? updateTime,
    String? title,
    bool isMaterial,
    List<AssignmentMaterial> materials,
  });
}

/// @nodoc
class _$AnnouncementCopyWithImpl<$Res, $Val extends Announcement>
    implements $AnnouncementCopyWith<$Res> {
  _$AnnouncementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Announcement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? text = null,
    Object? creationTime = null,
    Object? updateTime = freezed,
    Object? title = freezed,
    Object? isMaterial = null,
    Object? materials = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            courseId: null == courseId
                ? _value.courseId
                : courseId // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            creationTime: null == creationTime
                ? _value.creationTime
                : creationTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updateTime: freezed == updateTime
                ? _value.updateTime
                : updateTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            isMaterial: null == isMaterial
                ? _value.isMaterial
                : isMaterial // ignore: cast_nullable_to_non_nullable
                      as bool,
            materials: null == materials
                ? _value.materials
                : materials // ignore: cast_nullable_to_non_nullable
                      as List<AssignmentMaterial>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnnouncementImplCopyWith<$Res>
    implements $AnnouncementCopyWith<$Res> {
  factory _$$AnnouncementImplCopyWith(
    _$AnnouncementImpl value,
    $Res Function(_$AnnouncementImpl) then,
  ) = __$$AnnouncementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String courseId,
    String text,
    DateTime creationTime,
    DateTime? updateTime,
    String? title,
    bool isMaterial,
    List<AssignmentMaterial> materials,
  });
}

/// @nodoc
class __$$AnnouncementImplCopyWithImpl<$Res>
    extends _$AnnouncementCopyWithImpl<$Res, _$AnnouncementImpl>
    implements _$$AnnouncementImplCopyWith<$Res> {
  __$$AnnouncementImplCopyWithImpl(
    _$AnnouncementImpl _value,
    $Res Function(_$AnnouncementImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Announcement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? text = null,
    Object? creationTime = null,
    Object? updateTime = freezed,
    Object? title = freezed,
    Object? isMaterial = null,
    Object? materials = null,
  }) {
    return _then(
      _$AnnouncementImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        courseId: null == courseId
            ? _value.courseId
            : courseId // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        creationTime: null == creationTime
            ? _value.creationTime
            : creationTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updateTime: freezed == updateTime
            ? _value.updateTime
            : updateTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        isMaterial: null == isMaterial
            ? _value.isMaterial
            : isMaterial // ignore: cast_nullable_to_non_nullable
                  as bool,
        materials: null == materials
            ? _value._materials
            : materials // ignore: cast_nullable_to_non_nullable
                  as List<AssignmentMaterial>,
      ),
    );
  }
}

/// @nodoc

class _$AnnouncementImpl implements _Announcement {
  const _$AnnouncementImpl({
    required this.id,
    required this.courseId,
    required this.text,
    required this.creationTime,
    this.updateTime,
    this.title,
    this.isMaterial = false,
    final List<AssignmentMaterial> materials = const [],
  }) : _materials = materials;

  @override
  final String id;
  @override
  final String courseId;
  @override
  final String text;
  @override
  final DateTime creationTime;
  @override
  final DateTime? updateTime;
  @override
  final String? title;
  @override
  @JsonKey()
  final bool isMaterial;
  final List<AssignmentMaterial> _materials;
  @override
  @JsonKey()
  List<AssignmentMaterial> get materials {
    if (_materials is EqualUnmodifiableListView) return _materials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_materials);
  }

  @override
  String toString() {
    return 'Announcement(id: $id, courseId: $courseId, text: $text, creationTime: $creationTime, updateTime: $updateTime, title: $title, isMaterial: $isMaterial, materials: $materials)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnnouncementImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.creationTime, creationTime) ||
                other.creationTime == creationTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.isMaterial, isMaterial) ||
                other.isMaterial == isMaterial) &&
            const DeepCollectionEquality().equals(
              other._materials,
              _materials,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    courseId,
    text,
    creationTime,
    updateTime,
    title,
    isMaterial,
    const DeepCollectionEquality().hash(_materials),
  );

  /// Create a copy of Announcement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnnouncementImplCopyWith<_$AnnouncementImpl> get copyWith =>
      __$$AnnouncementImplCopyWithImpl<_$AnnouncementImpl>(this, _$identity);
}

abstract class _Announcement implements Announcement {
  const factory _Announcement({
    required final String id,
    required final String courseId,
    required final String text,
    required final DateTime creationTime,
    final DateTime? updateTime,
    final String? title,
    final bool isMaterial,
    final List<AssignmentMaterial> materials,
  }) = _$AnnouncementImpl;

  @override
  String get id;
  @override
  String get courseId;
  @override
  String get text;
  @override
  DateTime get creationTime;
  @override
  DateTime? get updateTime;
  @override
  String? get title;
  @override
  bool get isMaterial;
  @override
  List<AssignmentMaterial> get materials;

  /// Create a copy of Announcement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnnouncementImplCopyWith<_$AnnouncementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
