@echo off
REM Скрипт для развертывания на VPS с Windows машины
REM Требуется: Git Bash или WSL

echo ========================================
echo   Развертывание "Мое добро" на VPS
echo ========================================
echo.

set VPS_IP=185.40.4.195
set VPS_USER=root
set PROJECT_DIR=/var/www/moe-dobro

echo [1/5] Упаковка файлов...
tar -czf moe-dobro.tar.gz backend --exclude=backend/node_modules --exclude=backend/uploads --exclude=backend/logs --exclude=backend/.env

if errorlevel 1 (
    echo ОШИБКА: Не удалось создать архив
    pause
    exit /b 1
)

echo [2/5] Загрузка на сервер...
scp moe-dobro.tar.gz %VPS_USER%@%VPS_IP%:/tmp/

if errorlevel 1 (
    echo ОШИБКА: Не удалось загрузить файлы на сервер
    pause
    exit /b 1
)

echo [3/5] Распаковка и установка на сервере...
ssh %VPS_USER%@%VPS_IP% "cd /var/www/moe-dobro && tar -xzf /tmp/moe-dobro.tar.gz && rm /tmp/moe-dobro.tar.gz && cd backend && npm install --production && mkdir -p uploads logs && chown -R www-data:www-data uploads logs && chmod -R 755 uploads"

if errorlevel 1 (
    echo ОШИБКА: Не удалось установить на сервере
    pause
    exit /b 1
)

echo [4/5] Перезапуск приложения...
ssh %VPS_USER%@%VPS_IP% "pm2 restart moe-dobro-api || pm2 start /var/www/moe-dobro/backend/src/server.js --name moe-dobro-api && pm2 save"

if errorlevel 1 (
    echo ОШИБКА: Не удалось перезапустить приложение
    pause
    exit /b 1
)

echo [5/5] Очистка...
del moe-dobro.tar.gz

echo.
echo ========================================
echo   Развертывание завершено успешно!
echo ========================================
echo.
echo API доступен по адресу: http://%VPS_IP%/api
echo.
echo Проверка статуса:
ssh %VPS_USER%@%VPS_IP% "pm2 status"

pause
