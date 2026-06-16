// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/uploads/[...path].dart' as uploads_$wildcard_path;
import '../routes/teacher/me.dart' as teacher_me;
import '../routes/teacher/themes/[id]/subthemes.dart' as teacher_themes_$id_subthemes;
import '../routes/teacher/themes/[id]/index.dart' as teacher_themes_$id_index;
import '../routes/teacher/subthemes/[id]/test.dart' as teacher_subthemes_$id_test;
import '../routes/teacher/subthemes/[id]/results.dart' as teacher_subthemes_$id_results;
import '../routes/teacher/subthemes/[id]/index.dart' as teacher_subthemes_$id_index;
import '../routes/teacher/subthemes/[id]/images.dart' as teacher_subthemes_$id_images;
import '../routes/teacher/subthemes/[id]/attachments.dart' as teacher_subthemes_$id_attachments;
import '../routes/teacher/subjects/index.dart' as teacher_subjects_index;
import '../routes/teacher/subjects/[id]/themes.dart' as teacher_subjects_$id_themes;
import '../routes/teacher/subjects/[id]/results.dart' as teacher_subjects_$id_results;
import '../routes/teacher/subjects/[id]/students/index.dart' as teacher_subjects_$id_students_index;
import '../routes/teacher/subjects/[id]/students/[studentId].dart' as teacher_subjects_$id_students_$student_id;
import '../routes/teacher/subjects/[id]/code/rotate.dart' as teacher_subjects_$id_code_rotate;
import '../routes/teacher/subjects/[id]/code/lock.dart' as teacher_subjects_$id_code_lock;
import '../routes/teacher/subjects/[id]/code/index.dart' as teacher_subjects_$id_code_index;
import '../routes/teacher/results/[id].dart' as teacher_results_$id;
import '../routes/teacher/results/[id]/retake.dart' as teacher_results_$id_retake;
import '../routes/student/results.dart' as student_results;
import '../routes/student/join.dart' as student_join;
import '../routes/student/themes/[id]/subthemes.dart' as student_themes_$id_subthemes;
import '../routes/student/subthemes/[id]/test.dart' as student_subthemes_$id_test;
import '../routes/student/subthemes/[id]/submit.dart' as student_subthemes_$id_submit;
import '../routes/student/subthemes/[id]/index.dart' as student_subthemes_$id_index;
import '../routes/student/subjects/index.dart' as student_subjects_index;
import '../routes/student/subjects/[id]/themes.dart' as student_subjects_$id_themes;
import '../routes/me/index.dart' as me_index;
import '../routes/me/notifications/unread_count.dart' as me_notifications_unread_count;
import '../routes/me/notifications/read_all.dart' as me_notifications_read_all;
import '../routes/me/notifications/index.dart' as me_notifications_index;
import '../routes/me/notifications/[id]/read.dart' as me_notifications_$id_read;
import '../routes/auth/register.dart' as auth_register;
import '../routes/auth/refresh.dart' as auth_refresh;
import '../routes/auth/login.dart' as auth_login;
import '../routes/auth/change_password.dart' as auth_change_password;
import '../routes/admin/users/index.dart' as admin_users_index;
import '../routes/admin/users/[id]/role.dart' as admin_users_$id_role;
import '../routes/admin/users/[id]/positions.dart' as admin_users_$id_positions;
import '../routes/admin/subjects/index.dart' as admin_subjects_index;
import '../routes/admin/subjects/[id]/index.dart' as admin_subjects_$id_index;
import '../routes/admin/positions/index.dart' as admin_positions_index;
import '../routes/admin/positions/[id].dart' as admin_positions_$id;

