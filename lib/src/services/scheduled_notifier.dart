// Фоновый «шедулер»: раз в минуту проверяет, не наступило ли время выхода
// у запланированных подтем и тем. Если да — рассылает уведомления
// преподу и студентам, а потом ставит scheduled_notified = TRUE, чтобы
// не уведомить дважды.
//
// Полноценный cron-сервис делать не стали — для проекта такого масштаба
// одного Timer.periodic внутри процесса сервера достаточно.

import 'dart:async';
import 'dart:io';

import '../db/connection.dart';
import '../repositories/notification_repository.dart';
import '../repositories/subject_repository.dart';

class ScheduledNotifier {
  ScheduledNotifier({
    required Database db,
    required NotificationRepository notifications,
    required SubjectRepository subjects,
    this.interval = const Duration(minutes: 1),
  })  : _db = db,
        _notifications = notifications,
        _subjects = subjects;

  final Database _db;
  final NotificationRepository _notifications;
  final SubjectRepository _subjects;
  final Duration interval;

  Timer? _timer;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => _tick());
    // Первый прогон — сразу, чтобы при запуске сервера сработало
    // уведомление о просроченных запланированных событиях.
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      await _processSubthemes();
      await _processThemes();
    } catch (e, st) {
      stderr.writeln('ScheduledNotifier tick failed: $e\n$st');
    }
  }

  Future<void> _processSubthemes() async {
    final res = await _db.execute(
      "SELECT s.id, s.title, t.subject_id "
      "FROM subthemes s "
      "JOIN themes t ON t.id = s.theme_id "
      "WHERE s.visibility = 'scheduled' "
      "  AND s.scheduled_at IS NOT NULL "
      "  AND s.scheduled_at <= NOW() "
      "  AND s.scheduled_notified = FALSE",
    );
    for (final row in res) {
      final subthemeId = row[0].toString();
      final title = row[1] as String;
      final subjectId = row[2].toString();
      await _notifyAbout(
        kind: 'subtheme',
        contentId: subthemeId,
        subjectId: subjectId,
        title: title,
      );
      // Переводим запись из 'scheduled' в 'published' — чтобы и в UI препода,
      // и в /listByTheme статус отображался корректно, а не висел «По расписанию».
      await _db.execute(
        "UPDATE subthemes "
        "SET visibility = 'published', "
        "    scheduled_notified = TRUE, "
        "    updated_at = NOW() "
        "WHERE id = @i",
        parameters: {'i': subthemeId},
      );
    }
  }

  Future<void> _processThemes() async {
    final res = await _db.execute(
      "SELECT id, title, subject_id "
      "FROM themes "
      "WHERE visibility = 'scheduled' "
      "  AND scheduled_at IS NOT NULL "
      "  AND scheduled_at <= NOW() "
      "  AND scheduled_notified = FALSE",
    );
    for (final row in res) {
      final themeId = row[0].toString();
      final title = row[1] as String;
      final subjectId = row[2].toString();
      await _notifyAbout(
        kind: 'theme',
        contentId: themeId,
        subjectId: subjectId,
        title: title,
      );
      await _db.execute(
        "UPDATE themes "
        "SET visibility = 'published', "
        "    scheduled_notified = TRUE, "
        "    updated_at = NOW() "
        "WHERE id = @i",
        parameters: {'i': themeId},
      );
    }
  }

  Future<void> _notifyAbout({
    required String kind, // 'theme' | 'subtheme'
    required String contentId,
    required String subjectId,
    required String title,
  }) async {
    final subject = await _subjects.findById(subjectId);
    if (subject == null) return;

    final humanKind = kind == 'theme' ? 'тема' : 'лекция';
    final data = <String, dynamic>{
      'subjectId': subjectId,
      if (kind == 'theme') 'themeId': contentId,
      if (kind == 'subtheme') 'subthemeId': contentId,
    };

    // Преподавателю — отдельное уведомление о выходе своего материала.
    if (subject.teacherId != null) {
      await _notifications.create(
        userId: subject.teacherId!,
        type: 'scheduled_published',
        title: 'Запланированный материал опубликован',
        body: 'Вышла $humanKind «$title» по предмету «${subject.name}».',
        data: data,
      );
    }

    // Всем студентам предмета — то же, что мы уже шлём при ручной публикации.
    final students = await _subjects.listStudents(subjectId);
    if (students.isNotEmpty) {
      await _notifications.createBulk(
        userIds: students.map((m) => m['id'] as String).toList(),
        type: kind == 'theme' ? 'new_theme' : 'new_subtheme',
        title: kind == 'theme' ? 'Новая тема' : 'Новая лекция',
        body: 'Преподаватель опубликовал ${humanKind == 'тема' ? 'тему' : 'лекцию'} «$title».',
        data: data,
      );
    }
  }
}
