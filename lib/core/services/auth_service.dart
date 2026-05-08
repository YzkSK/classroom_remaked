// lib/core/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.rosters.readonly',
  ];

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '184568296872-7079toktlo42fe5etcbke4mkue9l7ua7.apps.googleusercontent.com',
    );
  }

  /// サイレントサインインを試みる。失敗・タイムアウト時は null を返す。
  /// Android では Credential Manager UI が裏で待機し続ける場合があるため
  /// 3秒でタイムアウトして未サインイン扱いにする。
  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    try {
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future == null) return null;
      return await future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// ユーザー操作によるサインイン。
  Future<GoogleSignInAccount> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('このプラットフォームはサインインをサポートしていません');
    }
    return GoogleSignIn.instance.authenticate(scopeHint: scopes);
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;
}
