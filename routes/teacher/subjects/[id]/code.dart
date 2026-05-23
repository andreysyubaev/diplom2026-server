// GET /teacher/subjects/<id>/code
// Возвращает текущий действующий 5-минутный код входа для предмета.
// Если кода нет или он истёк — генерируется новый.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await ensureCanManageSubject(context, id);
    final code = await context.services.codes.currentForSubject(id);
    return jsonOk(code.toJson());
  });
}
