import 'package:college_app_server/src/models/api_error.dart';
import 'package:test/test.dart';

void main() {
  group('ApiError factories', () {
    test('badRequest → 400', () {
      expect(ApiError.badRequest('x').statusCode, 400);
    });
    test('unauthorized → 401', () {
      expect(ApiError.unauthorized().statusCode, 401);
    });
    test('forbidden → 403', () {
      expect(ApiError.forbidden().statusCode, 403);
    });
    test('notFound → 404', () {
      expect(ApiError.notFound().statusCode, 404);
    });
    test('conflict → 409', () {
      expect(ApiError.conflict('x').statusCode, 409);
    });
    test('toJson включает code/message', () {
      final j = ApiError.notFound('Не нашёл').toJson();
      expect(j['error']['message'], 'Не нашёл');
      expect(j['error']['code'], 'not_found');
    });
  });
}
