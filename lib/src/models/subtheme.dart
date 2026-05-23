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

class Subtheme {
  Subtheme({
    required this.id,
    required this.themeId,
    required this.title,
    required this.content,
    required this.sortOrder,
    required this.visibility,
    this.scheduledAt,
    required this.hasTest,
    this.images = const [],
    required this.createdAt,
  });

  final String id;
  final String themeId;
  final String title;
  final String content;
  final int sortOrder;
  final ContentVisibility visibility;
  final DateTime? scheduledAt;
  final bool hasTest;
  final List<SubthemeImage> images;
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
        'sortOrder': sortOrder,
        'visibility': visibility.toSql(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'hasTest': hasTest,
        'isUnlocked': isUnlockedNow,
        'images': images.map((i) => i.toJson()).toList(),
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
  }) =>
      Subtheme(
        id: row['id'].toString(),
        themeId: row['theme_id'].toString(),
        title: row['title'] as String,
        content: (row['content'] as String?) ?? '',
        sortOrder: row['sort_order'] as int,
        visibility: ContentVisibility.parse(row['visibility'] as String),
        scheduledAt: row['scheduled_at'] as DateTime?,
        hasTest: hasTest,
        images: images,
        createdAt: row['created_at'] as DateTime,
      );
}
