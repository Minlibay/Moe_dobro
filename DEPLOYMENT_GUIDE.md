# Руководство по развертыванию на VPS (Ubuntu 24.04)

## Информация о сервере
- IP: 185.40.4.195
- ОС: Ubuntu 24.04
- Компоненты: Backend API + PostgreSQL

## Шаг 1: Подключение к серверу

```bash
ssh root@185.40.4.195
```

## Шаг 2: Установка необходимого ПО

```bash
# Обновление системы
apt update && apt upgrade -y

# Установка Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Установка PostgreSQL
apt install -y postgresql postgresql-contrib

# Установка Nginx
apt install -y nginx

# Установка PM2 для управления процессами
npm install -g pm2

# Установка Git
apt install -y git
```

## Шаг 3: Настройка PostgreSQL

```bash
# Переключиться на пользователя postgres
sudo -u postgres psql

# В psql выполнить:
CREATE DATABASE moe_dobro;
CREATE USER admin WITH PASSWORD 'admin123';
GRANT ALL PRIVILEGES ON DATABASE moe_dobro TO admin;
\q

# Разрешить подключения с localhost
nano /etc/postgresql/16/main/pg_hba.conf
# Добавить строку:
# local   all   admin   md5

# Перезапустить PostgreSQL
systemctl restart postgresql
```

## Шаг 4: Клонирование проекта

```bash
# Создать директорию для проекта
mkdir -p /var/www/moe-dobro
cd /var/www/moe-dobro

# Клонировать репозиторий (замените на ваш URL)
git clone <your-repo-url> .

# Или загрузить файлы через SCP с локальной машины:
# scp -r D:\buble\backend root@185.40.4.195:/var/www/moe-dobro/
```

## Шаг 5: Настройка Backend

```bash
cd /var/www/moe-dobro/backend

# Установить зависимости
npm install --production

# Создать .env файл
nano .env
```

Содержимое `.env` файла:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=moe_dobro
DB_USER=admin
DB_PASSWORD=admin123

# Server
PORT=3003
NODE_ENV=production

# JWT
JWT_SECRET=ЗАМЕНИТЕ_НА_СЛУЧАЙНУЮ_СТРОКУ_МИНИМУМ_32_СИМВОЛА
JWT_EXPIRES_IN=7d

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_DIR=/var/www/moe-dobro/backend/uploads

# CORS (разрешить запросы с вашего домена)
ALLOWED_ORIGINS=http://185.40.4.195,http://localhost:3000
```

**ВАЖНО:** Сгенерируйте безопасный JWT_SECRET:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Шаг 6: Инициализация базы данных

```bash
cd /var/www/moe-dobro/backend

# Выполнить SQL скрипты
psql -U admin -d moe_dobro -f database/init.sql

