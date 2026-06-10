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

  // ── Картинки ──────────────────────────────────────────────────
  static const _maxImageBytes = 5 * 1024 * 1024; // 5 MB
  static const _allowedImages = {
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  };

  // ── Документы (вложения к подтеме) ───────────────────────────
  static const _maxDocBytes = 25 * 1024 * 1024; // 25 MB
  static const _allowedDocs = {
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'text/csv',
    'application/rtf',
    'application/zip',
    'application/x-rar-compressed',
    'application/vnd.rar',
    'application/x-7z-compressed',
  };

  /// Сохраняет картинку. Возвращает относительный путь.
  Future<String> saveBytes(Uint8List bytes, {String? originalFilename}) async {
    if (bytes.length > _maxImageBytes) {
      throw ApiError.badRequest(
          'Файл больше ${_maxImageBytes ~/ 1024 ~/ 1024} МБ');
    }
    final mime = lookupMimeType(originalFilename ?? '', headerBytes: bytes);
    if (mime == null || !_allowedImages.contains(mime)) {
      throw ApiError.badRequest(
        'Неподдерживаемый формат файла. Разрешены: jpg, png, gif, webp',
      );
    }
    return _writeFile(bytes, ext: _extForMime(mime));
  }

  /// Сохраняет документ-вложение (PDF, DOC/X, XLS/X, PPT/X, TXT, ZIP, RAR…).
  /// Возвращает относительный путь и определённый MIME-тип.
  Future<({String path, String mime})> saveDocument(
    Uint8List bytes, {
    required String originalFilename,
  }) async {
    if (bytes.length > _maxDocBytes) {
      throw ApiError.badRequest(
          'Файл больше ${_maxDocBytes ~/ 1024 ~/ 1024} МБ');
    }
    var mime = lookupMimeType(originalFilename, headerBytes: bytes);
    // Иногда mime-сниффер для офисных файлов возвращает 'application/zip' —
    // считаем это валидным.
    if (mime == null || !_allowedDocs.contains(mime)) {
      throw ApiError.badRequest(
        'Неподдерживаемый формат. Разрешены: PDF, Word, Excel, PowerPoint, '
        'TXT, CSV, RTF, ZIP, RAR, 7Z',
      );
    }
    // Расширение из имени файла, не из MIME — пользователь скачает с тем же.
    final origExt = _extFromName(originalFilename);
    return (path: await _writeFile(bytes, ext: origExt), mime: mime);
  }

  Future<String> _writeFile(Uint8List bytes, {required String ext}) async {
    final id = const Uuid().v4();
    final relative = '${id.substring(0, 2)}/${id.substring(2, 4)}/$id$ext';
    final absolute = File('$_dir/$relative');
    await absolute.create(recursive: true);
    await absolute.writeAsBytes(bytes, flush: true);
    return relative;
  }

  String _extFromName(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return '';
    return filename.substring(dot).toLowerCase();
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
