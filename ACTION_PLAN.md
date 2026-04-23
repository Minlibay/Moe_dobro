# 🚀 ПЛАН ДЕЙСТВИЙ ПО УЛУЧШЕНИЮ

## 🔴 ФАЗА 1: КРИТИЧЕСКИЕ ИСПРАВЛЕНИЯ (1-3 дня)

### 1.1 Исправить утечку паролей ✅ ПРИОРИТЕТ #1
**Файл:** `backend/src/controllers/authController.js`

**Проблема:**
```javascript
// Строка 28 - пароль возвращается в ответе!
const user = result.rows[0];
```

**Решение:**
```javascript
// Вариант 1: Исключить из SELECT
const result = await pool.query(
  `INSERT INTO users (phone, password, full_name) VALUES ($1, $2, $3)
   RETURNING id, phone, full_name, avatar_url, bio, is_verified,
             total_donated, total_received, people_helped, fundraisers_count, created_at`,
  [phone, hashedPassword, full_name]
);

// Вариант 2: Удалить перед отправкой
const user = result.rows[0];
delete user.password;
```

### 1.2 Изменить JWT_SECRET ✅ ПРИОРИТЕТ #2
**Файл:** `backend/.env`

**Текущее:**
```
JWT_SECRET=your-secret-key-change-in-production
```

**Новое:**
```bash
# Сгенерировать криптостойкий ключ:
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 1.3 Добавить транзакции ✅ ПРИОРИТЕТ #3
**Файл:** `backend/src/controllers/fundraiserController.js`

**Проблема:** Строки 97-110 - нет транзакции

**Решение:**
```javascript
const client = await pool.connect();
try {
  await client.query('BEGIN');

  const result = await client.query(
    `INSERT INTO fundraisers (...) VALUES (...) RETURNING *`,
    [...]
  );

  await client.query(
    'UPDATE users SET fundraisers_count = fundraisers_count + 1 WHERE id = $1',
    [req.userId]
  );

  await client.query('COMMIT');
  res.status(201).json({ message: 'Сбор создан успешно', fundraiser: result.rows[0] });
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

### 1.4 Rate limiting для донатов ✅ ПРИОРИТЕТ #4
**Файл:** `backend/src/server.js`

**Добавить:**
```javascript
const donationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 час
  max: 10, // максимум 10 донатов в час
  message: { error: 'Слишком много донатов, попробуйте через час' }
});

app.use('/api/donations', donationLimiter, donationRoutes);
```

---

## 🟡 ФАЗА 2: ВАЖНЫЕ УЛУЧШЕНИЯ (1-2 недели)

### 2.1 Оптимизация SQL запросов

**Заменить SELECT * на конкретные поля:**
- `authController.js:9` - SELECT для проверки существования
- `authController.js:48` - SELECT для логина
- `fundraiserController.js:145` - SELECT для проверки прав

**Добавить индексы:**
```sql
-- backend/database/migrations/003_add_indexes.sql
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON donations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fundraisers_created_at ON fundraisers(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);
```

### 2.2 Централизованная обработка ошибок

**Создать:** `backend/src/middleware/errorHandler.js`
```javascript
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}

const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;

  if (process.env.NODE_ENV === 'development') {
    res.status(err.statusCode).json({
      error: err.message,
      stack: err.stack
    });
  } else {
    res.status(err.statusCode).json({
      error: err.isOperational ? err.message : 'Ошибка сервера'
    });
  }
};

module.exports = { AppError, errorHandler };
```

### 2.3 Структурированное логирование

**Установить Winston:**
```bash
cd backend
npm install winston
```

**Создать:** `backend/src/utils/logger.js`
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

module.exports = logger;
```

**Заменить все console.log/error:**
```javascript
// Было:
console.error('Ошибка регистрации:', error);

// Стало:
logger.error('Ошибка регистрации', { error: error.message, stack: error.stack });
```

### 2.4 Валидация и санитизация

**Добавить в:** `backend/src/middleware/validation.js`
```javascript
const sanitizeHtml = require('sanitize-html');

const sanitizeInput = (field) => {
  return body(field).customSanitizer(value => {
    if (typeof value === 'string') {
      return sanitizeHtml(value, {
        allowedTags: [],
        allowedAttributes: {}
      });
    }
    return value;
  });
};

const validateAmount = () => {
  return body('amount')
    .isFloat({ min: 1, max: 1000000 })
    .withMessage('Сумма должна быть от 1 до 1,000,000 рублей');
};

module.exports = {
  // ... existing
  sanitizeInput,
  validateAmount
};
```

---

## 🟢 ФАЗА 3: УЛУЧШЕНИЯ (1-2 месяца)

### 3.1 Тестирование

**Установить Jest:**
```bash
cd backend
npm install --save-dev jest supertest
```

**Создать:** `backend/tests/auth.test.js`
```javascript
const request = require('supertest');
const app = require('../src/server');

describe('Auth API', () => {
  test('POST /api/auth/register - should register new user', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        phone: '+79991234567',
        full_name: 'Test User',
        password: 'test123'
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    expect(response.body.user).not.toHaveProperty('password');
  });
});
```

### 3.2 Кеширование (Redis)

**Установить:**
```bash
npm install redis
```

**Создать:** `backend/src/config/redis.js`
```javascript
const redis = require('redis');
const client = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379
});

