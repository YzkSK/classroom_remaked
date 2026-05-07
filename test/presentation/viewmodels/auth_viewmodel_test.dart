// test/presentation/viewmodels/auth_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:classroom_remaked/presentation/viewmodels/auth_viewmodel.dart';
import 'package:classroom_remaked/core/services/auth_service.dart';
import 'package:classroom_remaked/core/di/providers.dart';

class MockAuthService extends Mock implements AuthService {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthViewModel', () {
    test('初期状態は AsyncLoading', () {
      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('サイレントサインイン成功時は GoogleSignInAccount を返す', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockAuthService.attemptSilentSignIn())
          .thenAnswer((_) async => mockAccount);

      await container.read(authViewModelProvider.future);
      final state = container.read(authViewModelProvider);

      expect(state, isA<AsyncData<GoogleSignInAccount?>>());
      expect(state.value, mockAccount);
    });

    test('サイレントサインイン失敗時は null を返す（例外ではない）', () async {
      when(() => mockAuthService.attemptSilentSignIn())
          .thenAnswer((_) async => null);

      await container.read(authViewModelProvider.future);
      final state = container.read(authViewModelProvider);

      expect(state, isA<AsyncData<GoogleSignInAccount?>>());
      expect(state.value, isNull);
    });
  });
}
