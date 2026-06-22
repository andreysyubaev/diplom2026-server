// POST /teacher/subthemes/<id>/copy
// Body: { "targetThemeId": "<uuid>" }
//
// Копирует подтему (лекция, картинки, вложения, тест) в указанную тему.
// Скопированная подтема всегда получает статус draft.
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
    // Проверяем, что текущий преподаватель владеет исходной подтемой.
    final owner = await ownerOfSubtheme(context, id);
    await ensureCanManageSubject(context, owner.subjectId);

    final body = await readJson(context.request);
    final targetThemeId = body.reqString('targetThemeId');

    // Проверяем права на тему назначения.
    final targetTheme = await context.services.themes.findById(targetThemeId);
    if (targetTheme == null) throw ApiError.notFound('Тема назначения не найдена');
    await ensureCanManageSubject(context, targetTheme.subjectId);

    final newId = await context.services.copy.copySubtheme(id, targetThemeId);
    return jsonOk({'id': newId});
  });
}