client.on('error', (err) => console.error('Redis error:', err));

const cache = {
  async get(key) {
    return await client.get(key);
  },
  async set(key, value, ttl = 300) {
    await client.setEx(key, ttl, JSON.stringify(value));
  },
  async del(key) {
    await client.del(key);
  }
};

module.exports = cache;
```

**Использовать в контроллерах:**
```javascript
// fundraiserController.js
exports.getAllFundraisers = async (req, res) => {
  const cacheKey = `fundraisers:${JSON.stringify(req.query)}`;

  // Проверить кеш
  const cached = await cache.get(cacheKey);
  if (cached) {
    return res.json(JSON.parse(cached));
  }

  // Запрос к БД
  const result = await pool.query(...);

  // Сохранить в кеш на 5 минут
  await cache.set(cacheKey, result.rows, 300);

  res.json(result.rows);
};
```

### 3.3 Push уведомления (FCM)

**Flutter - установить:**
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
```

**Backend - установить:**
```bash
npm install firebase-admin
```

**Создать:** `backend/src/services/pushNotification.js`
```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('../config/firebase-key.json'))
});

async function sendPushNotification(userId, title, body) {
  // Получить FCM token пользователя из БД
  const result = await pool.query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
  const token = result.rows[0]?.fcm_token;

  if (!token) return;

  await admin.messaging().send({
    token,
    notification: { title, body },
    data: { click_action: 'FLUTTER_NOTIFICATION_CLICK' }
  });
}

module.exports = { sendPushNotification };
```

### 3.4 Docker

**Создать:** `backend/Dockerfile`
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

**Создать:** `docker-compose.yml`
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: moe_dobro
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin123
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build: ./backend
    ports:
      - "3003:3000"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
    depends_on:
      - postgres

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

### 3.5 CI/CD Pipeline

**Создать:** `.github/workflows/ci.yml`
```yaml
name: CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      run: |
        cd backend
        npm ci

    - name: Run tests
      run: |
        cd backend
        npm test

    - name: Run linter
      run: |
        cd backend
        npm run lint

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Deploy to production
      run: |
        # Ваш скрипт деплоя
        echo "Deploying..."
```

---

## 📋 ЧЕКЛИСТ ПЕРЕД ПРОДАКШЕНОМ

### Безопасность
- [ ] Изменен JWT_SECRET на криптостойкий
- [ ] Пароли не возвращаются в API
- [ ] HTTPS настроен
- [ ] Helmet.js установлен
- [ ] Rate limiting на всех endpoints
- [ ] Валидация всех входных данных
- [ ] Санитизация HTML
- [ ] CORS правильно настроен
- [ ] Файлы проверяются на MIME type

### Производительность
- [ ] Индексы добавлены в БД
- [ ] SELECT * заменены на конкретные поля
- [ ] Кеширование настроено
- [ ] Compression включен
- [ ] CDN для статики
- [ ] Database connection pooling настроен

### Мониторинг
- [ ] Структурированное логирование (Winston)
- [ ] APM установлен (Sentry/DataDog)
- [ ] Health check endpoint
- [ ] Метрики собираются
- [ ] Алерты настроены

### Тестирование
- [ ] Unit тесты (>70% coverage)
- [ ] Integration тесты
- [ ] E2E тесты
- [ ] Load testing

### DevOps
- [ ] CI/CD pipeline
- [ ] Docker контейнеризация
- [ ] Автоматические бэкапы БД
- [ ] Rollback стратегия
- [ ] Мониторинг логов

### Документация
- [ ] API документация (Swagger)
- [ ] README для разработчиков
- [ ] Deployment guide
- [ ] Changelog

---

## 🎯 МЕТРИКИ УСПЕХА

### После Фазы 1 (Критические исправления)
- ✅ 0 критических уязвимостей безопасности
- ✅ Все транзакции атомарны
- ✅ Rate limiting работает

### После Фазы 2 (Важные улучшения)
- ✅ Время ответа API < 200ms (95 перцентиль)
- ✅ 0 SELECT * запросов
- ✅ Централизованное логирование

### После Фазы 3 (Улучшения)
- ✅ Test coverage > 70%
- ✅ Uptime > 99.9%
- ✅ Push уведомления работают
- ✅ CI/CD автоматизирован

---

## 💰 ОЦЕНКА ВРЕМЕНИ

| Фаза | Задачи | Время | Приоритет |
|------|--------|-------|-----------|
| Фаза 1 | Критические исправления | 1-3 дня | 🔴 СРОЧНО |
| Фаза 2 | Важные улучшения | 1-2 недели | 🟡 ВАЖНО |
| Фаза 3 | Улучшения | 1-2 месяца | 🟢 ЖЕЛАТЕЛЬНО |

**Минимум для запуска:** Фаза 1 (1-3 дня)
**Рекомендуется для запуска:** Фаза 1 + Фаза 2 (2-3 недели)
**Идеально:** Все фазы (2-3 месяца)

---

**Следующий шаг:** Начать с Фазы 1, задача 1.1 - исправить утечку паролей
