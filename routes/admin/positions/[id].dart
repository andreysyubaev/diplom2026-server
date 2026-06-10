// DELETE /admin/positions/<id> — удалить должность.
// У всех привязанных преподов position_id автоматически становится NULL
// (ON DELETE SET NULL в миграции).

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await context.services.positions.delete(id);
    return noContent();
  });
}
