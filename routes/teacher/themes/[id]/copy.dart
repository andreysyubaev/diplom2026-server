// POST /teacher/themes/<id>/copy
// Body: { "targetSubjectId": "<uuid>" }
//
// Копирует тему (со всеми подтемами, лекциями, картинками, вложениями и тестами)
// в указанный предмет. Скопированная тема всегда получает статус draft.
// Возвращает { "id": "<новый uuid>" }.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }

  return runSafely(() async {
    // Проверяем, что текущий преподаватель владеет исходной темой.
    final theme = await context.services.themes.findById(id);
    if (theme == null) throw ApiError.notFound('Тема не найдена');
    await ensureCanManageSubject(context, theme.subjectId);

    final body = await readJson(context.request);
    final targetSubjectId = body.reqString('targetSubjectId');

    // Проверяем права и на целевой предмет.
    await ensureCanManageSubject(context, targetSubjectId);

    final newId = await context.services.copy.copyTheme(id, targetSubjectId);
    return jsonOk({'id': newId});
  });
}
