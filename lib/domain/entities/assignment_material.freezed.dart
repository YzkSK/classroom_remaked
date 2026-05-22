// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignment_material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AssignmentMaterial {
  String get title => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  AssignmentMaterialType get type => throw _privateConstructorUsedError;
  String? get driveFileId => throw _privateConstructorUsedError;
  String? get mimeType => throw _privateConstructorUsedError;

  /// Create a copy of AssignmentMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssignmentMaterialCopyWith<AssignmentMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssignmentMaterialCopyWith<$Res> {
  factory $AssignmentMaterialCopyWith(
    AssignmentMaterial value,
    $Res Function(AssignmentMaterial) then,
  ) = _$AssignmentMaterialCopyWithImpl<$Res, AssignmentMaterial>;
  @useResult
  $Res call({
    String title,
    String url,
    AssignmentMaterialType type,
    String? driveFileId,
    String? mimeType,
  });
}

/// @nodoc
class _$AssignmentMaterialCopyWithImpl<$Res, $Val extends AssignmentMaterial>
    implements $AssignmentMaterialCopyWith<$Res> {
  _$AssignmentMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssignmentMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? type = null,
    Object? driveFileId = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as AssignmentMaterialType,
            driveFileId: freezed == driveFileId
                ? _value.driveFileId
                : driveFileId // ignore: cast_nullable_to_non_nullable
                      as String?,
            mimeType: freezed == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssignmentMaterialImplCopyWith<$Res>
    implements $AssignmentMaterialCopyWith<$Res> {
  factory _$$AssignmentMaterialImplCopyWith(
    _$AssignmentMaterialImpl value,
    $Res Function(_$AssignmentMaterialImpl) then,
  ) = __$$AssignmentMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String url,
    AssignmentMaterialType type,
    String? driveFileId,
    String? mimeType,
  });
}

/// @nodoc
class __$$AssignmentMaterialImplCopyWithImpl<$Res>
    extends _$AssignmentMaterialCopyWithImpl<$Res, _$AssignmentMaterialImpl>
    implements _$$AssignmentMaterialImplCopyWith<$Res> {
  __$$AssignmentMaterialImplCopyWithImpl(
    _$AssignmentMaterialImpl _value,
    $Res Function(_$AssignmentMaterialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssignmentMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? type = null,
    Object? driveFileId = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(
      _$AssignmentMaterialImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as AssignmentMaterialType,
        driveFileId: freezed == driveFileId
            ? _value.driveFileId
            : driveFileId // ignore: cast_nullable_to_non_nullable
                  as String?,
        mimeType: freezed == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AssignmentMaterialImpl extends _AssignmentMaterial {
  const _$AssignmentMaterialImpl({
    required this.title,
    required this.url,
    required this.type,
    this.driveFileId,
    this.mimeType,
  }) : super._();

  @override
  final String title;
  @override
  final String url;
  @override
  final AssignmentMaterialType type;
  @override
  final String? driveFileId;
  @override
  final String? mimeType;

  @override
  String toString() {
    return 'AssignmentMaterial(title: $title, url: $url, type: $type, driveFileId: $driveFileId, mimeType: $mimeType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssignmentMaterialImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.driveFileId, driveFileId) ||
                other.driveFileId == driveFileId) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, title, url, type, driveFileId, mimeType);

  /// Create a copy of AssignmentMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssignmentMaterialImplCopyWith<_$AssignmentMaterialImpl> get copyWith =>
      __$$AssignmentMaterialImplCopyWithImpl<_$AssignmentMaterialImpl>(
        this,
        _$identity,
      );
}

abstract class _AssignmentMaterial extends AssignmentMaterial {
  const factory _AssignmentMaterial({
    required final String title,
    required final String url,
    required final AssignmentMaterialType type,
    final String? driveFileId,
    final String? mimeType,
  }) = _$AssignmentMaterialImpl;
  const _AssignmentMaterial._() : super._();

  @override
  String get title;
  @override
  String get url;
  @override
  AssignmentMaterialType get type;
  @override
  String? get driveFileId;
  @override
  String? get mimeType;

  /// Create a copy of AssignmentMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssignmentMaterialImplCopyWith<_$AssignmentMaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
