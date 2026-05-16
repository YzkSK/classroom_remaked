// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcements_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$announcementsViewModelHash() =>
    r'4be1fbaf5acecb14c959e321a0d7945271720d29';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [announcementsViewModel].
@ProviderFor(announcementsViewModel)
const announcementsViewModelProvider = AnnouncementsViewModelFamily();

/// See also [announcementsViewModel].
class AnnouncementsViewModelFamily
    extends Family<AsyncValue<List<Announcement>>> {
  /// See also [announcementsViewModel].
  const AnnouncementsViewModelFamily();

  /// See also [announcementsViewModel].
  AnnouncementsViewModelProvider call(String courseId) {
    return AnnouncementsViewModelProvider(courseId);
  }

  @override
  AnnouncementsViewModelProvider getProviderOverride(
    covariant AnnouncementsViewModelProvider provider,
  ) {
    return call(provider.courseId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'announcementsViewModelProvider';
}

/// See also [announcementsViewModel].
class AnnouncementsViewModelProvider
    extends AutoDisposeFutureProvider<List<Announcement>> {
  /// See also [announcementsViewModel].
  AnnouncementsViewModelProvider(String courseId)
    : this._internal(
        (ref) =>
            announcementsViewModel(ref as AnnouncementsViewModelRef, courseId),
        from: announcementsViewModelProvider,
        name: r'announcementsViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$announcementsViewModelHash,
        dependencies: AnnouncementsViewModelFamily._dependencies,
        allTransitiveDependencies:
            AnnouncementsViewModelFamily._allTransitiveDependencies,
        courseId: courseId,
      );

  AnnouncementsViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.courseId,
  }) : super.internal();

  final String courseId;

  @override
  Override overrideWith(
    FutureOr<List<Announcement>> Function(AnnouncementsViewModelRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnnouncementsViewModelProvider._internal(
        (ref) => create(ref as AnnouncementsViewModelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        courseId: courseId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Announcement>> createElement() {
    return _AnnouncementsViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnnouncementsViewModelProvider &&
        other.courseId == courseId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, courseId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnnouncementsViewModelRef
    on AutoDisposeFutureProviderRef<List<Announcement>> {
  /// The parameter `courseId` of this provider.
  String get courseId;
}

class _AnnouncementsViewModelProviderElement
    extends AutoDisposeFutureProviderElement<List<Announcement>>
    with AnnouncementsViewModelRef {
  _AnnouncementsViewModelProviderElement(super.provider);

  @override
  String get courseId => (origin as AnnouncementsViewModelProvider).courseId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
