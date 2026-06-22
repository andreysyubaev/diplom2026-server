--
-- PostgreSQL database dump
--

\restrict PjeT0SDOHruFI7PC1rtgCf7VOcLBuKZZwLjzd7I7FgqgTCQdWRLjvdbkzZxwGzf

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.user_positions DROP CONSTRAINT IF EXISTS user_positions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_positions DROP CONSTRAINT IF EXISTS user_positions_position_id_fkey;
ALTER TABLE IF EXISTS ONLY public.themes DROP CONSTRAINT IF EXISTS themes_subject_id_fkey;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_subtheme_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subthemes DROP CONSTRAINT IF EXISTS subthemes_theme_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subtheme_images DROP CONSTRAINT IF EXISTS subtheme_images_subtheme_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subtheme_attachments DROP CONSTRAINT IF EXISTS subtheme_attachments_subtheme_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subjects DROP CONSTRAINT IF EXISTS subjects_teacher_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subjects DROP CONSTRAINT IF EXISTS subjects_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.subject_students DROP CONSTRAINT IF EXISTS subject_students_subject_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subject_students DROP CONSTRAINT IF EXISTS subject_students_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.subject_codes DROP CONSTRAINT IF EXISTS subject_codes_subject_id_fkey;
ALTER TABLE IF EXISTS ONLY public.retake_permissions DROP CONSTRAINT IF EXISTS retake_permissions_subtheme_id_fkey;
ALTER TABLE IF EXISTS ONLY public.retake_permissions DROP CONSTRAINT IF EXISTS retake_permissions_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.retake_permissions DROP CONSTRAINT IF EXISTS retake_permissions_granted_by_fkey;
ALTER TABLE IF EXISTS ONLY public.results DROP CONSTRAINT IF EXISTS results_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.results DROP CONSTRAINT IF EXISTS results_subtheme_id_fkey;
ALTER TABLE IF EXISTS ONLY public.results DROP CONSTRAINT IF EXISTS results_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.questions DROP CONSTRAINT IF EXISTS questions_test_id_fkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
DROP TRIGGER IF EXISTS trg_users_updated ON public.users;
DROP TRIGGER IF EXISTS trg_themes_updated ON public.themes;
DROP TRIGGER IF EXISTS trg_tests_updated ON public.tests;
DROP TRIGGER IF EXISTS trg_subthemes_updated ON public.subthemes;
DROP TRIGGER IF EXISTS trg_subjects_updated ON public.subjects;
DROP INDEX IF EXISTS public.idx_users_role;
DROP INDEX IF EXISTS public.idx_users_email;
DROP INDEX IF EXISTS public.idx_user_positions_user;
DROP INDEX IF EXISTS public.idx_themes_subject;
DROP INDEX IF EXISTS public.idx_subthemes_theme;
DROP INDEX IF EXISTS public.idx_subtheme_images_subtheme;
DROP INDEX IF EXISTS public.idx_subtheme_attachments_subtheme;
DROP INDEX IF EXISTS public.idx_subjects_teacher;
DROP INDEX IF EXISTS public.idx_subject_students_student;
DROP INDEX IF EXISTS public.idx_subject_codes_subject;
DROP INDEX IF EXISTS public.idx_subject_codes_code;
DROP INDEX IF EXISTS public.idx_results_subtheme;
DROP INDEX IF EXISTS public.idx_results_student;
DROP INDEX IF EXISTS public.idx_refresh_user;
DROP INDEX IF EXISTS public.idx_questions_test;
DROP INDEX IF EXISTS public.idx_notifications_user;
DROP INDEX IF EXISTS public.idx_notifications_unread;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.user_positions DROP CONSTRAINT IF EXISTS user_positions_pkey;
ALTER TABLE IF EXISTS ONLY public.themes DROP CONSTRAINT IF EXISTS themes_pkey;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_subtheme_id_key;
ALTER TABLE IF EXISTS ONLY public.tests DROP CONSTRAINT IF EXISTS tests_pkey;
ALTER TABLE IF EXISTS ONLY public.subthemes DROP CONSTRAINT IF EXISTS subthemes_pkey;
ALTER TABLE IF EXISTS ONLY public.subtheme_images DROP CONSTRAINT IF EXISTS subtheme_images_pkey;
ALTER TABLE IF EXISTS ONLY public.subtheme_attachments DROP CONSTRAINT IF EXISTS subtheme_attachments_pkey;
ALTER TABLE IF EXISTS ONLY public.subjects DROP CONSTRAINT IF EXISTS subjects_pkey;
ALTER TABLE IF EXISTS ONLY public.subject_students DROP CONSTRAINT IF EXISTS subject_students_pkey;
ALTER TABLE IF EXISTS ONLY public.subject_codes DROP CONSTRAINT IF EXISTS subject_codes_pkey;
ALTER TABLE IF EXISTS ONLY public.schema_migrations DROP CONSTRAINT IF EXISTS schema_migrations_pkey;
ALTER TABLE IF EXISTS ONLY public.retake_permissions DROP CONSTRAINT IF EXISTS retake_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.results DROP CONSTRAINT IF EXISTS results_pkey;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_token_hash_key;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.questions DROP CONSTRAINT IF EXISTS questions_pkey;
ALTER TABLE IF EXISTS ONLY public.positions DROP CONSTRAINT IF EXISTS positions_pkey;
ALTER TABLE IF EXISTS ONLY public.positions DROP CONSTRAINT IF EXISTS positions_name_key;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_positions;
DROP TABLE IF EXISTS public.themes;
DROP TABLE IF EXISTS public.tests;
DROP TABLE IF EXISTS public.subthemes;
DROP TABLE IF EXISTS public.subtheme_images;
DROP TABLE IF EXISTS public.subtheme_attachments;
DROP TABLE IF EXISTS public.subjects;
DROP TABLE IF EXISTS public.subject_students;
DROP TABLE IF EXISTS public.subject_codes;
DROP TABLE IF EXISTS public.schema_migrations;
DROP TABLE IF EXISTS public.retake_permissions;
DROP TABLE IF EXISTS public.results;
DROP TABLE IF EXISTS public.refresh_tokens;
DROP TABLE IF EXISTS public.questions;
DROP TABLE IF EXISTS public.positions;
DROP TABLE IF EXISTS public.notifications;
DROP FUNCTION IF EXISTS public.set_updated_at();
DROP EXTENSION IF EXISTS pgcrypto;
--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.positions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.positions OWNER TO postgres;

--
-- Name: questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    test_id uuid NOT NULL,
    type text NOT NULL,
    text text NOT NULL,
    image_path text,
    sort_order integer DEFAULT 0 NOT NULL,
    points integer DEFAULT 1 NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT questions_type_check CHECK ((type = ANY (ARRAY['single_choice'::text, 'order'::text, 'text_input'::text])))
);


ALTER TABLE public.questions OWNER TO postgres;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone
);


ALTER TABLE public.refresh_tokens OWNER TO postgres;

--
-- Name: results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    subtheme_id uuid NOT NULL,
    test_id uuid NOT NULL,
    score integer NOT NULL,
    max_score integer NOT NULL,
    percentage numeric(5,2) NOT NULL,
    grade integer,
    is_first_attempt boolean DEFAULT false NOT NULL,
    answers jsonb NOT NULL,
    completed_at timestamp with time zone DEFAULT now() NOT NULL,
    is_retake boolean DEFAULT false NOT NULL
);


ALTER TABLE public.results OWNER TO postgres;

--
-- Name: retake_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.retake_permissions (
    student_id uuid NOT NULL,
    subtheme_id uuid NOT NULL,
    granted_by uuid NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.retake_permissions OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    name text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: subject_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subject_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_id uuid NOT NULL,
    code text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subject_codes OWNER TO postgres;

--
-- Name: subject_students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subject_students (
    subject_id uuid NOT NULL,
    student_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subject_students OWNER TO postgres;

--
-- Name: subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subjects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    teacher_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    code_locked boolean DEFAULT false NOT NULL
);


ALTER TABLE public.subjects OWNER TO postgres;

--
-- Name: subtheme_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subtheme_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subtheme_id uuid NOT NULL,
    file_path text NOT NULL,
    original_name text NOT NULL,
    mime_type text NOT NULL,
    size_bytes bigint NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subtheme_attachments OWNER TO postgres;

--
-- Name: subtheme_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subtheme_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subtheme_id uuid NOT NULL,
    file_path text NOT NULL,
    caption text,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subtheme_images OWNER TO postgres;

--
-- Name: subthemes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subthemes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    theme_id uuid NOT NULL,
    title text NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    visibility text DEFAULT 'draft'::text NOT NULL,
    scheduled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    content_blocks jsonb DEFAULT '[]'::jsonb NOT NULL,
    scheduled_notified boolean DEFAULT false NOT NULL,
    CONSTRAINT subthemes_visibility_check CHECK ((visibility = ANY (ARRAY['draft'::text, 'published'::text, 'visible_locked'::text, 'scheduled'::text])))
);


ALTER TABLE public.subthemes OWNER TO postgres;

--
-- Name: tests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subtheme_id uuid NOT NULL,
    grade_thresholds jsonb DEFAULT '{"2": 0, "3": 50, "4": 70, "5": 90}'::jsonb NOT NULL,
    shuffle_questions boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    time_limit_minutes integer,
    available_from timestamp with time zone,
    available_to timestamp with time zone
);


ALTER TABLE public.tests OWNER TO postgres;

--
-- Name: themes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.themes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    sort_order integer DEFAULT 0 NOT NULL,
    visibility text DEFAULT 'draft'::text NOT NULL,
    scheduled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    scheduled_notified boolean DEFAULT false NOT NULL,
    CONSTRAINT themes_visibility_check CHECK ((visibility = ANY (ARRAY['draft'::text, 'published'::text, 'visible_locked'::text, 'scheduled'::text])))
);


ALTER TABLE public.themes OWNER TO postgres;

--
-- Name: user_positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_positions (
    user_id uuid NOT NULL,
    position_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_positions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'teacher'::text, 'student'::text])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, type, title, body, data, is_read, created_at) FROM stdin;
