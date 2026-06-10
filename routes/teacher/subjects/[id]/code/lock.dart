// PATCH /teacher/subjects/<id>/code/lock — включить или выключить замок.
// Тело: { "locked": true }  или  { "locked": false }
//
// Когда залочено — код не меняется автоматически. Полезно, если препод
// хочет дать студентам один и тот же код заранее.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await ensureCanManageSubject(context, id);
    final body = await readJson(context.request);
    final locked = body.optBool('locked');
    if (locked == null) {
      throw ApiError.badRequest('Поле "locked" обязательно');
    }
    await context.services.codes.setLocked(id, locked);
    final code = await context.services.codes.currentForSubject(id);
    return jsonOk(code.toJson());
  });
}
