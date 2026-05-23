// GET /student/subjects/<id>/themes — список тем предмета для студента.
// Возвращает только темы с visibility != draft.
// Поле isUnlocked говорит, можно ли в неё войти.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/http/student_guard.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await ensureStudentJoined(context, id);
    final themes = await context.services.themes.listBySubject(id);
    final visible = themes.where((t) => t.isVisibleToStudent).toList();
    return jsonOk({'items': visible.map((t) => t.toJson()).toList()});
  });
}
