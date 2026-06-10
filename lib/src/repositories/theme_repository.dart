// CRUD по таблице themes (тем/коллекций).

import '../db/connection.dart';
import '../models/theme.dart';

class ThemeRepository {
  ThemeRepository(this._db);
  final Database _db;

  Future<Theme?> findById(String id) async {
    final res = await _db.execute(
      'SELECT id, subject_id, title, description, sort_order, visibility, scheduled_at, created_at '
      'FROM themes WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return Theme.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<List<Theme>> listBySubject(String subjectId) async {
    final res = await _db.execute(
      'SELECT id, subject_id, title, description, sort_order, visibility, scheduled_at, created_at '
      'FROM themes WHERE subject_id = @s ORDER BY sort_order, created_at',
      parameters: {'s': subjectId},
    );
    return res
        .map((r) => Theme.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<Theme> create({
    required String subjectId,
    required String title,
    String? description,
    int sortOrder = 0,
    ContentVisibility visibility = ContentVisibility.draft,
    DateTime? scheduledAt,
  }) async {
    final res = await _db.execute(
      'INSERT INTO themes (subject_id, title, description, sort_order, visibility, scheduled_at) '
      'VALUES (@s,@t,@d,@o,@v,@sa) '
      'RETURNING id, subject_id, title, description, sort_order, visibility, scheduled_at, created_at',
      parameters: {
        's': subjectId,
        't': title,
        'd': description,
        'o': sortOrder,
        'v': visibility.toSql(),
        'sa': scheduledAt,
      },
    );
    return Theme.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<Theme> update({
    required String id,
    String? title,
    String? description,
    int? sortOrder,
    ContentVisibility? visibility,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
  }) async {
    final sets = <String>[];
    final params = <String, Object?>{'i': id};
    if (title != null) {
      sets.add('title = @t');
      params['t'] = title;
    }
    if (description != null) {
      sets.add('description = @d');
      params['d'] = description;
    }
    if (sortOrder != null) {
      sets.add('sort_order = @o');
      params['o'] = sortOrder;
    }
    if (visibility != null) {
      sets.add('visibility = @v');
      params['v'] = visibility.toSql();
    }
    if (clearScheduledAt) {
      sets.add('scheduled_at = NULL');
    } else if (scheduledAt != null) {
      sets.add('scheduled_at = @sa');
      params['sa'] = scheduledAt;
    }
    // Сбрасываем флаг «уже уведомили», чтобы шедулер заметил
    // обновлённую дату/состояние.
    if (visibility == ContentVisibility.scheduled || scheduledAt != null) {
      sets.add('scheduled_notified = FALSE');
    }
    if (sets.isEmpty) return (await findById(id))!;
    await _db.execute(
      'UPDATE themes SET ${sets.join(', ')} WHERE id = @i',
      parameters: params,
    );
    return (await findById(id))!;
  }

  Future<void> delete(String id) async {
    await _db.execute(
      'DELETE FROM themes WHERE id = @i',
      parameters: {'i': id},
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
