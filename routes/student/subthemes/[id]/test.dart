// GET /student/subthemes/<id>/test — получить тест без правильных ответов.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/http/student_guard.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
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
    if (test == null) throw ApiError.notFound('Тест ещё не создан');

    // Подсказка студенту: пойдёт ли следующая попытка «на оценку».
    // Идёт, если это первая попытка ИЛИ препод выдал разрешение на пересдачу.
    final priorAttempts = await context.services.results.listForStudent(
      studentId: context.currentUser.id,
      subthemeId: id,
    );
    final hasRetake = await context.services.results.hasRetake(
      studentId: context.currentUser.id,
      subthemeId: id,
    );
    final nextGraded = priorAttempts.isEmpty || hasRetake;

    return jsonOk({
      ...test.toStudentJson(),
      'nextAttemptGraded': nextGraded,
      'retakeGranted': hasRetake,
    });
  });
}
