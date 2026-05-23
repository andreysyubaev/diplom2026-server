// Сервис генерации и проверки JWT-токенов.
// Используем алгоритм HS256: один секрет, и для подписи, и для проверки.

import 'dart:math';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../config/env.dart';
import '../models/api_error.dart';

class JwtClaims {
  JwtClaims({required this.userId, required this.role});

  final String userId;
  final String role;
}

class JwtService {
  JwtService({String? secret, int? accessTtlMinutes, int? refreshTtlDays})
      : _secret = secret ?? Env.instance.jwtSecret,
        _accessTtlMinutes = accessTtlMinutes ?? Env.instance.jwtAccessTtlMinutes,
        _refreshTtlDays = refreshTtlDays ?? Env.instance.jwtRefreshTtlDays;

  final String _secret;
  final int _accessTtlMinutes;
  final int _refreshTtlDays;

  /// Создаёт access-токен. Внутри: userId, role, iat, exp.
  String issueAccessToken({required String userId, required String role}) {
    final jwt = JWT(
      {'role': role},
      subject: userId,
      issuer: 'college-app',
    );
    return jwt.sign(
      SecretKey(_secret),
      expiresIn: Duration(minutes: _accessTtlMinutes),
    );
  }

  /// Создаёт refresh-токен (просто длинный JWT с дольшим TTL).
  String issueRefreshToken({required String userId}) {
    final rand = Random.secure();
    final nonce = List.generate(16, (_) => rand.nextInt(256));
    final jwt = JWT(
      {'nonce': nonce.join('-'), 'type': 'refresh'},
      subject: userId,
      issuer: 'college-app',
    );
    return jwt.sign(
      SecretKey(_secret),
      expiresIn: Duration(days: _refreshTtlDays),
    );
  }

  Duration get refreshTtl => Duration(days: _refreshTtlDays);
  Duration get accessTtl => Duration(minutes: _accessTtlMinutes);

  /// Проверяет и парсит access-токен. Кидает [ApiError.unauthorized] при ошибке.
  JwtClaims verifyAccessToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      final sub = jwt.subject;
      final role = (jwt.payload as Map<String, dynamic>)['role'] as String?;
      if (sub == null || role == null) {
        throw ApiError.unauthorized('Некорректный токен');
      }
      return JwtClaims(userId: sub, role: role);
    } on JWTExpiredException {
      throw ApiError.unauthorized('Срок действия токена истёк');
    } on JWTException {
      throw ApiError.unauthorized('Некорректный токен');
    }
  }

  /// Проверяет refresh-токен и возвращает userId.
  String verifyRefreshToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      final sub = jwt.subject;
      final type = (jwt.payload as Map<String, dynamic>)['type'] as String?;
      if (sub == null || type != 'refresh') {
        throw ApiError.unauthorized('Некорректный refresh-токен');
      }
      return sub;
    } on JWTExpiredException {
      throw ApiError.unauthorized('Refresh-токен истёк, нужно войти заново');
    } on JWTException {
      throw ApiError.unauthorized('Некорректный refresh-токен');
    }
  }
}
