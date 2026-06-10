import 'dart:convert';

enum UserRole {
  admin,
  teacher,
  student;

  static UserRole parse(String value) =>
      UserRole.values.firstWhere((e) => e.name == value);
}

class User {
  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.positions = const [],
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  /// Все назначенные должности (для preподов).
  /// У student / admin всегда пустой список.
  final List<UserPosition> positions;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'positions': positions.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromRow(Map<String, dynamic> row) => User(
        id: row['id'].toString(),
        email: row['email'] as String,
        fullName: row['full_name'] as String,
        role: UserRole.parse(row['role'] as String),
        positions: _parsePositions(row['positions']),
        createdAt: row['created_at'] as DateTime,
      );

  static List<UserPosition> _parsePositions(Object? raw) {
    if (raw == null) return const [];
    final dynamic decoded;
    if (raw is String) {
      if (raw.isEmpty) return const [];
      decoded = jsonDecode(raw);
    } else {
      decoded = raw;
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => UserPosition(
              id: m['id'].toString(),
              name: m['name'] as String,
            ))
        .toList();
  }
}

/// Лёгкая структура «id+name» для встраивания в JSON ответа.
class UserPosition {
  const UserPosition({required this.id, required this.name});
  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
