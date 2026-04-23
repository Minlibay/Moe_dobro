# 🚀 Быстрый старт развертывания на VPS

## Вариант 1: Автоматическая установка (рекомендуется)

### На VPS (185.40.4.195):

```bash
# 1. Подключиться к серверу
ssh root@185.40.4.195

# 2. Скачать и запустить скрипт установки
wget https://raw.githubusercontent.com/YOUR_REPO/setup-vps.sh
# Или скопировать файл setup-vps.sh на сервер
chmod +x setup-vps.sh
./setup-vps.sh

# 3. Загрузить файлы проекта (с локальной машины)
# На локальной машине выполнить:
scp -r D:\buble\backend root@185.40.4.195:/var/www/moe-dobro/

# 4. На сервере: установить зависимости
cd /var/www/moe-dobro/backend
npm install --production

# 5. Создать .env файл
cp .env.example .env
nano .env
# Изменить JWT_SECRET на случайную строку (сгенерировать командой ниже)

# Генерация JWT_SECRET:
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# 6. Инициализировать базу данных
psql -U admin -d moe_dobro -f database/init.sql

# Выполнить миграции
for file in database/migrations/*.sql; do
  psql -U admin -d moe_dobro -f "$file"
done

# 7. Создать директории
mkdir -p uploads logs
chown -R www-data:www-data uploads logs
chmod -R 755 uploads

# 8. Запустить приложение
pm2 start src/server.js --name moe-dobro-api
pm2 startup
pm2 save

# 9. Проверить статус
pm2 status
pm2 logs moe-dobro-api
```

## Вариант 2: Ручная установка

Следуйте подробной инструкции в файле `DEPLOYMENT_GUIDE.md`

## Проверка работы

```bash
# На сервере
curl http://localhost:3003/api

# С локальной машины
curl http://185.40.4.195/api
```

## Обновление приложения

### С локальной машины:

```bash
# Использовать скрипт deploy.sh
chmod +x deploy.sh
./deploy.sh
```

### Или вручную на сервере:

```bash
ssh root@185.40.4.195
cd /var/www/moe-dobro/backend
git pull  # или загрузить новые файлы через scp
npm install --production
pm2 restart moe-dobro-api
```

## Настройка Flutter приложения

В файле `lib/config/api_config.dart` измените:

```dart
static const String baseUrl = 'http://185.40.4.195/api';
```

Пересоберите приложение:

```bash
cd mobile
flutter build apk --release
# или для web
flutter build web
```

## Полезные команды

```bash
# Статус сервисов
pm2 status
systemctl status nginx
systemctl status postgresql

# Логи
pm2 logs moe-dobro-api
tail -f /var/log/nginx/error.log

# Перезапуск
pm2 restart moe-dobro-api
systemctl restart nginx

# Бэкап БД
pg_dump -U admin moe_dobro > backup_$(date +%Y%m%d).sql
```

## Важные URL

- **API**: http://185.40.4.195/api
- **Uploads**: http://185.40.4.195/uploads/
- **Главная**: http://185.40.4.195/

## Безопасность (TODO после базовой настройки)

1. ✅ Изменить пароль PostgreSQL
2. ✅ Сгенерировать уникальный JWT_SECRET
3. ⬜ Настроить домен
4. ⬜ Установить SSL сертификат (Let's Encrypt)
5. ⬜ Настроить автоматические бэкапы
6. ⬜ Настроить мониторинг

## Troubleshooting

### Backend не запускается
```bash
pm2 logs moe-dobro-api --lines 50
```

### Ошибка подключения к БД
```bash
systemctl status postgresql
psql -U admin -d moe_dobro -h localhost
```

### Nginx 502 Bad Gateway
```bash
pm2 status  # Проверить что backend запущен
curl http://localhost:3003/api  # Проверить прямое подключение
tail -f /var/log/nginx/error.log
```

## Контакты

После успешного развертывания:
- API: http://185.40.4.195/api
- Документация: См. DEPLOYMENT_GUIDE.md
