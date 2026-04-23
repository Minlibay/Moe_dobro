@echo off
chcp 65001 >nul
echo ========================================
echo   Запуск приложения "Моё добро"
echo ========================================
echo.

REM Проверка Docker
echo [1/5] Проверка Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker не установлен или не запущен
    echo Установите Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo ✅ Docker найден

REM Проверка Node.js
echo [2/5] Проверка Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js не установлен
    echo Установите Node.js: https://nodejs.org/
    pause
    exit /b 1
)
echo ✅ Node.js найден

REM Проверка Flutter
echo [3/5] Проверка Flutter...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter не установлен
    echo Установите Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo ✅ Flutter найден

REM Запуск Docker контейнеров
echo.
echo [4/5] Запуск PostgreSQL в Docker...
docker-compose up -d
if errorlevel 1 (
    echo ❌ Ошибка запуска Docker контейнеров
    pause
    exit /b 1
)
echo ✅ PostgreSQL запущен на порту 5433

REM Ожидание готовности базы данных
echo Ожидание готовности базы данных...
timeout /t 5 /nobreak >nul

REM Запуск backend
echo.
echo [5/5] Запуск Backend API...
cd backend

if not exist "node_modules" (
    echo 📥 Установка зависимостей backend...
    call npm install
)

if not exist ".env" (
    echo 📝 Создание .env файла...
    copy ..\.env.example .env
)

start "Backend API" cmd /k "npm run dev"
cd ..
echo ✅ Backend API запускается на порту 3003

REM Запуск Flutter
echo.
echo Запуск Flutter Web...
cd mobile

if not exist "pubspec.lock" (
    echo 📥 Установка зависимостей Flutter...
    call flutter pub get
)

start "Flutter Web" cmd /k "flutter run -d chrome --web-port 3300"
cd ..

echo.
echo ========================================
echo   Все сервисы запущены!
echo ========================================
echo.
echo 🗄️  PostgreSQL:  localhost:5433
echo 🚀 Backend API: http://localhost:3003/api
echo 🌐 Flutter Web: http://localhost:3300
echo.
echo Для остановки закройте все окна или нажмите Ctrl+C
echo.
pause
