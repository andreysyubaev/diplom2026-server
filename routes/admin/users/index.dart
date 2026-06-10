// GET  /admin/users               — список пользователей (?role=teacher&search=...)
// POST /admin/users               — создать преподавателя
//
// Тело POST:
//   { "email": "...", "password": "...", "fullName": "...",
//     "positionIds": ["<uuid>", "<uuid>"] }   // positionIds опционален

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context);
    case HttpMethod.post:
      return _create(context);
    default:
      return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
}

Future<Response> _list(RequestContext context) async {
  return runSafely(() async {
    final q = context.request.uri.queryParameters;
    UserRole? role;
    if (q['role'] != null) {
      try {
        role = UserRole.parse(q['role']!);
      } catch (_) {
        throw ApiError.badRequest('Некорректная роль');
      }
    }
    final list = await context.services.users.list(
      role: role,
      search: q['search'],
    );
    return jsonOk({'items': list.map((u) => u.toJson()).toList()});
  });
}

Future<Response> _create(RequestContext context) async {
  return runSafely(() async {
    final body = await readJson(context.request);
    final raw = body['positionIds'];
    final positionIds = raw is List
        ? raw.whereType<String>().toList()
        : <String>[];
    for (final pid in positionIds.toSet()) {
      final p = await context.services.positions.findById(pid);
      if (p == null) {
        throw ApiError.notFound('Должность $pid не найдена');
      }
    }
    final user = await context.services.auth.createTeacher(
      email: body.reqString('email'),
      password: body.reqString('password'),
      fullName: body.reqString('fullName'),
      positionIds: positionIds,
    );
    return jsonOk(user.toJson(), status: 201);
  });
}