af5ffdba-8ead-4dcb-9a68-c1438de34f61	75a87669-7c2d-4d35-94a4-9383c0e84e5a	retake	Назначена пересдача	Можно пройти тест по теме «test1» ещё раз — результат пойдёт на оценку.	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "e392c008-4f9b-4234-abf1-47e8d009e4be"}	t	2026-06-07 08:43:59.272471+05
f70a3f0d-dc06-47f8-ba47-6805dcb32c28	b517c2a1-27a4-4c66-a270-399ec7c527a2	kicked	Вы отчислены из предмета	Преподаватель удалил вас из «Информатика». Если это ошибка — попросите новый код входа.	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352"}	t	2026-06-07 20:25:00.752402+05
02b29929-7869-443c-ad2c-d4aa6955fa72	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_theme	Новая тема	Преподаватель опубликовал тему «test1».	{"themeId": "0f83413e-a574-415c-b47b-2ea6d31aea89", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352"}	t	2026-06-07 20:37:14.899317+05
eebe7e14-d121-4b66-8dfc-baf3138b2adc	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	scheduled_published	Запланированный материал опубликован	Вышла тема «test1» по предмету «Информатика».	{"themeId": "0f83413e-a574-415c-b47b-2ea6d31aea89", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352"}	t	2026-06-07 20:37:14.888986+05
3c1ac44a-1c89-4922-8cb7-1282c1144f65	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «двоичная система счисления».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "124d7ca6-105c-4944-aea7-038f7530f3e4"}	f	2026-06-08 10:15:51.305743+05
c187f212-94f7-46b3-993e-843fa4946d82	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	test_submitted	Тест сдан студентом	Мистер студент сдал тест по «двоичная система счисления» на 3 (67%).	{"resultId": "8d27ccd4-3ceb-49a1-bd3b-2f22e1900a7d", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "124d7ca6-105c-4944-aea7-038f7530f3e4"}	f	2026-06-08 10:20:54.947435+05
bdb82106-f19a-426d-951c-58a17f2643a7	b517c2a1-27a4-4c66-a270-399ec7c527a2	retake	Назначена пересдача	Можно пройти тест по теме «двоичная система счисления» ещё раз — результат пойдёт на оценку.	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "124d7ca6-105c-4944-aea7-038f7530f3e4"}	t	2026-06-08 10:32:57.909788+05
9dfb092c-eb63-4fa4-b6ce-dba67da08fb3	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	scheduled_published	Запланированный материал опубликован	Вышла тема «массивы» по предмету «Информатика».	{"themeId": "45d1f1fe-eed0-4f1c-9fb3-066f7ef3e69a", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352"}	f	2026-06-15 20:50:53.090584+05
d3c245e1-6d97-46d1-9462-ae475513ccb1	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_theme	Новая тема	Преподаватель опубликовал тему «массивы».	{"themeId": "45d1f1fe-eed0-4f1c-9fb3-066f7ef3e69a", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352"}	f	2026-06-15 20:50:53.133671+05
9e420e4a-4d79-47c5-96c7-10b758a8f346	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «Что такое реляционная модель».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "aa9add73-d599-47c0-88c4-e3de019fc890"}	f	2026-06-16 20:39:21.530243+05
a2dd58aa-3eff-4e3b-9f82-fb41cc271bb3	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «Первичный и внешний ключи».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "76c111a0-3b18-405a-abee-0c2e71b85f62"}	f	2026-06-16 20:42:37.633292+05
43a13976-b24c-47d7-b55f-8713959fee02	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «Команда SELECT».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "c6ee65e9-515e-4777-bd17-f708b2253a12"}	f	2026-06-16 20:49:03.612588+05
ad2d6447-a4d1-49ed-97c9-2a13dde5d045	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «Операция JOIN».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "d022aa3a-eaac-4fe8-af18-34e6e705bb94"}	f	2026-06-16 20:51:02.727835+05
a8a8644b-6f14-4088-857d-78589a485ffd	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «Понятие множества и его задание».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "f1805989-6339-4674-ad24-a6047d597a51"}	f	2026-06-16 20:53:20.055318+05
b9b050dc-20cb-4e3c-a1b2-c9b9d525abe0	b517c2a1-27a4-4c66-a270-399ec7c527a2	new_subtheme	Новая лекция	Преподаватель опубликовал лекцию «Подмножество и мощность множества».	{"subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "929ffbd6-dd66-48bc-a02e-9304dcbc8669"}	f	2026-06-16 20:55:13.491689+05
5573149a-f6fd-4eee-8d05-b03466179188	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	test_submitted	Тест сдан студентом	Мистер студент сдал тест по «Первичный и внешний ключи» на 2 (33%).	{"resultId": "ca58b932-5e71-4800-a3ef-35e316dba81b", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "76c111a0-3b18-405a-abee-0c2e71b85f62"}	f	2026-06-16 20:56:52.88867+05
63098f31-eaf6-4ed2-95c5-cf60e710a25e	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	test_submitted	Тест сдан студентом	Мистер студент сдал тест по «Что такое реляционная модель» на 2 (0%).	{"resultId": "b35fc815-8908-492d-b102-47480248a77d", "subjectId": "a8fdf27a-5a9a-4bb3-a01b-583700582352", "subthemeId": "aa9add73-d599-47c0-88c4-e3de019fc890"}	f	2026-06-16 21:14:11.63664+05
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.positions (id, name, created_at) FROM stdin;
7959ff10-18bc-41b0-9de4-2e6b40f27147	Математика	2026-06-07 20:59:44.460976+05
40dac2ac-4dc9-41db-8919-c5ce1f430a8e	Информатика	2026-06-07 20:59:53.873983+05
7ff1abe1-15b7-4073-92d2-6fa6c1a1d425	Физика	2026-06-07 21:00:04.58012+05
a933edbf-d6ed-45d7-8f6c-953152c4adf0	География	2026-06-07 21:00:11.647815+05
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.questions (id, test_id, type, text, image_path, sort_order, points, payload, created_at) FROM stdin;
c8e06416-7466-469e-9c4b-023ff5a64e24	613aefc4-3f8d-4a24-b066-4f47ab7df94b	single_choice	яблоко	\N	0	1	{"options": ["да", "нет"], "correctIndex": 0}	2026-05-22 08:36:55.609293+05
66e5ea69-74cd-4879-8b4a-61be9e216f1f	613aefc4-3f8d-4a24-b066-4f47ab7df94b	text_input	как именно	\N	1	1	{"caseSensitive": false, "acceptedAnswers": ["67"]}	2026-05-22 08:36:55.609293+05
0b1d54b4-ac5c-4aca-a4d2-fe893cc3c433	8579bf54-8b18-433f-b494-ea7f4573964e	text_input	врпао	\N	0	1	{"caseSensitive": false, "acceptedAnswers": ["6"]}	2026-05-23 14:14:39.172129+05
f54cb66e-2d61-40e3-a372-833ecbabd7b6	ca40872d-7108-4fb4-be0c-d89c54eef8f2	single_choice	test1	\N	0	1	{"options": ["1", "2"], "correctIndex": 0}	2026-06-07 08:32:59.432511+05
c3055add-c24d-4e16-b4f4-4fe53a121a41	ca40872d-7108-4fb4-be0c-d89c54eef8f2	single_choice	test2	\N	1	1	{"options": ["3", "4", "5", "6"], "correctIndex": 0}	2026-06-07 08:32:59.432511+05
986a034a-1dfc-4ff0-aab8-e6c33b7820da	b4f6d233-c4d0-432c-b96f-ca9cfb734968	single_choice	1	\N	0	1	{"options": ["1", "2"], "correctIndex": 0}	2026-06-08 10:15:42.256825+05
bc39b99a-2aee-4b86-8e6d-c60044495f2d	b4f6d233-c4d0-432c-b96f-ca9cfb734968	order	2	\N	1	1	{"items": ["1", "2", "3", "4"]}	2026-06-08 10:15:42.256825+05
c47546c2-620e-4469-ad45-9a2febb1821e	b4f6d233-c4d0-432c-b96f-ca9cfb734968	text_input	2+2 = ?	\N	2	1	{"caseSensitive": false, "acceptedAnswers": ["4", "четыре"]}	2026-06-08 10:15:42.256825+05
f43840f4-140e-4371-8798-88c3a20d3526	07b2be2a-5818-4dfd-aed6-c3051e0e143f	single_choice	Какое из утверждений о первичном ключе НЕВЕРНО?	\N	0	1	{"options": ["Должен быть уникальным", "Не может быть NULL", "Может содержать только числовые значения ← правильный (это и есть «неверно»)", "Идентифицирует каждую запись"], "correctIndex": 2}	2026-06-16 20:42:34.953402+05
9586b112-9724-49b3-9f8d-cef513931f97	07b2be2a-5818-4dfd-aed6-c3051e0e143f	order	Расположите этапы создания связи между таблицами в правильном порядке:	\N	1	1	{"items": ["Создать таблицу с первичным ключом", "Создать таблицу с полем под внешний ключ", "Указать REFERENCES на первичный ключ родительской таблицы", "Проверить целостность через тестовый INSERT"]}	2026-06-16 20:42:34.953402+05
6cfff2cf-9a87-4992-a25d-859dd4148940	07b2be2a-5818-4dfd-aed6-c3051e0e143f	text_input	Как называется поле, ссылающееся на первичный ключ другой таблицы?	\N	2	1	{"caseSensitive": false, "acceptedAnswers": ["внешний ключ", "foreign key", "FOREIGN KEY"]}	2026-06-16 20:42:34.953402+05
d5c84b1d-12ed-4ee3-bc6f-fa1c2c02fb53	3d0ca9a8-e281-48d9-b804-01e9a837ba1b	single_choice	Какая команда SQL используется для выборки данных?	\N	0	1	{"options": ["INSERT", "SELECT ", "UPDATE", "DELETE"], "correctIndex": 1}	2026-06-16 20:48:58.779177+05
cbe68b8d-8c58-4b4e-a268-5babe11d5a3b	3d0ca9a8-e281-48d9-b804-01e9a837ba1b	single_choice	Что делает оператор ORDER BY?	\N	1	1	{"options": ["Удаляет дубликаты", "Сортирует результат", "Группирует строки", "Ограничивает количество строк"], "correctIndex": 1}	2026-06-16 20:48:58.779177+05
dac3f3ae-a8fb-4eca-a16a-102f3664c156	3d0ca9a8-e281-48d9-b804-01e9a837ba1b	text_input	Какое ключевое слово используется для ограничения количества возвращаемых строк?	\N	2	1	{"caseSensitive": false, "acceptedAnswers": ["LIMIT", "limit"]}	2026-06-16 20:48:58.779177+05
bad790df-a770-4f01-a0e3-f7b456a1f970	3d1167dd-711e-484c-b7bb-f4c0ae0f3f7e	single_choice	Какой JOIN вернёт только те записи, для которых есть совпадение в обеих таблицах?»	\N	0	1	{"options": ["INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL OUTER JOIN"], "correctIndex": 0}	2026-06-16 20:50:57.331328+05
e8c0b8ee-f60b-4cf9-bbd1-742d29d5d96d	3d1167dd-711e-484c-b7bb-f4c0ae0f3f7e	order	Расположите типы JOIN от наименее к наиболее «инклюзивному»:	\N	1	1	{"items": ["INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL OUTER JOIN"]}	2026-06-16 20:50:57.331328+05
f7bffdb3-749b-46b4-9400-58c66bffee9b	9b5195ec-6ff5-4df9-be88-0cc5a9a10430	single_choice	«Если A = {1, 2, 3} и B = {2, 3, 4}, то чему равно A ∩ B?	\N	0	1	{"options": ["{1, 2, 3, 4}", "{2, 3}", "{1, 4}", "{1}"], "correctIndex": 1}	2026-06-16 20:53:17.408954+05
05b812f2-162f-4ef4-b6e8-105dc59700af	9b5195ec-6ff5-4df9-be88-0cc5a9a10430	single_choice	Какой знак обозначает объединение множеств?	\N	1	1	{"options": ["∩", "∪", "⊂", "∅"], "correctIndex": 0}	2026-06-16 20:53:17.408954+05
f67b4f37-f8e0-4d14-9c89-ecae654d391d	9b5195ec-6ff5-4df9-be88-0cc5a9a10430	text_input	Как называется множество, не содержащее ни одного элемента?	\N	2	1	{"caseSensitive": false, "acceptedAnswers": ["пустое", "пустое множество", "empty"]}	2026-06-16 20:53:17.408954+05
ba257761-73ff-4d9c-8f4f-4c7c21b1cf85	3f525a60-c6b2-4609-b35d-e393d0aedcb6	single_choice	Сколько подмножеств у множества {a, b, c, d}?	\N	0	1	{"options": ["4", "8", "16", "24"], "correctIndex": 2}	2026-06-16 20:55:10.480451+05
39dc16de-e8c4-4925-b349-fb02942c2354	3f525a60-c6b2-4609-b35d-e393d0aedcb6	single_choice	Какое из утверждений ВЕРНО?	\N	1	1	{"options": ["Пустое множество не является подмножеством никакого множества", "Пустое множество является подмножеством любого множества", "Пустое множество не имеет мощности", "Мощность пустого множества равна 1"], "correctIndex": 0}	2026-06-16 20:55:10.480451+05
69306018-90a1-46ca-9772-9b0b57e4c2e1	20900c21-d24e-418a-9a8b-632eb6c7267e	single_choice	Кто является автором реляционной модели данных?	\N	0	1	{"options": ["Алан Тьюринг", "Эдгар Кодд", "Линус Торвальдс", "Тим Бернерс-Ли"], "correctIndex": 0}	2026-06-16 21:30:44.547277+05
df9c9924-2f8b-4d32-a7c5-a7640321b7c9	20900c21-d24e-418a-9a8b-632eb6c7267e	single_choice	Как в реляционной модели называется строка таблицы?	\N	1	1	{"options": ["Атрибут", "Домен", "Кортеж", "Отношение"], "correctIndex": 2}	2026-06-16 21:30:44.547277+05
29bdf223-9f4b-47d2-8620-01ef62380690	20900c21-d24e-418a-9a8b-632eb6c7267e	text_input	В каком году Эдгар Кодд предложил реляционную модель?	\N	2	1	{"caseSensitive": false, "acceptedAnswers": ["1970", "1970 г.", "1970 году"]}	2026-06-16 21:30:44.547277+05
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, user_id, token_hash, expires_at, created_at, revoked_at) FROM stdin;
a95961cb-0b07-4b10-a18a-e42ad046187d	72222070-f1aa-4820-8028-3f139f8e7126	52bef0d8365730cadff82b8b3c3ea8dec14de20d1868f6e94feb93004f3f00c3	2026-06-21 05:27:57.578253+05	2026-05-22 05:27:57.580082+05	\N
916edbc2-9fe9-4529-b58f-dcae8a2df70d	72222070-f1aa-4820-8028-3f139f8e7126	721d2f241f68493b4189f7102835b4c758c3fe32fd68618db159524f0e46a18b	2026-06-21 05:28:18.431621+05	2026-05-22 05:28:18.432526+05	\N
cb1f8afe-d669-4a8f-9111-5d2cb1300845	72222070-f1aa-4820-8028-3f139f8e7126	8cd23a4b7755ea60773d49a91fce6107a3b233d2557fba5662cb02c1f3cfb4d6	2026-06-21 05:30:43.796721+05	2026-05-22 05:30:43.797742+05	\N
be81ea2c-a560-46fb-a381-0a14966d404a	72222070-f1aa-4820-8028-3f139f8e7126	1eceda18529d96ca37039085547822f3ebc4295368cba077f58ced4fb8107f34	2026-06-21 05:32:14.952526+05	2026-05-22 05:32:14.953576+05	2026-05-22 07:04:06.925885+05
88711918-b928-442b-a356-bec1d1c83f01	72222070-f1aa-4820-8028-3f139f8e7126	76206d8ed8e56acbe9d8584da34500e4cb82c3d10f9cf5db8dbf665102f0f75a	2026-06-21 07:04:06.92989+05	2026-05-22 07:04:06.931296+05	\N
2d33b44a-b56d-49b3-8756-31c3091dd666	72222070-f1aa-4820-8028-3f139f8e7126	6671ad5a6c6c28eeaedd22a7ba19e29c7c3a34bf948d8213e563fdfd5840759e	2026-06-21 07:12:47.772866+05	2026-05-22 07:12:47.77653+05	\N
b07b8e63-e56d-4108-9ce6-57659094d847	b517c2a1-27a4-4c66-a270-399ec7c527a2	fb77eeaf0c25a89b191c383d2cb25ec85ae1ae0c9fd31ec4d5cf761a3b563143	2026-06-21 07:13:58.960804+05	2026-05-22 07:13:58.963465+05	\N
4122c0ee-23a2-42e6-841b-64e993fbcb5c	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	f3699e89eb4d8460beffbda59a619d10924376dd4150ae19a34253e6f2c922ca	2026-06-21 07:36:38.890358+05	2026-05-22 07:36:38.890919+05	\N
9fa7948e-f5e1-4e7e-afbd-bf46dfecdf3e	72222070-f1aa-4820-8028-3f139f8e7126	3c3794daab91b014e987533e28aa6ea49f3b03dc56f21e9924d81fe48dc9814b	2026-06-21 07:37:29.745741+05	2026-05-22 07:37:29.746303+05	\N
d09c438e-56ac-40be-8350-30622dcf6899	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	8fc3a2f35a7d4c704955c282c8f141c7f75455e92d2ef9633fbe608d14d0c302	2026-06-21 07:38:24.13503+05	2026-05-22 07:38:24.135958+05	\N
7730ee1b-2708-4b34-9c7e-c72e4102f290	b517c2a1-27a4-4c66-a270-399ec7c527a2	5457af3b7ae98016c675753920749ef8b97620e4e84dd6c0e78b4e9f64d75417	2026-06-21 07:39:05.544575+05	2026-05-22 07:39:05.545228+05	2026-05-23 01:08:49.294369+05
b45e903d-142d-484a-b5bf-256cac1fdd7e	b517c2a1-27a4-4c66-a270-399ec7c527a2	bb1266ce8705fc1cbe892c4bc9fa6b55363a64aba73d2ad45d7135ee118ac172	2026-06-22 01:08:49.303272+05	2026-05-23 01:08:49.307301+05	\N
f052d6af-9e81-42b9-82c3-5766bd558327	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	e5606a2654bdd45ad00b422399afd223d34a233ea71095b56d0d95088477966a	2026-06-22 01:09:21.559324+05	2026-05-23 01:09:21.561216+05	\N
94692c8b-1b11-40d5-9355-fdd8e4c89364	72222070-f1aa-4820-8028-3f139f8e7126	7b79934c9bbec1ba5caab4320d59bac4224bd109d3603b1ea79836d2502a5052	2026-06-22 01:11:05.908636+05	2026-05-23 01:11:05.90949+05	2026-05-23 09:38:40.456961+05
a371ca3d-0b44-4774-9f95-7e484cb9d401	72222070-f1aa-4820-8028-3f139f8e7126	669fd8652e5b1d6c40b5d1c14f5fb1dffed4d54e1933112e9c4dd6099f14f291	2026-06-22 09:38:40.461725+05	2026-05-23 09:38:40.463909+05	\N
e6547f43-6db2-44c5-ba23-d766415a2184	b517c2a1-27a4-4c66-a270-399ec7c527a2	c35f48d9b1db508348a1c22175064a84ef4e38d810c2f98eeeb3e798818cbb11	2026-06-21 08:32:49.083934+05	2026-05-22 08:32:49.084705+05	2026-05-23 09:40:23.134644+05
cdc2c917-bd42-4728-baa9-b48984b87076	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	01622ec19b5fd4559a7819445801ef69759357b3347cf703ac5a36053d1768e8	2026-06-21 08:33:03.327493+05	2026-05-22 08:33:03.328133+05	2026-05-23 09:40:27.219306+05
e4728b30-f628-4f22-b9e2-d75846ab7f62	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	f159c235a2b424a5c180e9f76df8e6c8a6ab8b23e96a0eb911f8da7e1e5cad05	2026-06-22 09:40:27.227843+05	2026-05-23 09:40:27.22931+05	2026-05-23 13:55:52.898165+05
875de898-a17a-42a2-add9-9fa2ec1dd8bf	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	d0675deb19796dfe3a1d2175a6b2aa8c2fce8e8ba9543af3fb88fc879b1b5336	2026-06-22 13:55:52.903631+05	2026-05-23 13:55:52.905853+05	\N
64e47261-b121-4343-b34a-dde7d92946eb	b517c2a1-27a4-4c66-a270-399ec7c527a2	0d3e5a089b3767b023d85604eee9083d0bd34f7130351f16f72474896eb9f8c7	2026-06-22 09:40:23.153789+05	2026-05-23 09:40:23.169501+05	2026-05-23 13:56:46.410313+05
92ecc584-b869-4857-bcbe-56d0c2c9553c	b517c2a1-27a4-4c66-a270-399ec7c527a2	1e482dd4a5c94c89a1dd6c94dce0a2093728494c933f8c55353f559829864193	2026-06-22 13:56:46.412352+05	2026-05-23 13:56:46.414135+05	\N
4d9aae0a-920a-4e20-8bf0-d8c6e62b1062	72222070-f1aa-4820-8028-3f139f8e7126	e075b30d51d8b945bc78a288d53c21a6756229327460d2ec4bd569b570a6aacf	2026-06-22 14:17:35.478944+05	2026-05-23 14:17:35.480938+05	\N
3086d8af-94d4-4539-9b80-8c9254c87893	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	bb07f5944daaa3e58395d09b64eb346b597885376efb69a4807ca15b4c000191	2026-07-07 20:17:25.410904+05	2026-06-07 20:17:25.412233+05	2026-06-07 21:17:54.647301+05
20bdb7bf-886f-4b7e-9542-777662852c75	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	24327130149027bc48dcc16018602e3df6f9b47f4dc200896fef252ae2b39a97	2026-06-22 14:19:04.014508+05	2026-05-23 14:19:04.016188+05	2026-05-26 12:24:17.02329+05
44562ca5-14ad-4c20-86ef-95439421ac68	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	1bc7f291d58942cd07b8637871dadf1d012412d7a2713ff9e03ccda7fb13e3e3	2026-06-25 12:24:17.027705+05	2026-05-26 12:24:17.03471+05	\N
ebc9932b-2515-49df-bf26-81f6a83bb810	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	531443e893d73ae56e8b442f1d79166611654f5a0a12cf1f667673aab6d80e47	2026-06-25 12:24:17.030853+05	2026-05-26 12:24:17.038298+05	\N
cd0180dd-e264-485e-ad7d-5306b40f5ac8	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	e3ec727eb9d3ccee213f3b51e8ad9ff583f48cc2d1b8627a0d7ea008ab28dae2	2026-06-22 13:59:59.763567+05	2026-05-23 13:59:59.764668+05	2026-06-07 06:02:38.30937+05
9b13a121-6f4f-4d6f-aed0-a838b9d3b8c7	75a87669-7c2d-4d35-94a4-9383c0e84e5a	6fd0decd1ddd91ebcc057bdadcb6a57c7b4b57d15e958012cc61bd684028cf50	2026-06-22 14:15:46.814002+05	2026-05-23 14:15:46.81561+05	2026-06-07 06:04:36.716434+05
cac5e1b5-e38c-4547-978f-d834abad2d75	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	5184eb936c949b2f8caf6a843c682334e6087b1bcda2af6bea91bb6028906699	2026-07-07 06:02:38.318685+05	2026-06-07 06:02:38.32109+05	2026-06-07 08:31:38.753509+05
acc7f799-4020-4c52-ac07-10a3eb9e90ec	75a87669-7c2d-4d35-94a4-9383c0e84e5a	c5d29dc40adb0888908f5644272cc6de57cce706221d14be990969c07dbc6f64	2026-07-07 06:04:36.720675+05	2026-06-07 06:04:36.722387+05	2026-06-07 08:31:56.722083+05
2f7649ff-a6da-43fc-86b0-05b2f99ff352	75a87669-7c2d-4d35-94a4-9383c0e84e5a	e901afbe0e259c420bc3df51159f140bf42d00c62a6a57fd8c5cce2a42fa51d2	2026-07-07 08:31:56.731627+05	2026-06-07 08:31:56.733446+05	2026-06-07 20:17:14.889395+05
dbe9dbd0-4fb1-4149-b123-99c4f43040c9	75a87669-7c2d-4d35-94a4-9383c0e84e5a	42bbf213891136e2a30cf31034849c56604786d6db63aab46e1d9dc1b809d842	2026-07-07 20:17:14.896026+05	2026-06-07 20:17:14.898835+05	\N
43ef1886-0a6a-4b74-98d5-3ce06e857e73	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	d3c3023030931652680da35cc002d8c576a025d8b2391f50da9e990ff191ab54	2026-07-07 08:31:38.764062+05	2026-06-07 08:31:38.768745+05	2026-06-07 20:17:25.406675+05
6ca668f1-d108-4c9b-ba80-54081dbdead8	b517c2a1-27a4-4c66-a270-399ec7c527a2	b5f4c47dca8ff880337bb23cf97683667c9d61e97757a29067eced618a0fa30d	2026-07-07 20:24:13.664446+05	2026-06-07 20:24:13.66679+05	\N
9fde6b73-c889-4a95-a708-db75f19df6cf	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	763238648397cc60c0afe66dacf8e0f174981a593318c9881d6c690a6d96cb3e	2026-07-07 20:34:11.481292+05	2026-06-07 20:34:11.483762+05	\N
44700af8-1198-4525-8e5d-774c096c3301	72222070-f1aa-4820-8028-3f139f8e7126	b2f9dd7f058efc84f5d5135ed4faf8beb316c88450dc139abf186d4be244db86	2026-07-07 20:59:24.082449+05	2026-06-07 20:59:24.085437+05	2026-06-08 10:03:28.138332+05
66d8fa29-5c28-4b0f-bb84-4b9917013172	72222070-f1aa-4820-8028-3f139f8e7126	d012dc77d5bdc12df4d6b3f64b1401a878b95781303566c939e53ca0932bea29	2026-07-08 10:03:28.143324+05	2026-06-08 10:03:28.145541+05	\N
dcc10047-d4ba-4f30-aab8-424d9812ef05	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	5504f4b4ba9bdc6d2d3bd42d52e16363a5cf70d90d958939b903dc26996b64b7	2026-07-07 21:17:54.654958+05	2026-06-07 21:17:54.656494+05	2026-06-08 10:03:47.518889+05
69ec3fc9-832c-45d8-b0c5-3322b7aadb82	b517c2a1-27a4-4c66-a270-399ec7c527a2	a82d30a46668e48db5abed1be903d89e75c60a7cfc1d34180130408a97f5fb5b	2026-07-07 20:36:36.812005+05	2026-06-07 20:36:36.812504+05	2026-06-08 10:04:30.9649+05
e43e0978-f421-475f-98ad-2de1c01e4a18	b517c2a1-27a4-4c66-a270-399ec7c527a2	5ca98b54fe2154af967d38584a5e4016593e62c4ad7cccb94cce032dccca62b9	2026-07-08 10:04:30.967155+05	2026-06-08 10:04:30.968478+05	\N
ca80dcc3-cc84-4d12-b9f1-ab323c456647	72222070-f1aa-4820-8028-3f139f8e7126	f642f0b8435aa0d6571b49d7d84c29480a16d4d53e8eb24b120f159d66ae1b0f	2026-07-08 10:05:36.310748+05	2026-06-08 10:05:36.312729+05	\N
1893fb20-e8c5-4faf-af32-fb2d2e05f09a	b517c2a1-27a4-4c66-a270-399ec7c527a2	4b3fe13f3d4b6ea89a02fede6f01ee47b8a230de6ce03453662f3f865127b9d1	2026-07-08 10:25:10.917619+05	2026-06-08 10:25:10.91892+05	2026-06-08 21:21:48.280705+05
a38bcf15-e1d8-4017-b19f-75b539a98e47	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	d79c486c93fb8c4234465ac4858b0254f17c45abfa0ef50cdb45066f49a2a168	2026-07-08 10:03:47.535226+05	2026-06-08 10:03:47.536281+05	2026-06-08 21:21:54.922381+05
eb3f6c18-f2b6-44da-8c5b-cc53067370e3	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	c6bbe2651bbd49a06ee8c80e0acddd133c36293f17aff40d4178cbf7c3c6475c	2026-07-08 21:21:54.936433+05	2026-06-08 21:21:54.937815+05	\N
80067746-d348-431f-beaa-7b64ac85b3b1	b517c2a1-27a4-4c66-a270-399ec7c527a2	f8d8c4165438c9c22847ee826a49f451d62edd75d90be4b3553a71ab377ed656	2026-07-08 21:33:08.96061+05	2026-06-08 21:33:08.962289+05	\N
dac5db4e-52c7-4c1f-90b5-3607fa93df92	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	ba3335463f3817b2e07b402070c76b5a559370ee4b8b43662cf42286594b6b09	2026-07-08 21:36:19.980717+05	2026-06-08 21:36:19.981598+05	\N
ef47d97b-885a-402f-aa2f-72754ed07fda	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	2eea54b644614a564395ea3639f0d4ea7bb0551b6ecce0df0bd29b0030db41b7	2026-07-08 23:37:59.759403+05	2026-06-08 23:37:59.760229+05	\N
4dbb91eb-7eb7-4e59-b995-54e0a142152d	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	f1a57c2b254ba3e08cdda1b89dc065d71271615dd960385c711bae906e8d9dd3	2026-07-08 23:46:26.808321+05	2026-06-08 23:46:26.810777+05	\N
c90b9855-4e27-4855-b642-e7df192b6d66	72222070-f1aa-4820-8028-3f139f8e7126	73a453525fab6fb58ea42854ed18a61983a950736e95c6fc405c12c7b074dce3	2026-07-09 00:17:39.589477+05	2026-06-09 00:17:39.590549+05	\N
f7224796-9f35-44ae-85fd-45730bc5a856	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	d29206458fb1ddfbd986cc31a442ea89e184eaa9869e5fbe0da9801c75a51baa	2026-07-09 00:28:28.967285+05	2026-06-09 00:28:28.968218+05	\N
bac83a7e-b9e7-44f2-9c4c-73b1ed194594	b517c2a1-27a4-4c66-a270-399ec7c527a2	1a5b4d0d40c99658113c6a7348f81049d620beb0d924294c26ddd29b7d767349	2026-07-08 21:21:48.28223+05	2026-06-08 21:21:48.282979+05	2026-06-09 13:16:00.562909+05
8c0d5073-a1f0-4ab9-a8fd-18319d5600ba	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	7046f8af18f69ffb5fd3614db569c2aac5fbba8555bcb0dee1e11aebcfa4f519	2026-06-25 12:24:17.033632+05	2026-05-26 12:24:17.042962+05	2026-06-16 15:38:00.177262+05
ba90eafe-92f9-4e21-873b-eebc1685caa5	b517c2a1-27a4-4c66-a270-399ec7c527a2	d595aacaab21f669eb981f1ce4476e9af4ec9b2cbc1656ac4b6e12f37fc182f6	2026-07-09 00:36:43.234477+05	2026-06-09 00:36:43.235046+05	\N
a204c60d-d2eb-46e7-8396-04c3bda17be8	b517c2a1-27a4-4c66-a270-399ec7c527a2	329b7d19b3849cfbfb76a1fa7848de649e1dd506f9612f1f2f7442f88a03e9de	2026-07-09 02:49:15.016271+05	2026-06-09 02:49:15.017273+05	\N
43731cc8-a2f3-4003-b815-da09166562f8	b517c2a1-27a4-4c66-a270-399ec7c527a2	4f6c60d0304328b920a85de7695fdbd84fd1f627e3696000bd2f1007d7e9c1c8	2026-07-09 02:53:11.218742+05	2026-06-09 02:53:11.219914+05	\N
e6e50320-8324-4946-9a1e-a62dbd3430a2	72222070-f1aa-4820-8028-3f139f8e7126	f5a0496ab26663f8355999c55a46b715b482c6f6c21a2e3999b38ae346acb966	2026-07-09 03:23:52.780657+05	2026-06-09 03:23:52.781754+05	\N
dc94a873-607e-4781-9301-b9b001136767	72222070-f1aa-4820-8028-3f139f8e7126	8cd40dc53288e33d92684328ba0b5cd676023c8c467cc9182c44cf1f7052c0a2	2026-07-09 03:26:15.178423+05	2026-06-09 03:26:15.17944+05	\N
53132493-3c75-47ce-ba1c-cab91ae0d600	b517c2a1-27a4-4c66-a270-399ec7c527a2	a38732f812d111cf9c62e779b6909f2137f9615b57119b5ea7e4f281e500468c	2026-07-09 03:38:17.260972+05	2026-06-09 03:38:17.262588+05	\N
02c31dcb-bc75-4876-811e-83f8dd5ce556	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	9592cf7933228524c1e84e142e3f7b4970d353bcfdc2040d3f6bc811f783c30c	2026-07-09 03:27:51.967268+05	2026-06-09 03:27:51.968587+05	2026-06-09 13:07:50.503353+05
57924b32-11a6-4664-9e87-aebdd2a3134e	b517c2a1-27a4-4c66-a270-399ec7c527a2	9a7150768a77fafe5927dd5f143a883520aa38d37b7023f340dd4fe056e766db	2026-07-09 13:16:00.566014+05	2026-06-09 13:16:00.566644+05	\N
39eecb2b-0fe0-4624-8956-f6c15fecfe0b	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	9320bc90a081e20a12512b20cb5352c4ddb8c020fbd602ecb1bd781262edf4a6	2026-07-09 13:07:50.505431+05	2026-06-09 13:07:50.507282+05	2026-06-09 23:52:46.408603+05
a764dccb-0128-433e-bbc0-7f07c54d9013	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	a9ce9d3c7cc149441b9b72cc577bdfb9b0dbe5475b2df3f9848f3a6871e017f4	2026-07-09 23:52:46.411379+05	2026-06-09 23:52:46.412116+05	2026-06-16 15:18:29.585059+05
619a16d0-09ad-45f0-813d-058d0a98cd9d	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	4df9bccdac2fdc5c5b7a8838aae56b16a6ac2ad6f43b593a8876c65018473b8a	2026-07-16 15:18:29.597603+05	2026-06-16 15:18:29.598751+05	\N
0e760bd7-e19b-424b-b01b-e58ca4aa8bb9	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	3782ddff05d51e947e8424f829ab50765e80377a080df6c5672db046192ca1b1	2026-07-16 15:36:05.588546+05	2026-06-16 15:36:05.590895+05	\N
2e607b2c-9223-4271-b7de-88923f61cfe8	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	54b2894086757d8fd2b2eee393bb13e1e12ddf0d1498d0394e4c398bd1c4f242	2026-07-16 15:38:00.181235+05	2026-06-16 15:38:00.183802+05	\N
1730557f-bdfd-4512-ba75-67902ba22a8d	b517c2a1-27a4-4c66-a270-399ec7c527a2	84c03cfca9d1c4750e18d860a010e5b4e168364d73e03b571be4d93099b6d0b2	2026-07-16 15:44:20.030821+05	2026-06-16 15:44:20.031997+05	2026-06-16 20:34:33.962138+05
a39a2388-91fa-436e-bf73-4a1062e9c797	b517c2a1-27a4-4c66-a270-399ec7c527a2	26f3853f98e63f873377ba375e8ad9befd2882ebb0498fb95b3b8dfdfc91ab74	2026-07-16 20:34:33.965723+05	2026-06-16 20:34:33.966447+05	\N
2b579076-ee88-443f-a2cc-517ea27f4d1e	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	76750f2738a7f5cffed47860f72464f9a4266d984e7174bec019a8c0e76b73cb	2026-07-16 20:35:15.26718+05	2026-06-16 20:35:15.268349+05	\N
1e271410-48cf-45f9-8437-b1fa8d7224f7	b517c2a1-27a4-4c66-a270-399ec7c527a2	4d6064006924ccfc8ef0342d556d408abecefb77a419b2bd20f67953aecf5f8e	2026-07-16 20:55:35.872986+05	2026-06-16 20:55:35.873524+05	\N
a0b9e5b9-84ff-4a25-b95e-5067831ffb9f	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	72a625b8759a63b698720c755a5dd4e74b945aa95aedccbd7c4f73dbdf2bfdad	2026-07-16 20:57:28.674923+05	2026-06-16 20:57:28.676159+05	\N
a82918bc-0e99-458d-961b-fb1a91893c9b	b517c2a1-27a4-4c66-a270-399ec7c527a2	5506eedb8f3c85828ba8c24d1e84ceff2be6fb0298d5ea0e48c5325f886d8d6b	2026-07-16 21:13:59.744057+05	2026-06-16 21:13:59.745635+05	\N
4db60af7-cf9b-4b0d-bbea-b1ad94e5b93e	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	d712e516de40f827460e7b40293aeb2886abdaada9ba86f9bfa5baf77d448000	2026-07-16 21:30:19.844652+05	2026-06-16 21:30:19.84647+05	\N
e117c25f-26aa-4c53-9901-7e6c2d011965	b517c2a1-27a4-4c66-a270-399ec7c527a2	d5621fe60287f91d835b5d2b07a9b70d19ae7f42d23a1c318f9dfbfee4991423	2026-07-16 21:30:54.674885+05	2026-06-16 21:30:54.675659+05	2026-06-16 23:52:32.614392+05
ff1fc6cc-b548-4009-bac8-e3690695acc8	b517c2a1-27a4-4c66-a270-399ec7c527a2	700717a6c7f74dc72f6c0c2b655e4151c22927d7a4ad47d3900c50a80061f0ff	2026-07-16 23:52:32.628429+05	2026-06-16 23:52:32.63113+05	\N
\.


