// Юнит-тесты PasswordService. Без БД и без сети.

import 'package:college_app_server/src/services/password_service.dart';
import 'package:test/test.dart';

void main() {
  final service = PasswordService();

  group('validate', () {
    test('коротки пароли отклоняются', () {
      expect(service.validate('abc'), isNotNull);
    });
    test('пароли без цифр отклоняются', () {
      expect(service.validate('abcdefghij'), isNotNull);
    });
    test('пароли без букв отклоняются', () {
      expect(service.validate('1234567890'), isNotNull);
    });
    test('нормальные пароли проходят', () {
      expect(service.validate('hello123'), isNull);
      expect(service.validate('Пароль42'), isNull);
    });
  });

  group('hash/verify', () {
    test('хеш отличается от исходника и проходит verify', () async {
      final hash = await service.hash('Secret123');
      expect(hash, isNot('Secret123'));
      expect(await service.verify('Secret123', hash), isTrue);
      expect(await service.verify('wrong', hash), isFalse);
    });

    test('два хеша одного пароля разные (за счёт соли)', () async {
      final a = await service.hash('pass1234');
      final b = await service.hash('pass1234');
      expect(a, isNot(b));
    });
  });

  group('hashRefreshToken', () {
    test('детерминированный sha256 от токена', () {
      expect(service.hashRefreshToken('foo'), service.hashRefreshToken('foo'));
      expect(
        service.hashRefreshToken('foo'),
        isNot(service.hashRefreshToken('bar')),
      );
    });
  });
}
