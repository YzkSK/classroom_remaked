// lib/core/services/fcm_token_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  const FcmTokenService();

  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// サインイン後・sync 完了後に呼ぶ。
  /// FCM トークンと購読コース一覧を Firestore に保存する。
  Future<void> register({
    required String userId,
    required List<String> courseIds,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _saveToken(token: token, userId: userId, courseIds: courseIds);

    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(token: newToken, userId: userId, courseIds: courseIds);
    });
  }

  /// サインアウト時に呼ぶ。Firestore からトークンを削除する。
  Future<void> unregister() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('fcmTokens').doc(token).delete();
    }
    await _messaging.deleteToken();
  }

  Future<void> _saveToken({
    required String token,
    required String userId,
    required List<String> courseIds,
  }) async {
    await _firestore.collection('fcmTokens').doc(token).set({
      'token': token,
      'userId': userId,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'courseIds': courseIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
