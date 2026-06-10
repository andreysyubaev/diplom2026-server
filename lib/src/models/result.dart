class TestResult {
  TestResult({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.subthemeId,
    this.subthemeTitle,
    required this.testId,
    required this.score,
    required this.maxScore,
    required this.percentage,
    this.grade,
    required this.isFirstAttempt,
    this.isRetake = false,
    required this.completedAt,
  });

  final String id;
  final String studentId;
  final String? studentName;
  final String subthemeId;
  final String? subthemeTitle;
  final String testId;
  final int score;
  final int maxScore;
  final num percentage;
  final int? grade;
  final bool isFirstAttempt;
  final bool isRetake;
  final DateTime completedAt;

  /// Засчитана ли попытка «на оценку» (первая или пересдача).
  bool get isGraded => isFirstAttempt || isRetake;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'subthemeId': subthemeId,
        'subthemeTitle': subthemeTitle,
        'testId': testId,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'grade': grade,
        'isFirstAttempt': isFirstAttempt,
        'isRetake': isRetake,
        'isGraded': isGraded,
        'completedAt': completedAt.toIso8601String(),
      };

  factory TestResult.fromRow(Map<String, dynamic> row) => TestResult(
        id: row['id'].toString(),
        studentId: row['student_id'].toString(),
        studentName: row['student_name'] as String?,
        subthemeId: row['subtheme_id'].toString(),
        subthemeTitle: row['subtheme_title'] as String?,
        testId: row['test_id'].toString(),
        score: (row['score'] as num).toInt(),
        maxScore: (row['max_score'] as num).toInt(),
        // postgres 3.x возвращает NUMERIC как String (или иногда Decimal),
        // а не как num — поэтому нельзя кастить напрямую.
        percentage: _toNum(row['percentage']),
        grade: row['grade'] == null ? null : (row['grade'] as num).toInt(),
        isFirstAttempt: row['is_first_attempt'] as bool,
        isRetake: (row['is_retake'] as bool?) ?? false,
        completedAt: row['completed_at'] as DateTime,
      );

  static num _toNum(Object? v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.parse(v.toString());
  }
}
