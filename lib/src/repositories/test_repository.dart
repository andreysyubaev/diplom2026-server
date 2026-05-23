// CRUD по таблицам tests и questions.

import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../db/connection.dart';
import '../models/test.dart';

class TestRepository {
  TestRepository(this._db);
  final Database _db;

  Future<TestModel?> findBySubthemeId(String subthemeId, {bool withQuestions = true}) async {
    final res = await _db.execute(
      'SELECT id, subtheme_id, grade_thresholds, shuffle_questions '
      'FROM tests WHERE subtheme_id = @s',
      parameters: {'s': subthemeId},
    );
    if (res.isEmpty) return null;
    final row = _namedRow(res.first, res.schema.columns);
    if (!withQuestions) return TestModel.fromRow(row);
    final qs = await listQuestions(row['id'].toString());
    return TestModel.fromRow(row, questions: qs);
  }

  Future<TestModel?> findById(String id, {bool withQuestions = true}) async {
    final res = await _db.execute(
      'SELECT id, subtheme_id, grade_thresholds, shuffle_questions '
      'FROM tests WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    final row = _namedRow(res.first, res.schema.columns);
    if (!withQuestions) return TestModel.fromRow(row);
    final qs = await listQuestions(row['id'].toString());
    return TestModel.fromRow(row, questions: qs);
  }

  /// Создаёт или обновляет тест целиком вместе с вопросами (replace-стратегия).
  Future<TestModel> upsert({
    required String subthemeId,
    required Map<String, int> gradeThresholds,
    required bool shuffleQuestions,
    required List<Map<String, dynamic>> questions,
  }) async {
    return _db.runTx<TestModel>((tx) async {
      final existing = await tx.execute(
        Sql.named('SELECT id FROM tests WHERE subtheme_id = @s'),
        parameters: {'s': subthemeId},
      );
      String testId;
      if (existing.isEmpty) {
        final created = await tx.execute(
          Sql.named(
            'INSERT INTO tests (subtheme_id, grade_thresholds, shuffle_questions) '
            'VALUES (@s, @g::jsonb, @sh) RETURNING id',
          ),
          parameters: {
            's': subthemeId,
            'g': jsonEncode(gradeThresholds),
            'sh': shuffleQuestions,
          },
        );
        testId = created.first[0].toString();
      } else {
        testId = existing.first[0].toString();
        await tx.execute(
          Sql.named(
            'UPDATE tests SET grade_thresholds = @g::jsonb, shuffle_questions = @sh '
            'WHERE id = @i',
          ),
          parameters: {
            'g': jsonEncode(gradeThresholds),
            'sh': shuffleQuestions,
            'i': testId,
          },
        );
      }
      // Удаляем старые вопросы и вставляем новые
      await tx.execute(
        Sql.named('DELETE FROM questions WHERE test_id = @t'),
        parameters: {'t': testId},
      );
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        await tx.execute(
          Sql.named(
            'INSERT INTO questions '
            '(test_id, type, text, image_path, sort_order, points, payload) '
            'VALUES (@t,@ty,@tx,@im,@so,@pt,@pl::jsonb)',
          ),
          parameters: {
            't': testId,
            'ty': q['type'],
            'tx': q['text'],
            'im': q['imagePath'],
            'so': q['sortOrder'] ?? i,
            'pt': q['points'] ?? 1,
            'pl': jsonEncode(q['payload']),
          },
        );
      }
      final loaded = await tx.execute(
        Sql.named(
          'SELECT id, subtheme_id, grade_thresholds, shuffle_questions '
          'FROM tests WHERE id = @i',
        ),
        parameters: {'i': testId},
      );
      final qRows = await tx.execute(
        Sql.named(
          'SELECT id, test_id, type, text, image_path, sort_order, points, payload '
          'FROM questions WHERE test_id = @t ORDER BY sort_order',
        ),
        parameters: {'t': testId},
      );
      final qs = qRows
          .map((r) => Question.fromRow(_namedRow(r, qRows.schema.columns)))
          .toList();
      return TestModel.fromRow(
        _namedRow(loaded.first, loaded.schema.columns),
        questions: qs,
      );
    });
  }

  Future<List<Question>> listQuestions(String testId) async {
    final res = await _db.execute(
      'SELECT id, test_id, type, text, image_path, sort_order, points, payload '
      'FROM questions WHERE test_id = @t ORDER BY sort_order',
      parameters: {'t': testId},
    );
    return res
        .map((r) => Question.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<Question?> findQuestionById(String id) async {
    final res = await _db.execute(
      'SELECT id, test_id, type, text, image_path, sort_order, points, payload '
      'FROM questions WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return Question.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<void> updateQuestionImage(String questionId, String? imagePath) async {
    await _db.execute(
      'UPDATE questions SET image_path = @im WHERE id = @i',
      parameters: {'im': imagePath, 'i': questionId},
    );
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
