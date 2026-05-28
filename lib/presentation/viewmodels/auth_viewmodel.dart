// lib/presentation/viewmodels/auth_viewmodel.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../data/datasources/local/error_log_datasource.dart';
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
    try {
      final serverAuthCode = await authService.fetchServerAuthCode(account);
      if (serverAuthCode != null) {
        await ref.read(backendServiceProvider).registerToken(serverAuthCode);
      }
    } catch (e, st) {
      await ErrorLogDataSource(ref.read(appDatabaseProvider)).add(
        source: 'AuthViewModel.signIn/fetchServerAuthCode',
        message: e.toString(),
        stackTrace: st.toString(),
      );
      rethrow;
    }
    return account;
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AsyncData(null);
  }
}
