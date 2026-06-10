// PATCH /admin/users/<id>/positions — заменить весь набор должностей.
// Тело: { "positionIds": ["<uuid>", "<uuid>", ...] }
// Передать пустой массив — снять все должности.
//
// Назначать должности можно только преподавателю.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final target = await context.services.users.findById(id);
    if (target == null) throw ApiError.notFound('Пользователь не найден');
    if (target.role != UserRole.teacher) {
      throw ApiError.badRequest(
          'Должности можно назначать только преподавателю');
    }

    final body = await readJson(context.request);
    final raw = body['positionIds'];
    if (raw is! List) {
      throw ApiError.badRequest('Поле "positionIds" должно быть массивом');
    }
    final ids = raw.whereType<String>().toList();

    // Проверим, что каждая указанная должность существует.
    for (final pid in ids.toSet()) {
      final p = await context.services.positions.findById(pid);
      if (p == null) {
        throw ApiError.notFound('Должность $pid не найдена');
      }
    }

    final updated = await context.services.users.setPositions(id, ids);
    return jsonOk(updated.toJson());
  });
}
