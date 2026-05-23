// Хелперы для проверки "имеет ли пользователь право на этот объект".
// Вынесено отдельно чтобы не дублировать в каждом роуте преподавателя.

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

/// Проверяет, что текущий юзер - админ ИЛИ преподаватель указанного предмета.
Future<void> ensureCanManageSubject(
  RequestContext context,
  String subjectId,
) async {
  final user = context.currentUser;
  if (user.role == UserRole.admin) return;
  if (user.role != UserRole.teacher) {
    throw ApiError.forbidden();
  }
  final subj = await context.services.subjects.findById(subjectId);
  if (subj == null) throw ApiError.notFound('Предмет не найден');
  if (subj.teacherId != user.id) {
    throw ApiError.forbidden('Этот предмет принадлежит другому преподавателю');
  }
}

Future<String> subjectIdOfTheme(
  RequestContext context,
  String themeId,
) async {
  final th = await context.services.themes.findById(themeId);
  if (th == null) throw ApiError.notFound('Тема не найдена');
  return th.subjectId;
}

Future<({String themeId, String subjectId})> ownerOfSubtheme(
  RequestContext context,
  String subthemeId,
) async {
  final owner = await context.services.subthemes.ownerOf(subthemeId);
  if (owner == null) throw ApiError.notFound('Подтема не найдена');
  return owner;
}
