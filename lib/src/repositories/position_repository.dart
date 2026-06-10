import '../db/connection.dart';
import '../models/api_error.dart';
import '../models/position.dart';

class PositionRepository {
  PositionRepository(this._db);
  final Database _db;

  Future<List<Position>> listAll() async {
    final res = await _db.execute(
      'SELECT id, name, created_at FROM positions ORDER BY name',
    );
    return res
        .map((r) => Position.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<Position?> findById(String id) async {
    final res = await _db.execute(
      'SELECT id, name, created_at FROM positions WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return Position.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<Position> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiError.badRequest('Название должности не может быть пустым');
    }
    try {
      final res = await _db.execute(
        'INSERT INTO positions (name) VALUES (@n) '
        'RETURNING id, name, created_at',
        parameters: {'n': trimmed},
      );
      return Position.fromRow(_namedRow(res.first, res.schema.columns));
    } catch (e) {
      // unique_violation 23505 — должность с таким именем уже есть.
      if (e.toString().contains('23505')) {
        throw ApiError.badRequest('Должность с таким названием уже есть');
      }
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    await _db.execute(
      'DELETE FROM positions WHERE id = @i',
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
