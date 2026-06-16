-- Окно доступности теста.
-- available_from — раньше этого момента студент не может открыть тест;
-- available_to   — после этого момента тест автоматически закрывается:
--                  клиент по достижении этого времени отправляет
--                  ответы как при истечении таймера.
-- NULL в любом поле = ограничения нет (как было раньше).

ALTER TABLE tests
    ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS available_to   TIMESTAMPTZ;
