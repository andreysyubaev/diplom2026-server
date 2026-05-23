// Middleware-обёртки, которые подключают сервисы и авторизацию.

import 'package:dart_frog/dart_frog.dart';

import '../models/api_error.dart';
import '../models/user.dart';
import '../services/service_container.dart';
import 'context.dart';
import 'responses.dart';

/// Кладёт в контекст ServiceContainer.
Middleware provideServices(ServiceContainer container) {
  return provider<ServiceContainer>((_) => container);
}

/// Кладёт в контекст текущего юзера (или null если не авторизован).
/// Это middleware "мягкое": НЕ требует авторизации. Если в заголовках есть
/// корректный JWT — юзер будет в контексте, иначе там null.
Middleware optionalAuth() {
  return (handler) {
    return (context) async {
      final authHeader = context.request.headers['authorization'];
      User? user;
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7).trim();
        try {
          final claims = context.services.jwt.verifyAccessToken(token);
          user = await context.services.users.findById(claims.userId);
        } on ApiError {
          // не валидно — оставляем null, не падаем
        }
      }
      final updated = context.provide<User?>(() => user);
      return handler(updated);
    };
  };
}

/// Жёсткое требование авторизации. Использовать ПОСЛЕ optionalAuth().
Middleware requireAuth() {
  return (handler) {
    return (context) async {
      if (context.currentUserOrNull == null) {
        return errorResponse(ApiError.unauthorized());
      }
      return handler(context);
    };
  };
}

/// Требует, чтобы у пользователя была одна из указанных ролей.
Middleware requireRole(Set<UserRole> allowed) {
  return (handler) {
    return (context) async {
      final user = context.currentUserOrNull;
      if (user == null) return errorResponse(ApiError.unauthorized());
      if (!allowed.contains(user.role)) {
        return errorResponse(ApiError.forbidden());
      }
      return handler(context);
    };
  };
}

/// CORS — нужен чтобы Flutter Web и эмуляторы могли стучаться с других origin.
Middleware cors() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: 204,
          headers: _corsHeaders(),
        );
      }
      final response = await handler(context);
      final newHeaders = {...response.headers, ..._corsHeaders()};
      return response.copyWith(headers: newHeaders);
    };
  };
}

Map<String, String> _corsHeaders() => const {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
    };
