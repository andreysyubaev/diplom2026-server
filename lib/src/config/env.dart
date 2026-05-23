// Чтение конфигурации из переменных окружения и/или .env файла.
// Все настройки сервера собраны в один immutable-объект [Env].
//
// На локальной машине читаем .env через пакет dotenv.
// На проде (Amvera, Docker) — берём переменные из системного окружения.

import 'dart:io';

import 'package:dotenv/dotenv.dart';

class Env {
  Env._({
    required this.port,
    required this.host,
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.dbSsl,
    required this.jwtSecret,
    required this.jwtAccessTtlMinutes,
    required this.jwtRefreshTtlDays,
    required this.initialAdminEmail,
    required this.initialAdminPassword,
    required this.initialAdminName,
    required this.uploadsDir,
    required this.subjectCodeTtlMinutes,
  });

  final int port;
  final String host;

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final bool dbSsl;

  final String jwtSecret;
  final int jwtAccessTtlMinutes;
  final int jwtRefreshTtlDays;

  final String initialAdminEmail;
  final String initialAdminPassword;
  final String initialAdminName;

  final String uploadsDir;
  final int subjectCodeTtlMinutes;

  static Env? _instance;
  static Env get instance {
    return _instance ??= load();
  }

  /// Принудительная (повторная) загрузка — полезно в тестах.
  static Env load({String? envFile}) {
    final dotEnv = DotEnv(includePlatformEnvironment: true);
    final file = envFile ?? '.env';
    if (File(file).existsSync()) {
      dotEnv.load([file]);
    }

    String req(String key, {String? fallback}) {
      final v = dotEnv[key] ?? Platform.environment[key] ?? fallback;
      if (v == null || v.isEmpty) {
        throw StateError('Environment variable $key is not set');
      }
      return v;
    }

    int reqInt(String key, {int? fallback}) {
      final v = dotEnv[key] ?? Platform.environment[key];
      if (v == null || v.isEmpty) {
        if (fallback != null) return fallback;
        throw StateError('Environment variable $key is not set');
      }
      return int.parse(v);
    }

    bool reqBool(String key, {bool fallback = false}) {
      final v = dotEnv[key] ?? Platform.environment[key];
      if (v == null || v.isEmpty) return fallback;
      return v.toLowerCase() == 'true' || v == '1';
    }

    _instance = Env._(
      port: reqInt('PORT', fallback: 8080),
      host: req('HOST', fallback: '0.0.0.0'),
      dbHost: req('DB_HOST', fallback: 'localhost'),
      dbPort: reqInt('DB_PORT', fallback: 5432),
      dbName: req('DB_NAME', fallback: 'college_app'),
      dbUser: req('DB_USER', fallback: 'college_user'),
      dbPassword: req('DB_PASSWORD', fallback: 'college_pass'),
      dbSsl: reqBool('DB_SSL'),
      jwtSecret: req('JWT_SECRET'),
      jwtAccessTtlMinutes: reqInt('JWT_ACCESS_TTL_MINUTES', fallback: 60),
      jwtRefreshTtlDays: reqInt('JWT_REFRESH_TTL_DAYS', fallback: 30),
      initialAdminEmail: req('INITIAL_ADMIN_EMAIL'),
      initialAdminPassword: req('INITIAL_ADMIN_PASSWORD'),
      initialAdminName: req('INITIAL_ADMIN_NAME', fallback: 'Администратор'),
      uploadsDir: req('UPLOADS_DIR', fallback: 'uploads'),
      subjectCodeTtlMinutes: reqInt('SUBJECT_CODE_TTL_MINUTES', fallback: 5),
    );
    return _instance!;
  }

  /// Сброс кеша — для unit-тестов.
  static void reset() {
    _instance = null;
  }
}
