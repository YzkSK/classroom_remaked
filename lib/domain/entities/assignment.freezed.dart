// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Assignment {
  String get id => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  AssignmentState get state => throw _privateConstructorUsedError;
  SubmissionState? get submissionState => throw _privateConstructorUsedError;

  /// Create a copy of Assignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssignmentCopyWith<Assignment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssignmentCopyWith<$Res> {
  factory $AssignmentCopyWith(
    Assignment value,
    $Res Function(Assignment) then,
  ) = _$AssignmentCopyWithImpl<$Res, Assignment>;
  @useResult
  $Res call({
    String id,
    String courseId,
    String title,
    String? description,
    DateTime? dueDate,
    AssignmentState state,
    SubmissionState? submissionState,
  });
}

/// @nodoc
class _$AssignmentCopyWithImpl<$Res, $Val extends Assignment>
    implements $AssignmentCopyWith<$Res> {
  _$AssignmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Assignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? title = null,
    Object? description = freezed,
    Object? dueDate = freezed,
    Object? state = null,
    Object? submissionState = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as AssignmentState,
            submissionState: freezed == submissionState
                ? _value.submissionState
                : submissionState // ignore: cast_nullable_to_non_nullable
                      as SubmissionState?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssignmentImplCopyWith<$Res>
    implements $AssignmentCopyWith<$Res> {
  factory _$$AssignmentImplCopyWith(
    _$AssignmentImpl value,
    $Res Function(_$AssignmentImpl) then,
  ) = __$$AssignmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String courseId,
    String title,
    String? description,
    DateTime? dueDate,
    AssignmentState state,
    SubmissionState? submissionState,
  });
}

/// @nodoc
class __$$AssignmentImplCopyWithImpl<$Res>
    extends _$AssignmentCopyWithImpl<$Res, _$AssignmentImpl>
    implements _$$AssignmentImplCopyWith<$Res> {
  __$$AssignmentImplCopyWithImpl(
    _$AssignmentImpl _value,
    $Res Function(_$AssignmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Assignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? title = null,
    Object? description = freezed,
    Object? dueDate = freezed,
    Object? state = null,
    Object? submissionState = freezed,
  }) {
    return _then(
      _$AssignmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        courseId: null == courseId
            ? _value.courseId
            : courseId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as AssignmentState,
        submissionState: freezed == submissionState
            ? _value.submissionState
            : submissionState // ignore: cast_nullable_to_non_nullable
                  as SubmissionState?,
      ),
    );
  }
}

/// @nodoc

class _$AssignmentImpl implements _Assignment {
  const _$AssignmentImpl({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.dueDate,
    this.state = AssignmentState.published,
    this.submissionState,
  });

  @override
  final String id;
  @override
  final String courseId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final DateTime? dueDate;
  @override
  @JsonKey()
  final AssignmentState state;
  @override
  final SubmissionState? submissionState;

  @override
  String toString() {
    return 'Assignment(id: $id, courseId: $courseId, title: $title, description: $description, dueDate: $dueDate, state: $state, submissionState: $submissionState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssignmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.submissionState, submissionState) ||
                other.submissionState == submissionState));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    courseId,
    title,
    description,
    dueDate,
    state,
    submissionState,
  );

  /// Create a copy of Assignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssignmentImplCopyWith<_$AssignmentImpl> get copyWith =>
      __$$AssignmentImplCopyWithImpl<_$AssignmentImpl>(this, _$identity);
}

abstract class _Assignment implements Assignment {
  const factory _Assignment({
    required final String id,
    required final String courseId,
    required final String title,
    final String? description,
    final DateTime? dueDate,
    final AssignmentState state,
    final SubmissionState? submissionState,
  }) = _$AssignmentImpl;

  @override
  String get id;
  @override
  String get courseId;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime? get dueDate;
  @override
  AssignmentState get state;
  @override
  SubmissionState? get submissionState;

  /// Create a copy of Assignment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssignmentImplCopyWith<_$AssignmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
