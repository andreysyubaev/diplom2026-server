// GET /teacher/subjects — список предметов, привязанных к этому преподавателю.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final list = await context.services.subjects
        .listForTeacher(context.currentUser.id);
    return jsonOk({'items': list.map((s) => s.toJson()).toList()});
  });
}
