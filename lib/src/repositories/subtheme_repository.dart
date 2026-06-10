// CRUD по таблицам subthemes и subtheme_images.

import 'dart:convert';

import '../db/connection.dart';
import '../models/subtheme.dart';
import '../models/theme.dart';

class SubthemeRepository {
  SubthemeRepository(this._db);
  final Database _db;

  /// Базовый список колонок для SELECT — чтобы не забыть content_blocks.
  static const _cols =
      'id, theme_id, title, content, content_blocks, sort_order, visibility, scheduled_at, created_at';

  Future<Subtheme?> findById(String id, {bool withDetails = true}) async {
    final res = await _db.execute(
      'SELECT $_cols FROM subthemes WHERE id = @i',
      parameters: {'i': id},
    );
    if (res.isEmpty) return null;
    final row = _namedRow(res.first, res.schema.columns);
    if (!withDetails) return Subtheme.fromRow(row);
    final hasTest = await _hasTest(id);
    final imgs = await listImages(id);
    final atts = await listAttachments(id);
    return Subtheme.fromRow(
      row,
      hasTest: hasTest,
      images: imgs,
      attachments: atts,
    );
  }

  Future<bool> _hasTest(String subthemeId) async {
    final res = await _db.execute(
      'SELECT 1 FROM tests WHERE subtheme_id = @s LIMIT 1',
      parameters: {'s': subthemeId},
    );
    return res.isNotEmpty;
  }

  Future<List<Subtheme>> listByTheme(String themeId) async {
    final res = await _db.execute(
      'SELECT s.id, s.theme_id, s.title, s.content, s.content_blocks, s.sort_order, '
      's.visibility, s.scheduled_at, s.created_at, '
      'EXISTS (SELECT 1 FROM tests t WHERE t.subtheme_id = s.id) AS has_test '
      'FROM subthemes s WHERE s.theme_id = @t '
      'ORDER BY s.sort_order, s.created_at',
      parameters: {'t': themeId},
    );
    return res.map((r) {
      final m = _namedRow(r, res.schema.columns);
      return Subtheme.fromRow(m, hasTest: m['has_test'] as bool? ?? false);
    }).toList();
  }

  Future<Subtheme> create({
    required String themeId,
    required String title,
    String content = '',
    List<Map<String, dynamic>>? contentBlocks,
    int sortOrder = 0,
    ContentVisibility visibility = ContentVisibility.draft,
    DateTime? scheduledAt,
  }) async {
    final res = await _db.execute(
      'INSERT INTO subthemes (theme_id, title, content, content_blocks, sort_order, visibility, scheduled_at) '
      'VALUES (@t,@ti,@c,@cb::jsonb,@o,@v,@sa) '
      'RETURNING $_cols',
      parameters: {
        't': themeId,
        'ti': title,
        'c': content,
        'cb': jsonEncode(contentBlocks ?? const []),
        'o': sortOrder,
        'v': visibility.toSql(),
        'sa': scheduledAt,
      },
    );
    return Subtheme.fromRow(_namedRow(res.first, res.schema.columns));
  }

  Future<Subtheme> update({
    required String id,
    String? title,
    String? content,
    List<Map<String, dynamic>>? contentBlocks,
    int? sortOrder,
    ContentVisibility? visibility,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
  }) async {
    final sets = <String>[];
    final params = <String, Object?>{'i': id};
    if (title != null) {
      sets.add('title = @ti');
      params['ti'] = title;
    }
    if (content != null) {
      sets.add('content = @c');
      params['c'] = content;
    }
    if (contentBlocks != null) {
      sets.add('content_blocks = @cb::jsonb');
      params['cb'] = jsonEncode(contentBlocks);
    }
    if (sortOrder != null) {
      sets.add('sort_order = @o');
      params['o'] = sortOrder;
    }
    if (visibility != null) {
      sets.add('visibility = @v');
      params['v'] = visibility.toSql();
    }
    if (clearScheduledAt) {
      sets.add('scheduled_at = NULL');
    } else if (scheduledAt != null) {
      sets.add('scheduled_at = @sa');
      params['sa'] = scheduledAt;
    }
    // Если переводим в scheduled или меняем scheduled_at — сбрасываем
    // флаг «уже уведомили», чтобы шедулер ещё раз сработал.
    if (visibility == ContentVisibility.scheduled || scheduledAt != null) {
      sets.add('scheduled_notified = FALSE');
    }
    if (sets.isNotEmpty) {
      sets.add('updated_at = NOW()');
      await _db.execute(
        'UPDATE subthemes SET ${sets.join(', ')} WHERE id = @i',
        parameters: params,
      );
    }
    return (await findById(id))!;
  }

