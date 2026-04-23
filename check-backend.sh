#!/bin/bash

# Скрипт для диагностики backend на VPS

echo "=== Проверка backend на VPS ==="
echo ""

# Остановить PM2
echo "Останавливаем PM2..."
pm2 stop moe-dobro-api

# Перейти в директорию backend
cd /var/www/buble-master/backend

# Запустить backend напрямую
echo "Запускаем backend..."
node src/server.js
