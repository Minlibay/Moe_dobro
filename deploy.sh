#!/bin/bash

# Скрипт для быстрого развертывания на VPS
# Использование: ./deploy.sh

set -e

echo "🚀 Начало развертывания Моё добро на VPS..."

# Переменные
VPS_IP="185.40.4.195"
VPS_USER="root"
PROJECT_DIR="/var/www/moe-dobro"

echo "📦 Упаковка файлов..."
tar -czf moe-dobro.tar.gz \
  backend/ \
  --exclude=backend/node_modules \
  --exclude=backend/uploads \
  --exclude=backend/logs \
  --exclude=backend/.env

echo "📤 Загрузка на сервер..."
scp moe-dobro.tar.gz ${VPS_USER}@${VPS_IP}:/tmp/

echo "🔧 Установка на сервере..."
ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
set -e

# Создать директорию проекта
mkdir -p /var/www/moe-dobro
cd /var/www/moe-dobro

# Распаковать файлы
tar -xzf /tmp/moe-dobro.tar.gz
rm /tmp/moe-dobro.tar.gz

# Установить зависимости
cd backend
npm install --production

# Создать необходимые директории
mkdir -p uploads logs

# Установить права
chown -R www-data:www-data uploads logs
chmod -R 755 uploads

# Перезапустить приложение через PM2
if pm2 list | grep -q "moe-dobro-api"; then
  echo "♻️  Перезапуск приложения..."
  pm2 restart moe-dobro-api
else
  echo "🆕 Первый запуск приложения..."
  pm2 start src/server.js --name moe-dobro-api
  pm2 save
fi

echo "✅ Развертывание завершено!"
pm2 status

ENDSSH

echo "🎉 Готово! API доступен по адресу: http://${VPS_IP}/api"
echo "📝 Не забудьте настроить .env файл на сервере!"

# Удалить локальный архив
rm moe-dobro.tar.gz
