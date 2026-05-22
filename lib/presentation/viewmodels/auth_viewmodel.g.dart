// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authViewModelHash() => r'b7d78a66235b37621d7d547b009b150bcbd0460e';

/// See also [AuthViewModel].
@ProviderFor(AuthViewModel)
final authViewModelProvider =
    AutoDisposeAsyncNotifierProvider<
      AuthViewModel,
      GoogleSignInAccount?
    >.internal(
      AuthViewModel.new,
      name: r'authViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthViewModel = AutoDisposeAsyncNotifier<GoogleSignInAccount?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
