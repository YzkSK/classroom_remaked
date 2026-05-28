// lib/core/services/backend_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/datasources/local/error_log_datasource.dart';

class BackendService {
  final ErrorLogDataSource _errorLog;

  BackendService(this._errorLog);

  late final _fn = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  Future<void> registerToken(String serverAuthCode) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) throw Exception('FCM token unavailable');
      await _fn.httpsCallable('registerToken').call({
        'serverAuthCode': serverAuthCode,
        'fcmToken': fcmToken,
      });
    } catch (e, st) {
      await _log('BackendService.registerToken', e, st);
      rethrow;
    }
  }

  Future<void> debugPollNow({required bool asTeacher}) async {
    try {
      await _fn.httpsCallable('debugPollNow').call({'asTeacher': asTeacher});
    } catch (e, st) {
      await _log('BackendService.debugPollNow', e, st);
      rethrow;
    }
  }

  Future<void> _log(String source, Object e, StackTrace st) async {
    try {
      await _errorLog.add(
        source: source,
        message: e.toString(),
        stackTrace: st.toString(),
      );
    } catch (_) {}
  }
}
