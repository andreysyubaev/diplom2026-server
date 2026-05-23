// CRUD по таблице results (результатам тестов).

import 'dart:convert';

import '../db/connection.dart';
import '../models/result.dart';

class ResultRepository {
  ResultRepository(this._db);
  final Database _db;

  /// Сохраняет результат и возвращает его.
  Future<TestResult> save({
    required String studentId,
    required String subthemeId,
    required String testId,
    required int score,
    required int maxScore,
    required num percentage,
    int? grade,
    required Map<String, dynamic> answers,
  }) async {
    // Первый ли это раз? — Проверяем, есть ли уже хоть одна запись.
    final prev = await _db.execute(
      'SELECT 1 FROM results WHERE student_id = @s AND subtheme_id = @sub LIMIT 1',
      parameters: {'s': studentId, 'sub': subthemeId},
    );
    final isFirst = prev.isEmpty;

    final res = await _db.execute(
      'INSERT INTO results '
      '(student_id, subtheme_id, test_id, score, max_score, percentage, grade, is_first_attempt, answers) '
      'VALUES (@st,@sub,@t,@sc,@max,@p,@g,@f,@a::jsonb) '
      'RETURNING id, student_id, subtheme_id, test_id, score, max_score, percentage, grade, '
      'is_first_attempt, completed_at',
      parameters: {
        'st': studentId,
        'sub': subthemeId,
        't': testId,
        'sc': score,
        'max': maxScore,
        'p': percentage,
        'g': grade,
        'f': isFirst,
        'a': jsonEncode(answers),
      },
    );
    final row = _namedRow(res.first, res.schema.columns);
    return TestResult.fromRow(row);
  }

  /// Все результаты конкретного студента по конкретной подтеме.
  Future<List<TestResult>> listForStudent({
    required String studentId,
    String? subthemeId,
  }) async {
    final params = <String, Object?>{'st': studentId};
    var sql = 'SELECT r.id, r.student_id, NULL AS student_name, '
        'r.subtheme_id, sub.title AS subtheme_title, '
        'r.test_id, r.score, r.max_score, r.percentage, r.grade, '
        'r.is_first_attempt, r.completed_at '
        'FROM results r LEFT JOIN subthemes sub ON sub.id = r.subtheme_id '
        'WHERE r.student_id = @st';
    if (subthemeId != null) {
      sql += ' AND r.subtheme_id = @sub';
      params['sub'] = subthemeId;
    }
    sql += ' ORDER BY r.completed_at DESC';
    final res = await _db.execute(sql, parameters: params);
    return res
        .map((r) => TestResult.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  /// Все результаты по предмету (для преподавателя).
  Future<List<TestResult>> listForSubject(String subjectId) async {
    final res = await _db.execute(
      'SELECT r.id, r.student_id, u.full_name AS student_name, '
      'r.subtheme_id, sub.title AS subtheme_title, '
      'r.test_id, r.score, r.max_score, r.percentage, r.grade, '
      'r.is_first_attempt, r.completed_at '
      'FROM results r '
      'JOIN subthemes sub ON sub.id = r.subtheme_id '
      'JOIN themes th ON th.id = sub.theme_id '
      'JOIN users u ON u.id = r.student_id '
      'WHERE th.subject_id = @s '
      'ORDER BY r.completed_at DESC',
      parameters: {'s': subjectId},
    );
    return res
        .map((r) => TestResult.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  /// Все результаты по конкретной подтеме (для преподавателя).
  Future<List<TestResult>> listForSubtheme(String subthemeId) async {
    final res = await _db.execute(
      'SELECT r.id, r.student_id, u.full_name AS student_name, '
      'r.subtheme_id, sub.title AS subtheme_title, '
      'r.test_id, r.score, r.max_score, r.percentage, r.grade, '
      'r.is_first_attempt, r.completed_at '
      'FROM results r '
      'JOIN subthemes sub ON sub.id = r.subtheme_id '
      'JOIN users u ON u.id = r.student_id '
      'WHERE r.subtheme_id = @sub '
      'ORDER BY r.completed_at DESC',
      parameters: {'sub': subthemeId},
    );
    return res
        .map((r) => TestResult.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  static Map<String, dynamic> _namedRow(
    List<dynamic> row,
    List<dynamic> columns,
  ) {
    final map = <String, dynamic>{};
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i] as dynamic;
      map[col.columnName as String] = row[i];
    }
    return map;
  }
}
