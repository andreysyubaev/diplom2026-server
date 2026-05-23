# College App Server (Dart Frog)

Backend для мобильного приложения колледжа. Написан на **Dart Frog** + **PostgreSQL**.

> Это **только сервер**. Flutter-приложение будет отдельной частью проекта — мы его сделаем во второй итерации.

---

## Что умеет сервер (вкратце)

| Роль | Что может |
|---|---|
| **admin** | Создавать аккаунты преподавателей, менять роли пользователей, создавать предметы и назначать преподавателей |
| **teacher** | Заводить должность, видеть свои предметы, генерировать 5-минутный код входа, создавать темы/подтемы, наполнять конспекты и тесты, смотреть результаты |
| **student** | Регистрироваться, входить в предмет по коду, читать конспекты, проходить тесты, видеть свои результаты |

---

## 1. Что нужно установить (один раз)

### 1.1. Dart SDK
- Скачай с https://dart.dev/get-dart
- Проверь, что работает:
  ```bash
  dart --version
  ```
  Должно быть >= 3.3.

### 1.2. Dart Frog CLI
```bash
dart pub global activate dart_frog_cli
```
Проверь:
```bash
dart_frog --version
```

> Если команду не находит — добавь `~/.pub-cache/bin` (Linux/macOS) или `%LOCALAPPDATA%\Pub\Cache\bin` (Windows) в `PATH`.

### 1.3. Docker Desktop
Нужен только чтобы запустить PostgreSQL «одной командой».
- Скачай: https://www.docker.com/products/docker-desktop/
- Запусти. На иконке должна гореть зелёная точка.

