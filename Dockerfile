# Dockerfile для деплоя сервера (например, на Amvera, Render, или любой VPS).
# Сборка идёт в два этапа: сначала компилируем код, потом кладём только бинарь в финальный образ.

# ── Этап 1: сборка ──────────────────────────────────────────────
FROM dart:stable AS build

WORKDIR /app

# Сначала копируем pubspec.* чтобы кешировать pub get
COPY pubspec.* ./
RUN dart pub get

# Устанавливаем dart_frog_cli для сборки production-бандла
RUN dart pub global activate dart_frog_cli

# Копируем весь исходный код
COPY . .

# dart_frog build генерирует папку build/ с обычным Dart-приложением,
# которое уже можно скомпилировать в нативный бинарь.
RUN dart pub global run dart_frog_cli:dart_frog build

# Компилируем в нативный бинарник для максимальной скорости
RUN dart compile exe build/bin/server.dart -o build/bin/server

# ── Этап 2: финальный образ ─────────────────────────────────────
FROM debian:bookworm-slim

# Минимальный набор библиотек, нужный скомпилированному Dart
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем только бинарь и миграции
COPY --from=build /app/build/bin/server /app/server
COPY --from=build /app/migrations /app/migrations

# Папка, в которую сервер будет складывать загруженные картинки.
# На Amvera её удобно смонтировать как persistent volume.
RUN mkdir -p /app/uploads
ENV UPLOADS_DIR=/app/uploads

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]
