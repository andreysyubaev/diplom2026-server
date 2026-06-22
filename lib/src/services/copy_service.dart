// Сервис копирования тем и подтем вместе со всем вложенным контентом
// (лекция, картинки, вложения, тест).
//
// Алгоритм:
//  1. Загрузить исходный объект.
//  2. Скопировать бинарные файлы через UploadService.copyFile().
//  3. Построить карту старых путей → новых путей.
//  4. Переписать URL в content_blocks.
//  5. Создать новую запись в БД.
//  6. Повторить для вложений, картинок и теста.
//  7. При копировании темы — пройтись по всем подтемам рекурсивно.

import '../models/theme.dart';
import '../repositories/subject_repository.dart';
import '../repositories/subtheme_repository.dart';
import '../repositories/test_repository.dart';
import '../repositories/theme_repository.dart';
import 'upload_service.dart';

class CopyService {
  CopyService({
    required ThemeRepository themes,
    required SubthemeRepository subthemes,
    required TestRepository tests,
    required SubjectRepository subjects,
    required UploadService uploads,
  })  : _themes = themes,
        _subthemes = subthemes,
        _tests = tests,
        _subjects = subjects,
        _uploads = uploads;

  final ThemeRepository _themes;
  final SubthemeRepository _subthemes;
  final TestRepository _tests;
  final SubjectRepository _subjects;
  final UploadService _uploads;

  // ─────────────────────────────────────────────────────────────────────────
  // Публичные методы
  // ─────────────────────────────────────────────────────────────────────────

  /// Копирует подтему [subthemeId] в тему [targetThemeId].
  /// Возвращает id новой подтемы.
  Future<String> copySubtheme(String subthemeId, String targetThemeId) async {
    final src = await _subthemes.findById(subthemeId, withDetails: true);
    if (src == null) throw StateError('Подтема не найдена: $subthemeId');

    // Определяем уникальное название.
    final siblings = await _subthemes.listByTheme(targetThemeId);
    final siblingTitles = siblings.map((s) => s.title).toList();
    final newTitle = _suffixedName(src.title, siblingTitles);

    // Копируем картинки подтемы и строим карту путей.
    final pathMap = <String, String>{}; // oldRelativePath → newRelativePath

    for (final img in src.images) {
      final newPath = await _uploads.copyFile(img.filePath);
      pathMap[img.filePath] = newPath;
    }
    for (final att in src.attachments) {
      final newPath = await _uploads.copyFile(att.filePath);
      pathMap[att.filePath] = newPath;
    }

    // Переписываем URL в content_blocks.
    final newBlocks = _remapBlocks(src.contentBlocks, pathMap);

    // Создаём новую подтему.
    final newSub = await _subthemes.create(
      themeId: targetThemeId,
      title: newTitle,
      content: src.content,
      contentBlocks: newBlocks,
      sortOrder: src.sortOrder,
      visibility: ContentVisibility.draft,
    );

    // Переносим картинки (записи в subtheme_images).
    for (final img in src.images) {
      await _subthemes.addImage(
        subthemeId: newSub.id,
        filePath: pathMap[img.filePath]!,
        caption: img.caption,
        sortOrder: img.sortOrder,
      );
    }

    // Переносим вложения.
    for (final att in src.attachments) {
      await _subthemes.addAttachment(
        subthemeId: newSub.id,
        filePath: pathMap[att.filePath]!,
        originalName: att.originalName,
        mimeType: att.mimeType,
        sizeBytes: att.sizeBytes,
        sortOrder: att.sortOrder,
      );
    }

    // Копируем тест (если есть).
    await _copyTestIfExists(subthemeId, newSub.id, pathMap);

    return newSub.id;
  }

  /// Копирует тему [themeId] вместе со всеми подтемами в предмет [targetSubjectId].
  /// Возвращает id новой темы.
  Future<String> copyTheme(String themeId, String targetSubjectId) async {
    final src = await _themes.findById(themeId);
    if (src == null) throw StateError('Тема не найдена: $themeId');

    // Уникальное название.
    final siblings = await _themes.listBySubject(targetSubjectId);
    final siblingTitles = siblings.map((t) => t.title).toList();
    final newTitle = _suffixedName(src.title, siblingTitles);

    // Создаём новую тему.
    final newTheme = await _themes.create(
      subjectId: targetSubjectId,
      title: newTitle,
      description: src.description,
      sortOrder: src.sortOrder,
      visibility: ContentVisibility.draft,
    );

    // Копируем каждую подтему.
    final subthemes = await _subthemes.listByTheme(themeId);
    for (final sub in subthemes) {
      await copySubtheme(sub.id, newTheme.id);
    }

    return newTheme.id;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Вспомогательные методы
  // ─────────────────────────────────────────────────────────────────────────

  /// Генерирует уникальное название с суффиксом «(1)», «(2)» и т.д.
  static String _suffixedName(String base, List<String> existing) {
    if (!existing.contains(base)) return base;
    var i = 1;
    while (existing.contains('$base ($i)')) {
      i++;
    }
    return '$base ($i)';
  }

  /// Переписывает URL картинок в content_blocks по карте путей.
  /// Блоки с типом 'image' имеют поле 'url' вида '/uploads/<relativePath>'.
  List<Map<String, dynamic>> _remapBlocks(
    List<Map<String, dynamic>> blocks,
    Map<String, String> pathMap,
  ) {
    if (pathMap.isEmpty) return blocks;
    return blocks.map((block) {
      if (block['type'] != 'image') return Map<String, dynamic>.from(block);
      final url = block['url'] as String? ?? '';
      // url имеет вид '/uploads/xx/yy/uuid.ext'
      const prefix = '/uploads/';
      if (!url.startsWith(prefix)) return Map<String, dynamic>.from(block);
      final oldRelative = url.substring(prefix.length);
      final newRelative = pathMap[oldRelative];
      if (newRelative == null) return Map<String, dynamic>.from(block);
      return {
        ...block,
        'url': '$prefix$newRelative',
      };
    }).toList();
  }

  /// Копирует тест из [srcSubthemeId] в [dstSubthemeId], также копируя
  /// картинки вопросов через [existingPathMap] (дополняет его новыми записями).
  Future<void> _copyTestIfExists(
    String srcSubthemeId,
    String dstSubthemeId,
    Map<String, String> existingPathMap,
  ) async {
    final test = await _tests.findBySubthemeId(srcSubthemeId);
    if (test == null) return;

    final newQuestions = <Map<String, dynamic>>[];
    for (final q in test.questions) {
      String? newImagePath;
      if (q.imagePath != null && q.imagePath!.isNotEmpty) {
        // imagePath уже является относительным путём (без /uploads/).
        if (existingPathMap.containsKey(q.imagePath)) {
          newImagePath = existingPathMap[q.imagePath];
        } else {
          newImagePath = await _uploads.copyFile(q.imagePath!);
          existingPathMap[q.imagePath!] = newImagePath!;
        }
      }
      newQuestions.add({
        'type': q.type.toSql(),
        'text': q.text,
        'imagePath': newImagePath,
        'sortOrder': q.sortOrder,
        'points': q.points,
        'payload': q.payload,
      });
    }

    await _tests.upsert(
      subthemeId: dstSubthemeId,
      gradeThresholds: test.gradeThresholds,
      shuffleQuestions: test.shuffleQuestions,
      timeLimitMinutes: test.timeLimitMinutes,
      availableFrom: null,  // не переносим расписание — преподаватель выставит сам
      availableTo: null,
      questions: newQuestions,
    );
  }
}
