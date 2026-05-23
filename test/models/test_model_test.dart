// Тесты бизнес-логики моделей.

import 'package:college_app_server/src/models/test.dart';
import 'package:college_app_server/src/models/theme.dart';
import 'package:test/test.dart';

void main() {
  group('TestModel.gradeForPercentage', () {
    final model = TestModel(
      id: 't',
      subthemeId: 's',
      gradeThresholds: {'2': 0, '3': 50, '4': 70, '5': 90},
      shuffleQuestions: false,
    );

    test('0% → 2', () => expect(model.gradeForPercentage(0), 2));
    test('49% → 2', () => expect(model.gradeForPercentage(49), 2));
    test('50% → 3', () => expect(model.gradeForPercentage(50), 3));
    test('69% → 3', () => expect(model.gradeForPercentage(69), 3));
    test('70% → 4', () => expect(model.gradeForPercentage(70), 4));
    test('89% → 4', () => expect(model.gradeForPercentage(89), 4));
    test('90% → 5', () => expect(model.gradeForPercentage(90), 5));
    test('100% → 5', () => expect(model.gradeForPercentage(100), 5));
  });

  group('Theme visibility', () {
    Theme make(ContentVisibility v, {DateTime? sched}) => Theme(
          id: 'i',
          subjectId: 's',
          title: 't',
          sortOrder: 0,
          visibility: v,
          scheduledAt: sched,
          createdAt: DateTime.now(),
        );

    test('draft не видна студенту', () {
      expect(make(ContentVisibility.draft).isVisibleToStudent, isFalse);
    });
    test('published видна и доступна', () {
      final t = make(ContentVisibility.published);
      expect(t.isVisibleToStudent, isTrue);
      expect(t.isUnlockedNow, isTrue);
    });
    test('visible_locked видна но недоступна', () {
      final t = make(ContentVisibility.visibleLocked);
      expect(t.isVisibleToStudent, isTrue);
      expect(t.isUnlockedNow, isFalse);
    });
    test('scheduled в будущем — видна, недоступна', () {
      final t = make(
        ContentVisibility.scheduled,
        sched: DateTime.now().add(const Duration(days: 1)).toUtc(),
      );
      expect(t.isVisibleToStudent, isTrue);
      expect(t.isUnlockedNow, isFalse);
    });
    test('scheduled в прошлом — видна и доступна', () {
      final t = make(
        ContentVisibility.scheduled,
        sched: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
      );
      expect(t.isUnlockedNow, isTrue);
    });
  });

  group('Question.toStudentJson', () {
    test('single_choice не отдаёт correctIndex', () {
      final q = Question(
        id: 'q1',
        testId: 't1',
        type: QuestionType.singleChoice,
        text: '2+2?',
        sortOrder: 0,
        points: 1,
        payload: {
          'options': ['3', '4', '5'],
          'correctIndex': 1,
        },
      );
      final j = q.toStudentJson();
      expect(j['payload']['options'], ['3', '4', '5']);
      expect((j['payload'] as Map).containsKey('correctIndex'), isFalse);
    });

    test('text_input не отдаёт acceptedAnswers', () {
      final q = Question(
        id: 'q2',
        testId: 't1',
        type: QuestionType.textInput,
        text: '?',
        sortOrder: 0,
        points: 1,
        payload: {
          'acceptedAnswers': ['42'],
          'caseSensitive': false,
        },
      );
      final j = q.toStudentJson();
      expect((j['payload'] as Map).isEmpty, isTrue);
    });
  });
}
