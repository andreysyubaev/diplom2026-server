-- ===========================================================================
-- ПОЛНЫЙ СКРИПТ БАЗЫ ДАННЫХ ДЛЯ ЗАЩИТЫ ДИПЛОМА
-- ===========================================================================
-- Запускать на свежей PostgreSQL (14+).
-- Скрипт создаёт всю схему и загружает демо-данные.
-- Повторный запуск безопасен — все CREATE используют IF NOT EXISTS.
--
-- Учётки после загрузки (пароль у всех:  admin12345):
--   admin@college.local    — администратор
--   ivanov@college.local   — преподаватель (Базы данных + Дискретная математика)
--   petrova@college.local  — преподаватель (резерв)
--   student1@college.local — студент Андреев
--   student2@college.local — студент Борисов
--   student3@college.local — студент Васильев
-- ===========================================================================

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ЧАСТЬ 1 — СХЕМА БАЗЫ ДАННЫХ (все 12 миграций)             ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ─── Расширение UUID ──────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── ПОЛЬЗОВАТЕЛИ ────────────────────────────────────────────
-- role: 'admin' | 'teacher' | 'student'
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    full_name       TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN ('admin','teacher','student')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (lower(email));
CREATE INDEX IF NOT EXISTS idx_users_role  ON users (role);

-- ─── REFRESH-ТОКЕНЫ ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens (user_id);

