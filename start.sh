#!/bin/bash

echo "========================================"
echo "  Запуск приложения 'Моё добро'"
echo "========================================"
echo ""

# Проверка Docker
echo "[1/5] Проверка Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен"
    echo "Установите Docker: https://www.docker.com/products/docker-desktop"
    exit 1
fi
echo "✅ Docker найден"

# Проверка Node.js
echo "[2/5] Проверка Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не установлен"
    echo "Установите Node.js: https://nodejs.org/"
    exit 1
fi
echo "✅ Node.js найден"

# Проверка Flutter
echo "[3/5] Проверка Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не установлен"
    echo "Установите Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo "✅ Flutter найден"

# Запуск Docker контейнеров
echo ""
echo "[4/5] Запуск PostgreSQL в Docker..."
docker-compose up -d
if [ $? -ne 0 ]; then
    echo "❌ Ошибка запуска Docker контейнеров"
    exit 1
fi
echo "✅ PostgreSQL запущен на порту 5433"

# Ожидание готовности базы данных
echo "Ожидание готовности базы данных..."
sleep 5

# Запуск backend
echo ""
echo "[5/5] Запуск Backend API..."
cd backend

if [ ! -d "node_modules" ]; then
    echo "📥 Установка зависимостей backend..."
    npm install
fi

if [ ! -f ".env" ]; then
    echo "📝 Создание .env файла..."
    cp ../.env.example .env
fi

npm run dev &
BACKEND_PID=$!
cd ..
echo "✅ Backend API запускается на порту 3003"

# Запуск Flutter
echo ""
echo "Запуск Flutter Web..."
cd mobile

if [ ! -f "pubspec.lock" ]; then
    echo "📥 Установка зависимостей Flutter..."
    flutter pub get
fi

flutter run -d chrome --web-port 3300 &
FLUTTER_PID=$!
cd ..

echo ""
echo "========================================"
echo "  Все сервисы запущены!"
echo "========================================"
echo ""
echo "🗄️  PostgreSQL:  localhost:5433"
echo "🚀 Backend API: http://localhost:3003/api"
echo "🌐 Flutter Web: http://localhost:3300"
echo ""
echo "Для остановки нажмите Ctrl+C"
echo ""

# Функция для остановки всех процессов
cleanup() {
    echo ""
    echo "Остановка сервисов..."
    kill $BACKEND_PID 2>/dev/null
    kill $FLUTTER_PID 2>/dev/null
    docker-compose down
    exit 0
}

trap cleanup SIGINT SIGTERM

# Ожидание завершения
wait
