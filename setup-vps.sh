#!/bin/bash

# Скрипт для первоначальной настройки VPS
# Запускать на сервере: bash setup-vps.sh

set -e

echo "🔧 Настройка VPS для Моё добро..."

# Обновление системы
echo "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка Node.js 20.x
echo "📦 Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Установка PostgreSQL
echo "📦 Установка PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Установка Nginx
echo "📦 Установка Nginx..."
apt install -y nginx

# Установка PM2
echo "📦 Установка PM2..."
npm install -g pm2

# Установка Git
echo "📦 Установка Git..."
apt install -y git

# Настройка PostgreSQL
echo "🗄️  Настройка PostgreSQL..."
sudo -u postgres psql << EOF
CREATE DATABASE moe_dobro;
CREATE USER admin WITH PASSWORD 'admin123';
GRANT ALL PRIVILEGES ON DATABASE moe_dobro TO admin;
ALTER DATABASE moe_dobro OWNER TO admin;
\q
EOF

# Настройка pg_hba.conf
echo "🔐 Настройка доступа к PostgreSQL..."
PG_VERSION=$(ls /etc/postgresql/)
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

if ! grep -q "local.*all.*admin.*md5" "$PG_HBA"; then
  echo "local   all   admin   md5" >> "$PG_HBA"
fi

systemctl restart postgresql

# Создание директории проекта
echo "📁 Создание директории проекта..."
mkdir -p /var/www/moe-dobro/backend
mkdir -p /var/www/moe-dobro/public

# Создание простой главной страницы
cat > /var/www/moe-dobro/public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Моё добро API</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #6C63FF; }
        .status { background: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .link { color: #6C63FF; text-decoration: none; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🌟 Моё добро - API сервер</h1>
    <div class="status">
        <p>✅ Сервер работает</p>
        <p>API доступен по адресу: <a href="/api" class="link">/api</a></p>
    </div>
    <p>Это backend сервер для мобильного приложения "Моё добро"</p>
</body>
</html>
EOF

# Настройка Nginx
echo "🌐 Настройка Nginx..."
cat > /etc/nginx/sites-available/moe-dobro << 'EOF'
server {
    listen 80;
    server_name 185.40.4.195;

    client_max_body_size 10M;

    # API Backend
    location /api {
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Статические файлы
    location /uploads {
        alias /var/www/moe-dobro/backend/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Главная страница
    location / {
        root /var/www/moe-dobro/public;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
EOF

# Активация конфигурации Nginx
ln -sf /etc/nginx/sites-available/moe-dobro /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка и перезапуск Nginx
nginx -t
systemctl restart nginx

# Настройка Firewall
echo "🔥 Настройка Firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

# Создание .env шаблона
echo "📝 Создание .env шаблона..."
cat > /var/www/moe-dobro/backend/.env.example << 'EOF'
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=moe_dobro
DB_USER=admin
DB_PASSWORD=admin123

# Server
PORT=3003
NODE_ENV=production

# JWT - ОБЯЗАТЕЛЬНО ЗАМЕНИТЕ НА СВОЙ СЕКРЕТНЫЙ КЛЮЧ!
JWT_SECRET=ЗАМЕНИТЕ_МЕНЯ_НА_СЛУЧАЙНУЮ_СТРОКУ_32_СИМВОЛА
JWT_EXPIRES_IN=7d

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_DIR=/var/www/moe-dobro/backend/uploads

# CORS
ALLOWED_ORIGINS=http://185.40.4.195,http://localhost:3000
EOF

echo ""
echo "✅ Настройка VPS завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Загрузите файлы проекта в /var/www/moe-dobro/backend/"
echo "2. Создайте .env файл: cp /var/www/moe-dobro/backend/.env.example /var/www/moe-dobro/backend/.env"
echo "3. Отредактируйте .env и замените JWT_SECRET на случайную строку"
echo "4. Инициализируйте базу данных: psql -U admin -d moe_dobro -f /var/www/moe-dobro/backend/database/init.sql"
echo "5. Запустите приложение: cd /var/www/moe-dobro/backend && pm2 start src/server.js --name moe-dobro-api"
echo "6. Сохраните PM2: pm2 startup && pm2 save"
echo ""
echo "🌐 После запуска API будет доступен по адресу: http://185.40.4.195/api"