-- ─── ПРЕДМЕТЫ ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subjects (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    description     TEXT,
    teacher_id      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subjects_teacher ON subjects (teacher_id);

-- ─── КОДЫ ВХОДА В ПРЕДМЕТ ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS subject_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id  UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    code        TEXT NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subject_codes_subject ON subject_codes (subject_id);
CREATE INDEX IF NOT EXISTS idx_subject_codes_code    ON subject_codes (code);

-- ─── СВЯЗЬ СТУДЕНТ ↔ ПРЕДМЕТ ──────────────────────────────────
CREATE TABLE IF NOT EXISTS subject_students (
    subject_id  UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    student_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (subject_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_subject_students_student ON subject_students (student_id);

-- ─── ТЕМЫ ─────────────────────────────────────────────────────
-- visibility: 'draft' | 'published' | 'visible_locked' | 'scheduled'
CREATE TABLE IF NOT EXISTS themes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    description     TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    visibility      TEXT NOT NULL DEFAULT 'draft'
                    CHECK (visibility IN ('draft','published','visible_locked','scheduled')),
    scheduled_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_themes_subject ON themes (subject_id);

-- ─── ПОДТЕМЫ ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subthemes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id        UUID NOT NULL REFERENCES themes(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    content         TEXT NOT NULL DEFAULT '',
    sort_order      INTEGER NOT NULL DEFAULT 0,
    visibility      TEXT NOT NULL DEFAULT 'draft'
                    CHECK (visibility IN ('draft','published','visible_locked','scheduled')),
    scheduled_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subthemes_theme ON subthemes (theme_id);

-- ─── КАРТИНКИ К ПОДТЕМАМ ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS subtheme_images (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subtheme_id     UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    file_path       TEXT NOT NULL,
    caption         TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subtheme_images_subtheme ON subtheme_images (subtheme_id);

-- ─── ТЕСТЫ ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subtheme_id         UUID NOT NULL UNIQUE REFERENCES subthemes(id) ON DELETE CASCADE,
    grade_thresholds    JSONB NOT NULL DEFAULT '{"2":0,"3":50,"4":70,"5":90}'::jsonb,
    shuffle_questions   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ВОПРОСЫ ──────────────────────────────────────────────────
-- type: 'single_choice' | 'order' | 'text_input'
CREATE TABLE IF NOT EXISTS questions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id         UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
    type            TEXT NOT NULL CHECK (type IN ('single_choice','order','text_input')),
    text            TEXT NOT NULL,
    image_path      TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    points          INTEGER NOT NULL DEFAULT 1,
    payload         JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_questions_test ON questions (test_id);

-- ─── РЕЗУЛЬТАТЫ ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS results (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subtheme_id         UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    test_id             UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
    score               INTEGER NOT NULL,
    max_score           INTEGER NOT NULL,
    percentage          NUMERIC(5,2) NOT NULL,
    grade               INTEGER,
    is_first_attempt    BOOLEAN NOT NULL DEFAULT FALSE,
    answers             JSONB NOT NULL,
    completed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_results_student  ON results (student_id);
CREATE INDEX IF NOT EXISTS idx_results_subtheme ON results (subtheme_id);

-- ─── ТРИГГЕР updated_at ───────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['users','subjects','themes','subthemes','tests']
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_updated ON %I;
             CREATE TRIGGER trg_%I_updated BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION set_updated_at();',
            t, t, t, t
        );
    END LOOP;
END $$;

-- ─── Миграция 002: блочный редактор конспектов ────────────────
ALTER TABLE subthemes
    ADD COLUMN IF NOT EXISTS content_blocks JSONB NOT NULL DEFAULT '[]'::jsonb;

-- ─── Миграция 003: вложения к подтемам ───────────────────────
CREATE TABLE IF NOT EXISTS subtheme_attachments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subtheme_id     UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    file_path       TEXT NOT NULL,
    original_name   TEXT NOT NULL,
    mime_type       TEXT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subtheme_attachments_subtheme
    ON subtheme_attachments (subtheme_id);

-- ─── Миграция 004: пересдачи ──────────────────────────────────
CREATE TABLE IF NOT EXISTS retake_permissions (
    student_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subtheme_id  UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    granted_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    granted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (student_id, subtheme_id)
);

ALTER TABLE results
    ADD COLUMN IF NOT EXISTS is_retake BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── Миграция 005: уведомления ────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        TEXT NOT NULL,
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,
    data        JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user
    ON notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_unread
    ON notifications (user_id) WHERE is_read = FALSE;

-- ─── Миграция 006: флаг scheduled_notified ────────────────────
ALTER TABLE subthemes
    ADD COLUMN IF NOT EXISTS scheduled_notified BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE themes
    ADD COLUMN IF NOT EXISTS scheduled_notified BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── Миграция 008: должности преподавателей ───────────────────
CREATE TABLE IF NOT EXISTS positions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Временная колонка для переноса данных (удаляется в миграции 009)
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES positions(id)
        ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_position ON users (position_id);

-- ─── Миграция 009: M2M пользователь ↔ должность ──────────────
CREATE TABLE IF NOT EXISTS user_positions (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position_id UUID NOT NULL REFERENCES positions(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, position_id)
);

CREATE INDEX IF NOT EXISTS idx_user_positions_user
    ON user_positions (user_id);

-- Переносим старые одиночные привязки (если были)
INSERT INTO user_positions (user_id, position_id)
SELECT id, position_id FROM users WHERE position_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE users DROP COLUMN IF EXISTS position_id;

-- ─── Миграция 010: блокировка кода входа ─────────────────────
ALTER TABLE subjects
    ADD COLUMN IF NOT EXISTS code_locked BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── Миграция 011: лимит времени на тест ─────────────────────
ALTER TABLE tests
    ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER;

-- ─── Миграция 012: окно доступности теста ────────────────────
ALTER TABLE tests
    ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS available_to   TIMESTAMPTZ;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ЧАСТЬ 2 — ДЕМО-ДАННЫЕ                                      ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Очистка (повторный запуск скрипта заменит данные целиком)
TRUNCATE TABLE
    notifications,
    refresh_tokens,
    results,
    retake_permissions,
    questions,
    tests,
    subtheme_attachments,
    subtheme_images,
    subthemes,
    themes,
    subject_codes,
    subject_students,
    subjects,
    user_positions,
    positions,
    users
RESTART IDENTITY CASCADE;

-- ─── ПОЛЬЗОВАТЕЛИ ────────────────────────────────────────────
-- Пароль у всех: admin12345
INSERT INTO users (id, email, password_hash, full_name, role) VALUES
    ('11111111-1111-1111-1111-111111111111',
     'admin@college.local',
     '$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40',
     'Главный администратор', 'admin'),

    ('22222222-2222-2222-2222-222222222221',
     'ivanov@college.local',
     '$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40',
     'Иванов Сергей Петрович', 'teacher'),

    ('22222222-2222-2222-2222-222222222222',
     'petrova@college.local',
     '$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40',
     'Петрова Анна Викторовна', 'teacher'),

    ('33333333-3333-3333-3333-333333333331',
     'student1@college.local',
     '$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40',
     'Андреев Андрей Андреевич', 'student'),

    ('33333333-3333-3333-3333-333333333332',
     'student2@college.local',
     '$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40',
     'Борисов Борис Борисович', 'student'),

    ('33333333-3333-3333-3333-333333333333',
     'student3@college.local',
     '$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40',
     'Васильев Василий Васильевич', 'student');

-- ─── ДОЛЖНОСТИ ────────────────────────────────────────────────
INSERT INTO positions (id, name) VALUES
    ('44444444-4444-4444-4444-444444444441', 'Базы данных'),
    ('44444444-4444-4444-4444-444444444442', 'Дискретная математика'),
    ('44444444-4444-4444-4444-444444444443', 'Программирование'),
    ('44444444-4444-4444-4444-444444444444', 'Математический анализ');

-- Иванов — БД и Дискретка; Петрова — Программирование и Матан
INSERT INTO user_positions (user_id, position_id) VALUES
    ('22222222-2222-2222-2222-222222222221', '44444444-4444-4444-4444-444444444441'),
    ('22222222-2222-2222-2222-222222222221', '44444444-4444-4444-4444-444444444442'),
    ('22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444443'),
    ('22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444');

-- ─── ПРЕДМЕТЫ ─────────────────────────────────────────────────
INSERT INTO subjects (id, name, description, teacher_id, created_by) VALUES
    ('55555555-5555-5555-5555-555555555551',
     'Базы данных',
     'Курс по проектированию и работе с реляционными базами данных. '
     'Включает SQL, нормализацию, индексы, транзакции.',
     '22222222-2222-2222-2222-222222222221',
     '11111111-1111-1111-1111-111111111111'),

    ('55555555-5555-5555-5555-555555555552',
     'Дискретная математика',
     'Множества, логика, графы, комбинаторика — основа для алгоритмов и ИИ.',
     '22222222-2222-2222-2222-222222222221',
     '11111111-1111-1111-1111-111111111111');

-- Все три студента записаны на оба предмета
INSERT INTO subject_students (subject_id, student_id) VALUES
    ('55555555-5555-5555-5555-555555555551', '33333333-3333-3333-3333-333333333331'),
    ('55555555-5555-5555-5555-555555555551', '33333333-3333-3333-3333-333333333332'),
    ('55555555-5555-5555-5555-555555555551', '33333333-3333-3333-3333-333333333333'),
    ('55555555-5555-5555-5555-555555555552', '33333333-3333-3333-3333-333333333331'),
    ('55555555-5555-5555-5555-555555555552', '33333333-3333-3333-3333-333333333332'),
    ('55555555-5555-5555-5555-555555555552', '33333333-3333-3333-3333-333333333333');

-- ─── ТЕМЫ ─────────────────────────────────────────────────────
INSERT INTO themes (id, subject_id, title, description, sort_order, visibility) VALUES
    ('66666666-6666-6666-6666-666666666611',
     '55555555-5555-5555-5555-555555555551',
     'Введение в базы данных',
     'Что такое БД, зачем нужны, какие бывают.',
     0, 'published'),
    ('66666666-6666-6666-6666-666666666612',
     '55555555-5555-5555-5555-555555555551',
     'Язык SQL',
     'Базовые запросы: SELECT, WHERE, JOIN.',
     1, 'published'),
    ('66666666-6666-6666-6666-666666666621',
     '55555555-5555-5555-5555-555555555552',
     'Множества и отображения',
     'Базовые операции, кардинальность, отображения.',
     0, 'published'),
    ('66666666-6666-6666-6666-666666666622',
     '55555555-5555-5555-5555-555555555552',
     'Логика высказываний',
     'Логические операции, таблицы истинности, законы де Моргана.',
     1, 'published');

-- ─── ПОДТЕМЫ ──────────────────────────────────────────────────
INSERT INTO subthemes (id, theme_id, title, sort_order, visibility, content_blocks) VALUES
    ('77777777-7777-7777-7777-777777777711',
     '66666666-6666-6666-6666-666666666611',
     'Что такое база данных',
     0, 'published',
     '[
       {"id": "b1", "type": "text", "text": "## База данных\n\n**База данных (БД)** — это организованное хранилище структурированной информации, к которому можно обращаться по запросам.\n\n### Зачем нужна БД\n\n- хранить большие объёмы данных надёжно;\n- быстро искать нужное;\n- обеспечить **целостность** — нельзя получить противоречивые данные;\n- обслуживать одновременно много пользователей.\n\n### Примеры использования\n\n1. журнал успеваемости в колледже;\n2. список товаров в магазине;\n3. сообщения в мессенджере;\n4. посты в социальной сети.\n\n> Без БД любое серьёзное приложение превратится в кашу из текстовых файлов."}
     ]'::jsonb);

INSERT INTO subthemes (id, theme_id, title, sort_order, visibility, content_blocks) VALUES
    ('77777777-7777-7777-7777-777777777712',
     '66666666-6666-6666-6666-666666666611',
     'Реляционная модель',
     1, 'published',
     '[
       {"id": "b1", "type": "text", "text": "## Реляционная модель\n\nДанные хранятся в **таблицах** (отношениях). Каждая таблица:\n\n- состоит из **строк** (записей) и **столбцов** (атрибутов);\n- имеет **первичный ключ** — столбец, который однозначно идентифицирует строку;\n- может ссылаться на другие таблицы через **внешние ключи**.\n\n### Пример: таблица студентов\n\n| id | ФИО | группа |\n|----|-----|--------|\n| 1 | Иванов И.И. | ПР-41 |\n| 2 | Петров П.П. | ПР-41 |\n| 3 | Сидоров С.С. | ПР-42 |\n\n### Свойства реляционной модели\n\n1. **Атомарность** — в ячейке одно значение, не список.\n2. **Уникальность строк** — гарантируется первичным ключом.\n3. **Порядок строк не важен** — СУБД сама решает, в каком порядке хранить."}
     ]'::jsonb);

INSERT INTO subthemes (id, theme_id, title, sort_order, visibility, content_blocks) VALUES
    ('77777777-7777-7777-7777-777777777721',
     '66666666-6666-6666-6666-666666666612',
     'SELECT и WHERE',
     0, 'published',
     '[
       {"id": "b1", "type": "text", "text": "## Оператор SELECT\n\n**SELECT** — самый частый SQL-запрос. Достаёт строки из таблицы.\n\n```sql\nSELECT столбец1, столбец2\nFROM таблица\nWHERE условие;\n```\n\n### Примеры\n\nВсе студенты:\n```sql\nSELECT * FROM students;\n```\n\nТолько фамилии и группы:\n```sql\nSELECT full_name, group_name FROM students;\n```\n\nТолько студенты группы ПР-41:\n```sql\nSELECT full_name FROM students\nWHERE group_name = ''ПР-41'';\n```\n\nС несколькими условиями:\n```sql\nSELECT * FROM students\nWHERE group_name = ''ПР-41'' AND age >= 18;\n```\n\n### Полезные операторы в WHERE\n\n- `=` равно\n- `<>` или `!=` не равно\n- `<`, `>`, `<=`, `>=` сравнение\n- `LIKE ''Иван%''` — начинается с «Иван»\n- `IN (''ПР-41'', ''ПР-42'')` — входит в список\n- `BETWEEN 18 AND 25` — в диапазоне\n- `IS NULL` / `IS NOT NULL` — пусто или нет"}
     ]'::jsonb);

INSERT INTO subthemes (id, theme_id, title, sort_order, visibility, content_blocks) VALUES
    ('77777777-7777-7777-7777-777777777722',
     '66666666-6666-6666-6666-666666666612',
     'Соединение таблиц (JOIN)',
     1, 'published',
     '[
       {"id": "b1", "type": "text", "text": "## JOIN — соединение таблиц\n\nКогда данные разнесены по нескольким таблицам, их надо **соединять**. Делается это через JOIN по совпадающему столбцу.\n\n### INNER JOIN\n\nБерёт **только те строки**, для которых нашлось соответствие в обеих таблицах.\n\n```sql\nSELECT s.full_name, g.name\nFROM students s\nINNER JOIN groups g ON s.group_id = g.id;\n```\n\n### LEFT JOIN\n\nБерёт **все строки из левой таблицы**, даже если в правой нет соответствия — тогда правые столбцы будут NULL.\n\n```sql\nSELECT s.full_name, r.grade\nFROM students s\nLEFT JOIN results r ON r.student_id = s.id;\n```\n\nТакой запрос покажет всех студентов, в том числе тех, кто не сдавал тест.\n\n### Запомни\n\n> Если хочешь «всех + где есть» — LEFT JOIN.\n> Если хочешь только тех, у кого есть пара — INNER JOIN."}
     ]'::jsonb);

INSERT INTO subthemes (id, theme_id, title, sort_order, visibility, content_blocks) VALUES
    ('77777777-7777-7777-7777-777777777731',
     '66666666-6666-6666-6666-666666666621',
     'Операции над множествами',
     0, 'published',
     '[
       {"id": "b1", "type": "text", "text": "## Операции над множествами\n\n**Множество** — совокупность различимых объектов, рассматриваемых как единое целое.\n\nЕсли A = {1, 2, 3} и B = {3, 4, 5}, то:\n\n### Объединение  A ∪ B\n\nВсе элементы, которые есть хотя бы в одном множестве:\n\n```\nA ∪ B = {1, 2, 3, 4, 5}\n```\n\n### Пересечение  A ∩ B\n\nТолько те элементы, которые есть в обоих множествах:\n\n```\nA ∩ B = {3}\n```\n\n### Разность  A \\ B\n\nЭлементы A, которых нет в B:\n\n```\nA \\ B = {1, 2}\nB \\ A = {4, 5}\n```\n\n### Симметрическая разность  A △ B\n\nЭлементы, которые есть только в одном из множеств:\n\n```\nA △ B = {1, 2, 4, 5}\n```"}
     ]'::jsonb);

INSERT INTO subthemes (id, theme_id, title, sort_order, visibility, content_blocks) VALUES
    ('77777777-7777-7777-7777-777777777741',
     '66666666-6666-6666-6666-666666666622',
     'Логические операции',
     0, 'published',
     '[
       {"id": "b1", "type": "text", "text": "## Логические операции\n\nВ логике высказываний пять базовых операций.\n\n### Отрицание ¬A («не A»)\n\n| A | ¬A |\n|---|----|\n| 0 | 1  |\n| 1 | 0  |\n\n### Конъюнкция A ∧ B («A и B»)\n\nИстинна, **только когда оба** истинны.\n\n### Дизъюнкция A ∨ B («A или B»)\n\nИстинна, когда **хотя бы один** истинен.\n\n### Импликация A → B («если A, то B»)\n\nЛожна **только если** A истинно, а B ложно. В остальных случаях истинна.\n\n### Эквивалентность A ↔ B («A тогда и только тогда, когда B»)\n\nИстинна, когда A и B имеют **одинаковое** значение.\n\n### Законы де Моргана\n\n```\n¬(A ∧ B) = ¬A ∨ ¬B\n¬(A ∨ B) = ¬A ∧ ¬B\n```\n\nЭти два закона часто применяются в программировании, когда упрощают условия в `if`."}
     ]'::jsonb);

-- ─── ТЕСТЫ ────────────────────────────────────────────────────
-- Тест 1: простой, без таймера и окна доступности
INSERT INTO tests (id, subtheme_id, grade_thresholds, shuffle_questions,
                   time_limit_minutes, available_from, available_to) VALUES
    ('88888888-8888-8888-8888-888888888811',
     '77777777-7777-7777-7777-777777777711',
     '{"2": 0, "3": 50, "4": 70, "5": 90}'::jsonb,
     false, NULL, NULL, NULL);

INSERT INTO questions (id, test_id, type, text, sort_order, points, payload) VALUES
    ('99999999-9999-9999-9999-999999999911',
     '88888888-8888-8888-8888-888888888811',
     'single_choice',
     'Что такое база данных?',
     0, 1,
     '{"options": [
        "Текстовый файл с записями",
        "Организованное хранилище структурированной информации",
        "Программа для рисования таблиц",
        "Антивирус"
      ], "correctIndex": 1}'::jsonb),

    ('99999999-9999-9999-9999-999999999912',
     '88888888-8888-8888-8888-888888888811',
     'text_input',
     'Как называют столбец, который однозначно идентифицирует строку?',
     1, 1,
     '{"acceptedAnswers": ["первичный ключ", "primary key"],
       "caseSensitive": false}'::jsonb);

-- Тест 2: таймер 5 минут + перемешивание вопросов
INSERT INTO tests (id, subtheme_id, grade_thresholds, shuffle_questions,
                   time_limit_minutes, available_from, available_to) VALUES
    ('88888888-8888-8888-8888-888888888812',
     '77777777-7777-7777-7777-777777777712',
     '{"2": 0, "3": 50, "4": 70, "5": 90}'::jsonb,
     true, 5, NULL, NULL);

INSERT INTO questions (id, test_id, type, text, sort_order, points, payload) VALUES
    ('99999999-9999-9999-9999-999999999921',
     '88888888-8888-8888-8888-888888888812',
     'single_choice',
     'Какое из утверждений о реляционной модели НЕВЕРНО?',
     0, 1,
     '{"options": [
        "В ячейке может храниться список значений",
        "Данные хранятся в таблицах",
        "Каждая таблица имеет первичный ключ",
        "Порядок строк не имеет значения"
      ], "correctIndex": 0}'::jsonb),

    ('99999999-9999-9999-9999-999999999922',
     '88888888-8888-8888-8888-888888888812',
     'order',
     'Расставь шаги проектирования таблицы в правильном порядке:',
     1, 2,
     '{"items": [
        "Определить сущность",
        "Перечислить атрибуты",
        "Выбрать первичный ключ",
        "Описать связи с другими таблицами"
      ]}'::jsonb),

    ('99999999-9999-9999-9999-999999999923',
     '88888888-8888-8888-8888-888888888812',
     'text_input',
     'Как называют связь между таблицами, реализованную через внешний ключ?',
     2, 1,
     '{"acceptedAnswers": ["ссылочная целостность", "foreign key", "внешний ключ"],
       "caseSensitive": false}'::jsonb);

-- Тест 3: окно доступности (открыт сейчас, закроется через 7 дней)
INSERT INTO tests (id, subtheme_id, grade_thresholds, shuffle_questions,
                   time_limit_minutes, available_from, available_to) VALUES
    ('88888888-8888-8888-8888-888888888821',
     '77777777-7777-7777-7777-777777777721',
     '{"2": 0, "3": 60, "4": 75, "5": 90}'::jsonb,
     false, NULL,
     NOW() - INTERVAL '1 hour',
     NOW() + INTERVAL '7 days');

INSERT INTO questions (id, test_id, type, text, sort_order, points, payload) VALUES
    ('99999999-9999-9999-9999-999999999931',
     '88888888-8888-8888-8888-888888888821',
     'single_choice',
     'Какой запрос выберет всех студентов группы ПР-41?',
     0, 1,
     '{"options": [
        "SELECT students WHERE group_name = ''ПР-41''",
        "SELECT * FROM students WHERE group_name = ''ПР-41''",
        "GET students FROM ПР-41",
        "FIND * IN students = ПР-41"
      ], "correctIndex": 1}'::jsonb),

    ('99999999-9999-9999-9999-999999999932',
     '88888888-8888-8888-8888-888888888821',
     'text_input',
     'Каким оператором проверяют, что значение попадает в список вариантов?',
     1, 1,
     '{"acceptedAnswers": ["IN", "in"],
       "caseSensitive": false}'::jsonb);

-- Тест 4: таймер 10 минут + окно доступности (флагман по фичам)
INSERT INTO tests (id, subtheme_id, grade_thresholds, shuffle_questions,
                   time_limit_minutes, available_from, available_to) VALUES
    ('88888888-8888-8888-8888-888888888822',
     '77777777-7777-7777-7777-777777777722',
     '{"2": 0, "3": 50, "4": 70, "5": 90}'::jsonb,
     true, 10,
     NOW() - INTERVAL '1 hour',
     NOW() + INTERVAL '14 days');

INSERT INTO questions (id, test_id, type, text, sort_order, points, payload) VALUES
    ('99999999-9999-9999-9999-999999999941',
     '88888888-8888-8888-8888-888888888822',
     'single_choice',
     'Какой JOIN вернёт всех студентов, в том числе не сдававших тест?',
     0, 1,
     '{"options": ["INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "CROSS JOIN"],
       "correctIndex": 1}'::jsonb),

    ('99999999-9999-9999-9999-999999999942',
     '88888888-8888-8888-8888-888888888822',
     'order',
     'Расставь типы JOIN в порядке от самого «строгого» к самому «щедрому»:',
     1, 2,
     '{"items": [
        "INNER JOIN",
        "LEFT JOIN",
        "FULL OUTER JOIN",
        "CROSS JOIN"
      ]}'::jsonb),

    ('99999999-9999-9999-9999-999999999943',
     '88888888-8888-8888-8888-888888888822',
     'text_input',
     'По какому столбцу обычно соединяют таблицу студентов с таблицей групп?',
     2, 1,
     '{"acceptedAnswers": ["group_id", "id группы", "groupid"],
       "caseSensitive": false}'::jsonb);