  Future<void> delete(String id) async {
    await _db.execute(
      'DELETE FROM subthemes WHERE id = @i',
      parameters: {'i': id},
    );
  }

  // ── картинки ──────────────────────────────────────────────────────

  Future<List<SubthemeImage>> listImages(String subthemeId) async {
    final res = await _db.execute(
      'SELECT id, file_path, caption, sort_order FROM subtheme_images '
      'WHERE subtheme_id = @s ORDER BY sort_order, created_at',
      parameters: {'s': subthemeId},
    );
    return res
        .map((r) => SubthemeImage(
              id: r[0].toString(),
              filePath: r[1]! as String,
              caption: r[2] as String?,
              sortOrder: r[3]! as int,
            ))
        .toList();
  }

  Future<SubthemeImage> addImage({
    required String subthemeId,
    required String filePath,
    String? caption,
    int sortOrder = 0,
  }) async {
    final res = await _db.execute(
      'INSERT INTO subtheme_images (subtheme_id, file_path, caption, sort_order) '
      'VALUES (@s,@f,@c,@o) RETURNING id, file_path, caption, sort_order',
      parameters: {'s': subthemeId, 'f': filePath, 'c': caption, 'o': sortOrder},
    );
    final r = res.first;
    return SubthemeImage(
      id: r[0].toString(),
      filePath: r[1]! as String,
      caption: r[2] as String?,
      sortOrder: r[3]! as int,
    );
  }

  Future<String?> removeImage(String imageId) async {
    final res = await _db.execute(
      'DELETE FROM subtheme_images WHERE id = @i RETURNING file_path',
      parameters: {'i': imageId},
    );
    if (res.isEmpty) return null;
    return res.first[0] as String?;
  }

  // ── вложенные файлы ───────────────────────────────────────────────

  Future<List<SubthemeAttachment>> listAttachments(String subthemeId) async {
    final res = await _db.execute(
      'SELECT id, file_path, original_name, mime_type, size_bytes, sort_order '
      'FROM subtheme_attachments WHERE subtheme_id = @s '
      'ORDER BY sort_order, created_at',
      parameters: {'s': subthemeId},
    );
    return res
        .map((r) => SubthemeAttachment(
              id: r[0].toString(),
              filePath: r[1]! as String,
              originalName: r[2]! as String,
              mimeType: r[3]! as String,
              sizeBytes: (r[4]! as num).toInt(),
              sortOrder: r[5]! as int,
            ))
        .toList();
  }

  Future<SubthemeAttachment> addAttachment({
    required String subthemeId,
    required String filePath,
    required String originalName,
    required String mimeType,
    required int sizeBytes,
    int sortOrder = 0,
  }) async {
    final res = await _db.execute(
      'INSERT INTO subtheme_attachments '
      '(subtheme_id, file_path, original_name, mime_type, size_bytes, sort_order) '
      'VALUES (@s,@f,@n,@m,@b,@o) '
      'RETURNING id, file_path, original_name, mime_type, size_bytes, sort_order',
      parameters: {
        's': subthemeId,
        'f': filePath,
        'n': originalName,
        'm': mimeType,
        'b': sizeBytes,
        'o': sortOrder,
      },
    );
    final r = res.first;
    return SubthemeAttachment(
      id: r[0].toString(),
      filePath: r[1]! as String,
      originalName: r[2]! as String,
      mimeType: r[3]! as String,
      sizeBytes: (r[4]! as num).toInt(),
      sortOrder: r[5]! as int,
    );
  }

  Future<String?> removeAttachment(String attachmentId) async {
    final res = await _db.execute(
      'DELETE FROM subtheme_attachments WHERE id = @i RETURNING file_path',
      parameters: {'i': attachmentId},
    );
    if (res.isEmpty) return null;
    return res.first[0] as String?;
  }

  /// Возвращает теме предмет, к которому относится подтема — нужно для проверки прав.
  Future<({String themeId, String subjectId})?> ownerOf(String subthemeId) async {
    final res = await _db.execute(
      'SELECT s.theme_id, t.subject_id FROM subthemes s '
      'JOIN themes t ON t.id = s.theme_id WHERE s.id = @i',
      parameters: {'i': subthemeId},
    );
    if (res.isEmpty) return null;
    return (themeId: res.first[0].toString(), subjectId: res.first[1].toString());
  }

  static Map<String, dynamic> _namedRow(
    List<dynamic> row,
    List<dynamic> columns,
  ) {
    final map = <String, dynamic>{};
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i] as dynamic;
      map[col.columnName as String] = row[i];
    }
    return map;
  }
}
