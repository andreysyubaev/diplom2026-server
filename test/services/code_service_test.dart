// Простые проверки без подключения к БД.
// Полноценный интеграционный тест CodeService живёт в test/integration/
// (запускается только при поднятом PostgreSQL).

import 'package:college_app_server/src/models/subject.dart';
import 'package:test/test.dart';

void main() {
  group('SubjectCode JSON', () {
    test('toJson отдаёт ожидаемые поля', () {
      final exp = DateTime.utc(2026, 9, 1, 10, 30);
      final code = SubjectCode(
        code: 'ABC123',
        expiresAt: exp,
        refreshInSeconds: 300,
      );
      final json = code.toJson();
      expect(json['code'], 'ABC123');
      expect(json['refreshInSeconds'], 300);
      expect(json['expiresAt'], exp.toIso8601String());
    });
  });
}
