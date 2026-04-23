const pool = require('../config/database');
const logger = require('../utils/logger');

exports.getAllFundraisers = async (req, res) => {
  const { category, status = 'active', limit = 20, offset = 0 } = req.query;

  logger.info('getAllFundraisers called', { status, category, limit, offset });

  try {
    let query = `
      SELECT f.*, u.full_name as creator_name, u.avatar_url as creator_avatar,
             ROUND((f.current_amount / f.goal_amount) * 100, 2) as progress_percent,
             (SELECT COUNT(*) FROM donations WHERE fundraiser_id = f.id AND status = 'approved') as donors_count
      FROM fundraisers f
      JOIN users u ON f.user_id = u.id
    `;
    const values = [];
    let paramCount = 1;

    // Для верифицированных завершенных сборов
    if (status === 'verified_completed') {
      query += ` WHERE f.status = 'verified_completed'`;
    } else if (status === 'completed') {
      // Все завершенные сборы
      query += ` WHERE f.status = 'completed'`;
    } else {
      query += ` WHERE f.status = $${paramCount}`;
      values.push(status);
      paramCount++;
    }

    if (category) {
      query += ` AND f.category = $${paramCount}`;
      values.push(category);
      paramCount++;
    }

    // Сортировка: завершенные по дате подтверждения (новые сверху), остальные по приоритету
    if (status === 'verified_completed') {
      query += ` ORDER BY f.completion_verified_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    } else {
      query += ` ORDER BY f.is_featured DESC, f.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    }
    values.push(limit, offset);

    const result = await pool.query(query, values);
    logger.info('getAllFundraisers result', { status, count: result.rows.length, firstRow: result.rows[0]?.completion_proof_url });
    res.json(result.rows);
  } catch (error) {
    logger.error('Ошибка получения сборов', { error: error.message, query: req.query });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getFundraiserById = async (req, res) => {
  const { id } = req.params;
  
  logger.info('getFundraiserById called', { id, params: req.params, path: req.path });

  try {
    const result = await pool.query(
      `SELECT f.*, u.full_name as creator_name, u.avatar_url as creator_avatar, u.bio as creator_bio,
              ROUND((f.current_amount / f.goal_amount) * 100, 2) as progress_percent,
              (SELECT COUNT(*) FROM donations WHERE fundraiser_id = f.id AND status = 'approved') as donors_count
       FROM fundraisers f
       JOIN users u ON f.user_id = u.id
       WHERE f.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Сбор не найден' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Ошибка получения сбора', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.createFundraiser = async (req, res) => {
  const {
    title, description, category, goal_amount,
    payment_method,
    card_number, card_holder_name, bank_name,
    sbp_phone, sbp_bank
  } = req.body;
  
  logger.info('Создание сбора', { 
    title, 
    category, 
    goal_amount,
    payment_method,
    userId: req.userId,
    files: req.files,
    body: req.body 
  });
  
  const image_urls = req.files && req.files.length > 0 
    ? req.files.map(f => `/uploads/${f.filename}`) 
    : [];

  logger.info('Image URLs:', image_urls);

  try {
    const userCheck = await pool.query(
      'SELECT total_donated FROM users WHERE id = $1',
      [req.userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    if (userCheck.rows[0].total_donated < 100) {
      return res.status(403).json({
        error: 'Для создания сбора необходимо сначала помочь кому-то (минимум 100₽)'
      });
    }

    // Валидация в зависимости от метода оплаты
    if (payment_method === 'sbp') {
      if (!sbp_phone || !sbp_bank) {
        return res.status(400).json({ error: 'Для СБП необходимо указать номер телефона и банк' });
      }
    } else if (payment_method === 'card') {
      if (!card_number) {
        return res.status(400).json({ error: 'Для карты необходимо указать номер карты' });
      }
    } else {
      return res.status(400).json({ error: 'Неверный метод оплаты' });
    }

    // Используем транзакцию для атомарности операций
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const imageUrl = image_urls.length > 0 ? image_urls[0] : null;

      logger.info('Inserting fundraiser', {
        userId: req.userId, title, imageUrl, image_urls
      });

      const result = await client.query(
        `INSERT INTO fundraisers (user_id, title, description, category, goal_amount,
                                  payment_method, card_number, card_holder_name, bank_name,
                                  sbp_phone, sbp_bank, image_url, image_urls, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'pending') RETURNING *`,
        [req.userId, title, description, category, goal_amount,
         payment_method, card_number, card_holder_name, bank_name,
         sbp_phone, sbp_bank, imageUrl, image_urls]
      );

      logger.info('Fundraiser created:', result.rows[0]);

      await client.query(
        'UPDATE users SET fundraisers_count = fundraisers_count + 1 WHERE id = $1',
        [req.userId]
      );

      await client.query('COMMIT');

      res.status(201).json({
        message: 'Сбор создан успешно',
        fundraiser: result.rows[0]
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Ошибка создания сбора', { 
      error: error.message, 
      stack: error.stack,
      userId: req.userId,
      image_urls 
    });
    res.status(500).json({ error: 'Ошибка сервера: ' + error.message });
  }
};

exports.getMyFundraisers = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT f.*,
              ROUND((f.current_amount / f.goal_amount) * 100, 2) as progress_percent,
              (SELECT COUNT(*) FROM donations WHERE fundraiser_id = f.id AND status = 'approved') as donors_count
       FROM fundraisers f
       WHERE f.user_id = $1
       ORDER BY f.status = 'completed' DESC, f.created_at DESC`,
      [req.userId]
    );

    res.json(result.rows);
  } catch (error) {
    logger.error('Ошибка получения моих сборов', { error: error.message, userId: req.userId });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.closeFundraiser = async (req, res) => {
  const { id } = req.params;

  try {
    const fundraiser = await pool.query(
      'SELECT user_id FROM fundraisers WHERE id = $1',
      [id]
    );

    if (fundraiser.rows.length === 0) {
      return res.status(404).json({ error: 'Сбор не найден' });
    }

    if (fundraiser.rows[0].user_id !== req.userId) {
      return res.status(403).json({ error: 'Нет прав для закрытия этого сбора' });
    }

    await pool.query(
      'UPDATE fundraisers SET status = $1, completed_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['completed', id]
    );

    res.json({ message: 'Сбор успешно закрыт' });
  } catch (error) {
    logger.error('Ошибка закрытия сбора', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Отправить подтверждение завершения сбора
exports.submitCompletionProof = async (req, res) => {
  const { id } = req.params;
  const { message } = req.body;
  const proof_url = req.file ? `/uploads/${req.file.filename}` : null;

  if (!proof_url) {
    return res.status(400).json({ error: 'Необходимо прикрепить подтверждающий документ' });
  }

  try {
    // Проверяем, что сбор принадлежит пользователю
    const fundraiser = await pool.query(
      'SELECT * FROM fundraisers WHERE id = $1 AND user_id = $2',
      [id, req.userId]
    );

    if (fundraiser.rows.length === 0) {
      return res.status(404).json({ error: 'Сбор не найден или у вас нет прав' });
    }

    if (fundraiser.rows[0].status !== 'completed') {
      return res.status(400).json({ error: 'Сбор должен быть завершен для отправки подтверждения' });
    }

    await pool.query(
      `UPDATE fundraisers
       SET completion_proof_url = $1,
           completion_message = $2,
           completion_submitted_at = CURRENT_TIMESTAMP
       WHERE id = $3`,
      [proof_url, message, id]
    );

    logger.info('Completion proof submitted', { fundraiserId: id, userId: req.userId });

    res.json({ message: 'Подтверждение отправлено на проверку администратору' });
  } catch (error) {
    logger.error('Error submitting completion proof', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};
