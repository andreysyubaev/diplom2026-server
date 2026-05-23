// CRUD по таблице subjects + связи студент↔предмет.

import '../db/connection.dart';
import '../models/subject.dart';

class SubjectRepository {
  SubjectRepository(this._db);
  final Database _db;

  Future<Subject?> findById(String id) async {
    final res = await _db.execute(
      'SELECT s.id, s.name, s.description, s.teacher_id, '
      'u.full_name AS teacher_name, s.created_at '
      'FROM subjects s LEFT JOIN users u ON u.id = s.teacher_id '
      'WHERE s.id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return Subject.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<Subject> create({
    required String name,
    String? description,
    String? teacherId,
    String? createdBy,
  }) async {
    final res = await _db.execute(
      'INSERT INTO subjects (name, description, teacher_id, created_by) '
      'VALUES (@n,@d,@t,@c) '
      'RETURNING id, name, description, teacher_id, '
      '(SELECT full_name FROM users WHERE id = @t) AS teacher_name, created_at',
      parameters: {'n': name, 'd': description, 't': teacherId, 'c': createdBy},
    );
    return Subject.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<Subject> update({
    required String id,
    String? name,
    String? description,
    String? teacherId,
  }) async {
    final sets = <String>[];
    final params = <String, Object?>{'i': id};
    if (name != null) {
      sets.add('name = @n');
      params['n'] = name;
    }
    if (description != null) {
      sets.add('description = @d');
      params['d'] = description;
    }
    if (teacherId != null) {
      sets.add('teacher_id = @t');
      params['t'] = teacherId;
    }
    if (sets.isEmpty) {
      final s = await findById(id);
      return s!;
    }
    await _db.execute(
      'UPDATE subjects SET ${sets.join(', ')} WHERE id = @i',
      parameters: params,
    );
    final updated = await findById(id);
    return updated!;
  }

  Future<void> delete(String id) async {
    await _db.execute(
      'DELETE FROM subjects WHERE id = @i',
      parameters: {'i': id},
    );
  }

  Future<List<Subject>> listAll() async {
    final res = await _db.execute(
      'SELECT s.id, s.name, s.description, s.teacher_id, '
      'u.full_name AS teacher_name, s.created_at '
      'FROM subjects s LEFT JOIN users u ON u.id = s.teacher_id '
      'ORDER BY s.name',
    );
    return res
        .map((r) => Subject.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<List<Subject>> listForTeacher(String teacherId) async {
    final res = await _db.execute(
      'SELECT s.id, s.name, s.description, s.teacher_id, '
      'u.full_name AS teacher_name, s.created_at '
      'FROM subjects s LEFT JOIN users u ON u.id = s.teacher_id '
      'WHERE s.teacher_id = @t ORDER BY s.name',
      parameters: {'t': teacherId},
    );
    return res
        .map((r) => Subject.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<List<Subject>> listForStudent(String studentId) async {
    final res = await _db.execute(
      'SELECT s.id, s.name, s.description, s.teacher_id, '
      'u.full_name AS teacher_name, s.created_at '
      'FROM subjects s '
      'JOIN subject_students ss ON ss.subject_id = s.id '
      'LEFT JOIN users u ON u.id = s.teacher_id '
      'WHERE ss.student_id = @st ORDER BY s.name',
      parameters: {'st': studentId},
    );
    return res
        .map((r) => Subject.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<bool> isStudentJoined(String subjectId, String studentId) async {
    final res = await _db.execute(
      'SELECT 1 FROM subject_students WHERE subject_id = @s AND student_id = @st',
      parameters: {'s': subjectId, 'st': studentId},
    );
    return res.isNotEmpty;
  }

  Future<void> addStudent(String subjectId, String studentId) async {
    await _db.execute(
      'INSERT INTO subject_students (subject_id, student_id) VALUES (@s,@st) '
      'ON CONFLICT DO NOTHING',
      parameters: {'s': subjectId, 'st': studentId},
    );
  }

  Future<void> removeStudent(String subjectId, String studentId) async {
    await _db.execute(
      'DELETE FROM subject_students WHERE subject_id = @s AND student_id = @st',
      parameters: {'s': subjectId, 'st': studentId},
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
