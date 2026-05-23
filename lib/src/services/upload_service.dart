// Сохранение картинок к конспектам и тестам на диск.
// Файлы лежат в UPLOADS_DIR. В БД храним только относительный путь.

import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../config/env.dart';
import '../models/api_error.dart';

class UploadService {
  UploadService({String? dir}) : _dir = dir ?? Env.instance.uploadsDir;

  final String _dir;
  static const _maxBytes = 5 * 1024 * 1024; // 5 MB
  static const _allowed = {
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  };

  /// Сохраняет байты в файл. Возвращает относительный путь (например, "ab/cd/uuid.jpg").
  Future<String> saveBytes(Uint8List bytes, {String? originalFilename}) async {
    if (bytes.length > _maxBytes) {
      throw ApiError.badRequest('Файл больше ${_maxBytes ~/ 1024 ~/ 1024} МБ');
    }
    final mime = lookupMimeType(originalFilename ?? '', headerBytes: bytes);
    if (mime == null || !_allowed.contains(mime)) {
      throw ApiError.badRequest(
        'Неподдерживаемый формат файла. Разрешены: jpg, png, gif, webp',
      );
    }

    final ext = _extForMime(mime);
    final id = const Uuid().v4();
    final relative = '${id.substring(0, 2)}/${id.substring(2, 4)}/$id$ext';
    final absolute = File('$_dir/$relative');
    await absolute.create(recursive: true);
    await absolute.writeAsBytes(bytes, flush: true);
    return relative;
  }

  /// Полный путь на диске по относительному.
  File resolve(String relativePath) {
    if (relativePath.contains('..')) {
      throw ApiError.badRequest('Некорректный путь');
    }
    return File('$_dir/$relativePath');
  }

  Future<void> delete(String relativePath) async {
    final f = resolve(relativePath);
    if (await f.exists()) await f.delete();
  }

  String _extForMime(String mime) {
    switch (mime) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      default:
        return '';
    }
  }
}