-- Тест 5: дискретка, таймер 3 минуты (удобно показать срабатывание в живую)
INSERT INTO tests (id, subtheme_id, grade_thresholds, shuffle_questions,
                   time_limit_minutes, available_from, available_to) VALUES
    ('88888888-8888-8888-8888-888888888831',
     '77777777-7777-7777-7777-777777777731',
     '{"2": 0, "3": 50, "4": 70, "5": 90}'::jsonb,
     false, 3, NULL, NULL);

INSERT INTO questions (id, test_id, type, text, sort_order, points, payload) VALUES
    ('99999999-9999-9999-9999-999999999951',
     '88888888-8888-8888-8888-888888888831',
     'single_choice',
     'Чему равно A ∩ B, если A = {1,2,3} и B = {3,4,5}?',
     0, 1,
     '{"options": ["{1,2,3,4,5}", "{3}", "{1,2}", "{}"],
       "correctIndex": 1}'::jsonb),

    ('99999999-9999-9999-9999-999999999952',
     '88888888-8888-8888-8888-888888888831',
     'text_input',
     'Как называется операция «принадлежит только одному из множеств»?',
     1, 1,
     '{"acceptedAnswers": ["симметрическая разность", "xor"],
       "caseSensitive": false}'::jsonb);

-- ===========================================================================
-- Готово! Учётки для входа (пароль у всех: admin12345):
--   admin@college.local      — администратор
--   ivanov@college.local     — преподаватель (2 предмета, 4 темы, 6 подтем, 5 тестов)
--   petrova@college.local    — преподаватель (резерв, без предметов)
--   student1@college.local   — студент Андреев
--   student2@college.local   — студент Борисов
--   student3@college.local   — студент Васильев
-- ===========================================================================
