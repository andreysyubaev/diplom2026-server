// Глобальный контейнер сервисов и репозиториев.
// Создаётся один раз при старте сервера и инжектится во все запросы
// через middleware (см. routes/_middleware.dart).
//
// Зачем контейнер вместо инициализации в каждом роуте:
//   - один пул соединений с БД на весь процесс
//   - удобно подменять зависимости в тестах
//   - не нужно тащить кучу глобальных синглтонов

import '../db/connection.dart';
import '../repositories/notification_repository.dart';
import '../repositories/position_repository.dart';
import '../repositories/result_repository.dart';
import '../repositories/subject_repository.dart';
import '../repositories/subtheme_repository.dart';
import '../repositories/test_repository.dart';
import '../repositories/theme_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_service.dart';
import 'code_service.dart';
import 'copy_service.dart';
import 'jwt_service.dart';
import 'password_service.dart';
import 'scheduled_notifier.dart';
import 'upload_service.dart';

class ServiceContainer {
  ServiceContainer({
    required this.db,
    required this.users,
    required this.subjects,
    required this.themes,
    required this.subthemes,
    required this.tests,
    required this.results,
    required this.notifications,
    required this.positions,
    required this.passwords,
    required this.jwt,
    required this.auth,
    required this.codes,
    required this.uploads,
    required this.copy,
  });

  final Database db;
  final UserRepository users;
  final SubjectRepository subjects;
  final ThemeRepository themes;
  final SubthemeRepository subthemes;
  final TestRepository tests;
  final ResultRepository results;
  final NotificationRepository notifications;
  final PositionRepository positions;
  final PasswordService passwords;
  final JwtService jwt;
  final AuthService auth;
  final CodeService codes;
  final UploadService uploads;
  final CopyService copy;

  static Future<ServiceContainer> build(Database db) async {
    final users = UserRepository(db);
    final subjects = SubjectRepository(db);
    final themes = ThemeRepository(db);
    final subthemes = SubthemeRepository(db);
    final tests = TestRepository(db);
    final results = ResultRepository(db);
    final notifications = NotificationRepository(db);
    final positions = PositionRepository(db);
    final passwords = PasswordService();
    final jwt = JwtService();
    final codes = CodeService(db);
    final uploads = UploadService();
    final copy = CopyService(
      themes: themes,
      subthemes: subthemes,
      tests: tests,
      subjects: subjects,
      uploads: uploads,
    );
    final auth = AuthService(
      db,
      users: users,
      passwords: passwords,
      jwt: jwt,
    );

    // Запускаем фоновый шедулер. Раз в минуту проверяет, не пора ли
    // уведомить о выходе запланированных подтем/тем.
    ScheduledNotifier(
      db: db,
      notifications: notifications,
      subjects: subjects,
    ).start();

    return ServiceContainer(
      db: db,
      users: users,
      subjects: subjects,
      themes: themes,
      subthemes: subthemes,
      tests: tests,
      results: results,
      notifications: notifications,
      positions: positions,
      passwords: passwords,
      jwt: jwt,
      auth: auth,
      codes: codes,
      uploads: uploads,
      copy: copy,
    );
  }
}
