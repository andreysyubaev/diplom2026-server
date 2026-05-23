// GET    /teacher/themes/<id> — детали темы
// PATCH  /teacher/themes/<id> — обновить (title/description/visibility/sortOrder/scheduledAt)
// DELETE /teacher/themes/<id>

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/theme.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return runSafely(() async {
    final theme = await context.services.themes.findById(id);
    if (theme == null) throw ApiError.notFound('Тема не найдена');
    await ensureCanManageSubject(context, theme.subjectId);

    switch (context.request.method) {
      case HttpMethod.get:
        return jsonOk(theme.toJson());

      case HttpMethod.patch:
        final body = await readJson(context.request);
        ContentVisibility? vis;
        if (body['visibility'] != null) {
          try {
            vis = ContentVisibility.parse(body.reqString('visibility'));
          } catch (_) {
            throw ApiError.badRequest('Некорректная visibility');
          }
        }
        final updated = await context.services.themes.update(
          id: id,
          title: body.optString('title'),
          description: body.optString('description'),
          sortOrder: body.optInt('sortOrder'),
          visibility: vis,
          scheduledAt: body.optDateTime('scheduledAt'),
          clearScheduledAt: body['scheduledAt'] == null && body.containsKey('scheduledAt'),
        );
        return jsonOk(updated.toJson());

      case HttpMethod.delete:
        await context.services.themes.delete(id);
        return noContent();

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
