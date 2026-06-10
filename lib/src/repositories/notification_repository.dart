import 'dart:convert';

import '../db/connection.dart';
import '../models/notification.dart' as model;

class NotificationRepository {
  NotificationRepository(this._db);
  final Database _db;

  Future<model.Notification> create({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final res = await _db.execute(
      'INSERT INTO notifications (user_id, type, title, body, data) '
      'VALUES (@u,@t,@ti,@b,@d::jsonb) '
      'RETURNING id, user_id, type, title, body, data, is_read, created_at',
      parameters: {
        'u': userId,
        't': type,
        'ti': title,
        'b': body,
        'd': jsonEncode(data),
      },
    );
    return model.Notification.fromRow(_namedRow(res.first, res.schema.columns));
  }

  /// Создать одинаковое уведомление пачке пользователей.
  Future<void> createBulk({
    required List<String> userIds,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (userIds.isEmpty) return;
    final encoded = jsonEncode(data);
    for (final uid in userIds) {
      await _db.execute(
        'INSERT INTO notifications (user_id, type, title, body, data) '
        'VALUES (@u,@t,@ti,@b,@d::jsonb)',
        parameters: {
          'u': uid,
          't': type,
          'ti': title,
          'b': body,
          'd': encoded,
        },
      );
    }
  }

  Future<List<model.Notification>> listForUser(String userId,
      {int limit = 100}) async {
    final res = await _db.execute(
      'SELECT id, user_id, type, title, body, data, is_read, created_at '
      'FROM notifications WHERE user_id = @u '
      'ORDER BY created_at DESC LIMIT @lim',
      parameters: {'u': userId, 'lim': limit},
    );
    return res
        .map((r) => model.Notification.fromRow(_namedRow(r, res.schema.columns)))
        .toList();
  }

  Future<int> unreadCount(String userId) async {
    final res = await _db.execute(
      'SELECT COUNT(*) FROM notifications '
      'WHERE user_id = @u AND is_read = FALSE',
      parameters: {'u': userId},
    );
    return (res.first[0] as num).toInt();
  }

  Future<void> markRead(String id, String userId) async {
    await _db.execute(
      'UPDATE notifications SET is_read = TRUE '
      'WHERE id = @i AND user_id = @u',
      parameters: {'i': id, 'u': userId},
    );
  }

  Future<void> markAllRead(String userId) async {
    await _db.execute(
      'UPDATE notifications SET is_read = TRUE '
      'WHERE user_id = @u AND is_read = FALSE',
      parameters: {'u': userId},
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
