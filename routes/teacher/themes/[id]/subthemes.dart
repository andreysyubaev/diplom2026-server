// GET  /teacher/themes/<id>/subthemes — список подтем
// POST /teacher/themes/<id>/subthemes — создать подтему
//
// Тело POST:
//   { "title": "...", "content": "...",
//     "contentBlocks": [ {type:"text",text:"..."}, {type:"image",url:"...",caption:"..."} ],
//     "visibility": "draft|published|visible_locked|scheduled",
//     "scheduledAt": "...", "sortOrder": 0 }

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/subtheme.dart';
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
        final blocks = body.containsKey('contentBlocks')
            ? normalizeContentBlocks(body['contentBlocks'])
            : <Map<String, dynamic>>[];
        final sub = await context.services.subthemes.create(
          themeId: id,
          title: body.reqString('title'),
          content: body.optString('content') ?? '',
          contentBlocks: blocks,
          sortOrder: body.optInt('sortOrder') ?? 0,
          visibility: vis,
          scheduledAt: scheduledAt,
        );
        // Если сразу опубликовано — оповестим студентов.
        if (vis == ContentVisibility.published) {
          final students = await context.services.subjects
              .listStudents(theme.subjectId);
          if (students.isNotEmpty) {
            await context.services.notifications.createBulk(
              userIds: students.map((m) => m['id'] as String).toList(),
              type: 'new_subtheme',
              title: 'Новая лекция',
              body: 'Преподаватель опубликовал лекцию «${sub.title}».',
              data: {
                'subthemeId': sub.id,
                'subjectId': theme.subjectId,
              },
            );
          }
        }
        return jsonOk(sub.toJson(), status: 201);

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
