-- Должности преподавателей — теперь не свободный текст, а справочник.
-- Создаёт и редактирует список администратор. Препод видит свою
-- должность только для чтения.
--
-- Старое свободно-текстовое поле users.position обнуляется и удаляется
-- (по решению пользователя — в режиме разработки данные не сохраняем).

CREATE TABLE IF NOT EXISTS positions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Новая колонка-ссылка. ON DELETE SET NULL: если админ удалит должность,
-- у привязанных к ней преподов поле просто очистится.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES positions(id)
        ON DELETE SET NULL;

-- Старое текстовое поле больше не нужно.
ALTER TABLE users DROP COLUMN IF EXISTS position;

CREATE INDEX IF NOT EXISTS idx_users_position ON users (position_id);
