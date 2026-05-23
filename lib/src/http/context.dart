// Расширения на RequestContext для удобного доступа к сервисам и текущему юзеру.

import 'package:dart_frog/dart_frog.dart';

import '../models/api_error.dart';
import '../models/user.dart';
import '../services/service_container.dart';

extension AppContext on RequestContext {
  ServiceContainer get services => read<ServiceContainer>();

  /// Возвращает текущего юзера, если в контексте есть, иначе кидает 401.
  User get currentUser {
    final u = read<User?>();
    if (u == null) throw ApiError.unauthorized();
    return u;
  }

  /// null если юзер не авторизован.
  User? get currentUserOrNull => read<User?>();
}
