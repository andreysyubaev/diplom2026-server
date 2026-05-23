// GET / — простейший health-check.

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(body: {
    'status': 'ok',
    'service': 'college_app_server',
    'version': '0.1.0',
  });
}
