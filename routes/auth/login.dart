// POST /auth/login
// Тело:  { "email": "...", "password": "..." }
// Ответ: { accessToken, refreshToken, user }

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
    final tokens = await context.services.auth.login(
      email: body.reqString('email'),
      password: body.reqString('password'),
    );
    return jsonOk(tokens.toJson());
  });
}
