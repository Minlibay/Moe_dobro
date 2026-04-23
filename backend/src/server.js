const express = require('express');
const cors = require('cors');
const path = require('path');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const fundraiserRoutes = require('./routes/fundraisers');
const donationRoutes = require('./routes/donations');
const achievementRoutes = require('./routes/achievements');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');
const userRoutes = require('./routes/users');
const supportRoutes = require('./routes/support');
const legalRoutes = require('./routes/legal');

const app = express();
const PORT = process.env.PORT || 3000;

// Rate limiting для защиты от спама
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 1000, // максимум 1000 запросов с одного IP (для разработки)
  message: { error: 'Слишком много запросов, попробуйте позже' }
});

// Более строгий лимит для авторизации
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 50, // максимум 50 попыток входа/регистрации (для разработки)
  message: { error: 'Слишком много попыток входа, попробуйте через 15 минут' }
});

// Лимит для донатов
const donationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 час
  max: 10, // максимум 10 донатов в час
  message: { error: 'Слишком много донатов, попробуйте через час' }
});

// Логирование HTTP запросов
app.use(morgan('dev'));

// Безопасность HTTP заголовков
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: {
    directives: {
      ...helmet.contentSecurityPolicy.getDefaultDirectives(),
      "img-src": ["'self'", "data:", "http://localhost:5173", "http://127.0.0.1:5173"],
    },
  },
}));

// Сжатие ответов
app.use(compression());

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Применяем общий rate limiter ко всем запросам
app.use('/api/', limiter);

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/fundraisers', fundraiserRoutes);
app.use('/api/donations', donationRoutes);
app.use('/api/achievements', achievementRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/legal', legalRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Моё добро API работает' });
});

// Catch-all для несуществующих роутов
app.use((req, res) => {
  logger.warn('404: endpoint не найден', { method: req.method, path: req.path, originalUrl: req.originalUrl });
  res.status(404).json({ error: ' endpoint не найден', path: req.path });
});

app.use((err, req, res, next) => {
  console.error('Ошибка:', err);

  // Обработка ошибок multer
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'Файл слишком большой (максимум 10MB)' });
    }
    return res.status(400).json({ error: `Ошибка загрузки файла: ${err.message}` });
  }

  res.status(err.status || 500).json({
    error: err.message || 'Внутренняя ошибка сервера'
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Сервер запущен на порту ${PORT}`);
  console.log(`📡 API доступен по адресу: http://localhost:${PORT}/api`);
});

module.exports = app;
