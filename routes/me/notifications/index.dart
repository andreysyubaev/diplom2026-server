// GET  /me/notifications — список моих уведомлений (последние 100).
// POST /me/notifications/read-all — отметить все прочитанными.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  return runSafely(() async {
    final userId = context.currentUser.id;
    switch (context.request.method) {
      case HttpMethod.get:
        final list = await context.services.notifications.listForUser(userId);
        final unread =
            await context.services.notifications.unreadCount(userId);
        return jsonOk({
          'items': list.map((n) => n.toJson()).toList(),
          'unreadCount': unread,
        });
      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
