// Тонкая обёртка над пакетом `postgres`.
// Используем ОДНО постоянное соединение вместо Pool, чтобы обойти баг
// `postgres` 3.x в Pool/AuthenticationProcedure
// (FormatException: Missing extension byte при попытке открыть второе
// соединение).
//
// Для дев-окружения и небольшого прода этого более чем хватит.
// Все запросы сериализуются через простой мьютекс, потому что один Connection
// не поддерживает параллельные execute().

import 'dart:async';

import 'package:postgres/postgres.dart';

import '../config/env.dart';

class Database {
  Database._(this._conn);

  final Connection _conn;
  final _Mutex _lock = _Mutex();

  static Database? _instance;

  /// Получить инстанс. При первом вызове открывается соединение и прогревается.
  static Future<Database> instance() async {
    if (_instance != null) return _instance!;
    final env = Env.instance;
    final conn = await Connection.open(
      Endpoint(
        host: env.dbHost,
        port: env.dbPort,
        database: env.dbName,
        username: env.dbUser,
        password: env.dbPassword,
      ),
      settings: ConnectionSettings(
        sslMode: env.dbSsl ? SslMode.require : SslMode.disable,
      ),
    );
    // Прогрев — сразу увидим ошибки конфигурации.
    await conn.execute('SELECT 1');
    return _instance = Database._(conn);
  }

  /// Выполнить SQL через PREPARED STATEMENT (с параметрами).
  /// Внутри ровно одна SQL-команда.
  Future<Result> execute(
    Object sql, {
    Object? parameters,
  }) {
    return _lock.protect(() async {
      if (sql is String) {
        return _conn.execute(Sql.named(sql), parameters: parameters);
      }
      return _conn.execute(sql, parameters: parameters);
    });
  }

  /// Выполнить «сырой» SQL через simple query protocol (без prepared statement).
  /// Поддерживает несколько SQL-команд через `;`.
  /// Параметры передавать НЕЛЬЗЯ — для них используй [execute].
  /// Используется в основном для миграций.
  Future<Result> executeRaw(String sql) {
    return _lock.protect(
      () => _conn.execute(sql, queryMode: QueryMode.simple),
    );
  }

  /// Запустить колбэк внутри транзакции с автоматическим rollback при ошибке.
  Future<T> runTx<T>(Future<T> Function(TxSession tx) action) {
    return _lock.protect(() => _conn.runTx(action));
  }

  /// Закрыть соединение (используется в тестах).
  Future<void> close() async {
    await _conn.close();
    _instance = null;
  }
}

/// Простейший мьютекс на Future-цепочке.
/// Гарантирует, что в каждый момент времени только один запрос
/// идёт через единственное Connection.
class _Mutex {
  Future<void> _tail = Future.value();

  Future<T> protect<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final previous = _tail;
    _tail = completer.future;
    return previous.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }
}
