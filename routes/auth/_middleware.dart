// /auth/* — большинство роутов открыто, но /auth/change_password требует авторизации.

import 'package:college_app_server/src/http/middleware.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final path = context.request.uri.path;
    final secured = path.endsWith('/auth/change_password');
    final wrapped = secured ? handler.use(requireAuth()) : handler;
    return wrapped(context);
  };
}
