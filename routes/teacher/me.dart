// PATCH /teacher/me  — преподаватель задаёт/меняет свою должность.
// Тело: { "position": "доцент кафедры математики" }

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.patch) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final body = await readJson(context.request);
    final position = body.optString('position');
    final user =
        await context.services.users.updatePosition(context.currentUser.id, position);
    return jsonOk(user.toJson());
  });
}
