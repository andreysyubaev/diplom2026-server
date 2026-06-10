-- Переход от «одна должность на препода» к «много должностей».
-- В реальной кафедре препод может быть одновременно «доцентом» и
-- «куратором группы»; раньше можно было выбрать только одну.

CREATE TABLE IF NOT EXISTS user_positions (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position_id UUID NOT NULL REFERENCES positions(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, position_id)
);

CREATE INDEX IF NOT EXISTS idx_user_positions_user
    ON user_positions (user_id);

-- Переносим имеющиеся одно-значные привязки в новую таблицу.
INSERT INTO user_positions (user_id, position_id)
SELECT id, position_id FROM users WHERE position_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Старая колонка больше не нужна.
ALTER TABLE users DROP COLUMN IF EXISTS position_id;