--
-- Data for Name: results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.results (id, student_id, subtheme_id, test_id, score, max_score, percentage, grade, is_first_attempt, answers, completed_at, is_retake) FROM stdin;
96d88e81-3856-4b7b-8400-339d7adba46d	b517c2a1-27a4-4c66-a270-399ec7c527a2	34d97a5b-3e52-409b-b479-735e6bb871a6	613aefc4-3f8d-4a24-b066-4f47ab7df94b	1	2	50.00	3	t	{"66e5ea69-74cd-4879-8b4a-61be9e216f1f": {"text": "67"}, "c8e06416-7466-469e-9c4b-023ff5a64e24": {"selectedIndex": 1}}	2026-05-22 08:37:52.468344+05	f
0f98b6c4-f5b8-45cf-8061-529ee9c4e9e6	b517c2a1-27a4-4c66-a270-399ec7c527a2	34d97a5b-3e52-409b-b479-735e6bb871a6	613aefc4-3f8d-4a24-b066-4f47ab7df94b	2	2	100.00	5	f	{"66e5ea69-74cd-4879-8b4a-61be9e216f1f": {"text": "67"}, "c8e06416-7466-469e-9c4b-023ff5a64e24": {"selectedIndex": 0}}	2026-05-22 08:38:05.263266+05	f
fd7ab6ac-a670-4785-9b0d-3c6ea01de838	b517c2a1-27a4-4c66-a270-399ec7c527a2	34d97a5b-3e52-409b-b479-735e6bb871a6	613aefc4-3f8d-4a24-b066-4f47ab7df94b	1	2	50.00	3	f	{"66e5ea69-74cd-4879-8b4a-61be9e216f1f": {"text": "67"}, "c8e06416-7466-469e-9c4b-023ff5a64e24": {"selectedIndex": 1}}	2026-05-23 09:40:52.061379+05	f
31ae4cb2-0fe6-4e3d-a6b0-c24ca34c970f	75a87669-7c2d-4d35-94a4-9383c0e84e5a	34d97a5b-3e52-409b-b479-735e6bb871a6	613aefc4-3f8d-4a24-b066-4f47ab7df94b	1	2	50.00	3	t	{"66e5ea69-74cd-4879-8b4a-61be9e216f1f": {"text": "8"}, "c8e06416-7466-469e-9c4b-023ff5a64e24": {"selectedIndex": 0}}	2026-05-23 14:16:22.264134+05	f
9d57d8a6-c73c-4a52-9e5f-6417170063b6	75a87669-7c2d-4d35-94a4-9383c0e84e5a	e392c008-4f9b-4234-abf1-47e8d009e4be	ca40872d-7108-4fb4-be0c-d89c54eef8f2	1	2	50.00	3	t	{"c3055add-c24d-4e16-b4f4-4fe53a121a41": {"selectedIndex": 1}, "f54cb66e-2d61-40e3-a372-833ecbabd7b6": {"selectedIndex": 0}}	2026-06-07 08:33:22.456022+05	f
fdbb7a5e-4b55-4e6a-8082-eff9a312ecc4	75a87669-7c2d-4d35-94a4-9383c0e84e5a	e392c008-4f9b-4234-abf1-47e8d009e4be	ca40872d-7108-4fb4-be0c-d89c54eef8f2	2	2	100.00	\N	f	{"c3055add-c24d-4e16-b4f4-4fe53a121a41": {"selectedIndex": 0}, "f54cb66e-2d61-40e3-a372-833ecbabd7b6": {"selectedIndex": 0}}	2026-06-07 08:33:30.665804+05	f
e63473f9-28e8-4b24-ba7e-eb30d8f8f681	75a87669-7c2d-4d35-94a4-9383c0e84e5a	e392c008-4f9b-4234-abf1-47e8d009e4be	ca40872d-7108-4fb4-be0c-d89c54eef8f2	2	2	100.00	5	f	{"c3055add-c24d-4e16-b4f4-4fe53a121a41": {"selectedIndex": 0}, "f54cb66e-2d61-40e3-a372-833ecbabd7b6": {"selectedIndex": 0}}	2026-06-07 08:34:12.074744+05	t
2e438ef1-712e-4612-8c7c-dd5880906a4a	75a87669-7c2d-4d35-94a4-9383c0e84e5a	e392c008-4f9b-4234-abf1-47e8d009e4be	ca40872d-7108-4fb4-be0c-d89c54eef8f2	1	2	50.00	3	f	{"c3055add-c24d-4e16-b4f4-4fe53a121a41": {"selectedIndex": 2}, "f54cb66e-2d61-40e3-a372-833ecbabd7b6": {"selectedIndex": 0}}	2026-06-07 08:44:09.653739+05	t
8d27ccd4-3ceb-49a1-bd3b-2f22e1900a7d	b517c2a1-27a4-4c66-a270-399ec7c527a2	124d7ca6-105c-4944-aea7-038f7530f3e4	b4f6d233-c4d0-432c-b96f-ca9cfb734968	2	3	66.67	3	t	{"986a034a-1dfc-4ff0-aab8-e6c33b7820da": {"selectedIndex": 1}, "bc39b99a-2aee-4b86-8e6d-c60044495f2d": {"order": ["1", "2", "3", "4"]}, "c47546c2-620e-4469-ad45-9a2febb1821e": {"text": "4"}}	2026-06-08 10:20:54.937933+05	f
cc2b9053-6f2c-46e6-a7e6-a8a347cbaa11	b517c2a1-27a4-4c66-a270-399ec7c527a2	124d7ca6-105c-4944-aea7-038f7530f3e4	b4f6d233-c4d0-432c-b96f-ca9cfb734968	1	3	33.33	\N	f	{"986a034a-1dfc-4ff0-aab8-e6c33b7820da": {"selectedIndex": 0}, "bc39b99a-2aee-4b86-8e6d-c60044495f2d": {"order": ["4", "1", "2", "3"]}, "c47546c2-620e-4469-ad45-9a2febb1821e": {"text": "8"}}	2026-06-08 10:30:54.695214+05	f
b134d03d-5aaa-4b6b-9dad-8cd3a7453071	b517c2a1-27a4-4c66-a270-399ec7c527a2	124d7ca6-105c-4944-aea7-038f7530f3e4	b4f6d233-c4d0-432c-b96f-ca9cfb734968	1	3	33.33	2	f	{"986a034a-1dfc-4ff0-aab8-e6c33b7820da": {"selectedIndex": 0}, "bc39b99a-2aee-4b86-8e6d-c60044495f2d": {"order": ["3", "2", "1", "4"]}, "c47546c2-620e-4469-ad45-9a2febb1821e": {"text": "9"}}	2026-06-08 10:33:20.281983+05	t
ca58b932-5e71-4800-a3ef-35e316dba81b	b517c2a1-27a4-4c66-a270-399ec7c527a2	76c111a0-3b18-405a-abee-0c2e71b85f62	07b2be2a-5818-4dfd-aed6-c3051e0e143f	1	3	33.33	2	t	{"6cfff2cf-9a87-4992-a25d-859dd4148940": {"text": "select"}, "9586b112-9724-49b3-9f8d-cef513931f97": {"order": ["Создать таблицу с первичным ключом", "Создать таблицу с полем под внешний ключ", "Указать REFERENCES на первичный ключ родительской таблицы", "Проверить целостность через тестовый INSERT"]}, "f43840f4-140e-4371-8798-88c3a20d3526": {"selectedIndex": 1}}	2026-06-16 20:56:52.885886+05	f
37a489ed-07c4-407c-ac7b-7052468ef70b	b517c2a1-27a4-4c66-a270-399ec7c527a2	76c111a0-3b18-405a-abee-0c2e71b85f62	07b2be2a-5818-4dfd-aed6-c3051e0e143f	0	3	0.00	\N	f	{"9586b112-9724-49b3-9f8d-cef513931f97": {"order": ["Создать таблицу с полем под внешний ключ", "Создать таблицу с первичным ключом", "Указать REFERENCES на первичный ключ родительской таблицы", "Проверить целостность через тестовый INSERT"]}}	2026-06-16 20:57:02.036002+05	f
b35fc815-8908-492d-b102-47480248a77d	b517c2a1-27a4-4c66-a270-399ec7c527a2	aa9add73-d599-47c0-88c4-e3de019fc890	20900c21-d24e-418a-9a8b-632eb6c7267e	0	3	0.00	2	t	{}	2026-06-16 21:14:11.626092+05	f
168dded8-6992-4133-8114-02881e876d05	b517c2a1-27a4-4c66-a270-399ec7c527a2	aa9add73-d599-47c0-88c4-e3de019fc890	20900c21-d24e-418a-9a8b-632eb6c7267e	0	3	0.00	\N	f	{}	2026-06-16 21:40:18.22583+05	f
\.


