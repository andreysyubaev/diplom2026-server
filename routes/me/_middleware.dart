// /me/* — требует авторизации.

import 'package:college_app_server/src/http/middleware.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) => handler.use(requireAuth());
