// POST /auth/refresh
// Тело:  { "refreshToken": "..." }
// Ответ: новая пара токенов (старый refresh инвалидируется).

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final body = await readJson(context.request);
    final tokens = await context.services.auth.refresh(body.reqString('refreshToken'));
    return jsonOk(tokens.toJson());
  });
}
