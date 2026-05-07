// lib/data/datasources/remote/classroom_http_client.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';

class ClassroomHttpClient extends http.BaseClient {
  ClassroomHttpClient(this._account);

  final GoogleSignInAccount _account;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final auth =
        await _account.authorizationClient
            .authorizationForScopes(AuthService.scopes) ??
        await _account.authorizationClient
            .authorizeScopes(AuthService.scopes);
    request.headers['Authorization'] = 'Bearer ${auth.accessToken}';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
