// Единый формат ошибки, возвращаемой клиенту.
// Используется во всех роутах, чтобы фронт мог унифицированно показывать сообщения.

class ApiError implements Exception {
  ApiError(this.statusCode, this.message, {this.code, this.details});

  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => {
        'error': {
          'message': message,
          if (code != null) 'code': code,
          if (details != null) 'details': details,
        },
      };

  factory ApiError.badRequest(String msg, {String? code}) =>
      ApiError(400, msg, code: code ?? 'bad_request');

  factory ApiError.unauthorized([String msg = 'Не авторизован']) =>
      ApiError(401, msg, code: 'unauthorized');

  factory ApiError.forbidden([String msg = 'Доступ запрещён']) =>
      ApiError(403, msg, code: 'forbidden');

  factory ApiError.notFound([String msg = 'Не найдено']) =>
      ApiError(404, msg, code: 'not_found');

  factory ApiError.conflict(String msg, {String? code}) =>
      ApiError(409, msg, code: code ?? 'conflict');

  factory ApiError.server([String msg = 'Внутренняя ошибка']) =>
      ApiError(500, msg, code: 'server_error');
}
