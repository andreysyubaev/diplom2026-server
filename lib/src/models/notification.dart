import 'dart:convert';

/// Уведомление пользователя.
class Notification {
  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Notification.fromRow(Map<String, dynamic> row) => Notification(
        id: row['id'].toString(),
        userId: row['user_id'].toString(),
        type: row['type'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        data: _decode(row['data']),
        isRead: row['is_read'] as bool,
        createdAt: row['created_at'] as DateTime,
      );

  static Map<String, dynamic> _decode(Object? raw) {
    if (raw == null) return const {};
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      if (raw.isEmpty) return const {};
      try {
        final d = jsonDecode(raw);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return const {};
  }
}
