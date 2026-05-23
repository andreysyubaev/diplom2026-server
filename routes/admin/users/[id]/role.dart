// PATCH /admin/users/<id>/role
// Тело: { "role": "teacher" | "student" | "admin" }

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final body = await readJson(context.request);
    UserRole role;
    try {
      role = UserRole.parse(body.reqString('role'));
    } catch (_) {
      throw ApiError.badRequest('Некорректная роль');
    }
    final existing = await context.services.users.findById(id);
    if (existing == null) throw ApiError.notFound('Пользователь не найден');
    final updated = await context.services.users.updateRole(id, role);
    return jsonOk(updated.toJson());
  });
}
