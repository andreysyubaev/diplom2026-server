// POST /student/join — войти в предмет по коду.
// Тело: { "code": "ABC123" }
// Ответ: данные предмета (после успеха студент попадает в subject_students).

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return errorResponse(ApiError(405, 'Метод не поддерживается'));
  }
  return runSafely(() async {
    final body = await readJson(context.request);
    final code = body.reqString('code');
    final subjectId = await context.services.codes.resolveSubjectId(code);
    final subj = await context.services.subjects.findById(subjectId);
    if (subj == null) throw ApiError.notFound('Предмет не найден');
    // Дважды по коду в один и тот же предмет — не уведомляем повторно.
    final wasJoined = await context.services.subjects
        .isStudentJoined(subjectId, context.currentUser.id);
    await context.services.subjects.addStudent(subjectId, context.currentUser.id);
    if (!wasJoined && subj.teacherId != null) {
      await context.services.notifications.create(
        userId: subj.teacherId!,
        type: 'student_joined',
        title: 'Новый студент в предмете',
        body: '${context.currentUser.fullName} присоединился к «${subj.name}».',
        data: {'subjectId': subjectId, 'studentId': context.currentUser.id},
      );
    }
    return jsonOk(subj.toJson());
  });
}