Можно вместо Docker поставить PostgreSQL вручную (https://www.postgresql.org/download/) — но через Docker проще, ничего не ломается в системе.

---

## 2. Первый запуск проекта

Все команды выполняются из папки `server/`.

### Шаг 1. Скачай зависимости
```bash
dart pub get
```

### Шаг 2. Подними базу данных
```bash
docker compose up -d
```
Эта команда поднимет:
- **PostgreSQL** на `localhost:5432` (пользователь `college_user`, пароль `college_pass`, БД `college_app`)
- **pgAdmin** (графический клиент) на http://localhost:8081 (логин `admin@college.local`, пароль `admin`)

> Если порт `5432` уже занят (например, у тебя свой Postgres) — поменяй маппинг в `docker-compose.yml` на `5433:5432` и в `.env` поставь `DB_PORT=5433`.

Проверить что БД работает:
```bash
docker compose ps
```
В колонке STATUS должно быть `healthy`.

### Шаг 3. Создай .env
Скопируй пример:

- **Linux/macOS:**
  ```bash
  cp .env.example .env
  ```
- **Windows (PowerShell):**
  ```powershell
  Copy-Item .env.example .env
  ```

Открой `.env` и **поменяй JWT_SECRET** на любую длинную случайную строку. На проде это обязательно!

### Шаг 4. Запусти сервер
```bash
dart_frog dev
```

В консоли увидишь:
```
✓ Создан первый администратор: admin@college.local
The Dart VM service is listening on http://...
The Dart Frog DevServer is listening on http://localhost:8080
```

> Сервер сам создал таблицы и админа (логин/пароль — из `.env`).

Проверь, что всё живо:
```bash
curl http://localhost:8080
# {"status":"ok","service":"college_app_server","version":"0.1.0"}
```

---

## 3. Как «погонять» сервер вручную (через curl)

Все запросы возвращают/принимают JSON.

### Залогиниться админом
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@college.local","password":"admin12345"}'
```
Ответ:
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": { "id": "...", "role": "admin", ... }
}
```
Сохрани `accessToken` куда-нибудь — он нужен как `Authorization: Bearer <token>` во всех защищённых запросах.

### Создать преподавателя
```bash
ADMIN_TOKEN="eyJ..."
curl -X POST http://localhost:8080/admin/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email":"ivanov@college.local",
    "password":"teacher123",
    "fullName":"Иванов Иван Иванович",
    "position":"преподаватель"
  }'
```

### Создать предмет и привязать преподавателя
```bash
curl -X POST http://localhost:8080/admin/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Математика",
    "description":"Высшая математика для 1 курса",
    "teacherId":"<id преподавателя из предыдущего шага>"
  }'
```

### Залогиниться преподавателем и получить код предмета
```bash
TEACHER_TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ivanov@college.local","password":"teacher123"}' \
  | jq -r .accessToken)

curl http://localhost:8080/teacher/subjects/<SUBJECT_ID>/code \
  -H "Authorization: Bearer $TEACHER_TOKEN"
# {"code":"ABC123","expiresAt":"...","refreshInSeconds":300}
```

### Зарегистрировать студента и войти по коду
```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"stud@college.local","password":"stud1234","fullName":"Петров П."}'

# Войти в предмет:
STUDENT_TOKEN="..."
curl -X POST http://localhost:8080/student/join \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"code":"ABC123"}'
```

---

## 4. Структура проекта

```
server/
├── routes/                         ← файловый роутинг Dart Frog
│   ├── _middleware.dart            ← CORS, БД, JWT — для всех
│   ├── index.dart                  ← GET / — health check
│   ├── auth/
│   │   ├── register.dart           ← POST /auth/register (только студент)
│   │   ├── login.dart              ← POST /auth/login
│   │   ├── refresh.dart            ← POST /auth/refresh
│   │   └── change_password.dart    ← POST /auth/change_password
│   ├── me/index.dart               ← GET  /me
│   ├── admin/                      ← все требуют role=admin
│   │   ├── users/
│   │   │   ├── index.dart          ← GET/POST  /admin/users
│   │   │   └── [id]/role.dart      ← PATCH     /admin/users/<id>/role
│   │   └── subjects/
│   │       ├── index.dart          ← GET/POST  /admin/subjects
│   │       └── [id]/index.dart     ← GET/PATCH/DELETE
│   ├── teacher/                    ← role=teacher (или admin)
│   │   ├── me.dart                 ← PATCH /teacher/me (должность)
│   │   ├── subjects/
│   │   │   ├── index.dart          ← GET    /teacher/subjects
│   │   │   └── [id]/
│   │   │       ├── code.dart       ← GET   /teacher/subjects/<id>/code
│   │   │       ├── results.dart    ← GET   /teacher/subjects/<id>/results
│   │   │       └── themes.dart     ← GET/POST
│   │   ├── themes/[id]/
│   │   │   ├── index.dart          ← GET/PATCH/DELETE
│   │   │   └── subthemes.dart      ← GET/POST
│   │   └── subthemes/[id]/
│   │       ├── index.dart          ← GET/PATCH/DELETE
│   │       ├── test.dart           ← GET/PUT (конструктор теста)
│   │       ├── images.dart         ← POST/DELETE (картинки)
│   │       └── results.dart        ← GET
│   ├── student/                    ← role=student (или admin)
│   │   ├── join.dart               ← POST  /student/join (по коду)
│   │   ├── results.dart            ← GET
│   │   ├── subjects/
│   │   │   ├── index.dart
│   │   │   └── [id]/themes.dart
│   │   ├── themes/[id]/subthemes.dart
│   │   └── subthemes/[id]/
│   │       ├── index.dart          ← GET (конспект)
│   │       ├── test.dart           ← GET (вопросы без ответов)
│   │       └── submit.dart         ← POST (отправить ответы)
│   └── uploads/[...path].dart      ← раздача файлов
│
├── lib/src/
│   ├── config/env.dart             ← чтение .env
│   ├── db/
│   │   ├── connection.dart         ← пул PostgreSQL
│   │   └── migrator.dart           ← наката SQL миграций
│   ├── models/                     ← классы данных
│   ├── repositories/               ← SQL запросы
│   ├── services/                   ← бизнес-логика
│   ├── http/                       ← хелперы для роутов
│   └── bootstrap.dart              ← инициализация при старте
│
├── migrations/001_init.sql         ← схема БД
├── test/                           ← unit-тесты
├── uploads/                        ← загруженные картинки (создаётся автоматически)
├── pubspec.yaml
├── docker-compose.yml              ← PostgreSQL + pgAdmin локально
├── Dockerfile                      ← для деплоя на Amvera/VPS
├── .env.example
└── README.md
```

---

## 5. Запуск тестов

```bash
dart test
```

Что тестируется:
- `test/services/password_service_test.dart` — валидация и хеширование паролей
- `test/services/jwt_service_test.dart` — выпуск/проверка JWT
- `test/services/auth_service_test.dart` — регистрация, логин, конфликты
- `test/services/code_service_test.dart` — модель кода входа
- `test/models/test_model_test.dart` — расчёт оценки, видимость тем
- `test/models/api_error_test.dart` — формат ошибок
- `test/routes/submit_logic_test.dart` — проверка ответов на тесты

Эти тесты НЕ требуют запущенной БД.

---

## 6. API кратко

### Авторизация
| Метод | URL | Кто может | Что делает |
|---|---|---|---|
| POST | `/auth/register` | все | Регистрирует студента |
| POST | `/auth/login` | все | Возвращает access+refresh токены |
| POST | `/auth/refresh` | все | Обменивает refresh на новую пару |
| POST | `/auth/change_password` | любой авторизованный | Меняет пароль |
| GET  | `/me` | любой авторизованный | Текущий профиль |

### Админ
| Метод | URL | Что |
|---|---|---|
| GET  | `/admin/users?role=teacher&search=...` | Список пользователей |
| POST | `/admin/users` | Создать преподавателя |
| PATCH| `/admin/users/<id>/role` | Сменить роль |
| GET/POST | `/admin/subjects` | Список/создать предмет |
| GET/PATCH/DELETE | `/admin/subjects/<id>` | Управление предметом |

### Преподаватель
| Метод | URL | Что |
|---|---|---|
| PATCH | `/teacher/me` | Сохранить должность |
| GET   | `/teacher/subjects` | Свои предметы |
| GET   | `/teacher/subjects/<id>/code` | Текущий код входа (5 минут) |
| GET   | `/teacher/subjects/<id>/results` | Все результаты по предмету |
| GET/POST | `/teacher/subjects/<id>/themes` | Темы предмета |
| GET/PATCH/DELETE | `/teacher/themes/<id>` | Управление темой |
| GET/POST | `/teacher/themes/<id>/subthemes` | Подтемы темы |
| GET/PATCH/DELETE | `/teacher/subthemes/<id>` | Подтема |
| GET/PUT | `/teacher/subthemes/<id>/test` | Конструктор теста |
| POST/DELETE | `/teacher/subthemes/<id>/images` | Картинки |
| GET   | `/teacher/subthemes/<id>/results` | Результаты по подтеме |

### Студент
| Метод | URL | Что |
|---|---|---|
| POST | `/student/join` | Войти в предмет по коду |
| GET  | `/student/subjects` | Свои предметы |
| GET  | `/student/subjects/<id>/themes` | Темы (видимые) |
| GET  | `/student/themes/<id>/subthemes` | Подтемы |
| GET  | `/student/subthemes/<id>` | Конспект |
| GET  | `/student/subthemes/<id>/test` | Тест (без ответов) |
| POST | `/student/subthemes/<id>/submit` | Сдать тест |
| GET  | `/student/results` | Свои результаты |

---

## 7. Формат теста (для PUT `/teacher/subthemes/<id>/test`)

```json
{
  "gradeThresholds": { "2": 0, "3": 50, "4": 70, "5": 90 },
  "shuffleQuestions": false,
  "questions": [
    {
      "type": "single_choice",
      "text": "Чему равно 2 × 3?",
      "imagePath": null,
      "points": 1,
      "payload": {
        "options": ["5","6","7","8"],
        "correctIndex": 1
      }
    },
    {
      "type": "order",
      "text": "Расставь по возрастанию",
      "points": 2,
      "payload": { "items": ["1","2","3","4"] }
    },
    {
      "type": "text_input",
      "text": "Сколько будет 5+5?",
      "points": 1,
      "payload": {
        "acceptedAnswers": ["10","десять"],
        "caseSensitive": false
      }
    }
  ]
}
```

Студент отправляет ответы так:
```json
{
  "answers": {
    "<id вопроса 1>": { "selectedIndex": 1 },
    "<id вопроса 2>": { "order": ["1","2","3","4"] },
    "<id вопроса 3>": { "text": "10" }
  }
}
```

---

## 8. Деплой на Amvera (по шагам)

Amvera поддерживает Docker-сборку и managed PostgreSQL.

1. **Создай managed PostgreSQL** в панели Amvera. Получишь host, port, user, password.
2. **Создай новое приложение типа Docker.**
3. **Загрузи проект** (push в git-репозиторий Amvera).
4. **Перейди в Настройки → Переменные окружения** и пропиши:
   ```
   PORT=8080
   HOST=0.0.0.0
   DB_HOST=<host_от_managed_db>
   DB_PORT=5432
   DB_NAME=<имя_бд>
   DB_USER=<пользователь>
   DB_PASSWORD=<пароль>
   DB_SSL=true
   JWT_SECRET=<длинная_случайная_строка>
   INITIAL_ADMIN_EMAIL=admin@yourcollege.ru
   INITIAL_ADMIN_PASSWORD=<надёжный_пароль>
   INITIAL_ADMIN_NAME=Главный администратор
   SUBJECT_CODE_TTL_MINUTES=5
   ```
5. **Persistent storage** — смонтируй volume на `/app/uploads`, иначе картинки будут пропадать при перезапуске.
6. **Deploy** → дождись `healthy`. Сервер сам создаст таблицы и админа из переменных.

---

## 9. Что делать, если что-то сломалось

| Симптом | Что проверить |
|---|---|
| `Connection refused` к БД | `docker compose ps` — Postgres `healthy`? Совпадают порты в `.env` и `docker-compose.yml`? |
| `JWT_SECRET is not set` | Скопирован ли `.env.example` → `.env`? |
| `Files not found: migrations/` | Запускаешь команду не из папки `server/`? |
| `permission denied` на `uploads/` | Создай папку руками: `mkdir -p uploads` |
| Изменения в коде не применяются | `dart_frog dev` подхватывает изменения автоматически. Если нет — Ctrl+C и заново. |
| `pubspec.yaml has changed` | `dart pub get` |

---

## 10. Что дальше (план второй итерации)

- [ ] Flutter-приложение (Riverpod, Material 3, bottom navigation bar)
- [ ] Экран `auth_screen` (логин/регистрация)
- [ ] Экраны студента: главная (список предметов), ввод кода, чтение конспекта, прохождение теста, результаты
- [ ] Экраны преподавателя: предметы, конструктор тем/подтем, конструктор теста, результаты группы
- [ ] Экраны админа: пользователи, предметы
- [ ] Профиль/настройки (смена пароля, выход)
- [ ] Widget-тесты основных экранов

Дай знать когда дойдём — поможем строить приложение точно так же по шагам.
