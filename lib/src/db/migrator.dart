// Применяет SQL миграции из папки migrations/ при старте сервера.
// Просто берёт все *.sql файлы по имени и выполняет их по порядку,
// записывая в schema_migrations какие уже накатаны.

import 'dart:io';

import 'connection.dart';

class Migrator {
  Migrator(this._db, {this.directory = 'migrations'});

  final Database _db;
  final String directory;

  Future<void> migrate() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    ''');

    final dir = Directory(directory);
    if (!dir.existsSync()) {
      throw StateError(
        'Migrations directory "$directory" not found. '
        'Запусти сервер из корня проекта.',
      );
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final applied = (await _db.execute('SELECT name FROM schema_migrations'))
        .map((row) => row[0]! as String)
        .toSet();

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (applied.contains(name)) continue;
      stdout.writeln('▶ Применяю миграцию: $name');
      final sql = await file.readAsString();
      // executeRaw — без prepared statement, чтобы можно было выполнить
      // несколько SQL-команд из одного файла за раз.
      await _db.executeRaw(sql);
      await _db.execute(
        'INSERT INTO schema_migrations (name) VALUES (@n)',
        parameters: {'n': name},
      );
    }
  }
}
