// POST /auth/change-password
// Заголовок: Authorization: Bearer <accessToken>
// Тело:      { "currentPassword": "...", "newPassword": "..." }

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final user = context.currentUser;
    final body = await readJson(context.request);
    await context.services.auth.changePassword(
      userId: user.id,
      currentPassword: body.reqString('currentPassword'),
      newPassword: body.reqString('newPassword'),
    );
    return jsonOk({'ok': true});
  });
}
