-- Флаг «о выходе этой запланированной сущности уже уведомили».
-- Используется фоновым таймером сервера, который раз в минуту проверяет:
--   visibility = 'scheduled' AND scheduled_at <= NOW() AND scheduled_notified = FALSE
-- и шлёт уведомления преподавателю и студентам.

ALTER TABLE subthemes
    ADD COLUMN IF NOT EXISTS scheduled_notified BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE themes
    ADD COLUMN IF NOT EXISTS scheduled_notified BOOLEAN NOT NULL DEFAULT FALSE;
