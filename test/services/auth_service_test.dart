// Тесты AuthService с мокнутыми зависимостями.
// Не требуют запущенной БД.

import 'package:college_app_server/src/db/connection.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:college_app_server/src/repositories/user_repository.dart';
import 'package:college_app_server/src/services/auth_service.dart';
import 'package:college_app_server/src/services/jwt_service.dart';
import 'package:college_app_server/src/services/password_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _MockDb extends Mock implements Database {}
class _MockUsers extends Mock implements UserRepository {}
class _MockResult extends Mock implements Result {}

void main() {
  late _MockDb db;
  late _MockUsers users;
  late PasswordService passwords;
  late JwtService jwt;
  late AuthService auth;

  setUp(() {
    db = _MockDb();
    users = _MockUsers();
    passwords = PasswordService();
    jwt = JwtService(
      secret: 'unit-test-secret-which-is-long-enough',
      accessTtlMinutes: 60,
      refreshTtlDays: 30,
    );
    auth = AuthService(db, users: users, passwords: passwords, jwt: jwt);

    // Заглушка для INSERT в refresh_tokens
    final result = _MockResult();
    when(() => db.execute(any(), parameters: any(named: 'parameters')))
        .thenAnswer((_) async => result);
  });

  group('registerStudent', () {
    test('некорректный email — 400', () async {
      expect(
        () => auth.registerStudent(
          email: 'not-an-email',
          password: 'pass1234',
          fullName: 'A B',
        ),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('слабый пароль — 400', () async {
      expect(
        () => auth.registerStudent(
          email: 'a@b.ru',
          password: '123',
          fullName: 'A B',
        ),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('занятый email — 409', () async {
      when(() => users.findByEmail(any())).thenAnswer(
        (_) async => User(
          id: 'u1',
          email: 'taken@example.com',
          fullName: 'X',
          role: UserRole.student,
          createdAt: DateTime.now(),
        ),
      );
      expect(
        () => auth.registerStudent(
          email: 'taken@example.com',
          password: 'pass1234',
          fullName: 'A B',
        ),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 409)),
      );
    });

    test('успешная регистрация возвращает токены', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => null);
      when(
        () => users.create(
          email: any(named: 'email'),
          passwordHash: any(named: 'passwordHash'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          position: any(named: 'position'),
        ),
      ).thenAnswer((_) async => User(
            id: 'u-new',
            email: 'new@example.com',
            fullName: 'Иван Иванов',
            role: UserRole.student,
            createdAt: DateTime.now(),
          ));
      final tokens = await auth.registerStudent(
        email: 'new@example.com',
        password: 'pass1234',
        fullName: 'Иван Иванов',
      );
      expect(tokens.accessToken, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
      expect(tokens.user.role, UserRole.student);
    });
  });

  group('login', () {
    test('неверный email — 401', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => null);
      expect(
        () => auth.login(email: 'x@y.ru', password: 'whatever1'),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('верный пароль → токены', () async {
      final hash = await passwords.hash('correct123');
      final u = User(
        id: 'u-1',
        email: 'a@b.ru',
        fullName: 'A B',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      when(() => users.findByEmail(any())).thenAnswer((_) async => u);
      when(() => users.getPasswordHash('u-1')).thenAnswer((_) async => hash);

      final tokens = await auth.login(email: 'a@b.ru', password: 'correct123');
      expect(tokens.user.id, 'u-1');
      // и token валиден
      expect(jwt.verifyAccessToken(tokens.accessToken).userId, 'u-1');
    });

    test('неверный пароль — 401', () async {
      final hash = await passwords.hash('correct123');
      final u = User(
        id: 'u-1',
        email: 'a@b.ru',
        fullName: 'A B',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      when(() => users.findByEmail(any())).thenAnswer((_) async => u);
      when(() => users.getPasswordHash('u-1')).thenAnswer((_) async => hash);

      expect(
        () => auth.login(email: 'a@b.ru', password: 'wrong-pass1'),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 401)),
      );
    });
  });
}
