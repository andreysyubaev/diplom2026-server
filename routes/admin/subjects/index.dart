// GET  /admin/subjects        — список всех предметов
// POST /admin/subjects        — создать предмет
//
// Тело POST: { "name": "Математика", "description": "...", "teacherId": "<uuid>" }

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
    final list = await context.services.subjects.listAll();
    return jsonOk({'items': list.map((s) => s.toJson()).toList()});
  });
}

Future<Response> _create(RequestContext context) async {
  return runSafely(() async {
    final body = await readJson(context.request);
    final name = body.reqString('name');
    final teacherId = body.optString('teacherId');
    if (teacherId != null) {
      final t = await context.services.users.findById(teacherId);
      if (t == null) throw ApiError.notFound('Преподаватель не найден');
      if (t.role != UserRole.teacher) {
        throw ApiError.badRequest('Указанный пользователь не преподаватель');
      }
    }
    final subj = await context.services.subjects.create(
      name: name,
      description: body.optString('description'),
      teacherId: teacherId,
      createdBy: context.currentUser.id,
    );
    return jsonOk(subj.toJson(), status: 201);
  });
}
