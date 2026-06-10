-- Уведомления пользователя.
-- Сервер создаёт записи при событиях (пересдача назначена, материал опубликован),
-- клиент периодически опрашивает /me/notifications и показывает их в отдельной
-- вкладке. Push-уведомлений (FCM/APNs) нет — это можно добавить позже.

CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        TEXT NOT NULL,           -- 'retake' / 'new_subtheme' / 'new_theme'
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,
    -- произвольные данные для навигации (subjectId, subthemeId, …)
    data        JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user
    ON notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_unread
    ON notifications (user_id) WHERE is_read = FALSE;
