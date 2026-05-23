// GET  /teacher/subjects/<id>/themes  — все темы предмета (включая черновики)
// POST /teacher/subjects/<id>/themes  — создать новую тему
//
// Тело POST:
//   { "title": "Производные", "description": "...",
//     "visibility": "draft|published|visible_locked|scheduled",
//     "scheduledAt": "2026-09-01T08:00:00Z",
//     "sortOrder": 0 }

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/theme.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context, id);
    case HttpMethod.post:
      return _create(context, id);
    default:
      return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
}

Future<Response> _list(RequestContext context, String id) async {
  return runSafely(() async {
    await ensureCanManageSubject(context, id);
    final themes = await context.services.themes.listBySubject(id);
    return jsonOk({'items': themes.map((t) => t.toJson()).toList()});
  });
}

Future<Response> _create(RequestContext context, String id) async {
  return runSafely(() async {
    await ensureCanManageSubject(context, id);
    final body = await readJson(context.request);
    final visStr = body.optString('visibility') ?? 'draft';
    ContentVisibility vis;
    try {
      vis = ContentVisibility.parse(visStr);
    } catch (_) {
      throw ApiError.badRequest('Некорректная visibility');
    }
    final scheduledAt = body.optDateTime('scheduledAt');
    if (vis == ContentVisibility.scheduled && scheduledAt == null) {
      throw ApiError.badRequest(
        'Для visibility=scheduled нужно указать scheduledAt',
      );
    }
    final theme = await context.services.themes.create(
      subjectId: id,
      title: body.reqString('title'),
      description: body.optString('description'),
      sortOrder: body.optInt('sortOrder') ?? 0,
      visibility: vis,
      scheduledAt: scheduledAt,
    );
    return jsonOk(theme.toJson(), status: 201);
  });
}
