// Хэширование и проверка паролей.
// Используем Argon2id - современный, рекомендованный OWASP алгоритм,
// который специально замедлен для защиты от brute-force.

import 'dart:convert';
import 'package:crypto/crypto.dart';
//import 'package:dargon2/dargon2.dart';
import 'argon/argon_pure.dart';

// class PasswordService {
//   static const _iterations = 2;
//   static const _memory = 1 << 16; // 64 MB
//   static const _parallelism = 2;

//   /// Хэширует пароль и возвращает encoded-строку,
//   /// которую можно положить в БД и потом проверить через [verify].
//   Future<String> hash(String password) async {
//     final salt = Salt.newSalt();
//     final result = await argon2.hashPasswordString(
//       password,
//       salt: salt,
//       iterations: _iterations,
//       memory: _memory,
//       parallelism: _parallelism,
//       type: Argon2Type.id,
//       version: Argon2Version.V13,
//     );
//     return result.encodedString;
//   }

//   /// Проверяет, что пароль соответствует ранее сохранённому хэшу.
//   Future<bool> verify(String password, String encodedHash) async {
//     try {
//       final result = await argon2.verifyHashString(password, encodedHash);
//       return result;
//     } catch (_) {
//       return false;
//     }
//   }

//   /// Проверка минимальных требований к паролю.
//   /// Возвращает текст ошибки или null если пароль ок.
//   String? validate(String password) {
//     if (password.length < 8) {
//       return 'Пароль должен содержать минимум 8 символов';
//     }
//     if (password.length > 128) {
//       return 'Слишком длинный пароль (максимум 128)';
//     }
//     if (!RegExp(r'[A-Za-zА-Яа-я]').hasMatch(password)) {
//       return 'Пароль должен содержать хотя бы одну букву';
//     }
//     if (!RegExp(r'\d').hasMatch(password)) {
//       return 'Пароль должен содержать хотя бы одну цифру';
//     }
//     return null;
//   }

//   /// SHA-256 от refresh-токена. Используется чтобы хранить не сам токен,
//   /// а его хэш в таблице refresh_tokens.
//   String hashRefreshToken(String token) {
//     return sha256.convert(utf8.encode(token)).toString();
//   }
// }

class PasswordService {
  static const _iterations = 2;
  static const _memory = 1 << 16; // 64 MB
  static const _parallelism = 2;

  Future<String> hash(String password) async {
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      iterations: _iterations,
      memory: _memory,
      lanes: _parallelism,
    );

    final passwordBytes = utf8.encode(password);
    final saltBytes = Argon2Parameters.generateSalt();
    final argon2 = Argon2(parameters);
    final hashBytes = argon2.argon2(passwordBytes, saltBytes);

    return parameters.encodeStringToPHC(hashBytes, saltBytes);
  }

  Future<bool> verify(String password, String encodedHash) async {
    try {
      return Argon2.verifyString(encodedHash, password);
    } catch (_) {
      return false;
    }
  }

  String? validate(String password) {
    if (password.length < 8) return 'Пароль должен содержать минимум 8 символов';
    if (password.length > 128) return 'Слишком длинный пароль (максимум 128)';
    if (!RegExp(r'[A-Za-zА-Яа-я]').hasMatch(password)) return 'Пароль должен содержать хотя бы одну букву';
    if (!RegExp(r'\d').hasMatch(password)) return 'Пароль должен содержать хотя бы одну цифру';
    return null;
  }

  String hashRefreshToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }
}