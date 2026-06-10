import 'dart:convert';

import 'theme.dart';

class SubthemeImage {
  SubthemeImage({
    required this.id,
    required this.filePath,
    this.caption,
    required this.sortOrder,
  });

  final String id;
  final String filePath;
  final String? caption;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': '/uploads/$filePath',
        'caption': caption,
        'sortOrder': sortOrder,
      };
}

/// Вложенный к под-теме файл (PDF, Word, Excel и т.п.).
class SubthemeAttachment {
  SubthemeAttachment({
    required this.id,
    required this.filePath,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sortOrder,
  });

  final String id;
  final String filePath;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': '/uploads/$filePath',
        'name': originalName,
        'mime': mimeType,
        'size': sizeBytes,
        'sortOrder': sortOrder,
      };
}

class Subtheme {
  Subtheme({
    required this.id,
    required this.themeId,
    required this.title,
    required this.content,
    required this.contentBlocks,
    required this.sortOrder,
    required this.visibility,
    this.scheduledAt,
    required this.hasTest,
    this.images = const [],
    this.attachments = const [],
    required this.createdAt,
  });

  final String id;
  final String themeId;
  final String title;

  /// Старое одно-полевое содержимое. Оставлено для обратной совместимости —
  /// новый редактор пишет блоки в [contentBlocks].
  final String content;

  /// Блоки лекции в порядке отображения.
  /// Каждый элемент — Map с полем `type` ('text' или 'image') и
  /// специфичными для типа полями. См. _normalizeBlocks().
  final List<Map<String, dynamic>> contentBlocks;

  final int sortOrder;
  final ContentVisibility visibility;
  final DateTime? scheduledAt;
  final bool hasTest;
  final List<SubthemeImage> images;
  final List<SubthemeAttachment> attachments;
  final DateTime createdAt;

  bool get isUnlockedNow {
    switch (visibility) {
      case ContentVisibility.published:
        return true;
      case ContentVisibility.scheduled:
        return scheduledAt != null &&
            DateTime.now().toUtc().isAfter(scheduledAt!.toUtc());
      case ContentVisibility.draft:
      case ContentVisibility.visibleLocked:
        return false;
    }
  }

  bool get isVisibleToStudent => visibility != ContentVisibility.draft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'themeId': themeId,
        'title': title,
        'content': content,
        'contentBlocks': contentBlocks,
        'sortOrder': sortOrder,
        'visibility': visibility.toSql(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'hasTest': hasTest,
        'isUnlocked': isUnlockedNow,
        'images': images.map((i) => i.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  /// Краткая версия — без конспекта и картинок (для списков).
  Map<String, dynamic> toShortJson() => {
        'id': id,
        'themeId': themeId,
        'title': title,
        'sortOrder': sortOrder,
        'visibility': visibility.toSql(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'hasTest': hasTest,
        'isUnlocked': isUnlockedNow,
      };

  factory Subtheme.fromRow(
    Map<String, dynamic> row, {
    bool hasTest = false,
    List<SubthemeImage> images = const [],
    List<SubthemeAttachment> attachments = const [],
  }) =>
      Subtheme(
        id: row['id'].toString(),
        themeId: row['theme_id'].toString(),
        title: row['title'] as String,
        content: (row['content'] as String?) ?? '',
        contentBlocks: _parseBlocks(row['content_blocks']),
        sortOrder: row['sort_order'] as int,
        visibility: ContentVisibility.parse(row['visibility'] as String),
        scheduledAt: row['scheduled_at'] as DateTime?,
        hasTest: hasTest,
        images: images,
        attachments: attachments,
        createdAt: row['created_at'] as DateTime,
      );

  /// postgres 3.x возвращает JSONB либо уже разобранным (List/Map),
  /// либо строкой — нормализуем оба случая.
  static List<Map<String, dynamic>> _parseBlocks(Object? raw) {
    if (raw == null) return const [];
    final dynamic decoded;
    if (raw is String) {
      if (raw.isEmpty) return const [];
      decoded = jsonDecode(raw);
    } else {
      decoded = raw;
    }
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();
  }
}

/// Валидирует и нормализует список блоков, пришедший от клиента.
/// Отбрасывает блоки с неизвестным type и пустые text-блоки без текста.
List<Map<String, dynamic>> normalizeContentBlocks(Object? raw) {
  if (raw is! List) return const [];
  final result = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final type = item['type'];
    if (type == 'text') {
      final text = (item['text'] as String?) ?? '';
      result.add({'type': 'text', 'text': text});
    } else if (type == 'image') {
      final url = (item['url'] as String?) ?? '';
      if (url.isEmpty) continue;
      final caption = item['caption'] as String?;
      result.add({
        'type': 'image',
        'url': url,
        if (caption != null) 'caption': caption,
      });
    }
  }
  return result;
}
