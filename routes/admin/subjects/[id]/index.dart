// GET    /admin/subjects/<id>  — детали предмета
// PATCH  /admin/subjects/<id>  — обновить имя/описание/преподавателя
// DELETE /admin/subjects/<id>

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return runSafely(() async {
    final existing = await context.services.subjects.findById(id);
    if (existing == null) throw ApiError.notFound('Предмет не найден');

    switch (context.request.method) {
      case HttpMethod.get:
        return jsonOk(existing.toJson());
      case HttpMethod.patch:
        final body = await readJson(context.request);
        final teacherId = body.optString('teacherId');
        if (teacherId != null) {
          final t = await context.services.users.findById(teacherId);
          if (t == null) throw ApiError.notFound('Преподаватель не найден');
          if (t.role != UserRole.teacher) {
            throw ApiError.badRequest('Указанный пользователь не преподаватель');
          }
        }
        final updated = await context.services.subjects.update(
          id: id,
          name: body.optString('name'),
          description: body.optString('description'),
          teacherId: teacherId,
        );
        return jsonOk(updated.toJson());
      case HttpMethod.delete:
        await context.services.subjects.delete(id);
        return noContent();
      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
