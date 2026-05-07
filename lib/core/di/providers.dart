// lib/core/di/providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
part 'providers.g.dart';

@riverpod
AuthService authService(AuthServiceRef ref) => AuthService();
