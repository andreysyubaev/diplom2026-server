// GET /me — данные текущего пользователя (для проверки токена и заполнения профиля).

import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return jsonOk(context.currentUser.toJson());
}
