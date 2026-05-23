// GET    /teacher/subthemes/<id>
// PATCH  /teacher/subthemes/<id>
// DELETE /teacher/subthemes/<id>

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/theme.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return runSafely(() async {
    final owner = await ownerOfSubtheme(context, id);
    await ensureCanManageSubject(context, owner.subjectId);

    switch (context.request.method) {
      case HttpMethod.get:
        final sub = await context.services.subthemes.findById(id);
        return jsonOk(sub!.toJson());

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
        final updated = await context.services.subthemes.update(
          id: id,
          title: body.optString('title'),
          content: body.optString('content'),
          sortOrder: body.optInt('sortOrder'),
          visibility: vis,
          scheduledAt: body.optDateTime('scheduledAt'),
          clearScheduledAt:
              body['scheduledAt'] == null && body.containsKey('scheduledAt'),
        );
        return jsonOk(updated.toJson());

      case HttpMethod.delete:
        await context.services.subthemes.delete(id);
        return noContent();

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
