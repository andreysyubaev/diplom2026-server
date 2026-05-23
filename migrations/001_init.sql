-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Начальная схема БД для приложения колледжа                       ║
-- ║  Запускается автоматически сервером при первом старте.            ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Включаем расширение для UUID, чтобы можно было генерировать ID на стороне БД
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── ПОЛЬЗОВАТЕЛИ ───────────────────────────────────────────────────
-- role: 'admin' | 'teacher' | 'student'
-- position: должность преподавателя (заполняется только у teacher)
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    full_name       TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN ('admin','teacher','student')),
    position        TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (lower(email));
CREATE INDEX IF NOT EXISTS idx_users_role  ON users (role);

-- ─── REFRESH-ТОКЕНЫ ─────────────────────────────────────────────────
-- Храним хэши, чтобы при утечке БД токены нельзя было использовать
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens (user_id);

-- ─── ПРЕДМЕТЫ ───────────────────────────────────────────────────────
-- Один предмет принадлежит одному преподавателю (на старте).
-- При необходимости позже можно сделать связь many-to-many через subject_teachers.
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

-- ─── КОДЫ ВХОДА В ПРЕДМЕТ ────────────────────────────────────────────
-- Преподаватель видит актуальный код, который автоматически меняется
-- каждые N минут. Студенты используют его для вступления в предмет.
CREATE TABLE IF NOT EXISTS subject_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id  UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    code        TEXT NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subject_codes_subject ON subject_codes (subject_id);
CREATE INDEX IF NOT EXISTS idx_subject_codes_code    ON subject_codes (code);

-- ─── СВЯЗЬ СТУДЕНТ ↔ ПРЕДМЕТ ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subject_students (
    subject_id  UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    student_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (subject_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_subject_students_student ON subject_students (student_id);

-- ─── ТЕМЫ (КОЛЛЕКЦИИ) ────────────────────────────────────────────────
-- visibility:
--   'draft'           - черновик, видит только препод
--   'published'       - опубликовано, доступно студентам
--   'visible_locked'  - студенты ВИДЯТ название, но не могут открыть
--   'scheduled'       - откроется автоматически в дату scheduled_at
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

-- ─── ПОД-ТЕМЫ ────────────────────────────────────────────────────────
-- Содержат конспект и привязанный к ним тест
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

-- ─── КАРТИНКИ К ПОД-ТЕМАМ ───────────────────────────────────────────
-- file_path - относительный путь внутри UPLOADS_DIR
CREATE TABLE IF NOT EXISTS subtheme_images (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subtheme_id     UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    file_path       TEXT NOT NULL,
    caption         TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subtheme_images_subtheme ON subtheme_images (subtheme_id);

-- ─── ТЕСТЫ ───────────────────────────────────────────────────────────
-- Один тест на одну подтему.
-- grade_thresholds хранит проценты для оценок 2..5, например:
--   {"2":0,"3":50,"4":70,"5":90}
CREATE TABLE IF NOT EXISTS tests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subtheme_id         UUID NOT NULL UNIQUE REFERENCES subthemes(id) ON DELETE CASCADE,
    grade_thresholds    JSONB NOT NULL DEFAULT '{"2":0,"3":50,"4":70,"5":90}'::jsonb,
    shuffle_questions   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ВОПРОСЫ ─────────────────────────────────────────────────────────
-- type:
--   'single_choice'  - 4 варианта, один правильный
--   'order'          - сопоставление/упорядочивание
--   'text_input'     - студент вписывает ответ текстом (проверка по совпадению)
CREATE TABLE IF NOT EXISTS questions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id         UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
    type            TEXT NOT NULL CHECK (type IN ('single_choice','order','text_input')),
    text            TEXT NOT NULL,
    image_path      TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    points          INTEGER NOT NULL DEFAULT 1,
    -- payload зависит от типа вопроса:
    --   single_choice: {"options":["...","..."], "correctIndex": 2}
    --   order:         {"items":["a","b","c","d"]}  (правильный порядок = массиву)
    --   text_input:    {"acceptedAnswers":["42","сорок два"], "caseSensitive": false}
    payload         JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_questions_test ON questions (test_id);

-- ─── РЕЗУЛЬТАТЫ ──────────────────────────────────────────────────────
-- Записывается каждое прохождение теста студентом.
-- is_first_attempt = true только у первой записи на пару (student, subtheme).
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

-- ─── ТРИГГЕРЫ ОБНОВЛЕНИЯ updated_at ──────────────────────────────────
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
