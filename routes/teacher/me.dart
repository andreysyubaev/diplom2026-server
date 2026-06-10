// PATCH /teacher/me — оставлен ради совместимости со старым клиентом,
// но теперь возвращает 403: должность преподавателю назначает только
// администратор, а сам преподаватель её менять не может.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.patch) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    throw ApiError.forbidden(
      'Должность преподавателю назначает администратор.',
    );
  });
}
