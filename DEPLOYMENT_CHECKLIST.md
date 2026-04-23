# ✅ Чеклист развертывания на VPS

## Подготовка (на локальной машине)

- [ ] Убедиться что есть SSH доступ к серверу: `ssh root@185.40.4.195`
- [ ] Проверить что все файлы проекта на месте
- [ ] Убедиться что backend работает локально

## Первоначальная настройка VPS (один раз)

### 1. Подключение к серверу
```bash
ssh root@185.40.4.195
```

### 2. Загрузка скрипта установки
```bash
# Вариант А: Скопировать с локальной машины
# На Windows (в Git Bash или PowerShell):
scp D:\buble\setup-vps.sh root@185.40.4.195:/root/

# Вариант Б: Создать вручную на сервере
nano setup-vps.sh
# Скопировать содержимое из файла setup-vps.sh
```

### 3. Запуск установки
```bash
chmod +x setup-vps.sh
./setup-vps.sh
```

**Время выполнения:** ~5-10 минут

- [ ] Node.js установлен
- [ ] PostgreSQL установлен и настроен
- [ ] Nginx установлен и настроен
- [ ] PM2 установлен
- [ ] Firewall настроен
- [ ] База данных создана

## Развертывание приложения

### 4. Загрузка файлов проекта

**На Windows:**
```bash
# Вариант А: Использовать deploy.bat
deploy.bat

# Вариант Б: Вручную
scp -r D:\buble\backend root@185.40.4.195:/var/www/moe-dobro/
```

**На Linux/Mac:**
```bash
./deploy.sh
```

- [ ] Файлы загружены на сервер

### 5. Настройка окружения (на сервере)

```bash
cd /var/www/moe-dobro/backend

# Установить зависимости
npm install --production

# Создать .env файл
cp .env.example .env
nano .env
```

**В .env файле изменить:**
```env
JWT_SECRET=<сгенерировать случайную строку>
NODE_ENV=production
```

**Генерация JWT_SECRET:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

- [ ] Зависимости установлены
- [ ] .env файл создан и настроен
- [ ] JWT_SECRET сгенерирован и установлен

### 6. Инициализация базы данных

```bash
cd /var/www/moe-dobro/backend

# Основная схема
psql -U admin -d moe_dobro -f database/init.sql

# Миграции
psql -U admin -d moe_dobro -f database/migrations/001_add_password_field.sql
psql -U admin -d moe_dobro -f database/migrations/002_add_sbp_support.sql
psql -U admin -d moe_dobro -f database/migrations/004_add_performance_indexes.sql
psql -U admin -d moe_dobro -f database/migrations/005_add_admin_role.sql
psql -U admin -d moe_dobro -f database/migrations/006_add_completion_fields.sql

# Опционально: тестовые данные
# psql -U admin -d moe_dobro -f database/seed_completed_fundraisers.sql
# psql -U admin -d moe_dobro -f database/seed_donations.sql
```

- [ ] База данных инициализирована
- [ ] Миграции выполнены
- [ ] Тестовые данные загружены (опционально)

### 7. Создание директорий и прав

```bash
cd /var/www/moe-dobro/backend
mkdir -p uploads logs
chown -R www-data:www-data uploads logs
chmod -R 755 uploads
```

- [ ] Директории созданы
- [ ] Права установлены

### 8. Запуск приложения

```bash
cd /var/www/moe-dobro/backend

# Запустить через PM2
pm2 start src/server.js --name moe-dobro-api

# Настроить автозапуск
pm2 startup
pm2 save

# Проверить статус
pm2 status
pm2 logs moe-dobro-api --lines 20
```

- [ ] Приложение запущено
- [ ] Автозапуск настроен
- [ ] Логи показывают успешный запуск

## Проверка работы

### 9. Тестирование API

```bash
# На сервере
curl http://localhost:3003/api

# С локальной машины
curl http://185.40.4.195/api

# Проверка конкретных эндпоинтов
curl http://185.40.4.195/api/fundraisers
```

**Ожидаемый результат:** JSON ответ от API

- [ ] API отвечает на localhost
- [ ] API доступен извне
- [ ] Эндпоинты работают корректно

### 10. Проверка Nginx

```bash
# Статус Nginx
systemctl status nginx

# Логи
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Тест конфигурации
nginx -t
```

- [ ] Nginx запущен
- [ ] Нет ошибок в логах
- [ ] Конфигурация валидна

### 11. Проверка PostgreSQL

