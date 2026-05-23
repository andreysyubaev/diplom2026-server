// Один раз при запуске процесса:
//   1) загружаем .env
//   2) подключаемся к БД
//   3) накатываем миграции
//   4) если нет ни одного админа — создаём INITIAL_ADMIN
//   5) собираем ServiceContainer и возвращаем
//
// Кэш — чтобы в hot-reload режиме dart_frog не пересоздавать всё на каждый запрос.

import 'dart:async';
import 'dart:io';

import 'config/env.dart';
import 'db/connection.dart';
import 'db/migrator.dart';
import 'models/user.dart';
import 'services/service_container.dart';

ServiceContainer? _cached;
Completer<ServiceContainer>? _building;

Future<ServiceContainer> bootstrap() async {
  if (_cached != null) return _cached!;
  if (_building != null) return _building!.future;
  _building = Completer<ServiceContainer>();
  try {
    Env.load(); // безопасно вызывать многократно
    final db = await Database.instance();
    await Migrator(db).migrate();
    final container = await ServiceContainer.build(db);
    await _ensureInitialAdmin(container);
    _cached = container;
    _building!.complete(container);
    return container;
  } catch (e, st) {
    _building!.completeError(e, st);
    _building = null;
    rethrow;
  }
}

Future<void> _ensureInitialAdmin(ServiceContainer c) async {
  final count = await c.users.countByRole(UserRole.admin);
  if (count > 0) return;
  final env = Env.instance;
  final existing = await c.users.findByEmail(env.initialAdminEmail);
  if (existing != null) {
    if (existing.role != UserRole.admin) {
      await c.users.updateRole(existing.id, UserRole.admin);
      stdout.writeln('⚙ Существующий пользователь повышен до admin: ${env.initialAdminEmail}');
    }
    return;
  }
  final hash = await c.passwords.hash(env.initialAdminPassword);
  await c.users.create(
    email: env.initialAdminEmail.toLowerCase(),
    passwordHash: hash,
    fullName: env.initialAdminName,
    role: UserRole.admin,
  );
  stdout.writeln('✓ Создан первый администратор: ${env.initialAdminEmail}');
}
