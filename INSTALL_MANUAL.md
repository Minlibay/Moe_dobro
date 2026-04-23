# Быстрая установка на VPS

## Шаг 1: Подключитесь к серверу
```bash
ssh root@185.40.4.195
# Пароль: XQ9114iFXF25
```

## Шаг 2: Установите Git
```bash
apt update
apt install -y git
```

## Шаг 3: Клонируйте репозиторий
```bash
cd /var/www
git clone https://github.com/edoblack55/buble moe-dobro
cd moe-dobro
```

## Шаг 4: Запустите скрипт автоматической установки
```bash
chmod +x setup-vps.sh
./setup-vps.sh
```

Скрипт автоматически установит:
- Node.js 20.x
- PostgreSQL
- Nginx
- PM2
- Настроит базу данных
- Настроит Nginx

## Шаг 5: Установите зависимости и запустите backend
```bash
cd /var/www/moe-dobro/backend
npm install --production

# Создайте .env файл
cp .env.example .env
nano .env
```

В .env измените:
```env
JWT_SECRET=<сгенерируйте случайную строку>
```

Генерация JWT_SECRET:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Шаг 6: Инициализируйте базу данных
```bash
psql -U admin -d moe_dobro -f database/init.sql

# Миграции
for file in database/migrations/*.sql; do
  psql -U admin -d moe_dobro -f "$file"
done
```

## Шаг 7: Создайте директории и запустите
```bash
mkdir -p uploads logs
chown -R www-data:www-data uploads logs
chmod -R 755 uploads

# Запустите приложение
pm2 start src/server.js --name moe-dobro-api
pm2 startup
pm2 save
```

## Шаг 8: Проверьте работу
```bash
pm2 status
pm2 logs moe-dobro-api

# Проверьте API
curl http://localhost:3003/api
curl http://185.40.4.195/api
```

## Готово! 🎉

API доступен по адресу: http://185.40.4.195/api

---

## Если нужно обновить код:
```bash
cd /var/www/moe-dobro
git pull
cd backend
npm install --production
pm2 restart moe-dobro-api
```
