// GET /student/themes/<id>/subthemes — список подтем темы для студента.

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
    final theme = await context.services.themes.findById(id);
    if (theme == null || !theme.isVisibleToStudent) {
      throw ApiError.notFound('Тема не найдена');
    }
    await ensureStudentJoined(context, theme.subjectId);
    if (!theme.isUnlockedNow) {
      throw ApiError.forbidden('Тема пока недоступна');
    }
    final subs = await context.services.subthemes.listByTheme(id);
    final visible = subs.where((s) => s.isVisibleToStudent).toList();
    return jsonOk({'items': visible.map((s) => s.toShortJson()).toList()});
  });
}
