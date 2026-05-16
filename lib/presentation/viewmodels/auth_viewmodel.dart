// lib/presentation/viewmodels/auth_viewmodel.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../core/services/fcm_token_service.dart';
part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  Future<GoogleSignInAccount?> build() async {
    final authService = ref.watch(authServiceProvider);
    return authService.attemptSilentSignIn();
  }

  Future<GoogleSignInAccount> signIn() async {
    final authService = ref.read(authServiceProvider);
    final account = await authService.signIn();
    state = AsyncData(account);
    return account;
  }

  Future<void> signOut() async {
    await const FcmTokenService().unregister();
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AsyncData(null);
  }
}
