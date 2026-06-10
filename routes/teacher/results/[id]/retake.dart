// POST   /teacher/results/<resultId>/retake — назначить пересдачу студенту
//                                              из этой попытки.
// DELETE /teacher/results/<resultId>/retake — отменить назначенную пересдачу.
//
// Доступ: препод-владелец предмета или админ.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return runSafely(() async {
    final pair = await context.services.results.findByIdWithAnswers(id);
    if (pair == null) throw ApiError.notFound('Результат не найден');
    final result = pair.result;

    final owner = await ownerOfSubtheme(context, result.subthemeId);
    await ensureCanManageSubject(context, owner.subjectId);

    switch (context.request.method) {
      case HttpMethod.post:
        await context.services.results.grantRetake(
          studentId: result.studentId,
          subthemeId: result.subthemeId,
          grantedBy: context.currentUser.id,
        );
        // Уведомляем студента.
        final sub =
            await context.services.subthemes.findById(result.subthemeId);
        await context.services.notifications.create(
          userId: result.studentId,
          type: 'retake',
          title: 'Назначена пересдача',
          body: sub == null
              ? 'Можно пройти тест ещё раз — результат пойдёт на оценку.'
              : 'Можно пройти тест по теме «${sub.title}» ещё раз — '
                  'результат пойдёт на оценку.',
          data: {
            'subthemeId': result.subthemeId,
            'subjectId': owner.subjectId,
          },
        );
        return jsonOk({'granted': true});

      case HttpMethod.delete:
        await context.services.results.revokeRetake(
          studentId: result.studentId,
          subthemeId: result.subthemeId,
        );
        return jsonOk({'granted': false});

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
