// /admin/* — только для админа.

import 'package:college_app_server/src/http/middleware.dart';
import 'package:college_app_server/src/models/user.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) =>
    handler.use(requireRole({UserRole.admin}));
