// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignments_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AssignmentsState {
  List<Assignment> get assignments => throw _privateConstructorUsedError;
  List<String> get hiddenAssignmentIds => throw _privateConstructorUsedError;
  AssignmentsFilter get filter => throw _privateConstructorUsedError;

  /// Create a copy of AssignmentsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssignmentsStateCopyWith<AssignmentsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssignmentsStateCopyWith<$Res> {
  factory $AssignmentsStateCopyWith(
    AssignmentsState value,
    $Res Function(AssignmentsState) then,
  ) = _$AssignmentsStateCopyWithImpl<$Res, AssignmentsState>;
  @useResult
  $Res call({
    List<Assignment> assignments,
    List<String> hiddenAssignmentIds,
    AssignmentsFilter filter,
  });
}

/// @nodoc
class _$AssignmentsStateCopyWithImpl<$Res, $Val extends AssignmentsState>
    implements $AssignmentsStateCopyWith<$Res> {
  _$AssignmentsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssignmentsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assignments = null,
    Object? hiddenAssignmentIds = null,
    Object? filter = null,
  }) {
    return _then(
      _value.copyWith(
            assignments: null == assignments
                ? _value.assignments
                : assignments // ignore: cast_nullable_to_non_nullable
                      as List<Assignment>,
            hiddenAssignmentIds: null == hiddenAssignmentIds
                ? _value.hiddenAssignmentIds
                : hiddenAssignmentIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            filter: null == filter
                ? _value.filter
                : filter // ignore: cast_nullable_to_non_nullable
                      as AssignmentsFilter,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssignmentsStateImplCopyWith<$Res>
    implements $AssignmentsStateCopyWith<$Res> {
  factory _$$AssignmentsStateImplCopyWith(
    _$AssignmentsStateImpl value,
    $Res Function(_$AssignmentsStateImpl) then,
  ) = __$$AssignmentsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Assignment> assignments,
    List<String> hiddenAssignmentIds,
    AssignmentsFilter filter,
  });
}

/// @nodoc
class __$$AssignmentsStateImplCopyWithImpl<$Res>
    extends _$AssignmentsStateCopyWithImpl<$Res, _$AssignmentsStateImpl>
    implements _$$AssignmentsStateImplCopyWith<$Res> {
  __$$AssignmentsStateImplCopyWithImpl(
    _$AssignmentsStateImpl _value,
    $Res Function(_$AssignmentsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssignmentsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assignments = null,
    Object? hiddenAssignmentIds = null,
    Object? filter = null,
  }) {
    return _then(
      _$AssignmentsStateImpl(
        assignments: null == assignments
            ? _value._assignments
            : assignments // ignore: cast_nullable_to_non_nullable
                  as List<Assignment>,
        hiddenAssignmentIds: null == hiddenAssignmentIds
            ? _value._hiddenAssignmentIds
            : hiddenAssignmentIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        filter: null == filter
            ? _value.filter
            : filter // ignore: cast_nullable_to_non_nullable
                  as AssignmentsFilter,
      ),
    );
  }
}

/// @nodoc

class _$AssignmentsStateImpl extends _AssignmentsState {
  const _$AssignmentsStateImpl({
    required final List<Assignment> assignments,
    required final List<String> hiddenAssignmentIds,
    this.filter = AssignmentsFilter.all,
  }) : _assignments = assignments,
       _hiddenAssignmentIds = hiddenAssignmentIds,
       super._();

  final List<Assignment> _assignments;
  @override
  List<Assignment> get assignments {
    if (_assignments is EqualUnmodifiableListView) return _assignments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignments);
  }

  final List<String> _hiddenAssignmentIds;
  @override
  List<String> get hiddenAssignmentIds {
    if (_hiddenAssignmentIds is EqualUnmodifiableListView)
      return _hiddenAssignmentIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hiddenAssignmentIds);
  }

  @override
  @JsonKey()
  final AssignmentsFilter filter;

  @override
  String toString() {
    return 'AssignmentsState(assignments: $assignments, hiddenAssignmentIds: $hiddenAssignmentIds, filter: $filter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssignmentsStateImpl &&
            const DeepCollectionEquality().equals(
              other._assignments,
              _assignments,
            ) &&
            const DeepCollectionEquality().equals(
              other._hiddenAssignmentIds,
              _hiddenAssignmentIds,
            ) &&
            (identical(other.filter, filter) || other.filter == filter));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_assignments),
    const DeepCollectionEquality().hash(_hiddenAssignmentIds),
    filter,
  );

  /// Create a copy of AssignmentsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssignmentsStateImplCopyWith<_$AssignmentsStateImpl> get copyWith =>
      __$$AssignmentsStateImplCopyWithImpl<_$AssignmentsStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AssignmentsState extends AssignmentsState {
  const factory _AssignmentsState({
    required final List<Assignment> assignments,
    required final List<String> hiddenAssignmentIds,
    final AssignmentsFilter filter,
  }) = _$AssignmentsStateImpl;
  const _AssignmentsState._() : super._();

  @override
  List<Assignment> get assignments;
  @override
  List<String> get hiddenAssignmentIds;
  @override
  AssignmentsFilter get filter;

  /// Create a copy of AssignmentsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssignmentsStateImplCopyWith<_$AssignmentsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
