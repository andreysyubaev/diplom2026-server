// Высокоуровневый сервис аутентификации:
//   - регистрация студентов
//   - вход (логин/пароль → пара access+refresh токенов)
//   - обновление пары токенов по refresh
//   - смена пароля
//   - создание учётки преподавателя админом

import '../db/connection.dart';
import '../models/api_error.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'jwt_service.dart';
import 'password_service.dart';

class AuthTokens {
  AuthTokens(this.accessToken, this.refreshToken, this.user);
  final String accessToken;
  final String refreshToken;
  final User user;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };
}

class AuthService {
  AuthService(this._db, {
    required this.users,
    required this.passwords,
    required this.jwt,
  });

  final Database _db;
  final UserRepository users;
  final PasswordService passwords;
  final JwtService jwt;

  Future<AuthTokens> registerStudent({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _validateEmail(email);
    final pwdError = passwords.validate(password);
    if (pwdError != null) throw ApiError.badRequest(pwdError);
    if (fullName.trim().length < 2) {
      throw ApiError.badRequest('Введите полное имя');
    }

    final existing = await users.findByEmail(email);
    if (existing != null) {
      throw ApiError.conflict('Пользователь с таким email уже существует',
          code: 'email_taken');
    }
    final hash = await passwords.hash(password);
    final user = await users.create(
      email: email.trim().toLowerCase(),
      passwordHash: hash,
      fullName: fullName.trim(),
      role: UserRole.student,
    );
    return _issueTokens(user);
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final user = await users.findByEmail(email);
    if (user == null) {
      throw ApiError.unauthorized('Неверный email или пароль');
    }
    final hash = await users.getPasswordHash(user.id);
    if (hash == null || !await passwords.verify(password, hash)) {
      throw ApiError.unauthorized('Неверный email или пароль');
    }
    return _issueTokens(user);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final userId = jwt.verifyRefreshToken(refreshToken);
    final tokenHash = passwords.hashRefreshToken(refreshToken);
    final res = await _db.execute(
      'SELECT id FROM refresh_tokens '
      'WHERE token_hash = @h AND user_id = @u '
      'AND revoked_at IS NULL AND expires_at > NOW() LIMIT 1',
      parameters: {'h': tokenHash, 'u': userId},
    );
    if (res.isEmpty) {
      throw ApiError.unauthorized('Refresh-токен недействителен');
    }
    // Отзываем старый, выдаём новый (rotation)
    await _db.execute(
      'UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = @h',
      parameters: {'h': tokenHash},
    );
    final user = await users.findById(userId);
    if (user == null) throw ApiError.unauthorized();
    return _issueTokens(user);
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final err = passwords.validate(newPassword);
    if (err != null) throw ApiError.badRequest(err);
    final hash = await users.getPasswordHash(userId);
    if (hash == null ||
        !await passwords.verify(currentPassword, hash)) {
      throw ApiError.unauthorized('Текущий пароль введён неверно');
    }
    final newHash = await passwords.hash(newPassword);
    await users.updatePasswordHash(userId, newHash);
    // Отзываем все refresh-токены - пользователь должен войти заново на других устройствах
    await _db.execute(
      'UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = @u AND revoked_at IS NULL',
      parameters: {'u': userId},
    );
  }

  Future<User> createTeacher({
    required String email,
    required String password,
    required String fullName,
    List<String> positionIds = const [],
  }) async {
    _validateEmail(email);
    final err = passwords.validate(password);
    if (err != null) throw ApiError.badRequest(err);
    if (await users.findByEmail(email) != null) {
      throw ApiError.conflict('Email уже занят', code: 'email_taken');
    }
    final hash = await passwords.hash(password);
    return users.create(
      email: email.trim().toLowerCase(),
      passwordHash: hash,
      fullName: fullName.trim(),
      role: UserRole.teacher,
      positionIds: positionIds,
    );
  }

  Future<AuthTokens> _issueTokens(User user) async {
    final access = jwt.issueAccessToken(userId: user.id, role: user.role.name);
    final refresh = jwt.issueRefreshToken(userId: user.id);
    final hash = passwords.hashRefreshToken(refresh);
    await _db.execute(
      'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) '
      'VALUES (@u, @h, @e)',
      parameters: {
        'u': user.id,
        'h': hash,
        'e': DateTime.now().toUtc().add(jwt.refreshTtl),
      },
    );
    return AuthTokens(access, refresh, user);
  }

  static void _validateEmail(String email) {
    final v = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      throw ApiError.badRequest('Некорректный email');
    }
  }
}
