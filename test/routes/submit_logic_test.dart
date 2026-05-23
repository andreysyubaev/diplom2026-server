// Проверка чистой логики проверки ответов в submit.dart.
// Дублируем функцию _isCorrect здесь, чтобы протестировать её отдельно от Request/Response.

import 'package:college_app_server/src/models/test.dart';
import 'package:test/test.dart';

bool isCorrect(Question q, dynamic answer) {
  if (answer is! Map<String, dynamic>) return false;
  switch (q.type) {
    case QuestionType.singleChoice:
      final selected = answer['selectedIndex'];
      if (selected is! int) return false;
      return selected == (q.payload['correctIndex'] as int);
    case QuestionType.order:
      final given = answer['order'];
      if (given is! List) return false;
      final correct = q.payload['items'] as List;
      if (given.length != correct.length) return false;
      for (var i = 0; i < correct.length; i++) {
        if (given[i] != correct[i]) return false;
      }
      return true;
    case QuestionType.textInput:
      final txt = answer['text'];
      if (txt is! String) return false;
      final accepted = (q.payload['acceptedAnswers'] as List).cast<String>();
      final caseSensitive = (q.payload['caseSensitive'] as bool?) ?? false;
      if (caseSensitive) {
        return accepted.contains(txt.trim());
      }
      final normalized = txt.trim().toLowerCase();
      return accepted.any((a) => a.toLowerCase() == normalized);
  }
}

Question _sc({required int correct, required List<String> opts}) => Question(
      id: 'q',
      testId: 't',
      type: QuestionType.singleChoice,
      text: '?',
      sortOrder: 0,
      points: 1,
      payload: {'options': opts, 'correctIndex': correct},
    );

void main() {
  group('single_choice', () {
    final q = _sc(correct: 1, opts: ['a', 'b', 'c']);
    test('верный ответ', () =>
        expect(isCorrect(q, {'selectedIndex': 1}), isTrue));
    test('неверный ответ', () =>
        expect(isCorrect(q, {'selectedIndex': 0}), isFalse));
    test('ответ null/мусор', () {
      expect(isCorrect(q, null), isFalse);
      expect(isCorrect(q, {'selectedIndex': 'x'}), isFalse);
    });
  });

  group('order', () {
    final q = Question(
      id: 'q',
      testId: 't',
      type: QuestionType.order,
      text: '?',
      sortOrder: 0,
      points: 2,
      payload: {
        'items': ['1', '2', '3', '4'],
      },
    );
    test('правильный порядок', () => expect(
          isCorrect(q, {'order': ['1', '2', '3', '4']}),
          isTrue,
        ));
    test('неправильный порядок', () => expect(
          isCorrect(q, {'order': ['1', '3', '2', '4']}),
          isFalse,
        ));
    test('разная длина — неверно', () => expect(
          isCorrect(q, {'order': ['1', '2']}),
          isFalse,
        ));
  });

  group('text_input', () {
    final q = Question(
      id: 'q',
      testId: 't',
      type: QuestionType.textInput,
      text: '?',
      sortOrder: 0,
      points: 1,
      payload: {
        'acceptedAnswers': ['42', 'сорок два'],
        'caseSensitive': false,
      },
    );
    test('точное совпадение', () =>
        expect(isCorrect(q, {'text': '42'}), isTrue));
    test('регистронезависимо', () =>
        expect(isCorrect(q, {'text': 'СОРОК ДВА'}), isTrue));
    test('с обрезанием пробелов', () =>
        expect(isCorrect(q, {'text': '  42  '}), isTrue));
    test('неверно', () =>
        expect(isCorrect(q, {'text': '41'}), isFalse));
  });
}
