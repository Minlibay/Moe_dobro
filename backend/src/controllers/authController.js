const pool = require('../config/database');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const logger = require('../utils/logger');

exports.register = async (req, res) => {
  const { phone, full_name, password } = req.body;

  try {
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE phone = $1',
      [phone]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'Пользователь с таким номером уже существует' });
    }

    // Хешируем пароль
    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (phone, password, full_name) VALUES ($1, $2, $3)
       RETURNING id, phone, full_name, avatar_url, bio, is_verified, is_admin,
                 total_donated, total_received, people_helped, fundraisers_count, created_at`,
      [phone, hashedPassword, full_name]
    );

    const user = result.rows[0];
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN
    });

    res.status(201).json({
      message: 'Регистрация успешна',
      token,
      user: user
    });
  } catch (error) {
    logger.error('Ошибка регистрации', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.login = async (req, res) => {
  const { phone, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT id, phone, password, full_name, avatar_url, bio, is_verified, is_admin, is_blocked, block_reason, total_donated, total_received, people_helped, fundraisers_count, created_at FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const user = result.rows[0];

    // Проверяем, заблокирован ли пользователь
    if (user.is_blocked) {
      return res.status(403).json({
        error: 'Ваш аккаунт заблокирован',
        blocked: true,
        block_reason: user.block_reason || 'Нарушение правил платформы'
      });
    }

    // Проверяем пароль
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Неверный пароль' });
    }

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN
    });

    res.json({
      message: 'Вход выполнен',
      token,
      user: {
        id: user.id,
        phone: user.phone,
        full_name: user.full_name,
        avatar_url: user.avatar_url,
        bio: user.bio,
        is_verified: user.is_verified,
        is_admin: user.is_admin,
        total_donated: user.total_donated,
        total_received: user.total_received,
        people_helped: user.people_helped,
        fundraisers_count: user.fundraisers_count,
        created_at: user.created_at
      }
    });
  } catch (error) {
    logger.error('Ошибка входа', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, phone, full_name, avatar_url, bio, is_verified, is_admin,
              total_donated, total_received, people_helped, fundraisers_count,
              created_at
       FROM users WHERE id = $1`,
      [req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Ошибка получения профиля', { error: error.message, userId: req.userId });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.updateProfile = async (req, res) => {
  const { full_name, bio } = req.body;
  const avatar_url = req.file ? `/uploads/${req.file.filename}` : null;

  try {
    let query = 'UPDATE users SET updated_at = CURRENT_TIMESTAMP';
    const values = [];
    let paramCount = 1;

    if (full_name) {
      query += `, full_name = $${paramCount}`;
      values.push(full_name);
      paramCount++;
    }

    if (bio) {
      query += `, bio = $${paramCount}`;
      values.push(bio);
      paramCount++;
    }

    if (avatar_url) {
      query += `, avatar_url = $${paramCount}`;
      values.push(avatar_url);
      paramCount++;
    }

    query += ` WHERE id = $${paramCount} RETURNING *`;
    values.push(req.userId);

    const result = await pool.query(query, values);

    res.json({
      message: 'Профиль обновлен',
      user: result.rows[0]
    });
  } catch (error) {
    logger.error('Ошибка обновления профиля', { error: error.message, userId: req.userId });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};
