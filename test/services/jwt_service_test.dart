// Юнит-тесты JwtService. Не зависит от Env.

import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/services/jwt_service.dart';
import 'package:test/test.dart';

void main() {
  final jwt = JwtService(
    secret: 'super-secret-for-tests-must-be-long-enough',
    accessTtlMinutes: 60,
    refreshTtlDays: 30,
  );

  test('access токен подписывается и валидируется', () {
    final token = jwt.issueAccessToken(userId: 'u1', role: 'student');
    final claims = jwt.verifyAccessToken(token);
    expect(claims.userId, 'u1');
    expect(claims.role, 'student');
  });

  test('refresh токен подписывается и валидируется', () {
    final token = jwt.issueRefreshToken(userId: 'u2');
    expect(jwt.verifyRefreshToken(token), 'u2');
  });

  test('испорченный токен — 401', () {
    expect(
      () => jwt.verifyAccessToken('not.a.jwt'),
      throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('refresh с не тем secret — 401', () {
    final t = jwt.issueRefreshToken(userId: 'u3');
    final other = JwtService(
      secret: 'another-secret-that-is-definitely-different',
      accessTtlMinutes: 60,
      refreshTtlDays: 30,
    );
    expect(
      () => other.verifyRefreshToken(t),
      throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('access-токен НЕ считается refresh-токеном', () {
    final accessToken = jwt.issueAccessToken(userId: 'u4', role: 'admin');
    expect(
      () => jwt.verifyRefreshToken(accessToken),
      throwsA(isA<ApiError>()),
    );
  });
}
