# Архитектура проекта "Моё добро"

## 📁 Структура проекта

```
moe-dobro/
├── backend/                    # Node.js + Express API
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js    # Подключение к PostgreSQL
│   │   ├── controllers/       # Бизнес-логика
│   │   │   ├── authController.js
│   │   │   ├── fundraiserController.js
│   │   │   ├── donationController.js
│   │   │   ├── achievementController.js
│   │   │   └── notificationController.js
│   │   ├── middleware/        # Middleware
│   │   │   ├── auth.js        # JWT аутентификация
│   │   │   └── upload.js      # Загрузка файлов
│   │   ├── routes/            # API роуты
│   │   │   ├── auth.js
│   │   │   ├── fundraisers.js
│   │   │   ├── donations.js
│   │   │   ├── achievements.js
│   │   │   └── notifications.js
│   │   └── server.js          # Главный файл сервера
│   ├── database/
│   │   └── init.sql           # Схема БД и начальные данные
│   └── package.json
│
├── mobile/                     # Flutter приложение
│   ├── lib/
│   │   ├── config/
│   │   │   └── api_config.dart        # API endpoints
│   │   ├── models/                    # Модели данных
│   │   │   ├── user.dart
│   │   │   ├── fundraiser.dart
│   │   │   ├── donation.dart
│   │   │   └── achievement.dart
│   │   ├── providers/                 # State management
│   │   │   ├── auth_provider.dart
│   │   │   ├── fundraiser_provider.dart
│   │   │   ├── donation_provider.dart
│   │   │   └── achievement_provider.dart
│   │   ├── screens/                   # UI экраны
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── fundraiser/
│   │   │   │   ├── fundraiser_detail_screen.dart
│   │   │   │   └── create_fundraiser_screen.dart
│   │   │   ├── profile/
│   │   │   │   └── profile_screen.dart
│   │   │   └── achievements/
│   │   │       └── achievements_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart       # HTTP клиент
│   │   ├── widgets/                   # Переиспользуемые виджеты
│   │   │   ├── fundraiser_card.dart
│   │   │   └── category_chip.dart
│   │   └── main.dart                  # Точка входа
│   └── pubspec.yaml
│
├── docker-compose.yml          # Docker конфигурация
├── .env.example               # Пример переменных окружения
├── start.sh                   # Скрипт запуска (Linux/Mac)
├── start.bat                  # Скрипт запуска (Windows)
├── README.md                  # Основная документация
└── SETUP.md                   # Руководство по установке
```

## 🏗️ Технологический стек

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL 15
- **Authentication**: JWT (jsonwebtoken)
- **File Upload**: Multer
- **Validation**: express-validator

### Frontend (Mobile)
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: http, dio
- **UI**: Material Design 3
- **Fonts**: Google Fonts (Inter)
- **Image Handling**: image_picker, cached_network_image

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Database**: PostgreSQL in Docker

## 🔄 Поток данных

### Регистрация/Вход
```
User Input → AuthProvider → ApiService → Backend API → PostgreSQL
                ↓
            JWT Token → SharedPreferences
```

### Просмотр сборов
```
HomeScreen → FundraiserProvider → ApiService → GET /api/fundraisers
                ↓
            List<Fundraiser> → UI Update
```

### Создание пожертвования
```
DonateDialog → DonationProvider → ApiService (multipart/form-data)
                ↓
            POST /api/donations (screenshot + data)
                ↓
            Backend → Save to DB → Notification to fundraiser owner
                ↓
            Status: pending → awaiting approval
```

### Подтверждение пожертвования
```
Fundraiser Owner → Approve/Reject
                ↓
            PATCH /api/donations/:id/approve
                ↓
            Transaction:
            - Update donation status
            - Update fundraiser current_amount
            - Update user statistics
            - Check and award achievements
            - Send notification to donor
```

## 🗄️ Схема базы данных

### Таблицы

1. **users** - Пользователи
   - Профиль, статистика, контакты

2. **fundraisers** - Сборы средств
   - Цель, описание, реквизиты, прогресс

3. **donations** - Пожертвования
   - Сумма, скриншот, статус

4. **achievements** - Достижения
   - Условия получения, иконки

5. **user_achievements** - Полученные достижения
   - Связь пользователь-достижение

