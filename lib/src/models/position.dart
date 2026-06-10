/// Должность преподавателя.
class Position {
  Position({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Position.fromRow(Map<String, dynamic> row) => Position(
        id: row['id'].toString(),
        name: row['name'] as String,
        createdAt: row['created_at'] as DateTime,
      );
}
