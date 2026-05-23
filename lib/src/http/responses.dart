// Хелперы для построения JSON-ответов и обработки ошибок.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../models/api_error.dart';

Response jsonOk(Object? body, {int status = 200}) {
  return Response.json(statusCode: status, body: body);
}

Response noContent() => Response(statusCode: 204);

Response errorResponse(ApiError e) {
  return Response.json(statusCode: e.statusCode, body: e.toJson());
}

/// Оборачивает handler. Перехватывает [ApiError] и неожиданные ошибки,
/// чтобы клиент всегда получал JSON в одном формате.
Future<Response> runSafely(FutureOr<Response> Function() body) async {
  try {
    return await body();
  } on ApiError catch (e) {
    return errorResponse(e);
  } on FormatException catch (e) {
    return errorResponse(ApiError.badRequest('Некорректный JSON: ${e.message}'));
  } catch (e, st) {
    stderr.writeln('❌ Unhandled error: $e\n$st');
    return errorResponse(ApiError.server());
  }
}

Future<Map<String, dynamic>> readJson(Request request) async {
  final body = await request.body();
  if (body.isEmpty) return <String, dynamic>{};
  final dynamic decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw ApiError.badRequest('Ожидался JSON-объект');
  }
  return decoded;
}

extension JsonGetters on Map<String, dynamic> {
  String reqString(String key) {
    final v = this[key];
    if (v is! String || v.trim().isEmpty) {
      throw ApiError.badRequest('Поле "$key" обязательно');
    }
    return v;
  }

  String? optString(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is! String) throw ApiError.badRequest('Поле "$key" должно быть строкой');
    return v;
  }

  int? optInt(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is num) return v.toInt();
    throw ApiError.badRequest('Поле "$key" должно быть числом');
  }

  bool? optBool(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is bool) return v;
    throw ApiError.badRequest('Поле "$key" должно быть true/false');
  }

  DateTime? optDateTime(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is! String) throw ApiError.badRequest('Поле "$key" должно быть ISO-датой');
    final parsed = DateTime.tryParse(v);
    if (parsed == null) throw ApiError.badRequest('Некорректная дата в поле "$key"');
    return parsed;
  }

  List<dynamic> reqList(String key) {
    final v = this[key];
    if (v is! List) throw ApiError.badRequest('Поле "$key" должно быть массивом');
    return v;
  }
}
