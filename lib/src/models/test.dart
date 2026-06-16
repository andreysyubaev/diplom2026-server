enum QuestionType {
  singleChoice,
  order,
  textInput;

  static const _toSql = {
    QuestionType.singleChoice: 'single_choice',
    QuestionType.order: 'order',
    QuestionType.textInput: 'text_input',
  };
  static const _fromSql = {
    'single_choice': QuestionType.singleChoice,
    'order': QuestionType.order,
    'text_input': QuestionType.textInput,
  };

  String toSql() => _toSql[this]!;
  static QuestionType parse(String v) => _fromSql[v]!;
}

class Question {
  Question({
    required this.id,
    required this.testId,
    required this.type,
    required this.text,
    this.imagePath,
    required this.sortOrder,
    required this.points,
    required this.payload,
  });

  final String id;
  final String testId;
  final QuestionType type;
  final String text;
  final String? imagePath;
  final int sortOrder;
  final int points;

  /// Содержит правильные ответы. На студенческой стороне НИКОГДА не отдаём.
  final Map<String, dynamic> payload;

  /// Версия для студента (без правильных ответов).
  Map<String, dynamic> toStudentJson() {
    Map<String, dynamic> safePayload;
    switch (type) {
      case QuestionType.singleChoice:
        safePayload = {
          'options': payload['options'],
        };
      case QuestionType.order:
        // Перемешиваем порядок, чтобы студент его восстанавливал
        final items = (payload['items'] as List).toList()..shuffle();
        safePayload = {'items': items};
      case QuestionType.textInput:
        safePayload = const {};
    }
    return {
      'id': id,
      'type': type.toSql(),
      'text': text,
      'imageUrl': imagePath != null ? '/uploads/$imagePath' : null,
      'sortOrder': sortOrder,
      'points': points,
      'payload': safePayload,
    };
  }

  /// Полная версия для преподавателя (с правильными ответами).
  Map<String, dynamic> toTeacherJson() => {
        'id': id,
        'type': type.toSql(),
        'text': text,
        'imageUrl': imagePath != null ? '/uploads/$imagePath' : null,
        'sortOrder': sortOrder,
        'points': points,
        'payload': payload,
      };

  factory Question.fromRow(Map<String, dynamic> row) => Question(
        id: row['id'].toString(),
        testId: row['test_id'].toString(),
        type: QuestionType.parse(row['type'] as String),
        text: row['text'] as String,
        imagePath: row['image_path'] as String?,
        sortOrder: row['sort_order'] as int,
        points: row['points'] as int,
        payload: Map<String, dynamic>.from(row['payload'] as Map),
      );
}

class TestModel {
  TestModel({
    required this.id,
    required this.subthemeId,
    required this.gradeThresholds,
    required this.shuffleQuestions,
    this.timeLimitMinutes,
    this.availableFrom,
    this.availableTo,
    this.questions = const [],
  });

  final String id;
  final String subthemeId;

  /// Карта: "2","3","4","5" → процент.
  final Map<String, int> gradeThresholds;
  final bool shuffleQuestions;

  /// Лимит времени на прохождение теста в минутах. null — без ограничения.
  final int? timeLimitMinutes;

  /// Окно доступности теста. NULL = без ограничения с соответствующей стороны.
  final DateTime? availableFrom;
  final DateTime? availableTo;

  final List<Question> questions;

  /// Считает оценку (2..5) по проценту правильных.
  int gradeForPercentage(num percentage) {
    var best = 2;
    for (final g in [2, 3, 4, 5]) {
      final threshold = gradeThresholds[g.toString()] ?? -1;
      if (threshold < 0) continue;
      if (percentage >= threshold) best = g;
    }
    return best;
  }

  Map<String, dynamic> toTeacherJson() => {
        'id': id,
        'subthemeId': subthemeId,
        'gradeThresholds': gradeThresholds,
        'shuffleQuestions': shuffleQuestions,
        'timeLimitMinutes': timeLimitMinutes,
        'availableFrom': availableFrom?.toUtc().toIso8601String(),
        'availableTo': availableTo?.toUtc().toIso8601String(),
        'questions': questions.map((q) => q.toTeacherJson()).toList(),
      };

  Map<String, dynamic> toStudentJson() {
    final qs = [...questions];
    if (shuffleQuestions) qs.shuffle();
    return {
      'id': id,
      'subthemeId': subthemeId,
      'timeLimitMinutes': timeLimitMinutes,
      'availableFrom': availableFrom?.toUtc().toIso8601String(),
      'availableTo': availableTo?.toUtc().toIso8601String(),
      'questions': qs.map((q) => q.toStudentJson()).toList(),
    };
  }

  factory TestModel.fromRow(
    Map<String, dynamic> row, {
    List<Question> questions = const [],
  }) {
    final raw = row['grade_thresholds'] as Map;
    final thresholds = <String, int>{
      for (final e in raw.entries)
        e.key.toString(): (e.value as num).toInt(),
    };
    return TestModel(
      id: row['id'].toString(),
      subthemeId: row['subtheme_id'].toString(),
      gradeThresholds: thresholds,
      shuffleQuestions: row['shuffle_questions'] as bool,
      timeLimitMinutes: row['time_limit_minutes'] == null
          ? null
          : (row['time_limit_minutes'] as num).toInt(),
      availableFrom: row['available_from'] as DateTime?,
      availableTo: row['available_to'] as DateTime?,
      questions: questions,
    );
  }
}