import '../routes/_middleware.dart' as middleware;
import '../routes/uploads/_middleware.dart' as uploads_middleware;
import '../routes/teacher/_middleware.dart' as teacher_middleware;
import '../routes/student/_middleware.dart' as student_middleware;
import '../routes/me/_middleware.dart' as me_middleware;
import '../routes/auth/_middleware.dart' as auth_middleware;
import '../routes/admin/_middleware.dart' as admin_middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/uploads', (context) => buildUploadsHandler()(context))
    ..mount('/teacher', (context) => buildTeacherHandler()(context))
    ..mount('/teacher/themes/<id>', (context,id,) => buildTeacherThemes$idHandler(id,)(context))
    ..mount('/teacher/subthemes/<id>', (context,id,) => buildTeacherSubthemes$idHandler(id,)(context))
    ..mount('/teacher/subjects', (context) => buildTeacherSubjectsHandler()(context))
    ..mount('/teacher/subjects/<id>', (context,id,) => buildTeacherSubjects$idHandler(id,)(context))
    ..mount('/teacher/subjects/<id>/students', (context,id,) => buildTeacherSubjects$idStudentsHandler(id,)(context))
    ..mount('/teacher/subjects/<id>/code', (context,id,) => buildTeacherSubjects$idCodeHandler(id,)(context))
    ..mount('/teacher/results', (context) => buildTeacherResultsHandler()(context))
    ..mount('/teacher/results/<id>', (context,id,) => buildTeacherResults$idHandler(id,)(context))
    ..mount('/student', (context) => buildStudentHandler()(context))
    ..mount('/student/themes/<id>', (context,id,) => buildStudentThemes$idHandler(id,)(context))
    ..mount('/student/subthemes/<id>', (context,id,) => buildStudentSubthemes$idHandler(id,)(context))
    ..mount('/student/subjects', (context) => buildStudentSubjectsHandler()(context))
    ..mount('/student/subjects/<id>', (context,id,) => buildStudentSubjects$idHandler(id,)(context))
    ..mount('/me', (context) => buildMeHandler()(context))
    ..mount('/me/notifications', (context) => buildMeNotificationsHandler()(context))
    ..mount('/me/notifications/<id>', (context,id,) => buildMeNotifications$idHandler(id,)(context))
    ..mount('/auth', (context) => buildAuthHandler()(context))
    ..mount('/admin/users', (context) => buildAdminUsersHandler()(context))
    ..mount('/admin/users/<id>', (context,id,) => buildAdminUsers$idHandler(id,)(context))
    ..mount('/admin/subjects', (context) => buildAdminSubjectsHandler()(context))
    ..mount('/admin/subjects/<id>', (context,id,) => buildAdminSubjects$idHandler(id,)(context))
    ..mount('/admin/positions', (context) => buildAdminPositionsHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildUploadsHandler() {
  final pipeline = const Pipeline().addMiddleware(uploads_middleware.middleware);
  final router = Router()
    ..mount('/', (context) => uploads_$wildcard_path.onRequest(context,context.request.url.path));
  return pipeline.addHandler(router);
}

Handler buildTeacherHandler() {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/me', (context) => teacher_me.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildTeacherThemes$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/subthemes', (context) => teacher_themes_$id_subthemes.onRequest(context,id,))..all('/', (context) => teacher_themes_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildTeacherSubthemes$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/attachments', (context) => teacher_subthemes_$id_attachments.onRequest(context,id,))..all('/images', (context) => teacher_subthemes_$id_images.onRequest(context,id,))..all('/results', (context) => teacher_subthemes_$id_results.onRequest(context,id,))..all('/test', (context) => teacher_subthemes_$id_test.onRequest(context,id,))..all('/', (context) => teacher_subthemes_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildTeacherSubjectsHandler() {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/', (context) => teacher_subjects_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildTeacherSubjects$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/results', (context) => teacher_subjects_$id_results.onRequest(context,id,))..all('/themes', (context) => teacher_subjects_$id_themes.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildTeacherSubjects$idStudentsHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/<studentId>', (context,studentId,) => teacher_subjects_$id_students_$student_id.onRequest(context,id,studentId,))..all('/', (context) => teacher_subjects_$id_students_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildTeacherSubjects$idCodeHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/lock', (context) => teacher_subjects_$id_code_lock.onRequest(context,id,))..all('/rotate', (context) => teacher_subjects_$id_code_rotate.onRequest(context,id,))..all('/', (context) => teacher_subjects_$id_code_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildTeacherResultsHandler() {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/<id>', (context,id,) => teacher_results_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildTeacherResults$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(teacher_middleware.middleware);
  final router = Router()
    ..all('/retake', (context) => teacher_results_$id_retake.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildStudentHandler() {
  final pipeline = const Pipeline().addMiddleware(student_middleware.middleware);
  final router = Router()
    ..all('/join', (context) => student_join.onRequest(context,))..all('/results', (context) => student_results.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildStudentThemes$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(student_middleware.middleware);
  final router = Router()
    ..all('/subthemes', (context) => student_themes_$id_subthemes.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildStudentSubthemes$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(student_middleware.middleware);
  final router = Router()
    ..all('/submit', (context) => student_subthemes_$id_submit.onRequest(context,id,))..all('/test', (context) => student_subthemes_$id_test.onRequest(context,id,))..all('/', (context) => student_subthemes_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildStudentSubjectsHandler() {
  final pipeline = const Pipeline().addMiddleware(student_middleware.middleware);
  final router = Router()
    ..all('/', (context) => student_subjects_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildStudentSubjects$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(student_middleware.middleware);
  final router = Router()
    ..all('/themes', (context) => student_subjects_$id_themes.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildMeHandler() {
  final pipeline = const Pipeline().addMiddleware(me_middleware.middleware);
  final router = Router()
    ..all('/', (context) => me_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildMeNotificationsHandler() {
  final pipeline = const Pipeline().addMiddleware(me_middleware.middleware);
  final router = Router()
    ..all('/read_all', (context) => me_notifications_read_all.onRequest(context,))..all('/unread_count', (context) => me_notifications_unread_count.onRequest(context,))..all('/', (context) => me_notifications_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildMeNotifications$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(me_middleware.middleware);
  final router = Router()
    ..all('/read', (context) => me_notifications_$id_read.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline().addMiddleware(auth_middleware.middleware);
  final router = Router()
    ..all('/change_password', (context) => auth_change_password.onRequest(context,))..all('/login', (context) => auth_login.onRequest(context,))..all('/refresh', (context) => auth_refresh.onRequest(context,))..all('/register', (context) => auth_register.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminUsersHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_users_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminUsers$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/positions', (context) => admin_users_$id_positions.onRequest(context,id,))..all('/role', (context) => admin_users_$id_role.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildAdminSubjectsHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_subjects_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminSubjects$idHandler(String id,) {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_subjects_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildAdminPositionsHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/<id>', (context,id,) => admin_positions_$id.onRequest(context,id,))..all('/', (context) => admin_positions_index.onRequest(context,));
  return pipeline.addHandler(router);
}

