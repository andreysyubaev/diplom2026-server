// Проверки доступа студента к контенту.

import 'package:dart_frog/dart_frog.dart';

import '../models/api_error.dart';
import 'context.dart';

Future<void> ensureStudentJoined(
  RequestContext context,
  String subjectId,
) async {
  final isJoined = await context.services.subjects
      .isStudentJoined(subjectId, context.currentUser.id);
  if (!isJoined) {
    throw ApiError.forbidden('Вы не присоединены к этому предмету');
  }
}
