# ===========================================================================
# СКРИПТ РАЗВЁРТЫВАНИЯ БАЗЫ ДАННЫХ ДЛЯ ЗАЩИТЫ ДИПЛОМА
# ===========================================================================
# Запускать в PowerShell от имени обычного пользователя.
# Требуется: PostgreSQL 14+ установлен и запущен.
#
# КАК ЗАПУСТИТЬ:
#   1. Правой кнопкой по файлу → «Выполнить с помощью PowerShell»
#      ИЛИ откройте PowerShell и введите:
#      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#      .\ЗАПУСТИТЬ_НА_ЗАЩИТЕ.ps1
#
# ===========================================================================

$ErrorActionPreference = "Stop"

# ─── НАСТРОЙКИ ───────────────────────────────────────────────────────────────
# Имя создаваемой базы данных
$DB_NAME = "college_app"

# Пользователь postgres (суперпользователь)
$PG_USER = "postgres"

# ПАРОЛЬ от postgres — спросим при запуске, чтобы не хранить в файле
# (на компьютере преподавателя пароль может быть любым)
# ===========================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   РАЗВЁРТЫВАНИЕ БД ДЛЯ ДИПЛОМА — Приложение колледжа" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ─── Получаем пароль ─────────────────────────────────────────────────────────
$pgPasswordSecure = Read-Host "Введите пароль пользователя postgres" -AsSecureString
$pgPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPasswordSecure)
)
$env:PGPASSWORD = $pgPassword

# ─── Ищем psql ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[1/4] Проверяю наличие psql..." -ForegroundColor Yellow

$psqlPath = $null

# Сначала ищем в PATH
try {
    $psqlPath = (Get-Command psql -ErrorAction Stop).Source
} catch {
    # Пробуем стандартные пути установки PostgreSQL
    $pgDirs = @(
        "C:\Program Files\PostgreSQL\17\bin\psql.exe",
        "C:\Program Files\PostgreSQL\16\bin\psql.exe",
        "C:\Program Files\PostgreSQL\15\bin\psql.exe",
        "C:\Program Files\PostgreSQL\14\bin\psql.exe",
        "C:\Program Files (x86)\PostgreSQL\17\bin\psql.exe",
        "C:\Program Files (x86)\PostgreSQL\16\bin\psql.exe"
    )
    foreach ($p in $pgDirs) {
        if (Test-Path $p) {
            $psqlPath = $p
            break
        }
    }
}

if (-not $psqlPath) {
    Write-Host ""
    Write-Host "ОШИБКА: psql не найден!" -ForegroundColor Red
    Write-Host "Убедитесь, что PostgreSQL установлен." -ForegroundColor Red
    Write-Host "Скачать: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

Write-Host "   OK: $psqlPath" -ForegroundColor Green

# ─── Проверяем соединение ────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/4] Проверяю подключение к PostgreSQL..." -ForegroundColor Yellow

$testResult = & $psqlPath -h 127.0.0.1 -U $PG_USER -c "SELECT 1;" postgres 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ОШИБКА подключения к PostgreSQL!" -ForegroundColor Red
    Write-Host "Проверьте:" -ForegroundColor Yellow
    Write-Host "  • PostgreSQL запущен (Службы → postgresql-x64-*)" -ForegroundColor Yellow
    Write-Host "  • Пароль введён верно" -ForegroundColor Yellow
    Write-Host "  • Пользователь 'postgres' существует" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Вывод ошибки: $testResult" -ForegroundColor Red
    Write-Host ""
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

Write-Host "   OK: подключение успешно" -ForegroundColor Green

# ─── Создаём базу данных ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/4] Создаю базу данных '$DB_NAME'..." -ForegroundColor Yellow

# Проверяем, существует ли уже
$dbExists = & $psqlPath -h 127.0.0.1 -U $PG_USER -tAc `
    "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" postgres 2>&1

if ($dbExists -eq "1") {
    Write-Host "   База '$DB_NAME' уже существует — пересоздаю..." -ForegroundColor Yellow
    & $psqlPath -h 127.0.0.1 -U $PG_USER -c `
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME';" postgres | Out-Null
    & $psqlPath -h 127.0.0.1 -U $PG_USER -c "DROP DATABASE IF EXISTS `"$DB_NAME`";" postgres | Out-Null
}

& $psqlPath -h 127.0.0.1 -U $PG_USER -c `
    "CREATE DATABASE `"$DB_NAME`" ENCODING 'UTF8' LC_COLLATE 'Russian_Russia.1251' LC_CTYPE 'Russian_Russia.1251' TEMPLATE template0;" postgres 2>&1

if ($LASTEXITCODE -ne 0) {
    # Пробуем без кириллической локали (на английских Windows)
    & $psqlPath -h 127.0.0.1 -U $PG_USER -c `
        "CREATE DATABASE `"$DB_NAME`" ENCODING 'UTF8';" postgres | Out-Null
}

Write-Host "   OK: база '$DB_NAME' создана" -ForegroundColor Green

# ─── Применяем схему и данные ────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Применяю схему и загружаю демо-данные..." -ForegroundColor Yellow

$scriptPath = Join-Path $PSScriptRoot "setup_defense.sql"

if (-not (Test-Path $scriptPath)) {
    Write-Host ""
    Write-Host "ОШИБКА: файл setup_defense.sql не найден рядом со скриптом!" -ForegroundColor Red
    Write-Host "Путь: $scriptPath" -ForegroundColor Red
    Write-Host ""
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

& $psqlPath -h 127.0.0.1 -U $PG_USER -d $DB_NAME `
    --set ON_ERROR_STOP=1 `
    -f $scriptPath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ОШИБКА при выполнении SQL-скрипта!" -ForegroundColor Red
    Write-Host "Проверьте вывод выше." -ForegroundColor Red
    Write-Host ""
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

Write-Host "   OK: схема и данные загружены" -ForegroundColor Green

# ─── Итог ────────────────────────────────────────────────────────────────────
$env:PGPASSWORD = ""

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "   ГОТОВО! База данных развёрнута успешно." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "База данных:  $DB_NAME" -ForegroundColor Cyan
Write-Host "Хост:         127.0.0.1:5432" -ForegroundColor Cyan
Write-Host ""
Write-Host "Учётки для входа в приложение (пароль у всех: admin12345):" -ForegroundColor White
Write-Host "  admin@college.local      — администратор" -ForegroundColor White
Write-Host "  ivanov@college.local     — преподаватель (2 предмета)" -ForegroundColor White
Write-Host "  petrova@college.local    — преподаватель (резерв)" -ForegroundColor White
Write-Host "  student1@college.local   — студент Андреев" -ForegroundColor White
Write-Host "  student2@college.local   — студент Борисов" -ForegroundColor White
Write-Host "  student3@college.local   — студент Васильев" -ForegroundColor White
Write-Host ""
Write-Host "Теперь запустите сервер (в папке server/):" -ForegroundColor Yellow
Write-Host "  dart run bin/server.dart" -ForegroundColor Yellow
Write-Host ""
Read-Host "Нажмите Enter для закрытия"
