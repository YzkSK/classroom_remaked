// test/core/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/core/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('インスタンス化できる', () {
      expect(() => AuthService(), returnsNormally);
    });

    test('scopes に必要な Classroom スコープが含まれている', () {
      expect(
        AuthService.scopes,
        containsAll([
          'https://www.googleapis.com/auth/classroom.courses.readonly',
          'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
          'https://www.googleapis.com/auth/classroom.announcements.readonly',
          'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
          'https://www.googleapis.com/auth/classroom.rosters.readonly',
        ]),
      );
    });
  });
}