# Выполнить миграции (если есть)
for file in database/migrations/*.sql; do
  psql -U admin -d moe_dobro -f "$file"
done
```

## Шаг 7: Создание директорий и прав доступа

```bash
# Создать директорию для загрузок
mkdir -p /var/www/moe-dobro/backend/uploads
mkdir -p /var/www/moe-dobro/backend/logs

# Установить права
chown -R www-data:www-data /var/www/moe-dobro/backend/uploads
chown -R www-data:www-data /var/www/moe-dobro/backend/logs
chmod -R 755 /var/www/moe-dobro/backend/uploads
```

## Шаг 8: Запуск Backend через PM2

```bash
cd /var/www/moe-dobro/backend

# Запустить приложение
pm2 start src/server.js --name moe-dobro-api

# Настроить автозапуск при перезагрузке
pm2 startup
pm2 save

# Проверить статус
pm2 status
pm2 logs moe-dobro-api
```

## Шаг 9: Настройка Nginx

```bash
# Создать конфигурацию Nginx
nano /etc/nginx/sites-available/moe-dobro
```

Содержимое конфигурации:

```nginx
server {
    listen 80;
    server_name 185.40.4.195;

    # Увеличить размер загружаемых файлов
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

    # Статические файлы (загруженные изображения)
    location /uploads {
        alias /var/www/moe-dobro/backend/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Корневая страница (можно добавить простую HTML страницу)
    location / {
        root /var/www/moe-dobro/public;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
```

```bash
# Создать простую главную страницу
mkdir -p /var/www/moe-dobro/public
echo '<h1>Моё добро API</h1><p>API работает на <a href="/api">/api</a></p>' > /var/www/moe-dobro/public/index.html

# Активировать конфигурацию
ln -s /etc/nginx/sites-available/moe-dobro /etc/nginx/sites-enabled/

# Удалить дефолтную конфигурацию
rm /etc/nginx/sites-enabled/default

# Проверить конфигурацию
nginx -t

# Перезапустить Nginx
systemctl restart nginx
```

## Шаг 10: Настройка Firewall

```bash
# Разрешить HTTP, HTTPS и SSH
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
ufw status
```

## Шаг 11: Проверка работы

```bash
# Проверить статус всех сервисов
systemctl status postgresql
systemctl status nginx
pm2 status

# Проверить API
curl http://localhost:3003/api
curl http://185.40.4.195/api

# Проверить логи
pm2 logs moe-dobro-api
tail -f /var/log/nginx/error.log
```

## Шаг 12: Настройка SSL (опционально, но рекомендуется)

```bash
# Установить Certbot
apt install -y certbot python3-certbot-nginx

# Получить SSL сертификат (нужен домен, не IP)
# certbot --nginx -d yourdomain.com

# Для IP адреса SSL не работает, нужен домен
```

## Полезные команды PM2

```bash
# Перезапустить приложение
pm2 restart moe-dobro-api

# Остановить приложение
pm2 stop moe-dobro-api

# Посмотреть логи
pm2 logs moe-dobro-api

# Посмотреть использование ресурсов
pm2 monit

# Удалить приложение из PM2
pm2 delete moe-dobro-api
```

## Обновление приложения

```bash
cd /var/www/moe-dobro/backend

# Получить последние изменения
git pull

# Установить новые зависимости (если есть)
npm install --production

# Перезапустить приложение
pm2 restart moe-dobro-api
```

## Резервное копирование базы данных

```bash
# Создать бэкап
pg_dump -U admin moe_dobro > /var/backups/moe_dobro_$(date +%Y%m%d).sql

# Восстановить из бэкапа
psql -U admin moe_dobro < /var/backups/moe_dobro_20260419.sql

# Настроить автоматический бэкап (cron)
crontab -e
# Добавить строку (бэкап каждый день в 3:00):
# 0 3 * * * pg_dump -U admin moe_dobro > /var/backups/moe_dobro_$(date +\%Y\%m\%d).sql
```

## Мониторинг и логи

```bash
# Логи приложения
pm2 logs moe-dobro-api

# Логи Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Логи PostgreSQL
tail -f /var/log/postgresql/postgresql-16-main.log

# Использование диска
df -h

# Использование памяти
free -h

# Процессы
htop
```

## Настройка Flutter приложения для работы с VPS

В Flutter приложении измените API URL:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://185.40.4.195/api';
  // Или если используете домен:
  // static const String baseUrl = 'https://yourdomain.com/api';
}
```

## Troubleshooting

### Backend не запускается
```bash
pm2 logs moe-dobro-api --lines 100
# Проверить .env файл
# Проверить подключение к БД
```

### Ошибка подключения к БД
```bash
# Проверить что PostgreSQL запущен
systemctl status postgresql

# Проверить подключение
psql -U admin -d moe_dobro -h localhost

# Проверить pg_hba.conf
cat /etc/postgresql/16/main/pg_hba.conf
```

### Nginx возвращает 502
```bash
# Проверить что backend запущен
pm2 status
curl http://localhost:3003/api

# Проверить логи Nginx
tail -f /var/log/nginx/error.log
```

### Не загружаются изображения
```bash
# Проверить права доступа
ls -la /var/www/moe-dobro/backend/uploads

# Установить правильные права
chown -R www-data:www-data /var/www/moe-dobro/backend/uploads
chmod -R 755 /var/www/moe-dobro/backend/uploads
```

## Контакты и поддержка

После развертывания API будет доступен по адресу:
- **API**: http://185.40.4.195/api
- **Загруженные файлы**: http://185.40.4.195/uploads/

Для production рекомендуется:
1. Использовать домен вместо IP
2. Настроить SSL сертификат
3. Настроить регулярные бэкапы
4. Настроить мониторинг (например, UptimeRobot)
5. Использовать более сложные пароли для БД
