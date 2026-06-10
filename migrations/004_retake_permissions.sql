-- Разрешения на пересдачу теста.
-- Когда препод нажимает «Назначить пересдачу» у студента — создаётся запись.
-- При сдаче студентом эта запись исчезает, а сама попытка
-- помечается как is_retake = TRUE и засчитывается «на оценку».
--
-- На одну пару (student, subtheme) одновременно — только одна
-- разрешённая пересдача.

CREATE TABLE IF NOT EXISTS retake_permissions (
    student_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subtheme_id  UUID NOT NULL REFERENCES subthemes(id) ON DELETE CASCADE,
    granted_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    granted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (student_id, subtheme_id)
);

-- Помечает попытку как пересдачу, назначенную преподавателем.
ALTER TABLE results
    ADD COLUMN IF NOT EXISTS is_retake BOOLEAN NOT NULL DEFAULT FALSE;
