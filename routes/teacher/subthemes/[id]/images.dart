// POST   /teacher/subthemes/<id>/images   — добавить картинку (multipart/form-data, поле "file")
// DELETE /teacher/subthemes/<id>/images?imageId=<uuid>
//
// Для simple JSON-загрузки тоже принимаем base64:
// POST application/json: { "base64": "...", "filename": "...", "caption": "..." }

import 'dart:convert';
import 'dart:typed_data';

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return runSafely(() async {
    final owner = await ownerOfSubtheme(context, id);
    await ensureCanManageSubject(context, owner.subjectId);

    switch (context.request.method) {
      case HttpMethod.post:
        return _add(context, id);
      case HttpMethod.delete:
        return _delete(context, id);
      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}

Future<Response> _add(RequestContext context, String subthemeId) async {
  final contentType =
      context.request.headers['content-type']?.toLowerCase() ?? '';
  Uint8List bytes;
  String? filename;
  String? caption;

  if (contentType.startsWith('application/json')) {
    final body = await readJson(context.request);
    final b64 = body.reqString('base64');
    bytes = base64Decode(b64);
    filename = body.optString('filename');
    caption = body.optString('caption');
  } else {
    // ожидаем multipart/form-data
    final formData = await context.request.formData();
    final file = formData.files['file'];
    if (file == null) throw ApiError.badRequest('Поле "file" обязательно');
    bytes = Uint8List.fromList(await file.readAsBytes());
    filename = file.name;
    caption = formData.fields['caption'];
  }

  final path = await context.services.uploads
      .saveBytes(bytes, originalFilename: filename);
  final img = await context.services.subthemes.addImage(
    subthemeId: subthemeId,
    filePath: path,
    caption: caption,
  );
  return jsonOk(img.toJson(), status: 201);
}

Future<Response> _delete(RequestContext context, String subthemeId) async {
  final imageId = context.request.uri.queryParameters['imageId'];
  if (imageId == null || imageId.isEmpty) {
    throw ApiError.badRequest('Нужен query-параметр imageId');
  }
  final removedPath = await context.services.subthemes.removeImage(imageId);
  if (removedPath != null) {
    await context.services.uploads.delete(removedPath);
  }
  return noContent();
}
