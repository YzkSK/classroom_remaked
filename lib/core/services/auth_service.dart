// lib/core/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.rosters.readonly',
    'https://www.googleapis.com/auth/classroom.push-notifications',
    'https://www.googleapis.com/auth/pubsub',
  ];

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize();
  }

  /// サイレントサインインを試みる。失敗時は null を返す（例外を投げない）。
  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    try {
      return await GoogleSignIn.instance.attemptLightweightAuthentication() ??
          Future.value(null);
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
