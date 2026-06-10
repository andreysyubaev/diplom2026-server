// POST /student/subthemes/<id>/submit — отправить ответы и получить результат.
//
// Тело:
//   { "answers": {
//       "<questionId>": { "selectedIndex": 1 },            // для single_choice
//       "<questionId>": { "order": ["a","b","c","d"] },    // для order
//       "<questionId>": { "text": "42" }                   // для text_input
//     }
//   }
//
// Ответ: { id, score, maxScore, percentage, grade, isFirstAttempt, details: [...] }

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/http/student_guard.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/test.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final sub = await context.services.subthemes.findById(id);
    if (sub == null || !sub.isVisibleToStudent) {
      throw ApiError.notFound('Подтема не найдена');
    }
    final theme = await context.services.themes.findById(sub.themeId);
    if (theme == null) throw ApiError.notFound('Подтема не найдена');
    await ensureStudentJoined(context, theme.subjectId);
    if (!sub.isUnlockedNow) {
      throw ApiError.forbidden('Подтема пока недоступна');
    }
    final test = await context.services.tests.findBySubthemeId(id);
    if (test == null) throw ApiError.notFound('Тест отсутствует');

    final body = await readJson(context.request);
    final answersRaw = body['answers'];
    if (answersRaw is! Map<String, dynamic>) {
      throw ApiError.badRequest('Поле answers обязательно');
    }

    var earned = 0;
    var maxScore = 0;
    final details = <Map<String, dynamic>>[];

    for (final q in test.questions) {
      maxScore += q.points;
      final ans = answersRaw[q.id];
      final ok = _isCorrect(q, ans);
      if (ok) earned += q.points;
      details.add({
        'questionId': q.id,
        'correct': ok,
        'points': ok ? q.points : 0,
      });
    }

    final percentage = maxScore == 0 ? 0.0 : (earned * 100.0 / maxScore);
    final grade = test.gradeForPercentage(percentage);

    final result = await context.services.results.save(
      studentId: context.currentUser.id,
      subthemeId: id,
      testId: test.id,
      score: earned,
      maxScore: maxScore,
      percentage: double.parse(percentage.toStringAsFixed(2)),
      grade: grade,
      answers: answersRaw,
    );

    // Уведомляем препода о зачётной сдаче (первая попытка или пересдача).
    if (result.isFirstAttempt || result.isRetake) {
      final subject =
          await context.services.subjects.findById(theme.subjectId);
      if (subject != null && subject.teacherId != null) {
        final gradeText = result.grade == null ? '—' : '${result.grade}';
        await context.services.notifications.create(
          userId: subject.teacherId!,
          type: 'test_submitted',
          title: result.isRetake
              ? 'Пересдача: новый результат'
              : 'Тест сдан студентом',
          body:
              '${context.currentUser.fullName} сдал тест по «${sub.title}» '
              'на $gradeText (${result.percentage.toStringAsFixed(0)}%).',
          data: {
            'subjectId': theme.subjectId,
            'subthemeId': id,
            'resultId': result.id,
          },
        );
      }
    }

    return jsonOk({
      ...result.toJson(),
      'details': details,
    });
  });
}

bool _isCorrect(Question q, dynamic answer) {
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
