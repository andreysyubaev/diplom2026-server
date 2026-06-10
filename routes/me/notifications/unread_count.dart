// GET /me/notifications/unread_count — для бейджа на вкладке.
// Легковесный эндпоинт, не таскает весь список.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final n = await context.services.notifications
        .unreadCount(context.currentUser.id);
    return jsonOk({'unreadCount': n});
  });
}
