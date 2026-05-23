enum ContentVisibility {
  draft,
  published,
  visibleLocked,
  scheduled;

  static const _toSql = {
    ContentVisibility.draft: 'draft',
    ContentVisibility.published: 'published',
    ContentVisibility.visibleLocked: 'visible_locked',
    ContentVisibility.scheduled: 'scheduled',
  };
  static const _fromSql = {
    'draft': ContentVisibility.draft,
    'published': ContentVisibility.published,
    'visible_locked': ContentVisibility.visibleLocked,
    'scheduled': ContentVisibility.scheduled,
  };

  String toSql() => _toSql[this]!;
  static ContentVisibility parse(String v) => _fromSql[v]!;
}

class Theme {
  Theme({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.sortOrder,
    required this.visibility,
    this.scheduledAt,
    required this.createdAt,
  });

  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final int sortOrder;
  final ContentVisibility visibility;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  /// Если visibility=scheduled и время ещё не наступило — фактически студенту недоступно.
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

  /// Видит ли студент сам факт существования темы.
  bool get isVisibleToStudent =>
      visibility != ContentVisibility.draft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'sortOrder': sortOrder,
        'visibility': visibility.toSql(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'isUnlocked': isUnlockedNow,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Theme.fromRow(Map<String, dynamic> row) => Theme(
        id: row['id'].toString(),
        subjectId: row['subject_id'].toString(),
        title: row['title'] as String,
        description: row['description'] as String?,
        sortOrder: row['sort_order'] as int,
        visibility: ContentVisibility.parse(row['visibility'] as String),
        scheduledAt: row['scheduled_at'] as DateTime?,
        createdAt: row['created_at'] as DateTime,
      );
}
