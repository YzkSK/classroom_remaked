// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingNotificationRouteHash() =>
    r'870feb6016f9a662ed86719684a543397f38c1bb';

/// 通知タップ時のナビゲーション先を保持する。
/// null = 通常起動、非 null = 通知から起動されたルート。
///
/// Copied from [PendingNotificationRoute].
@ProviderFor(PendingNotificationRoute)
final pendingNotificationRouteProvider =
    AutoDisposeNotifierProvider<PendingNotificationRoute, String?>.internal(
      PendingNotificationRoute.new,
      name: r'pendingNotificationRouteProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingNotificationRouteHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingNotificationRoute = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
