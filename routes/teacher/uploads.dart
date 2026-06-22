// POST /teacher/uploads — загружает произвольный файл (картинку) на сервер
// и возвращает относительный путь, который потом можно сохранить
// в нужном поле (например, в imagePath вопроса теста).
//
// Используется конструктором теста, чтобы прикрепить иллюстрацию к
// конкретному вопросу: фронт сначала шлёт сюда байты файла, получает
// path, и сохраняет его в payload теста при PUT /teacher/subthemes/<id>/test.
//
// Тело (JSON):
//   {
//     "base64":   "...",    // обязательно: содержимое файла в base64
//     "filename": "..."     // опционально: оригинальное имя для расширения
//   }
//
// Ответ:
//   { "path": "ab/cd/uuid.jpg" }

import 'dart:convert';
import 'dart:typed_data';

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  return runSafely(() async {
    // Только преподаватель и админ имеют право грузить файлы.
    final user = context.currentUser;
    if (user.role != UserRole.teacher && user.role != UserRole.admin) {
      throw ApiError.forbidden();
    }

    if (context.request.method != HttpMethod.post) {
      return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }

    final contentType =
        context.request.headers['content-type']?.toLowerCase() ?? '';

    Uint8List bytes;
    String? filename;

    if (contentType.startsWith('application/json')) {
      final body = await readJson(context.request);
      final b64 = body.reqString('base64');
      bytes = base64Decode(b64);
      filename = body.optString('filename');
    } else {
      // multipart/form-data — на случай если фронт отправит как файл
      final form = await context.request.formData();
      final file = form.files['file'];
      if (file == null) throw ApiError.badRequest('Поле "file" обязательно');
      bytes = Uint8List.fromList(await file.readAsBytes());
      filename = file.name;
    }

    final path = await context.services.uploads
        .saveBytes(bytes, originalFilename: filename);

    return jsonOk({'path': path}, status: 201);
  });
}
