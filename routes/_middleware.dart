// Глобальное middleware приложения.
// Применяется ко всем роутам.
//
// Порядок выполнения (важно!):
//   1) CORS — самый внешний, чтобы preflight-OPTIONS не падал на других мидлварах
//   2) ServiceContainer — нужен всем остальным мидлварам и хендлерам
//   3) optionalAuth — читает Authorization-заголовок и кладёт User? в контекст

import 'package:college_app_server/src/bootstrap.dart';
import 'package:college_app_server/src/http/middleware.dart';
import 'package:college_app_server/src/services/service_container.dart';
import 'package:dart_frog/dart_frog.dart';

// Глобальный кэш — bootstrap делается один раз за всё время жизни процесса.
ServiceContainer? _containerCache;

Handler middleware(Handler handler) {
  return handler
      .use(optionalAuth())
      .use(_provideServices())
      .use(cors());
}

Middleware _provideServices() {
  return (handler) {
    return (context) async {
      _containerCache ??= await bootstrap();
      final updated = context.provide<ServiceContainer>(() => _containerCache!);
      return handler(updated);
    };
  };
}
