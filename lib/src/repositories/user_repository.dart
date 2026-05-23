// CRUD по таблице users.

import '../db/connection.dart';
import '../models/user.dart';

class UserRepository {
  UserRepository(this._db);
  final Database _db;

  Future<User?> findById(String id) async {
    final res = await _db.execute(
      'SELECT id,email,full_name,role,position,created_at FROM users WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    return User.fromRow(_row(res.first, res.schema.columns));
  }

  Future<User?> findByEmail(String email) async {
    final res = await _db.execute(
      'SELECT id,email,full_name,role,position,created_at FROM users WHERE lower(email) = lower(@e)',
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
    String? position,
  }) async {
    final res = await _db.execute(
      'INSERT INTO users (email,password_hash,full_name,role,position) '
      'VALUES (@e,@h,@n,@r,@p) '
      'RETURNING id,email,full_name,role,position,created_at',
      parameters: {
        'e': email,
        'h': passwordHash,
        'n': fullName,
        'r': role.name,
        'p': position,
      },
    );
    return User.fromRow(_row(res.first, res.schema.columns));
  }

  Future<void> updatePasswordHash(String id, String hash) async {
    await _db.execute(
      'UPDATE users SET password_hash = @h WHERE id = @i',
      parameters: {'h': hash, 'i': id},
    );
  }

  Future<User> updateRole(String id, UserRole role) async {
    final res = await _db.execute(
      'UPDATE users SET role = @r WHERE id = @i '
      'RETURNING id,email,full_name,role,position,created_at',
      parameters: {'r': role.name, 'i': id},
    );
    return User.fromRow(_row(res.first, res.schema.columns));
  }

  Future<User> updatePosition(String id, String? position) async {
    final res = await _db.execute(
      'UPDATE users SET position = @p WHERE id = @i '
      'RETURNING id,email,full_name,role,position,created_at',
      parameters: {'p': position, 'i': id},
    );
    return User.fromRow(_row(res.first, res.schema.columns));
  }

  Future<List<User>> list({UserRole? role, String? search, int limit = 100}) async {
    final clauses = <String>[];
    final params = <String, Object?>{'lim': limit};
    if (role != null) {
      clauses.add('role = @r');
      params['r'] = role.name;
    }
    if (search != null && search.isNotEmpty) {
      clauses.add('(lower(email) LIKE @s OR lower(full_name) LIKE @s)');
      params['s'] = '%${search.toLowerCase()}%';
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final res = await _db.execute(
      'SELECT id,email,full_name,role,position,created_at FROM users '
      '$where ORDER BY created_at DESC LIMIT @lim',
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
