# 🚀 Быстрый запуск

## Автоматический запуск (рекомендуется)

### Windows
```bash
start.bat
```

### Linux/Mac
```bash
chmod +x start.sh
./start.sh
```

Скрипт автоматически:
- Проверит наличие Docker, Node.js и Flutter
- Запустит PostgreSQL в Docker (порт 5433)
- Установит зависимости (если нужно)
- Запустит Backend API (порт 3003)
- Запустит Flutter Web (порт 3300)

## Ручной запуск

### 1. Запуск базы данных
```bash
docker-compose up -d
```

### 2. Запуск Backend
```bash
cd backend
npm install
cp ../.env.example .env
npm run dev
```

### 3. Запуск Flutter
```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port 3300
```

## Доступ к приложению

- 🌐 **Flutter Web**: http://localhost:3300
- 🚀 **Backend API**: http://localhost:3003/api
- 🗄️ **PostgreSQL**: localhost:5433

## Тестовые данные

Для входа используйте:
- Телефон: `+79991234567`, Пароль: `password123`
- Телефон: `+79991234568`, Пароль: `password123`
- Телефон: `+79991234569`, Пароль: `password123`

**Все тестовые пользователи имеют пароль:** `password123`

## Остановка

### Windows
Закройте все окна командной строки или нажмите Ctrl+C

### Linux/Mac
Нажмите Ctrl+C в терминале

Для остановки Docker:
```bash
docker-compose down
```