6. **notifications** - Уведомления
   - Типы событий, статус прочтения

### Связи
```
users (1) ←→ (N) fundraisers
users (1) ←→ (N) donations
users (1) ←→ (N) user_achievements
achievements (1) ←→ (N) user_achievements
fundraisers (1) ←→ (N) donations
users (1) ←→ (N) notifications
```

## 🎨 UI/UX Особенности

### Цветовая палитра
- **Primary**: #6C63FF (фиолетовый)
- **Secondary**: Градиент от primary
- **Background**: #F8F9FA (светло-серый)
- **Success**: Зеленый
- **Warning**: Оранжевый
- **Error**: Красный

### Компоненты
- **Cards**: Скругленные углы (16px), тени
- **Buttons**: Высота 56px, скругление 16px
- **Inputs**: Filled style, скругление 12-16px
- **Progress bars**: Скругленные, градиенты
- **Chips**: Категории и фильтры

### Анимации
- Плавные переходы между экранами
- Shimmer эффекты при загрузке
- Ripple эффекты на кнопках
- Pull-to-refresh

## 🔐 Безопасность

### Реализовано
- JWT токены для аутентификации
- Middleware для защищенных роутов
- Валидация входных данных
- Ограничение размера файлов (5MB)
- Фильтрация типов файлов (только изображения)

### Рекомендации для продакшена
- HTTPS обязательно
- Rate limiting (express-rate-limit)
- Helmet.js для HTTP заголовков
- CORS настройка
- Хеширование паролей (если добавите)
- SQL injection защита (используем параметризованные запросы)
- XSS защита
- CSRF токены

## 📊 Система достижений

### Категории
1. **Donor** (Донор) - за пожертвования
2. **Fundraiser** (Сборщик) - за создание сборов
3. **Community** (Сообщество) - за активность

### Базовые достижения
- 🌱 Первый шаг (1 пожертвование)
- ❤️ Щедрое сердце (5 людям помог)
- 🌟 Филантроп (20 людям помог)
- 🦸 Герой добра (50 людям помог)
- 💰 Начинающий благотворитель (1000₽)
- 💎 Большое сердце (10000₽)
- 👑 Меценат (50000₽)
- 🎯 Первый сбор
- 🏆 Успешный сбор (100%)
- ⭐ Звезда сообщества (100 донатов)

### Логика начисления
Автоматическая проверка при:
- Подтверждении пожертвования
- Закрытии сбора
- Обновлении статистики

## 🚀 Производительность

### Backend
- Connection pooling для PostgreSQL
- Индексы на часто запрашиваемые поля
- Транзакции для критичных операций

### Frontend
- Lazy loading изображений
- Кэширование сетевых изображений
- Provider для эффективного state management
- Pull-to-refresh для обновления данных

## 📱 Поддерживаемые платформы

- ✅ Android 5.0+ (API 21+)
- ✅ iOS 11.0+
- 🔄 Web (требует доработки)
- 🔄 Desktop (требует доработки)

## 🧪 Тестирование

### Ручное тестирование
1. Регистрация нового пользователя
2. Просмотр списка сборов
3. Фильтрация по категориям
4. Создание пожертвования
5. Подтверждение пожертвования
6. Создание собственного сбора
7. Просмотр профиля и статистики
8. Проверка достижений

### Автоматизированное (TODO)
- Unit тесты для providers
- Widget тесты для UI
- Integration тесты
- API тесты (Postman/Jest)

## 📈 Метрики успеха

- Количество зарегистрированных пользователей
- Количество активных сборов
- Общая сумма пожертвований
- Среднее время подтверждения доната
- Конверсия: просмотр → пожертвование
- Retention rate пользователей

## 🔄 Будущие улучшения

### Высокий приоритет
- Push-уведомления (Firebase Cloud Messaging)
- Верификация пользователей (документы)
- Модерация сборов
- Отчеты о расходовании средств

### Средний приоритет
- Интеграция платежных систем (ЮKassa, Stripe)
- Социальные сети (шаринг, авторизация)
- Чат между пользователями
- Комментарии к сборам

### Низкий приоритет
- Темная тема
- Мультиязычность (i18n)
- Аналитика и дашборды
- Экспорт данных
