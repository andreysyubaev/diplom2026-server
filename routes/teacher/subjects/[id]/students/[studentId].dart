// DELETE /teacher/subjects/<id>/students/<studentId> — отчислить студента.
// Удаляет из subject_students. Результаты тестов остаются в БД.
// Студенту прилетает уведомление «отчислен», чтобы клиент мог
// освежить кеш списка предметов.

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
  String studentId,
) async {
  if (context.request.method != HttpMethod.delete) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    await ensureCanManageSubject(context, id);
    final subject = await context.services.subjects.findById(id);
    await context.services.subjects.removeStudent(id, studentId);
    if (subject != null) {
      await context.services.notifications.create(
        userId: studentId,
        type: 'kicked',
        title: 'Вы отчислены из предмета',
        body: 'Преподаватель удалил вас из «${subject.name}». '
            'Если это ошибка — попросите новый код входа.',
        data: {'subjectId': id},
      );
    }
    return noContent();
  });
}
