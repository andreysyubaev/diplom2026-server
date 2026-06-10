-- Одноразовая правка: те запланированные подтемы и темы, у которых
-- срок наступил, а флаг scheduled_notified уже TRUE (то есть таймер
-- их уже «выпустил»), переводим в visibility='published'.
-- Это убирает баг, когда в UI препода после публикации по расписанию
-- статус продолжал показываться как «По расписанию».

UPDATE subthemes
SET visibility = 'published',
    updated_at = NOW()
WHERE visibility = 'scheduled'
  AND scheduled_at IS NOT NULL
  AND scheduled_at <= NOW();

UPDATE themes
SET visibility = 'published'
WHERE visibility = 'scheduled'
  AND scheduled_at IS NOT NULL
  AND scheduled_at <= NOW();
