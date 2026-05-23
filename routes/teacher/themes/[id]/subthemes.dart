// GET  /teacher/themes/<id>/subthemes — список подтем
// POST /teacher/themes/<id>/subthemes — создать подтему
//
// Тело POST:
//   { "title": "...", "content": "...",
//     "visibility": "draft|published|visible_locked|scheduled",
//     "scheduledAt": "...", "sortOrder": 0 }

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
        final subs = await context.services.subthemes.listByTheme(id);
        return jsonOk({'items': subs.map((s) => s.toShortJson()).toList()});

      case HttpMethod.post:
        final body = await readJson(context.request);
        ContentVisibility vis;
        try {
          vis = ContentVisibility.parse(body.optString('visibility') ?? 'draft');
        } catch (_) {
          throw ApiError.badRequest('Некорректная visibility');
        }
        final scheduledAt = body.optDateTime('scheduledAt');
        if (vis == ContentVisibility.scheduled && scheduledAt == null) {
          throw ApiError.badRequest('Для scheduled нужно указать scheduledAt');
        }
        final sub = await context.services.subthemes.create(
          themeId: id,
          title: body.reqString('title'),
          content: body.optString('content') ?? '',
          sortOrder: body.optInt('sortOrder') ?? 0,
          visibility: vis,
          scheduledAt: scheduledAt,
        );
        return jsonOk(sub.toJson(), status: 201);

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
