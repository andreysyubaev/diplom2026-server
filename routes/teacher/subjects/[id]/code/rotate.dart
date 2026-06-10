// POST /teacher/subjects/<id>/code/rotate — принудительно сменить код входа.
// Все ранее выданные коды этого предмета становятся недействительными.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await ensureCanManageSubject(context, id);
    final code = await context.services.codes.rotate(id);
    return jsonOk(code.toJson());
  });
}
