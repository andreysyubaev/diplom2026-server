// GET /teacher/subthemes/<id>/test — получить полный тест (с правильными ответами)
// PUT /teacher/subthemes/<id>/test — заменить тест целиком (вопросы тоже)
//
// Тело PUT:
//   {
//     "gradeThresholds": {"2": 0, "3": 50, "4": 70, "5": 90},
//     "shuffleQuestions": false,
//     "questions": [
//        {
//          "type": "single_choice",
//          "text": "Сколько будет 2+2?",
//          "imagePath": null,
//          "points": 1,
//          "sortOrder": 0,
//          "payload": { "options": ["3","4","5","6"], "correctIndex": 1 }
//        },
//        {
//          "type": "order",
//          "text": "Расставь по возрастанию",
//          "points": 2,
//          "payload": { "items": ["1","2","3","4"] }
//        },
//        {
//          "type": "text_input",
//          "text": "Введи квадрат двойки",
//          "points": 1,
//          "payload": { "acceptedAnswers": ["4","четыре"], "caseSensitive": false }
//        }
//     ]
//   }

import 'package:college_app_server/src/http/authorization.dart';
import 'package:college_app_server/src/http/context.dart';
import 'package:college_app_server/src/http/responses.dart';
import 'package:college_app_server/src/models/api_error.dart';
import 'package:dart_frog/dart_frog.dart';

const _allowedTypes = {'single_choice', 'order', 'text_input'};

Future<Response> onRequest(RequestContext context, String id) async {
  return runSafely(() async {
    final owner = await ownerOfSubtheme(context, id);
    await ensureCanManageSubject(context, owner.subjectId);

    switch (context.request.method) {
      case HttpMethod.get:
        final test = await context.services.tests.findBySubthemeId(id);
        if (test == null) return jsonOk({'exists': false});
        return jsonOk({'exists': true, ...test.toTeacherJson()});

      case HttpMethod.put:
        final body = await readJson(context.request);
        final thresholdsRaw = body['gradeThresholds'];
        if (thresholdsRaw is! Map) {
          throw ApiError.badRequest('Поле gradeThresholds обязательно');
        }
        final thresholds = <String, int>{};
        for (final e in thresholdsRaw.entries) {
          thresholds[e.key.toString()] = (e.value as num).toInt();
        }
        _validateThresholds(thresholds);

        final qRaw = body.reqList('questions');
        final normalized = <Map<String, dynamic>>[];
        for (var i = 0; i < qRaw.length; i++) {
          final q = qRaw[i];
          if (q is! Map<String, dynamic>) {
            throw ApiError.badRequest('Вопрос #$i должен быть объектом');
          }
          normalized.add(_validateQuestion(q, i));
        }

        // Лимит времени (минуты). null/0/отрицательное — без ограничения.
        final tlmRaw = body['timeLimitMinutes'];
        int? timeLimit;
        if (tlmRaw is num) {
          final v = tlmRaw.toInt();
          timeLimit = v > 0 ? v : null;
        }

        // Окно доступности теста (ISO 8601 строки или null).
        final availableFrom =
            _parseIsoDate(body['availableFrom'], 'availableFrom');
        final availableTo = _parseIsoDate(body['availableTo'], 'availableTo');
        if (availableFrom != null &&
            availableTo != null &&
            !availableTo.isAfter(availableFrom)) {
          throw ApiError.badRequest(
              'Дата окончания доступности должна быть позже даты начала');
        }

        final test = await context.services.tests.upsert(
          subthemeId: id,
          gradeThresholds: thresholds,
          shuffleQuestions: (body['shuffleQuestions'] as bool?) ?? false,
          timeLimitMinutes: timeLimit,
          availableFrom: availableFrom,
          availableTo: availableTo,
          questions: normalized,
        );
        return jsonOk(test.toTeacherJson());

      default:
        return errorResponse(ApiError(405, 'Метод не поддерживается'));
    }
  });
}

DateTime? _parseIsoDate(dynamic raw, String fieldName) {
  if (raw == null) return null;
  if (raw is! String || raw.trim().isEmpty) return null;
  try {
    return DateTime.parse(raw).toUtc();
  } catch (_) {
    throw ApiError.badRequest('Поле $fieldName должно быть датой ISO 8601');
  }
}

void _validateThresholds(Map<String, int> t) {
  for (final g in [2, 3, 4, 5]) {
    final v = t[g.toString()];
    if (v == null) {
      throw ApiError.badRequest('В gradeThresholds нет порога для оценки $g');
    }
    if (v < 0 || v > 100) {
      throw ApiError.badRequest('Порог оценки $g должен быть 0..100');
    }
  }
  if (!(t['2']! <= t['3']! && t['3']! <= t['4']! && t['4']! <= t['5']!)) {
    throw ApiError.badRequest('Пороги оценок должны идти по возрастанию');
  }
}

Map<String, dynamic> _validateQuestion(Map<String, dynamic> q, int index) {
  final type = q['type'];
  if (type is! String || !_allowedTypes.contains(type)) {
    throw ApiError.badRequest('Вопрос #$index: некорректный type');
  }
  final text = q['text'];
  if (text is! String || text.trim().isEmpty) {
    throw ApiError.badRequest('Вопрос #$index: пустой текст');
  }
  final payload = q['payload'];
  if (payload is! Map<String, dynamic>) {
    throw ApiError.badRequest('Вопрос #$index: payload обязателен');
  }

  switch (type) {
    case 'single_choice':
      final options = payload['options'];
      if (options is! List ||
          options.length < 2 ||
          options.any((o) => o is! String)) {
        throw ApiError.badRequest('Вопрос #$index: options должен быть массивом ≥2 строк');
      }
      final ci = payload['correctIndex'];
      if (ci is! int || ci < 0 || ci >= options.length) {
        throw ApiError.badRequest('Вопрос #$index: некорректный correctIndex');
      }
    case 'order':
      final items = payload['items'];
      if (items is! List ||
          items.length < 2 ||
          items.any((o) => o is! String)) {
        throw ApiError.badRequest('Вопрос #$index: items должен быть массивом ≥2 строк');
      }
    case 'text_input':
      final accepted = payload['acceptedAnswers'];
      if (accepted is! List ||
          accepted.isEmpty ||
          accepted.any((o) => o is! String)) {
        throw ApiError.badRequest(
            'Вопрос #$index: acceptedAnswers должен быть непустым массивом строк');
      }
  }

  return {
    'type': type,
    'text': text,
    'imagePath': q['imagePath'],
    'sortOrder': q['sortOrder'] ?? index,
    'points': q['points'] ?? 1,
    'payload': payload,
  };
}
