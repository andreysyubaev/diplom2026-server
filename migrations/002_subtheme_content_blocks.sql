-- Добавляет поле content_blocks к под-темам.
-- Это блочный конструктор лекции: список объектов вида
--   { "type": "text",  "text": "..." }
--   { "type": "image", "url": "/uploads/aa/bb.jpg", "caption": "..." }
--
-- Старое поле content остаётся для обратной совместимости, но новый
-- редактор пишет только в content_blocks. На фронте при пустом
-- content_blocks показывается пустой редактор с кнопкой "+".

ALTER TABLE subthemes
    ADD COLUMN IF NOT EXISTS content_blocks JSONB NOT NULL DEFAULT '[]'::jsonb;
