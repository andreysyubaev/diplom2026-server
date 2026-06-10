// POST /me/notifications/read_all — отметить все мои уведомления прочитанными.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await context.services.notifications.markAllRead(context.currentUser.id);
    return noContent();
  });
}
