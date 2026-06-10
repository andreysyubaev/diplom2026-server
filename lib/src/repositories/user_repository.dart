// CRUD по таблице users.
// Список должностей собираем подзапросом с json_agg, чтобы за один SELECT
// получить пользователя и все его должности.

import '../db/connection.dart';
import '../models/user.dart';

class UserRepository {
  UserRepository(this._db);
  final Database _db;

  /// Подзапрос с массивом должностей. COALESCE даёт пустой массив,
  /// если ни одна должность не привязана.
  static const _positionsSubquery =
      "(SELECT COALESCE(json_agg(json_build_object('id', p.id, 'name', p.name) "
      "ORDER BY p.name), '[]'::json) "
      "FROM user_positions up JOIN positions p ON p.id = up.position_id "
      "WHERE up.user_id = u.id) AS positions";

  static const _selectCols =
      'u.id, u.email, u.full_name, u.role, $_positionsSubquery, u.created_at';

  Future<User?> findById(String id) async {
    final res = await _db.execute(
      'SELECT $_selectCols FROM users u WHERE u.id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return User.fromRow(_row(res.first, res.schema.columns));
  }

  Future<User?> findByEmail(String email) async {
    final res = await _db.execute(
      'SELECT $_selectCols FROM users u WHERE lower(u.email) = lower(@e)',
      parameters: {'e': email.trim()},
    );
    if (res.isEmpty) return null;
    return User.fromRow(_row(res.first, res.schema.columns));
  }

  Future<String?> getPasswordHash(String id) async {
    final res = await _db.execute(
      'SELECT password_hash FROM users WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return res.first[0] as String?;
  }

  Future<User> create({
    required String email,
    required String passwordHash,
    required String fullName,
    required UserRole role,
    List<String> positionIds = const [],
  }) async {
    final res = await _db.execute(
      'INSERT INTO users (email, password_hash, full_name, role) '
      'VALUES (@e,@h,@n,@r) RETURNING id',
      parameters: {
        'e': email,
        'h': passwordHash,
        'n': fullName,
        'r': role.name,
      },
    );
    final id = res.first[0].toString();
    if (positionIds.isNotEmpty) {
      await setPositions(id, positionIds);
    }
    return (await findById(id))!;
  }

  Future<void> updatePasswordHash(String id, String hash) async {
    await _db.execute(
      'UPDATE users SET password_hash = @h WHERE id = @i',
      parameters: {'h': hash, 'i': id},
    );
  }

  Future<User> updateRole(String id, UserRole role) async {
    await _db.execute(
      'UPDATE users SET role = @r WHERE id = @i',
      parameters: {'r': role.name, 'i': id},
    );
    return (await findById(id))!;
  }

  /// Полная замена набора должностей у пользователя.
  /// [positionIds] = [] снимет все должности.
  Future<User> setPositions(String userId, List<String> positionIds) async {
    await _db.execute(
      'DELETE FROM user_positions WHERE user_id = @u',
      parameters: {'u': userId},
    );
    for (final pid in positionIds.toSet()) {
      await _db.execute(
        'INSERT INTO user_positions (user_id, position_id) VALUES (@u, @p) '
        'ON CONFLICT DO NOTHING',
        parameters: {'u': userId, 'p': pid},
      );
    }
    return (await findById(userId))!;
  }

  Future<List<User>> list({UserRole? role, String? search, int limit = 100}) async {
    final clauses = <String>[];
    final params = <String, Object?>{'lim': limit};
    if (role != null) {
      clauses.add('u.role = @r');
      params['r'] = role.name;
    }
    if (search != null && search.isNotEmpty) {
      clauses.add('(lower(u.email) LIKE @s OR lower(u.full_name) LIKE @s)');
      params['s'] = '%${search.toLowerCase()}%';
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final res = await _db.execute(
      'SELECT $_selectCols FROM users u '
      '$where ORDER BY u.created_at DESC LIMIT @lim',
      parameters: params,
    );
    return res
        .map((row) => User.fromRow(_row(row, res.schema.columns)))
        .toList();
  }

  Future<int> countByRole(UserRole role) async {
    final res = await _db.execute(
      'SELECT COUNT(*) FROM users WHERE role = @r',
      parameters: {'r': role.name},
    );
    return (res.first[0]! as int);
  }

  /// Превращает строку результата в Map<colName,value>.
  static Map<String, dynamic> _row(
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
