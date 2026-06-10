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
//
// ЗАМОК:
//   Когда subjects.code_locked = TRUE — код не меняется. При каждом запросе
//   currentForSubject expires_at у текущего кода продлевается на TTL,
//   так что он всегда «живой». При снятии лока код истечёт обычным образом.

import 'dart:math';

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

  /// Возвращает текущий код предмета. Если кода нет или он истёк —
  /// генерирует новый. Если предмет залочен — продлевает срок действия.
  Future<SubjectCode> currentForSubject(String subjectId) async {
    final now = DateTime.now().toUtc();
    final locked = await _isLocked(subjectId);

    final found = await _db.execute(
      'SELECT code, expires_at FROM subject_codes '
      'WHERE subject_id = @s AND expires_at > @n '
      'ORDER BY expires_at DESC LIMIT 1',
      parameters: {'s': subjectId, 'n': now},
    );
    if (found.isNotEmpty) {
      final code = found.first[0]! as String;
      var exp = found.first[1]! as DateTime;
      // Если залочено — продлеваем срок действия, чтобы код «не остыл».
      if (locked) {
        exp = now.add(_ttl);
        await _db.execute(
          'UPDATE subject_codes SET expires_at = @e '
          'WHERE subject_id = @s AND code = @c',
          parameters: {'e': exp, 's': subjectId, 'c': code},
        );
      }
      return SubjectCode(
        code: code,
        expiresAt: exp,
        refreshInSeconds: exp.difference(now).inSeconds,
        locked: locked,
      );
    }
    // Кода нет либо истёк — генерируем новый.
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
      locked: locked,
    );
  }

  /// Принудительно сгенерировать новый код для предмета.
  /// Старые коды помечаются истёкшими, чтобы по ним нельзя было войти.
  Future<SubjectCode> rotate(String subjectId) async {
    final now = DateTime.now().toUtc();
    // Все имеющиеся коды этого предмета помечаем уже истёкшими.
    await _db.execute(
      'UPDATE subject_codes SET expires_at = @n '
      'WHERE subject_id = @s AND expires_at > @n',
      parameters: {'s': subjectId, 'n': now},
    );
    final newCode = _generateCode();
    final expires = now.add(_ttl);
    await _db.execute(
      'INSERT INTO subject_codes (subject_id, code, expires_at) '
      'VALUES (@s, @c, @e)',
      parameters: {'s': subjectId, 'c': newCode, 'e': expires},
    );
    final locked = await _isLocked(subjectId);
    return SubjectCode(
      code: newCode,
      expiresAt: expires,
      refreshInSeconds: _ttl.inSeconds,
      locked: locked,
    );
  }

  /// Включить или выключить замок на смену кода.
  Future<void> setLocked(String subjectId, bool locked) async {
    await _db.execute(
      'UPDATE subjects SET code_locked = @l WHERE id = @s',
      parameters: {'l': locked, 's': subjectId},
    );
  }

  Future<bool> _isLocked(String subjectId) async {
    final res = await _db.execute(
      'SELECT code_locked FROM subjects WHERE id = @s',
      parameters: {'s': subjectId},
    );
    if (res.isEmpty) return false;
    return (res.first[0] as bool?) ?? false;
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
