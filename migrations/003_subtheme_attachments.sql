-- Вложенные файлы к под-теме (PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX и т.п.).
-- Файлы лежат в той же uploads/-папке, что и картинки.
-- В таблице — путь до файла + оригинальное имя (для скачивания)
-- и MIME-тип с размером (для отображения иконки и подсказки).

CREATE TABLE IF NOT EXISTS subtheme_attachments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subtheme_id     UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    file_path       TEXT NOT NULL,           -- путь от UPLOADS_DIR
    original_name   TEXT NOT NULL,           -- "Лекция 1.pdf"
    mime_type       TEXT NOT NULL,           -- "application/pdf"
    size_bytes      BIGINT NOT NULL,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subtheme_attachments_subtheme
    ON subtheme_attachments (subtheme_id);
