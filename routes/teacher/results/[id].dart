// GET /teacher/results/<id> — детали одной попытки:
//   - сам TestResult (баллы, оценка)
//   - ответы студента (что выбрал/написал/упорядочил)
//   - вопросы теста С эталонными правильными ответами (только препод)
// Доступ: препод-владелец предмета или админ.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final pair = await context.services.results.findByIdWithAnswers(id);
    if (pair == null) throw ApiError.notFound('Результат не найден');
    final result = pair.result;
    final answers = pair.answers;

    // Проверяем, что препод владеет соответствующим предметом.
    final owner = await ownerOfSubtheme(context, result.subthemeId);
    await ensureCanManageSubject(context, owner.subjectId);

    // Грузим тест с вопросами (включая эталонные ответы).
    final test = await context.services.tests.findBySubthemeId(result.subthemeId);
    final questions = test?.questions ?? const [];

    return jsonOk({
      ...result.toJson(),
      'answers': answers,
      'questions': questions.map((q) => q.toTeacherJson()).toList(),
    });
  });
}
