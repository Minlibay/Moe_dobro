const pool = require('../config/database');
const logger = require('../utils/logger');

const adminMiddleware = async (req, res, next) => {
  try {
    // Проверяем, что пользователь авторизован (должен быть установлен authMiddleware перед этим)
    if (!req.userId) {
      return res.status(401).json({ error: 'Необходима авторизация' });
    }

    // Проверяем, является ли пользователь администратором
    const result = await pool.query(
      'SELECT is_admin FROM users WHERE id = $1',
      [req.userId]
    );

    if (result.rows.length === 0) {
      logger.warn('User not found in admin check', { userId: req.userId });
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    if (!result.rows[0].is_admin) {
      logger.warn('Non-admin user attempted to access admin endpoint', { userId: req.userId });
      return res.status(403).json({ error: 'Доступ запрещен. Требуются права администратора' });
    }

    // Пользователь является администратором, продолжаем
    logger.debug('Admin access granted', { userId: req.userId });
    next();
  } catch (error) {
    logger.error('Error in admin middleware', { error: error.message, userId: req.userId });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

module.exports = adminMiddleware;
