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
    this.position,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? position;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'position': position,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromRow(Map<String, dynamic> row) => User(
        id: row['id'].toString(),
        email: row['email'] as String,
        fullName: row['full_name'] as String,
        role: UserRole.parse(row['role'] as String),
        position: row['position'] as String?,
        createdAt: row['created_at'] as DateTime,
      );
}
