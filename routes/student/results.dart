// GET /student/results — собственные результаты студента.
// Опциональный query ?subthemeId=...

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final list = await context.services.results.listForStudent(
      studentId: context.currentUser.id,
      subthemeId: context.request.uri.queryParameters['subthemeId'],
    );
    return jsonOk({'items': list.map((r) => r.toJson()).toList()});
  });
}
