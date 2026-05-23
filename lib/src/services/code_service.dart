// Генератор кодов входа в предмет (типа кода Google Classroom).
// Логика:
//   1. У каждого предмета есть "текущий" код, лежащий в таблице subject_codes
//      с полем expires_at.
//   2. Когда преподаватель просит код — сервис ищет последний неистёкший.
//      Если такого нет — генерирует новый, кладёт в БД и возвращает.
//   3. Когда студент пытается войти по коду — ищем последний код для этого
//      предмета, у которого expires_at > now, и сверяем регистронезависимо.
//
// Это даёт эффект "код меняется каждые ~5 минут".

import 'dart:math';

import 'package:postgres/postgres.dart';

import '../config/env.dart';
import '../db/connection.dart';
import '../models/api_error.dart';
import '../models/subject.dart';

class CodeService {
  CodeService(this._db, {int? ttlMinutes})
      : _ttl =
            Duration(minutes: ttlMinutes ?? Env.instance.subjectCodeTtlMinutes);

  final Database _db;
  final Duration _ttl;

  /// Получить или сгенерировать актуальный код для предмета.
  Future<SubjectCode> currentForSubject(String subjectId) async {
    final now = DateTime.now().toUtc();
    final found = await _db.execute(
      'SELECT code, expires_at FROM subject_codes '
      'WHERE subject_id = @s AND expires_at > @n '
      'ORDER BY expires_at DESC LIMIT 1',
      parameters: {'s': subjectId, 'n': now},
    );
    if (found.isNotEmpty) {
      final code = found.first[0]! as String;
      final exp = found.first[1]! as DateTime;
      return SubjectCode(
        code: code,
        expiresAt: exp,
        refreshInSeconds: exp.difference(now).inSeconds,
      );
    }
    final newCode = _generateCode();
    final expires = now.add(_ttl);
    await _db.execute(
      'INSERT INTO subject_codes (subject_id, code, expires_at) '
      'VALUES (@s, @c, @e)',
      parameters: {'s': subjectId, 'c': newCode, 'e': expires},
    );
    return SubjectCode(
      code: newCode,
      expiresAt: expires,
      refreshInSeconds: _ttl.inSeconds,
    );
  }

  /// Найти предмет по введённому коду. Возвращает id предмета или кидает 404.
  Future<String> resolveSubjectId(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length < 4) {
      throw ApiError.badRequest('Слишком короткий код');
    }
    final now = DateTime.now().toUtc();
    final res = await _db.execute(
      'SELECT subject_id FROM subject_codes '
      'WHERE UPPER(code) = @c AND expires_at > @n '
      'ORDER BY expires_at DESC LIMIT 1',
      parameters: {'c': normalized, 'n': now},
    );
    if (res.isEmpty) {
      throw ApiError.notFound('Код не найден или истёк');
    }
    return res.first[0].toString();
  }

  String _generateCode() {
    // Буквы и цифры без визуально похожих: без 0, O, 1, I, L
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => alphabet[rand.nextInt(alphabet.length)])
        .join();
  }
}
