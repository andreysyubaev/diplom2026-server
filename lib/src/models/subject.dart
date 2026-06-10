class Subject {
  Subject({
    required this.id,
    required this.name,
    this.description,
    this.teacherId,
    this.teacherName,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? teacherId;
  final String? teacherName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subject.fromRow(Map<String, dynamic> row) => Subject(
        id: row['id'].toString(),
        name: row['name'] as String,
        description: row['description'] as String?,
        teacherId: row['teacher_id']?.toString(),
        teacherName: row['teacher_name'] as String?,
        createdAt: row['created_at'] as DateTime,
      );
}

class SubjectCode {
  SubjectCode({
    required this.code,
    required this.expiresAt,
    required this.refreshInSeconds,
    this.locked = false,
  });

  final String code;
  final DateTime expiresAt;
  final int refreshInSeconds;

  /// Заблокирован ли код (не будет автоматически меняться).
  final bool locked;

  Map<String, dynamic> toJson() => {
        'code': code,
        'expiresAt': expiresAt.toIso8601String(),
        'refreshInSeconds': refreshInSeconds,
        'locked': locked,
      };
}