```bash
# Статус
systemctl status postgresql

# Подключение
psql -U admin -d moe_dobro

# В psql:
\dt  # Список таблиц
SELECT COUNT(*) FROM users;
\q
```

- [ ] PostgreSQL запущен
- [ ] Подключение работает
- [ ] Таблицы созданы

## Настройка Flutter приложения

### 12. Обновление API URL

**Файл:** `mobile/lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'http://185.40.4.195/api';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'http://185.40.4.195/$path';
  }
}
```

- [ ] API URL обновлен
- [ ] Приложение пересобрано

### 13. Тестирование с приложением

```bash
# Пересборка Flutter приложения
cd mobile
flutter clean
flutter pub get
flutter build apk --release  # для Android
# или
flutter build web  # для Web
```

- [ ] Приложение собрано
- [ ] Подключение к API работает
- [ ] Загрузка данных работает
- [ ] Загрузка изображений работает

## Мониторинг и обслуживание

### 14. Настройка мониторинга

```bash
# Просмотр логов в реальном времени
pm2 logs moe-dobro-api

# Мониторинг ресурсов
pm2 monit

# Статус всех процессов
pm2 status
```

- [ ] Мониторинг настроен
- [ ] Логи доступны

### 15. Настройка бэкапов

```bash
# Создать директорию для бэкапов
mkdir -p /var/backups/moe-dobro

# Ручной бэкап
pg_dump -U admin moe_dobro > /var/backups/moe-dobro/backup_$(date +%Y%m%d).sql

# Автоматический бэкап (cron)
crontab -e
# Добавить строку:
# 0 3 * * * pg_dump -U admin moe_dobro > /var/backups/moe-dobro/backup_$(date +\%Y\%m\%d).sql
```

- [ ] Директория для бэкапов создана
- [ ] Ручной бэкап работает
- [ ] Автоматический бэкап настроен

## Безопасность (рекомендуется)

### 16. Дополнительная безопасность

```bash
# Изменить пароль PostgreSQL
sudo -u postgres psql
ALTER USER admin WITH PASSWORD 'новый_сложный_пароль';
\q

# Обновить .env файл с новым паролем
nano /var/www/moe-dobro/backend/.env

# Перезапустить приложение
pm2 restart moe-dobro-api
```

- [ ] Пароль БД изменен
- [ ] .env обновлен
- [ ] Приложение перезапущено

### 17. SSL сертификат (если есть домен)

```bash
# Установить Certbot
apt install -y certbot python3-certbot-nginx

# Получить сертификат
certbot --nginx -d yourdomain.com

# Автообновление
certbot renew --dry-run
```

- [ ] Certbot установлен
- [ ] SSL сертификат получен
- [ ] Автообновление настроено

## Финальная проверка

### 18. Полное тестирование

**API эндпоинты:**
- [ ] GET /api/fundraisers - список сборов
- [ ] GET /api/fundraisers/:id - детали сбора
- [ ] POST /api/auth/login - авторизация
- [ ] POST /api/auth/register - регистрация
- [ ] GET /api/users/:id - профиль пользователя
- [ ] GET /uploads/* - загрузка изображений

**Функциональность:**
- [ ] Регистрация пользователя
- [ ] Авторизация
- [ ] Создание сбора
- [ ] Загрузка изображений
- [ ] Просмотр сборов
- [ ] Донаты

**Производительность:**
- [ ] Время ответа API < 500ms
- [ ] Изображения загружаются быстро
- [ ] Нет утечек памяти

## Документация

### 19. Сохранение информации

**Сохранить в безопасном месте:**
- [ ] IP адрес сервера: 185.40.4.195
- [ ] SSH доступ: root@185.40.4.195
- [ ] Пароль PostgreSQL
- [ ] JWT_SECRET
- [ ] Расположение бэкапов: /var/backups/moe-dobro/

## Готово! 🎉

Ваше приложение развернуто и работает!

**Доступ:**
- API: http://185.40.4.195/api
- Uploads: http://185.40.4.195/uploads/
- Главная: http://185.40.4.195/

**Полезные команды:**
```bash
# Перезапуск
pm2 restart moe-dobro-api

# Логи
pm2 logs moe-dobro-api

# Статус
pm2 status

# Обновление кода
cd /var/www/moe-dobro/backend
git pull  # или загрузить через scp
npm install --production
pm2 restart moe-dobro-api
```

**Следующие шаги:**
1. Настроить домен (опционально)
2. Установить SSL сертификат
3. Настроить регулярные бэкапы
4. Настроить мониторинг uptime
5. Оптимизировать производительность
