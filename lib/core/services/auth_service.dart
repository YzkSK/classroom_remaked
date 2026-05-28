// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.rosters.readonly',
'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.file',
  ];

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '184568296872-7079toktlo42fe5etcbke4mkue9l7ua7.apps.googleusercontent.com',
    );
  }

  /// サイレントサインインを試みる。
  /// スコープ未承認（初回ログイン）の場合は null を返してサインイン画面へ誘導する。
  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    try {
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future == null) return null;
      final account = await future;
      if (account == null) return null;
      // スコープ未承認なら初回ログイン扱い → サインイン画面で正式な認可フローを踏む
      final auth =
          await account.authorizationClient.authorizationForScopes(scopes);
      if (auth == null) return null;
      if (FirebaseAuth.instance.currentUser == null) {
        final credential =
            GoogleAuthProvider.credential(accessToken: auth.accessToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      return account;
    } catch (_) {
      return null;
    }
  }

  /// ユーザー操作によるサインイン。
  /// authenticate() → authorizeScopes() → Firebase Auth sign-in の順に処理する。
  Future<GoogleSignInAccount> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('このプラットフォームはサインインをサポートしていません');
    }
    final account = await GoogleSignIn.instance.authenticate(scopeHint: scopes);
    final alreadyAuthorized =
        await account.authorizationClient.authorizationForScopes(scopes);
    final auth = alreadyAuthorized ??
        await account.authorizationClient.authorizeScopes(scopes);
    if (FirebaseAuth.instance.currentUser == null) {
      final credential =
          GoogleAuthProvider.credential(accessToken: auth.accessToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    return account;
  }

  Future<String?> fetchServerAuthCode(GoogleSignInAccount account) async {
    final serverAuth =
        await account.authorizationClient.authorizeServer(scopes);
    return serverAuth?.serverAuthCode;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;
}
