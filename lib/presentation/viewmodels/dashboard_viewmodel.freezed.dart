// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DashboardState {
  List<Course> get courses => throw _privateConstructorUsedError;
  List<String> get hiddenCourseIds => throw _privateConstructorUsedError;
  List<String> get orderedCourseIds => throw _privateConstructorUsedError;
  List<Assignment> get upcomingDeadlines => throw _privateConstructorUsedError;
  bool get showHidden => throw _privateConstructorUsedError;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardStateCopyWith<DashboardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardStateCopyWith<$Res> {
  factory $DashboardStateCopyWith(
    DashboardState value,
    $Res Function(DashboardState) then,
  ) = _$DashboardStateCopyWithImpl<$Res, DashboardState>;
  @useResult
  $Res call({
    List<Course> courses,
    List<String> hiddenCourseIds,
    List<String> orderedCourseIds,
    List<Assignment> upcomingDeadlines,
    bool showHidden,
  });
}

/// @nodoc
class _$DashboardStateCopyWithImpl<$Res, $Val extends DashboardState>
    implements $DashboardStateCopyWith<$Res> {
  _$DashboardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? courses = null,
    Object? hiddenCourseIds = null,
    Object? orderedCourseIds = null,
    Object? upcomingDeadlines = null,
    Object? showHidden = null,
  }) {
    return _then(
      _value.copyWith(
            courses: null == courses
                ? _value.courses
                : courses // ignore: cast_nullable_to_non_nullable
                      as List<Course>,
            hiddenCourseIds: null == hiddenCourseIds
                ? _value.hiddenCourseIds
                : hiddenCourseIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            orderedCourseIds: null == orderedCourseIds
                ? _value.orderedCourseIds
                : orderedCourseIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            upcomingDeadlines: null == upcomingDeadlines
                ? _value.upcomingDeadlines
                : upcomingDeadlines // ignore: cast_nullable_to_non_nullable
                      as List<Assignment>,
            showHidden: null == showHidden
                ? _value.showHidden
                : showHidden // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardStateImplCopyWith<$Res>
    implements $DashboardStateCopyWith<$Res> {
  factory _$$DashboardStateImplCopyWith(
    _$DashboardStateImpl value,
    $Res Function(_$DashboardStateImpl) then,
  ) = __$$DashboardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Course> courses,
    List<String> hiddenCourseIds,
    List<String> orderedCourseIds,
    List<Assignment> upcomingDeadlines,
    bool showHidden,
  });
}

/// @nodoc
class __$$DashboardStateImplCopyWithImpl<$Res>
    extends _$DashboardStateCopyWithImpl<$Res, _$DashboardStateImpl>
    implements _$$DashboardStateImplCopyWith<$Res> {
  __$$DashboardStateImplCopyWithImpl(
    _$DashboardStateImpl _value,
    $Res Function(_$DashboardStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? courses = null,
    Object? hiddenCourseIds = null,
    Object? orderedCourseIds = null,
    Object? upcomingDeadlines = null,
    Object? showHidden = null,
  }) {
    return _then(
      _$DashboardStateImpl(
        courses: null == courses
            ? _value._courses
            : courses // ignore: cast_nullable_to_non_nullable
                  as List<Course>,
        hiddenCourseIds: null == hiddenCourseIds
            ? _value._hiddenCourseIds
            : hiddenCourseIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        orderedCourseIds: null == orderedCourseIds
            ? _value._orderedCourseIds
            : orderedCourseIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        upcomingDeadlines: null == upcomingDeadlines
            ? _value._upcomingDeadlines
            : upcomingDeadlines // ignore: cast_nullable_to_non_nullable
                  as List<Assignment>,
        showHidden: null == showHidden
            ? _value.showHidden
            : showHidden // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$DashboardStateImpl extends _DashboardState {
  const _$DashboardStateImpl({
    required final List<Course> courses,
    required final List<String> hiddenCourseIds,
    required final List<String> orderedCourseIds,
    required final List<Assignment> upcomingDeadlines,
    this.showHidden = false,
  }) : _courses = courses,
       _hiddenCourseIds = hiddenCourseIds,
       _orderedCourseIds = orderedCourseIds,
       _upcomingDeadlines = upcomingDeadlines,
       super._();

  final List<Course> _courses;
  @override
  List<Course> get courses {
    if (_courses is EqualUnmodifiableListView) return _courses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_courses);
  }

  final List<String> _hiddenCourseIds;
  @override
  List<String> get hiddenCourseIds {
    if (_hiddenCourseIds is EqualUnmodifiableListView) return _hiddenCourseIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hiddenCourseIds);
  }

  final List<String> _orderedCourseIds;
  @override
  List<String> get orderedCourseIds {
    if (_orderedCourseIds is EqualUnmodifiableListView)
      return _orderedCourseIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orderedCourseIds);
  }

  final List<Assignment> _upcomingDeadlines;
  @override
  List<Assignment> get upcomingDeadlines {
    if (_upcomingDeadlines is EqualUnmodifiableListView)
      return _upcomingDeadlines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upcomingDeadlines);
  }

  @override
  @JsonKey()
  final bool showHidden;

  @override
  String toString() {
    return 'DashboardState(courses: $courses, hiddenCourseIds: $hiddenCourseIds, orderedCourseIds: $orderedCourseIds, upcomingDeadlines: $upcomingDeadlines, showHidden: $showHidden)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardStateImpl &&
            const DeepCollectionEquality().equals(other._courses, _courses) &&
            const DeepCollectionEquality().equals(
              other._hiddenCourseIds,
              _hiddenCourseIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._orderedCourseIds,
              _orderedCourseIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._upcomingDeadlines,
              _upcomingDeadlines,
            ) &&
            (identical(other.showHidden, showHidden) ||
                other.showHidden == showHidden));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_courses),
    const DeepCollectionEquality().hash(_hiddenCourseIds),
    const DeepCollectionEquality().hash(_orderedCourseIds),
    const DeepCollectionEquality().hash(_upcomingDeadlines),
    showHidden,
  );

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardStateImplCopyWith<_$DashboardStateImpl> get copyWith =>
      __$$DashboardStateImplCopyWithImpl<_$DashboardStateImpl>(
        this,
        _$identity,
      );
}

abstract class _DashboardState extends DashboardState {
  const factory _DashboardState({
    required final List<Course> courses,
    required final List<String> hiddenCourseIds,
    required final List<String> orderedCourseIds,
    required final List<Assignment> upcomingDeadlines,
    final bool showHidden,
  }) = _$DashboardStateImpl;
  const _DashboardState._() : super._();

  @override
  List<Course> get courses;
  @override
  List<String> get hiddenCourseIds;
  @override
  List<String> get orderedCourseIds;
  @override
  List<Assignment> get upcomingDeadlines;
  @override
  bool get showHidden;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardStateImplCopyWith<_$DashboardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