--
-- Data for Name: retake_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.retake_permissions (student_id, subtheme_id, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (name, applied_at) FROM stdin;
001_init.sql	2026-05-22 05:25:53.749719+05
002_subtheme_content_blocks.sql	2026-06-07 06:02:38.199368+05
003_subtheme_attachments.sql	2026-06-07 06:15:05.189531+05
004_retake_permissions.sql	2026-06-07 08:31:38.623476+05
005_notifications.sql	2026-06-07 08:43:05.411315+05
006_scheduled_notified.sql	2026-06-07 20:33:14.914011+05
007_fix_published_status.sql	2026-06-07 20:59:24.007791+05
008_positions.sql	2026-06-07 20:59:24.03032+05
009_user_positions.sql	2026-06-07 21:09:49.200584+05
010_subject_code_lock.sql	2026-06-08 23:46:26.750165+05
011_test_time_limit.sql	2026-06-16 21:10:26.863909+05
012_test_availability_window.sql	2026-06-16 21:28:17.411565+05
\.


--
-- Data for Name: subject_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subject_codes (id, subject_id, code, expires_at, created_at) FROM stdin;
15b84778-613f-442d-a91c-a8ead7e58f48	a8fdf27a-5a9a-4bb3-a01b-583700582352	6GS6NY	2026-05-22 07:43:25.522274+05	2026-05-22 07:38:25.528127+05
6bd94d0d-42a2-4be9-ad68-273af77c3a17	a8fdf27a-5a9a-4bb3-a01b-583700582352	PS35HE	2026-05-22 08:38:07.220247+05	2026-05-22 08:33:07.221673+05
3c27f5b5-8832-4ca8-b132-b4d7f3e84cdf	a8fdf27a-5a9a-4bb3-a01b-583700582352	B7YK3B	2026-05-22 08:43:07.257285+05	2026-05-22 08:38:07.259547+05
df42147e-c515-49c9-ad52-6ab3efb27ff4	a8fdf27a-5a9a-4bb3-a01b-583700582352	YCACFK	2026-05-23 01:14:29.217271+05	2026-05-23 01:09:29.227494+05
d7deec87-560a-42c2-a64f-1cc655f904f2	a8fdf27a-5a9a-4bb3-a01b-583700582352	QA8S2T	2026-05-23 01:19:29.25626+05	2026-05-23 01:14:29.258279+05
4e40e070-0cb8-4fb3-a0e6-692ad0087552	a8fdf27a-5a9a-4bb3-a01b-583700582352	U53DW5	2026-05-23 09:45:35.510692+05	2026-05-23 09:40:35.513158+05
5e2c1509-f284-4a2c-8a85-1f6a6d3f5548	a8fdf27a-5a9a-4bb3-a01b-583700582352	ECAPGV	2026-05-23 09:50:35.547448+05	2026-05-23 09:45:35.549723+05
90024503-615f-47f6-8c51-30d176bf2958	a8fdf27a-5a9a-4bb3-a01b-583700582352	RMSUVT	2026-05-23 14:02:10.25924+05	2026-05-23 13:57:10.269943+05
e614b99d-2e00-4f02-929d-219aab98aece	a8fdf27a-5a9a-4bb3-a01b-583700582352	BWGACJ	2026-05-23 14:07:10.31703+05	2026-05-23 14:02:10.320841+05
c3242097-dcbe-4901-b5fd-b9057ad7c2cb	a8fdf27a-5a9a-4bb3-a01b-583700582352	X4J2SH	2026-05-23 14:12:14.897761+05	2026-05-23 14:07:14.900073+05
566514aa-b4e0-478a-b63b-8b9656cc9750	a8fdf27a-5a9a-4bb3-a01b-583700582352	6YNFPY	2026-05-23 14:17:14.936551+05	2026-05-23 14:12:14.941685+05
2bceb95c-bdc3-483c-be52-96fda18a364e	a7e98cda-cc7f-46c7-aafe-c7082ffdf944	S6G8B4	2026-05-23 14:24:06.288295+05	2026-05-23 14:19:06.293579+05
9a5cce1f-4e45-4a26-a1eb-6dc755869143	a7e98cda-cc7f-46c7-aafe-c7082ffdf944	P8JVCJ	2026-05-23 14:29:06.338461+05	2026-05-23 14:24:06.341605+05
c6c44a81-aff0-44fd-abeb-da5f9e8c01ce	a8fdf27a-5a9a-4bb3-a01b-583700582352	S4VRGE	2026-05-23 14:33:17.69038+05	2026-05-23 14:28:17.696789+05
feab0ed7-df69-4391-8a16-c77247f39708	a8fdf27a-5a9a-4bb3-a01b-583700582352	PWC2FM	2026-05-26 12:29:17.158806+05	2026-05-26 12:24:17.195579+05
f154e699-62ad-4470-a115-a7d2216aa40a	a8fdf27a-5a9a-4bb3-a01b-583700582352	KUSHTK	2026-05-26 12:29:17.161807+05	2026-05-26 12:24:17.199139+05
3e0e33a5-98f9-44e1-87a0-313c8824abfe	a8fdf27a-5a9a-4bb3-a01b-583700582352	BPFJT6	2026-05-26 12:29:17.180909+05	2026-05-26 12:24:17.206542+05
01f99991-f621-4e2d-8c88-0c8896692619	a7e98cda-cc7f-46c7-aafe-c7082ffdf944	2DQ7HA	2026-06-07 06:07:43.430587+05	2026-06-07 06:02:43.444779+05
44d5ff1d-6f50-43db-8a4b-b9dcdc5b09a3	a8fdf27a-5a9a-4bb3-a01b-583700582352	QSA5XY	2026-06-07 06:07:45.983385+05	2026-06-07 06:02:45.998171+05
50694392-5fa1-4c76-8560-f96e1fee07bc	a8fdf27a-5a9a-4bb3-a01b-583700582352	2EHB7Q	2026-06-07 06:20:09.881052+05	2026-06-07 06:15:09.892131+05
e869ab31-30e2-4ead-b44c-106a3a0074ce	a7e98cda-cc7f-46c7-aafe-c7082ffdf944	2832QV	2026-06-07 06:27:58.330074+05	2026-06-07 06:22:58.333439+05
326435ed-7e65-4447-aeb2-20428cf21c4a	a8fdf27a-5a9a-4bb3-a01b-583700582352	C4QB58	2026-06-07 06:27:59.352717+05	2026-06-07 06:22:59.360484+05
eea6ebd8-93ac-4253-ae4f-1894685eac98	a8fdf27a-5a9a-4bb3-a01b-583700582352	TT8E8F	2026-06-07 06:34:30.727655+05	2026-06-07 06:29:30.732882+05
a354373c-d3ff-4777-a0ab-2d213254da66	a8fdf27a-5a9a-4bb3-a01b-583700582352	4WSGMP	2026-06-07 08:36:50.564321+05	2026-06-07 08:31:50.589023+05
b11c7078-e325-49d4-847e-8d0dc60adbf4	a8fdf27a-5a9a-4bb3-a01b-583700582352	6UYGT5	2026-06-07 08:48:51.791994+05	2026-06-07 08:43:51.803317+05
2991d880-1528-4df8-a192-11ae7759da14	a8fdf27a-5a9a-4bb3-a01b-583700582352	YNKZ2R	2026-06-07 20:23:26.947722+05	2026-06-07 20:18:26.952849+05
1839d6be-16e5-4c48-8c57-a5baa33013d9	a8fdf27a-5a9a-4bb3-a01b-583700582352	A5QSKC	2026-06-07 20:29:47.998988+05	2026-06-07 20:24:48.008533+05
20e9f457-3692-4e42-b7e2-7024e28bd2ee	a8fdf27a-5a9a-4bb3-a01b-583700582352	6DRPSY	2026-06-07 20:40:46.206148+05	2026-06-07 20:35:46.220012+05
c5c85e56-2cd5-4a86-bcf1-699dd06fd0e9	a7e98cda-cc7f-46c7-aafe-c7082ffdf944	VMMYU9	2026-06-07 20:40:52.482648+05	2026-06-07 20:35:52.488556+05
65175616-6a48-4a40-a190-2d13af3df526	a8fdf27a-5a9a-4bb3-a01b-583700582352	UD5WFE	2026-06-08 10:14:44.469116+05	2026-06-08 10:09:44.490673+05
d7fbca68-4fae-4ed6-aafb-fd4ae2cb7dfb	a8fdf27a-5a9a-4bb3-a01b-583700582352	G5VDKB	2026-06-08 10:19:44.56314+05	2026-06-08 10:14:44.566667+05
4f2b69e8-cc17-4df6-a2fb-caf1cc9b8335	a8fdf27a-5a9a-4bb3-a01b-583700582352	86N75W	2026-06-08 10:24:44.597285+05	2026-06-08 10:19:44.600013+05
0cf18b4f-3b89-46be-bb53-f7e098b5bb92	a8fdf27a-5a9a-4bb3-a01b-583700582352	PERJ8Q	2026-06-08 10:30:23.3585+05	2026-06-08 10:25:23.364881+05
2fcc319b-ca73-44a4-8164-83b4f6660324	a8fdf27a-5a9a-4bb3-a01b-583700582352	DTBAAJ	2026-06-08 10:35:23.409165+05	2026-06-08 10:30:23.411445+05
14e677f3-4275-478c-bcf3-d2f689c7ae2a	a8fdf27a-5a9a-4bb3-a01b-583700582352	NJQBJW	2026-06-08 10:40:23.441397+05	2026-06-08 10:35:23.444063+05
9e9ab655-89fc-4a4a-97f0-41cc095a3ce4	a8fdf27a-5a9a-4bb3-a01b-583700582352	RM2H3Z	2026-06-08 23:43:07.799087+05	2026-06-08 23:38:07.802167+05
2b013448-1c79-432e-ae85-f09de24d9231	a8fdf27a-5a9a-4bb3-a01b-583700582352	MZ73US	2026-06-08 23:46:32.689009+05	2026-06-08 23:46:29.228032+05
a5b5fe5b-b8e6-4c64-96fd-6a431f1f2563	a8fdf27a-5a9a-4bb3-a01b-583700582352	NMTVFJ	2026-06-08 23:46:33.206241+05	2026-06-08 23:46:32.691478+05
f663aed4-328a-46bb-88b1-8549c8adfd3c	a8fdf27a-5a9a-4bb3-a01b-583700582352	TDTD5F	2026-06-08 23:46:33.454061+05	2026-06-08 23:46:33.210488+05
81b09c49-d2df-4231-836d-d9eb836f4daa	a8fdf27a-5a9a-4bb3-a01b-583700582352	GUDZN6	2026-06-08 23:46:33.738884+05	2026-06-08 23:46:33.456935+05
03201a69-8175-4bb0-be33-848134cca355	a8fdf27a-5a9a-4bb3-a01b-583700582352	XZPAM8	2026-06-08 23:46:34.287947+05	2026-06-08 23:46:33.742047+05
d710ac08-c1f3-4e3b-9045-46ef1b2a5b27	a8fdf27a-5a9a-4bb3-a01b-583700582352	HZ88ZH	2026-06-08 23:46:34.772492+05	2026-06-08 23:46:34.2914+05
e408277e-3b1b-42fc-aa81-1b3f46692647	a8fdf27a-5a9a-4bb3-a01b-583700582352	FNWPTY	2026-06-08 23:51:38.704217+05	2026-06-08 23:46:34.775711+05
8117f5d8-02fe-4537-8935-4d516003b0b4	a8fdf27a-5a9a-4bb3-a01b-583700582352	Y57H9T	2026-06-09 00:35:25.466174+05	2026-06-09 00:30:25.471094+05
d39e94cd-bc30-46ef-8001-ca1b92018d1f	a8fdf27a-5a9a-4bb3-a01b-583700582352	K7Z986	2026-06-09 00:40:25.618923+05	2026-06-09 00:35:25.621273+05
7a0b6cb1-9b9b-4439-af17-e2731fadaccf	a8fdf27a-5a9a-4bb3-a01b-583700582352	YESFND	2026-06-09 00:45:25.695508+05	2026-06-09 00:40:25.697665+05
40d5fd8f-26eb-453f-a9b1-56f06fb5a045	a8fdf27a-5a9a-4bb3-a01b-583700582352	RQQVT5	2026-06-09 03:34:46.623668+05	2026-06-09 03:29:46.628829+05
a7ed214f-4940-4e36-9ff5-f27b27751e6a	a8fdf27a-5a9a-4bb3-a01b-583700582352	QZURPU	2026-06-09 03:39:46.72872+05	2026-06-09 03:34:46.731229+05
b6dbc4ee-7571-4551-a0e3-67263cf25c20	a8fdf27a-5a9a-4bb3-a01b-583700582352	UM7CDR	2026-06-09 03:44:46.772038+05	2026-06-09 03:39:46.774052+05
0050c947-b31c-4ab1-9ee6-0657581c1ec1	a8fdf27a-5a9a-4bb3-a01b-583700582352	KM3GSF	2026-06-09 03:49:46.843141+05	2026-06-09 03:44:46.845468+05
e21c977e-0b65-4f67-9d63-44a231aca494	a8fdf27a-5a9a-4bb3-a01b-583700582352	Q5N42P	2026-06-09 13:13:03.479744+05	2026-06-09 13:08:03.485423+05
5d01e01c-6974-4670-b371-9f98ecc5b513	a8fdf27a-5a9a-4bb3-a01b-583700582352	YD8JU6	2026-06-09 13:18:03.584985+05	2026-06-09 13:13:03.588681+05
d409c076-f4e9-4351-847a-95686fd9acb1	a8fdf27a-5a9a-4bb3-a01b-583700582352	AREZNS	2026-06-16 15:43:03.465994+05	2026-06-16 15:36:09.144473+05
88877283-1982-42ed-a2eb-a22eebc6e808	a8fdf27a-5a9a-4bb3-a01b-583700582352	HF6NVS	2026-06-16 15:49:04.707041+05	2026-06-16 15:43:24.839115+05
28d0bed6-0499-44cc-a0a2-50d08cb21d9c	a8fdf27a-5a9a-4bb3-a01b-583700582352	HKZ7V7	2026-06-16 20:40:17.065461+05	2026-06-16 20:35:17.069698+05
8e5c996a-5690-4219-acfe-0b988c172afe	a8fdf27a-5a9a-4bb3-a01b-583700582352	FNXPHG	2026-06-16 20:48:59.343081+05	2026-06-16 20:40:17.103515+05
1aeb09ab-1701-4b7e-b7c6-99c1c5bc3990	a8fdf27a-5a9a-4bb3-a01b-583700582352	GPQ3YK	2026-06-16 20:53:59.354665+05	2026-06-16 20:48:59.356983+05
4939b74d-f355-408c-ab38-77d7a83c0325	a8fdf27a-5a9a-4bb3-a01b-583700582352	HG29XD	2026-06-16 20:59:03.623374+05	2026-06-16 20:54:03.629304+05
a5923f18-015f-41c0-ad58-fc48fe64c933	a8fdf27a-5a9a-4bb3-a01b-583700582352	ZYB3GH	2026-06-16 21:12:22.835272+05	2026-06-16 21:07:22.851724+05
ae66e990-3b26-41dd-9792-64e3711bdcd2	a8fdf27a-5a9a-4bb3-a01b-583700582352	9JFWQZ	2026-06-16 21:18:13.528686+05	2026-06-16 21:13:13.547736+05
12e6a5b6-48b1-4da2-ae2f-8869b2111381	a8fdf27a-5a9a-4bb3-a01b-583700582352	ZRXNUH	2026-06-16 21:35:20.957559+05	2026-06-16 21:30:20.966579+05
\.


--
-- Data for Name: subject_students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subject_students (subject_id, student_id, joined_at) FROM stdin;
a8fdf27a-5a9a-4bb3-a01b-583700582352	b517c2a1-27a4-4c66-a270-399ec7c527a2	2026-06-07 20:25:25.7445+05
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subjects (id, name, description, teacher_id, created_by, created_at, updated_at, code_locked) FROM stdin;
a7e98cda-cc7f-46c7-aafe-c7082ffdf944	Математика	ить	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	72222070-f1aa-4820-8028-3f139f8e7126	2026-05-23 14:18:45.229105+05	2026-05-23 14:18:45.229105+05	f
a1b1a645-5e70-43ab-84fe-f48557694413	Физика	Предмет физики	\N	72222070-f1aa-4820-8028-3f139f8e7126	2026-06-09 00:24:19.67053+05	2026-06-09 00:24:19.67053+05	f
fa642fe1-4b37-48e6-8789-b451baa5a8d4	Информационные технологии	\N	\N	72222070-f1aa-4820-8028-3f139f8e7126	2026-06-09 00:24:35.68602+05	2026-06-09 00:24:35.68602+05	f
f0658d12-e1ce-4977-9658-d42b3a3eae52	История	\N	\N	72222070-f1aa-4820-8028-3f139f8e7126	2026-06-09 00:24:47.015604+05	2026-06-09 00:24:47.015604+05	f
a8fdf27a-5a9a-4bb3-a01b-583700582352	Информатика	обучение, пары информатики, программирование	ddbc5882-85db-4bd0-8ce4-0554d060e1dd	72222070-f1aa-4820-8028-3f139f8e7126	2026-05-22 07:38:05.6115+05	2026-06-16 20:44:07.51006+05	f
\.


--
-- Data for Name: subtheme_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subtheme_attachments (id, subtheme_id, file_path, original_name, mime_type, size_bytes, sort_order, created_at) FROM stdin;
813e5bf9-b327-4db7-9dc8-0abc17d97582	e392c008-4f9b-4234-abf1-47e8d009e4be	67/04/6704976e-2bfd-4246-be48-8db0704cf7e2.pdf	Чащихин 06.06.22.pdf	application/pdf	2301233	0	2026-06-07 06:15:33.931898+05
a9f62df0-8c43-45ca-bad6-18e6240a2b4d	124d7ca6-105c-4944-aea7-038f7530f3e4	d1/6c/d16c2092-c0be-4103-9102-83539049fbaa.xlsx	user_import.xlsx	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet	10257	0	2026-06-08 10:14:13.297879+05
\.


--
-- Data for Name: subtheme_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subtheme_images (id, subtheme_id, file_path, caption, sort_order, created_at) FROM stdin;
d25a7d3a-6977-45e8-845a-c76d6ec60281	34d97a5b-3e52-409b-b479-735e6bb871a6	c6/92/c6922253-83c8-4d8d-b102-e8c1125493f7.png	\N	0	2026-05-22 08:34:30.15204+05
cca3ac40-feb0-482c-afe7-3cfdcd94d16d	b89344ef-c39c-4ade-8a20-dd28d93fb890	1f/8c/1f8cc3c0-dad9-4465-a6fc-6c238abcd7ef.png	\N	0	2026-05-23 14:02:51.444333+05
6e074999-0d17-4e53-aa9a-cd96a6c15661	e392c008-4f9b-4234-abf1-47e8d009e4be	71/89/7189d55b-7cb0-4453-b897-c03838368d2c.jpg	\N	0	2026-06-07 06:03:07.109253+05
3523082d-a0cc-4d33-b9d2-42db601d333c	e392c008-4f9b-4234-abf1-47e8d009e4be	74/2e/742eb9a5-0bee-426e-8ab7-e3d7f686fe05.jpg	\N	0	2026-06-07 20:19:13.108674+05
3556a62f-bccf-45c7-8475-433bf72f7ac9	124d7ca6-105c-4944-aea7-038f7530f3e4	f8/43/f8437b1b-75cf-4d2e-9459-44d848f9f615.jpg	\N	0	2026-06-08 10:13:37.68314+05
4288518c-d401-4a06-955b-7db83b6b9f3e	124d7ca6-105c-4944-aea7-038f7530f3e4	22/e3/22e3e9c9-af53-45cd-b37a-06ed66819314.jpg	\N	0	2026-06-16 15:38:12.839267+05
c0b77ec9-05ea-45ec-8daa-358b0da0569b	124d7ca6-105c-4944-aea7-038f7530f3e4	14/69/1469ff5b-6503-48dd-b92d-876a16a90a62.jpg	\N	0	2026-06-16 15:43:31.556515+05
93024bd5-24b3-485a-ad93-2086601116bb	aa9add73-d599-47c0-88c4-e3de019fc890	1b/4f/1b4f4ad9-cd77-406c-bb95-dcfe79ff58e9.jpg	\N	0	2026-06-16 20:37:03.988877+05
4d5b67f4-7e5a-4388-8f24-f65a7555ee85	76c111a0-3b18-405a-abee-0c2e71b85f62	9f/04/9f04a5d7-d79a-428e-8aad-1d8fd56055e9.png	\N	0	2026-06-16 20:40:57.61096+05
94c7b216-bcb3-45bf-a5e1-dfe580a55b55	c6ee65e9-515e-4777-bd17-f708b2253a12	5d/6c/5d6c197f-2556-48af-a778-93797dd46c0a.png	\N	0	2026-06-16 20:46:44.904582+05
89c92c8e-5585-41b2-a0f4-8a8a30621dbb	d022aa3a-eaac-4fe8-af18-34e6e705bb94	ab/af/abaf6458-be53-4d9d-9a95-48b9d05b6d2e.png	\N	0	2026-06-16 20:49:43.546346+05
0a6e4ce1-3923-4836-a65f-ac67347f046f	f1805989-6339-4674-ad24-a6047d597a51	27/34/2734420b-86d8-40ff-9196-833dfa6033d1.png	\N	0	2026-06-16 20:52:03.898938+05
50c81a4d-8670-49fb-8f25-971725ca1546	929ffbd6-dd66-48bc-a02e-9304dcbc8669	58/27/582710a9-bd8b-4e41-a83f-175a739cd7e8.png	\N	0	2026-06-16 20:53:54.486598+05
\.


--
-- Data for Name: subthemes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subthemes (id, theme_id, title, content, sort_order, visibility, scheduled_at, created_at, updated_at, content_blocks, scheduled_notified) FROM stdin;
aa9add73-d599-47c0-88c4-e3de019fc890	927947a6-a89c-47df-9434-67b039d9995a	Что такое реляционная модель		0	published	\N	2026-06-16 20:35:51.730608+05	2026-06-16 21:13:48.00693+05	[{"text": "Реляционная модель данных — это способ организации информации, при котором все данные представлены в виде **таблиц**, связанных между собой через значения определённых полей.\\r\\n\\r\\nМодель была предложена *Эдгаром Коддом* в 1970 году и сегодня лежит в основе подавляющего большинства промышленных систем управления базами данных: **PostgreSQL, MySQL, Oracle, Microsoft SQL Server** и других.\\r\\n\\r\\nКлючевые понятия реляционной модели:\\r\\n\\r\\n- **отношение** (relation) — таблица с данными;\\r\\n- **кортеж** (tuple) — строка таблицы, описывающая один объект;\\r\\n- **атрибут** (attribute) — столбец таблицы, описывающий одно свойство;\\r\\n- **домен** — множество допустимых значений для атрибута.", "type": "text"}, {"url": "/uploads/1b/4f/1b4f4ad9-cd77-406c-bb95-dcfe79ff58e9.jpg", "type": "image", "caption": "фото портрета Эдгара Кодда с подписью «Эдгар Кодд (1923–2003), автор реляционной модели»"}, {"text": "## Пример: таблица «Студенты»\\r\\n\\r\\n| ID | ФИО              | Группа | Дата рождения |\\r\\n|----|------------------|--------|---------------|\\r\\n| 1  | Иванов И.И.      | ПР-42  | 15.03.2006    |\\r\\n| 2  | Петрова А.С.     | ПР-42  | 22.07.2005    |\\r\\n| 3  | Сидоров К.В.     | ПР-41  | 04.11.2005    |\\r\\n\\r\\nВ этой таблице:\\r\\n- **строки** — конкретные студенты,\\r\\n- **столбцы** — характеристики студента,\\r\\n- **ID** — уникальный идентификатор каждой записи.", "type": "text"}, {"text": "## Преимущества реляционной модели\\r\\n\\r\\n1. **Простота восприятия** — таблица интуитивно понятна любому человеку.\\r\\n2. **Строгая математическая основа** — теория отношений и реляционная алгебра.\\r\\n3. **Гибкость запросов** — можно получать любые срезы данных через язык SQL.\\r\\n4. **Целостность данных** — система автоматически следит за корректностью связей.", "type": "text"}]	f
34d97a5b-3e52-409b-b479-735e6bb871a6	45d1f1fe-eed0-4f1c-9fb3-066f7ef3e69a	как создать массив	привет всем сегодня покажу как делать массив на c#	0	published	2026-05-23 08:37:00+05	2026-05-22 08:34:00.756652+05	2026-05-22 08:37:38.380365+05	[]	f
b89344ef-c39c-4ade-8a20-dd28d93fb890	a1b7ae07-2a0e-4125-af34-b45c75df4f5b	переменные		0	draft	\N	2026-05-23 14:02:05.592818+05	2026-05-23 14:02:05.592818+05	[]	f
76c111a0-3b18-405a-abee-0c2e71b85f62	927947a6-a89c-47df-9434-67b039d9995a	Первичный и внешний ключи		0	published	\N	2026-06-16 20:39:42.759265+05	2026-06-16 20:42:37.621926+05	[{"text": "Ключ в реляционной БД — это атрибут (или набор атрибутов), который позволяет однозначно идентифицировать запись в таблице или установить связь между таблицами.\\r\\n\\r\\n## Первичный ключ (PRIMARY KEY)\\r\\n\\r\\n**Первичный ключ** — это атрибут, значение которого уникально для каждой строки таблицы. Чаще всего в его роли выступает поле `id` — целое число или универсальный идентификатор UUID.\\r\\n\\r\\nПравила первичного ключа:\\r\\n- значение **не может быть NULL** (пустым);\\r\\n- значение должно быть **уникальным** в пределах таблицы;\\r\\n- значение в идеале **не должно меняться** на протяжении жизни записи.", "type": "text"}, {"url": "/uploads/9f/04/9f04a5d7-d79a-428e-8aad-1d8fd56055e9.png", "type": "image", "caption": "схема двух связанных таблиц «Студенты» и «Группы» с подсвеченным внешним ключом"}, {"text": "## Внешний ключ (FOREIGN KEY)\\r\\n\\r\\n**Внешний ключ** — это поле в одной таблице, которое ссылается на первичный ключ другой таблицы. Внешние ключи реализуют связи между таблицами.\\r\\n\\r\\n### Пример\\r\\n\\r\\nДопустим, есть две таблицы: «Студенты» и «Группы». В таблице студентов есть поле `group_id`, которое содержит идентификатор группы из таблицы групп. Это и есть внешний ключ.\\r\\n\\r\\nБаза данных следит за **ссылочной целостностью**: нельзя записать студента в несуществующую группу, и при удалении группы можно либо запретить операцию, либо каскадно удалить всех её студентов.", "type": "text"}, {"text": "## Пример SQL-определения\\r\\n\\r\\n```sql\\r\\nCREATE TABLE groups (\\r\\n    id    SERIAL PRIMARY KEY,\\r\\n    name  TEXT NOT NULL UNIQUE\\r\\n);\\r\\n\\r\\nCREATE TABLE students (\\r\\n    id        SERIAL PRIMARY KEY,\\r\\n    full_name TEXT NOT NULL,\\r\\n    group_id  INTEGER REFERENCES groups(id)\\r\\n                ON DELETE SET NULL\\r\\n);\\r\\n```\\r\\nВ этом примере при удалении группы поле `group_id` у её студентов автоматически станет NULL.", "type": "text"}]	f
124d7ca6-105c-4944-aea7-038f7530f3e4	d4249b56-6a01-4360-9eb1-cfb78318a62a	Двоичная система счисления		0	visible_locked	\N	2026-06-08 10:11:10.723027+05	2026-06-16 20:43:05.519714+05	[{"url": "/uploads/14/69/1469ff5b-6503-48dd-b92d-876a16a90a62.jpg", "type": "image"}, {"text": "**Система счисления** - это знаковая система, в котороой числа записываются по определенным правилам с помощью символов некоторого алфавита, называемых цифрами", "type": "text"}, {"text": "# Домашнее задание", "type": "text"}, {"text": "Уровень знания: выучить правило перевода чисел из любой системы счис-ления в десятичную.\\nУровень понимания: перевести в десятичную систему счисления следую¬щие числа: 110011,11012,1АВС16, \\n", "type": "text"}]	f
e392c008-4f9b-4234-abf1-47e8d009e4be	0f83413e-a574-415c-b47b-2ea6d31aea89	test1		0	published	\N	2026-06-07 06:02:54.98725+05	2026-06-07 20:19:40.789682+05	[{"text": "**жирный текст** *курсив* ~~зачеркнутый~~ `моноширинный код` [ссылка](https://google.com)", "type": "text"}, {"text": "# заголовок", "type": "text"}, {"url": "/uploads/74/2e/742eb9a5-0bee-426e-8ab7-e3d7f686fe05.jpg", "type": "image", "caption": "ботинкотуфлекроссовок"}, {"text": "- нумерованный список\\n- 1\\n- 2\\n- 3", "type": "text"}, {"text": "1. маркированный список\\n2. 1\\n3. 2\\n4. 3", "type": "text"}, {"text": "> цитата", "type": "text"}]	f
c6ee65e9-515e-4777-bd17-f708b2253a12	46d87cde-d3d8-4b06-b911-d4087a2e88cf	Команда SELECT		0	published	\N	2026-06-16 20:44:30.107499+05	2026-06-16 20:49:03.60731+05	[{"text": "**SQL** (Structured Query Language) — декларативный язык запросов к реляционным базам данных. Был создан в 1970-х годах в IBM и сегодня является международным стандартом ISO/IEC 9075.\\r\\n\\r\\nКоманда `SELECT` — самая часто используемая команда SQL, она отвечает за **выборку данных** из таблиц.\\r\\n\\r\\n## Базовая форма\\r\\n\\r\\n```sql\\r\\nSELECT столбцы FROM таблица WHERE условие;\\r\\n```", "type": "text"}, {"url": "/uploads/5d/6c/5d6c197f-2556-48af-a778-93797dd46c0a.png", "type": "image", "caption": "Вывод данных, где CategoryId = 1"}, {"text": "## Примеры\\r\\n\\r\\n**Вывести всех студентов:**\\r\\n```sql\\r\\nSELECT * FROM students;\\r\\n```\\r\\n\\r\\n**Вывести только имена студентов группы ПР-42:**\\r\\n```sql\\r\\nSELECT full_name FROM students WHERE group_name = 'ПР-42';\\r\\n```\\r\\n\\r\\n**Подсчитать количество студентов в каждой группе:**\\r\\n```sql\\r\\nSELECT group_name, COUNT(*) \\r\\nFROM students \\r\\nGROUP BY group_name;\\r\\n```", "type": "text"}, {"text": "## Дополнительные операторы\\r\\n\\r\\n- `ORDER BY` — сортировка результата;\\r\\n- `LIMIT N` — ограничить выборку N строками;\\r\\n- `DISTINCT` — убрать дубликаты;\\r\\n- `LIKE` — поиск по шаблону.\\r\\n\\r\\n**Пример с использованием всех операторов:**\\r\\n\\r\\n```sql\\r\\nSELECT DISTINCT full_name \\r\\nFROM students \\r\\nWHERE full_name LIKE 'Иванов%' \\r\\nORDER BY full_name ASC \\r\\nLIMIT 10;\\r\\n```", "type": "text"}]	f
d022aa3a-eaac-4fe8-af18-34e6e705bb94	46d87cde-d3d8-4b06-b911-d4087a2e88cf	Операция JOIN		0	published	\N	2026-06-16 20:49:18.432992+05	2026-06-16 20:51:02.723769+05	[{"text": "**JOIN** — операция объединения двух таблиц в одном запросе по условию связи. Используется, когда данные физически разнесены по разным таблицам, но нужно получить их вместе.\\r\\n\\r\\n## Виды JOIN\\r\\n\\r\\n- `INNER JOIN` — только записи, для которых нашлось совпадение в обеих таблицах;\\r\\n- `LEFT JOIN` — все записи из левой таблицы + совпадающие из правой;\\r\\n- `RIGHT JOIN` — все из правой + совпадающие из левой;\\r\\n- `FULL OUTER JOIN` — все записи из обеих таблиц.", "type": "text"}, {"url": "/uploads/ab/af/abaf6458-be53-4d9d-9a95-48b9d05b6d2e.png", "type": "image", "caption": "Диаграмма Венна для четырёх типов JOIN"}, {"text": "## Пример\\r\\n\\r\\nДопустим, есть таблицы «Студенты» и «Группы». Нужно вывести для каждого студента не только его имя, но и название группы.\\r\\n\\r\\n**С использованием INNER JOIN:**\\r\\n\\r\\n```sql\\r\\nSELECT s.full_name, g.name AS group_name\\r\\nFROM students s\\r\\nINNER JOIN groups g ON g.id = s.group_id;\\r\\n```\\r\\n\\r\\nВ результате получится таблица из двух столбцов: имя студента и название его группы.", "type": "text"}]	f
f1805989-6339-4674-ad24-a6047d597a51	40946cbf-daee-48e4-9b09-acba07f6201e	Понятие множества и его задание		0	published	\N	2026-06-16 20:51:34.868871+05	2026-06-16 20:53:20.04419+05	[{"text": "**Множество** — это совокупность каких-либо объектов, объединённых общим признаком. Объекты, входящие во множество, называются его **элементами**.\\r\\n\\r\\nМножества — основа всей современной математики. На них строятся понятия числа, функции, отношения, графа.\\r\\n\\r\\n## Способы задания множеств\\r\\n\\r\\n1. **Перечислением элементов** — простое перечисление в фигурных скобках:\\r\\n   `A = {1, 2, 3, 4, 5}`\\r\\n\\r\\n2. **Описанием свойства**, которым обладают все элементы:\\r\\n   `B = {x | x — чётное натуральное число, x ≤ 10}`\\r\\n\\r\\n3. **Графически** — диаграммой Эйлера-Венна.", "type": "text"}, {"url": "/uploads/27/34/2734420b-86d8-40ff-9196-833dfa6033d1.png", "type": "image", "caption": "Диаграмма Эйлера-Венна"}, {"text": "## Основные операции над множествами\\r\\n\\r\\n- **Объединение** $A \\\\cup B$ — все элементы, входящие хотя бы в одно множество.\\r\\n- **Пересечение** $A \\\\cap B$ — элементы, входящие в оба множества одновременно.\\r\\n- **Разность** $A \\\\setminus B$ — элементы из A, не входящие в B.\\r\\n- **Дополнение** $\\\\overline{A}$ — все элементы вне A (относительно универсума).\\r\\n\\r\\n## Пример\\r\\n\\r\\nПусть `A = {1, 2, 3, 4}`, `B = {3, 4, 5, 6}`.\\r\\n\\r\\n- A ∪ B = {1, 2, 3, 4, 5, 6}\\r\\n- A ∩ B = {3, 4}\\r\\n- A \\\\ B = {1, 2}\\r\\n- B \\\\ A = {5, 6}", "type": "text"}]	f
929ffbd6-dd66-48bc-a02e-9304dcbc8669	40946cbf-daee-48e4-9b09-acba07f6201e	Подмножество и мощность множества		0	published	\N	2026-06-16 20:53:27.165645+05	2026-06-16 20:55:13.486506+05	[{"text": "**Подмножество** — это множество, все элементы которого принадлежат другому множеству.\\r\\n\\r\\nЕсли каждый элемент множества A принадлежит множеству B, то говорят, что A — подмножество B, и пишут: $A \\\\subseteq B$.\\r\\n\\r\\n## Виды подмножеств\\r\\n\\r\\n- **Несобственное подмножество** — само множество, $A \\\\subseteq A$ всегда верно.\\r\\n- **Пустое множество** — подмножество **любого** множества: $\\\\varnothing \\\\subseteq A$.\\r\\n- **Собственное подмножество** — подмножество, не совпадающее с самим множеством: $A \\\\subset B$.", "type": "text"}, {"url": "/uploads/58/27/582710a9-bd8b-4e41-a83f-175a739cd7e8.png", "type": "image", "caption": "Диаграмма Венна"}, {"text": "## Мощность множества\\r\\n\\r\\n**Мощность** — это количество элементов в множестве. Обозначается $|A|$.\\r\\n\\r\\n- Если A = {1, 2, 3}, то |A| = 3.\\r\\n- Мощность пустого множества: |∅| = 0.\\r\\n\\r\\nМножества бывают **конечные** и **бесконечные**. Множество натуральных чисел ℕ — бесконечное.\\r\\n\\r\\n## Количество подмножеств\\r\\n\\r\\nЕсли в множестве n элементов, то у него ровно $2^n$ подмножеств (включая пустое и само множество).\\r\\n\\r\\n**Пример:** у множества из 3 элементов будет $2^3 = 8$ подмножеств.", "type": "text"}]	f
143668f4-e7ef-4566-b88a-e1c0eef4dcfb	0f83413e-a574-415c-b47b-2ea6d31aea89	zxc		0	draft	\N	2026-06-16 21:07:46.25005+05	2026-06-16 21:07:46.25005+05	[]	f
\.


--
-- Data for Name: tests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tests (id, subtheme_id, grade_thresholds, shuffle_questions, created_at, updated_at, time_limit_minutes, available_from, available_to) FROM stdin;
613aefc4-3f8d-4a24-b066-4f47ab7df94b	34d97a5b-3e52-409b-b479-735e6bb871a6	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-05-22 08:36:55.609293+05	2026-05-22 08:36:55.609293+05	\N	\N	\N
8579bf54-8b18-433f-b494-ea7f4573964e	b89344ef-c39c-4ade-8a20-dd28d93fb890	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-05-23 14:14:26.835363+05	2026-05-23 14:14:39.172129+05	\N	\N	\N
ca40872d-7108-4fb4-be0c-d89c54eef8f2	e392c008-4f9b-4234-abf1-47e8d009e4be	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-06-07 08:32:59.432511+05	2026-06-07 08:32:59.432511+05	\N	\N	\N
b4f6d233-c4d0-432c-b96f-ca9cfb734968	124d7ca6-105c-4944-aea7-038f7530f3e4	{"2": 0, "3": 50, "4": 70, "5": 90}	t	2026-06-08 10:15:42.256825+05	2026-06-08 10:15:42.256825+05	\N	\N	\N
07b2be2a-5818-4dfd-aed6-c3051e0e143f	76c111a0-3b18-405a-abee-0c2e71b85f62	{"2": 0, "3": 50, "4": 70, "5": 90}	t	2026-06-16 20:42:34.953402+05	2026-06-16 20:42:34.953402+05	\N	\N	\N
3d0ca9a8-e281-48d9-b804-01e9a837ba1b	c6ee65e9-515e-4777-bd17-f708b2253a12	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-06-16 20:48:43.116849+05	2026-06-16 20:48:58.779177+05	\N	\N	\N
3d1167dd-711e-484c-b7bb-f4c0ae0f3f7e	d022aa3a-eaac-4fe8-af18-34e6e705bb94	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-06-16 20:50:57.331328+05	2026-06-16 20:50:57.331328+05	\N	\N	\N
9b5195ec-6ff5-4df9-be88-0cc5a9a10430	f1805989-6339-4674-ad24-a6047d597a51	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-06-16 20:53:17.408954+05	2026-06-16 20:53:17.408954+05	\N	\N	\N
3f525a60-c6b2-4609-b35d-e393d0aedcb6	929ffbd6-dd66-48bc-a02e-9304dcbc8669	{"2": 0, "3": 50, "4": 70, "5": 90}	f	2026-06-16 20:55:10.480451+05	2026-06-16 20:55:10.480451+05	\N	\N	\N
20900c21-d24e-418a-9a8b-632eb6c7267e	aa9add73-d599-47c0-88c4-e3de019fc890	{"2": 0, "3": 50, "4": 70, "5": 90}	t	2026-06-16 20:39:16.927805+05	2026-06-16 21:30:44.547277+05	15	2026-06-16 21:35:00+05	2026-06-30 21:30:00+05
\.


--
-- Data for Name: themes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.themes (id, subject_id, title, description, sort_order, visibility, scheduled_at, created_at, updated_at, scheduled_notified) FROM stdin;
927947a6-a89c-47df-9434-67b039d9995a	a8fdf27a-5a9a-4bb3-a01b-583700582352	Реляционная модель данных	\N	0	published	\N	2026-06-16 20:35:44.611482+05	2026-06-16 20:35:44.611482+05	f
0f83413e-a574-415c-b47b-2ea6d31aea89	a8fdf27a-5a9a-4bb3-a01b-583700582352	test1		0	draft	2026-06-07 20:37:00+05	2026-06-07 06:02:49.973612+05	2026-06-16 20:43:25.249715+05	t
a1b7ae07-2a0e-4125-af34-b45c75df4f5b	a8fdf27a-5a9a-4bb3-a01b-583700582352	тема 1	описание	0	draft	\N	2026-05-23 14:01:50.392884+05	2026-06-16 20:43:36.30293+05	f
45d1f1fe-eed0-4f1c-9fb3-066f7ef3e69a	a8fdf27a-5a9a-4bb3-a01b-583700582352	Массивы	массивчики	0	visible_locked	2026-06-12 10:29:00+05	2026-05-22 08:33:41.472185+05	2026-06-16 20:43:43.411986+05	t
d4249b56-6a01-4360-9eb1-cfb78318a62a	a8fdf27a-5a9a-4bb3-a01b-583700582352	Система счисления		0	scheduled	2026-06-25 20:43:00+05	2026-06-08 10:10:51.611277+05	2026-06-16 20:43:57.390469+05	f
46d87cde-d3d8-4b06-b911-d4087a2e88cf	a8fdf27a-5a9a-4bb3-a01b-583700582352	Язык SQL		0	published	\N	2026-06-16 20:44:25.664611+05	2026-06-16 20:49:13.698532+05	f
40946cbf-daee-48e4-9b09-acba07f6201e	a8fdf27a-5a9a-4bb3-a01b-583700582352	Теория множеств	\N	0	published	\N	2026-06-16 20:51:29.726045+05	2026-06-16 20:51:29.726045+05	f
\.


--
-- Data for Name: user_positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_positions (user_id, position_id, assigned_at) FROM stdin;
ddbc5882-85db-4bd0-8ce4-0554d060e1dd	7959ff10-18bc-41b0-9de4-2e6b40f27147	2026-06-08 10:05:01.729719+05
ddbc5882-85db-4bd0-8ce4-0554d060e1dd	7ff1abe1-15b7-4073-92d2-6fa6c1a1d425	2026-06-08 10:05:01.731702+05
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, full_name, role, created_at, updated_at) FROM stdin;
501623c9-521a-40b7-bb82-fd907c0dd765	admin@college.local	$argon2id$v=19$m=65536,t=2,p=2$mpdcEl1SBgAAAAAAAAAAAA$lofK9Je9ehyjiz_dNAlQCm-HR-uQ0Yzzv6fOSZMYQ40	Главный администратор	admin	2026-05-22 05:25:53.760105+05	2026-05-22 05:25:53.760105+05
72222070-f1aa-4820-8028-3f139f8e7126	andreysyubaev68@gmail.com	$argon2id$v=19$m=65536,t=2,p=2$wsK9GV1SBgAAAAAAAAAAAA$G3YkB7hzL0QJuLZvGHeR90X2Uu8oF5vLtPvAVudOCjM	Андрей Студент	admin	2026-05-22 05:27:57.568334+05	2026-05-22 05:30:38.579886+05
b517c2a1-27a4-4c66-a270-399ec7c527a2	student@gmail.com	$argon2id$v=19$m=65536,t=2,p=2$gb_olF5SBgAAAAAAAAAAAA$LGgrKD9i2M_ShqbJIflv8ReyydWssvFWCrVx1faF2s0	Мистер студент	student	2026-05-22 07:13:58.952185+05	2026-05-22 07:13:58.952185+05
75a87669-7c2d-4d35-94a4-9383c0e84e5a	student2@gmail.com	$argon2id$v=19$m=65536,t=2,p=2$Gz03l3hSBgAAAAAAAAAAAA$dovWFndXoxqN1TW0ADVp3VSlXE4j0LkZYoB3GBUzkSA	студент2	student	2026-05-23 14:15:46.799284+05	2026-05-23 14:15:46.799284+05
ddbc5882-85db-4bd0-8ce4-0554d060e1dd	teacher@gmail.com	$argon2id$v=19$m=65536,t=2,p=2$n7L35V5SBgAAAAAAAAAAAA$nxOQQpYoO86LlOGtKKr4cp-qG68kt2KY2PNrk6mCzwk	Мистер преподаватель	teacher	2026-05-22 07:36:38.883803+05	2026-06-07 21:00:32.071374+05
\.


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: positions positions_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_name_key UNIQUE (name);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: retake_permissions retake_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.retake_permissions
    ADD CONSTRAINT retake_permissions_pkey PRIMARY KEY (student_id, subtheme_id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (name);


--
-- Name: subject_codes subject_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subject_codes
    ADD CONSTRAINT subject_codes_pkey PRIMARY KEY (id);


--
-- Name: subject_students subject_students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subject_students
    ADD CONSTRAINT subject_students_pkey PRIMARY KEY (subject_id, student_id);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: subtheme_attachments subtheme_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtheme_attachments
    ADD CONSTRAINT subtheme_attachments_pkey PRIMARY KEY (id);


--
-- Name: subtheme_images subtheme_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtheme_images
    ADD CONSTRAINT subtheme_images_pkey PRIMARY KEY (id);


--
-- Name: subthemes subthemes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subthemes
    ADD CONSTRAINT subthemes_pkey PRIMARY KEY (id);


--
-- Name: tests tests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (id);


--
-- Name: tests tests_subtheme_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_subtheme_id_key UNIQUE (subtheme_id);


--
-- Name: themes themes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (id);


--
-- Name: user_positions user_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_positions
    ADD CONSTRAINT user_positions_pkey PRIMARY KEY (user_id, position_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_notifications_unread; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_unread ON public.notifications USING btree (user_id) WHERE (is_read = false);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: idx_questions_test; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_test ON public.questions USING btree (test_id);


--
-- Name: idx_refresh_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refresh_user ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_results_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_results_student ON public.results USING btree (student_id);


--
-- Name: idx_results_subtheme; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_results_subtheme ON public.results USING btree (subtheme_id);


--
-- Name: idx_subject_codes_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subject_codes_code ON public.subject_codes USING btree (code);


--
-- Name: idx_subject_codes_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subject_codes_subject ON public.subject_codes USING btree (subject_id);


--
-- Name: idx_subject_students_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subject_students_student ON public.subject_students USING btree (student_id);


--
-- Name: idx_subjects_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subjects_teacher ON public.subjects USING btree (teacher_id);


--
-- Name: idx_subtheme_attachments_subtheme; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subtheme_attachments_subtheme ON public.subtheme_attachments USING btree (subtheme_id);


--
-- Name: idx_subtheme_images_subtheme; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subtheme_images_subtheme ON public.subtheme_images USING btree (subtheme_id);


--
-- Name: idx_subthemes_theme; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subthemes_theme ON public.subthemes USING btree (theme_id);


--
-- Name: idx_themes_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_themes_subject ON public.themes USING btree (subject_id);


--
-- Name: idx_user_positions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_positions_user ON public.user_positions USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (lower(email));


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: subjects trg_subjects_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_subjects_updated BEFORE UPDATE ON public.subjects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: subthemes trg_subthemes_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_subthemes_updated BEFORE UPDATE ON public.subthemes FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: tests trg_tests_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_tests_updated BEFORE UPDATE ON public.tests FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: themes trg_themes_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_themes_updated BEFORE UPDATE ON public.themes FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_updated BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: questions questions_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: results results_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: results results_subtheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_subtheme_id_fkey FOREIGN KEY (subtheme_id) REFERENCES public.subthemes(id) ON DELETE CASCADE;


--
-- Name: results results_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE CASCADE;


--
-- Name: retake_permissions retake_permissions_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.retake_permissions
    ADD CONSTRAINT retake_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: retake_permissions retake_permissions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.retake_permissions
    ADD CONSTRAINT retake_permissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: retake_permissions retake_permissions_subtheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.retake_permissions
    ADD CONSTRAINT retake_permissions_subtheme_id_fkey FOREIGN KEY (subtheme_id) REFERENCES public.subthemes(id) ON DELETE CASCADE;


--
-- Name: subject_codes subject_codes_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subject_codes
    ADD CONSTRAINT subject_codes_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: subject_students subject_students_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subject_students
    ADD CONSTRAINT subject_students_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: subject_students subject_students_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subject_students
    ADD CONSTRAINT subject_students_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: subjects subjects_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: subjects subjects_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: subtheme_attachments subtheme_attachments_subtheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtheme_attachments
    ADD CONSTRAINT subtheme_attachments_subtheme_id_fkey FOREIGN KEY (subtheme_id) REFERENCES public.subthemes(id) ON DELETE CASCADE;


--
-- Name: subtheme_images subtheme_images_subtheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtheme_images
    ADD CONSTRAINT subtheme_images_subtheme_id_fkey FOREIGN KEY (subtheme_id) REFERENCES public.subthemes(id) ON DELETE CASCADE;


--
-- Name: subthemes subthemes_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subthemes
    ADD CONSTRAINT subthemes_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES public.themes(id) ON DELETE CASCADE;


--
-- Name: tests tests_subtheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_subtheme_id_fkey FOREIGN KEY (subtheme_id) REFERENCES public.subthemes(id) ON DELETE CASCADE;


--
-- Name: themes themes_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: user_positions user_positions_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_positions
    ADD CONSTRAINT user_positions_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id) ON DELETE CASCADE;


--
-- Name: user_positions user_positions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_positions
    ADD CONSTRAINT user_positions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict PjeT0SDOHruFI7PC1rtgCf7VOcLBuKZZwLjzd7I7FgqgTCQdWRLjvdbkzZxwGzf

