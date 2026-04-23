# Моё добро - Руководство по запуску

## 📋 Требования

- **Docker Desktop** (для PostgreSQL)
- **Node.js** 16+ и npm
- **Flutter** 3.0+
- **Git**

## 🚀 Быстрый старт

### Windows

```bash
start.bat
```

### Linux/Mac

```bash
chmod +x start.sh
./start.sh
```

## 📝 Ручной запуск

### 1. База данных

```bash
docker-compose up -d
```

Проверка:
```bash
docker ps
```

### 2. Backend API

```bash
cd backend
npm install
cp ../.env.example .env
npm run dev
```

Backend будет доступен на `http://localhost:3000`

### 3. Flutter приложение

```bash
cd mobile
flutter pub get
flutter run
```

Выберите устройство (эмулятор Android/iOS или физическое устройство).

## 🔧 Конфигурация

### Backend (.env)

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=moe_dobro
DB_USER=admin
DB_PASSWORD=admin123

PORT=3000
JWT_SECRET=your-secret-key-change-in-production
```

### Flutter (lib/config/api_config.dart)

Если backend на другом хосте:
```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
```

## 📱 Тестирование

### Создание тестового пользователя

1. Запустите приложение
2. Нажмите "Зарегистрироваться"
3. Введите:
   - Имя: Тестовый Пользователь
   - Телефон: +79991234567

### Тестовый сценарий

1. **Просмотр сборов** - главный экран
2. **Фильтрация** - выберите категорию
3. **Детали сбора** - нажмите на карточку
4. **Пожертвование**:
   - Нажмите "Помочь"
   - Скопируйте реквизиты
   - Введите сумму (минимум 100₽)
   - Прикрепите скриншот
   - Отправьте на проверку
5. **Создание сбора** - доступно после первого пожертвования
6. **Профиль** - статистика и достижения
7. **Достижения** - прогресс и награды

## 🗄️ База данных

### Подключение к PostgreSQL

```bash
docker exec -it moe_dobro_db psql -U admin -d moe_dobro
```

### Полезные команды

```sql
-- Список таблиц
\dt

-- Просмотр пользователей
SELECT * FROM users;

-- Просмотр сборов
SELECT * FROM fundraisers;

-- Просмотр пожертвований
SELECT * FROM donations;

-- Просмотр достижений
SELECT * FROM achievements;
```

## 🐛 Решение проблем

### Backend не запускается

```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

### База данных не доступна

```bash
docker-compose down
docker-compose up -d
```

### Flutter ошибки

```bash
cd mobile
flutter clean
flutter pub get
```

### Порт 3000 занят

Измените PORT в `.env` файле:
```env
PORT=3001
```

И в Flutter `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3001/api';
```

## 📊 API Endpoints

### Аутентификация
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход
- `GET /api/auth/profile` - Профиль (требует токен)
- `PUT /api/auth/profile` - Обновление профиля

### Сборы
- `GET /api/fundraisers` - Список сборов
- `GET /api/fundraisers/:id` - Детали сбора
- `POST /api/fundraisers` - Создать сбор (требует токен)
- `GET /api/fundraisers/my` - Мои сборы

### Пожертвования
- `POST /api/donations` - Создать пожертвование
- `GET /api/donations/my` - Мои пожертвования
- `GET /api/donations/pending` - Ожидающие проверки
- `PATCH /api/donations/:id/approve` - Подтвердить
- `PATCH /api/donations/:id/reject` - Отклонить

### Достижения
- `GET /api/achievements/all` - Все достижения
- `GET /api/achievements/my` - Мои достижения

### Уведомления
- `GET /api/notifications` - Список уведомлений
- `PATCH /api/notifications/:id/read` - Отметить прочитанным

## 🎨 Кастомизация

### Цветовая схема

Измените в `mobile/lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF6C63FF), // Ваш цвет
  brightness: Brightness.light,
),
```

### Логотип

Замените эмодзи ❤️ на ваш логотип в:
- `mobile/lib/screens/splash_screen.dart`
- `mobile/lib/screens/auth/login_screen.dart`
- `mobile/lib/screens/auth/register_screen.dart`

## 📦 Сборка для продакшена

### Android

```bash
cd mobile
flutter build apk --release
```

APK будет в `mobile/build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
cd mobile
flutter build ios --release
```

## 🔐 Безопасность

⚠️ **Важно для продакшена:**

1. Измените `JWT_SECRET` в `.env`
2. Используйте сильные пароли для БД
3. Настройте HTTPS
4. Добавьте rate limiting
5. Валидация файлов (размер, тип)
6. Настройте CORS правильно

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи backend
2. Проверьте логи Docker
3. Проверьте Flutter console

## 🎯 Roadmap

- [ ] Push-уведомления
- [ ] Интеграция платежных систем
- [ ] Социальные сети (шаринг)
- [ ] Чат между пользователями
- [ ] Верификация пользователей
- [ ] Модерация сборов
- [ ] Аналитика и отчеты
