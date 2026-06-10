// POST   /teacher/subthemes/<id>/attachments
//   multipart/form-data, поле "file"
//   ИЛИ application/json: { "base64": "...", "filename": "..." }
// DELETE /teacher/subthemes/<id>/attachments?attachmentId=<uuid>

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
  String filename;

  if (contentType.startsWith('application/json')) {
    final body = await readJson(context.request);
    final b64 = body.reqString('base64');
    bytes = base64Decode(b64);
    filename = body.reqString('filename');
  } else {
    final formData = await context.request.formData();
    final file = formData.files['file'];
    if (file == null) throw ApiError.badRequest('Поле "file" обязательно');
    bytes = Uint8List.fromList(await file.readAsBytes());
    filename = file.name;
  }

  final saved = await context.services.uploads
      .saveDocument(bytes, originalFilename: filename);
  final att = await context.services.subthemes.addAttachment(
    subthemeId: subthemeId,
    filePath: saved.path,
    originalName: filename,
    mimeType: saved.mime,
    sizeBytes: bytes.length,
  );
  return jsonOk(att.toJson(), status: 201);
}

Future<Response> _delete(RequestContext context, String subthemeId) async {
  final attId = context.request.uri.queryParameters['attachmentId'];
  if (attId == null || attId.isEmpty) {
    throw ApiError.badRequest('Нужен query-параметр attachmentId');
  }
  final removedPath =
      await context.services.subthemes.removeAttachment(attId);
  if (removedPath != null) {
    await context.services.uploads.delete(removedPath);
  }
  return noContent();
}
