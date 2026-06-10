// GET  /admin/positions       — список всех должностей
// POST /admin/positions       — создать новую должность
//   { "name": "Доцент кафедры математики" }

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  return runSafely(() async {
    switch (context.request.method) {
      case HttpMethod.get:
        final list = await context.services.positions.listAll();
        return jsonOk({'items': list.map((p) => p.toJson()).toList()});

      case HttpMethod.post:
        final body = await readJson(context.request);
        final p =
            await context.services.positions.create(body.reqString('name'));
        return jsonOk(p.toJson(), status: 201);

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}
