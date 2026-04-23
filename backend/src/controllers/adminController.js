const pool = require('../config/database');
const logger = require('../utils/logger');

// Получить всех пользователей с фильтрами
exports.getUsers = async (req, res) => {
  const { search, is_verified, limit = 50, offset = 0 } = req.query;

  try {
    let query = `
      SELECT id, phone, full_name, avatar_url, bio, is_verified, is_admin,
             is_blocked, block_reason,
             total_donated, total_received, people_helped, fundraisers_count,
             created_at, updated_at
      FROM users
      WHERE 1=1
    `;
    const values = [];
    let paramCount = 1;

    if (search) {
      query += ` AND (full_name ILIKE $${paramCount} OR phone ILIKE $${paramCount})`;
      values.push(`%${search}%`);
      paramCount++;
    }

    if (is_verified !== undefined) {
      query += ` AND is_verified = $${paramCount}`;
      values.push(is_verified === 'true');
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(limit, offset);

    const result = await pool.query(query, values);

    // Получить общее количество
    const countResult = await pool.query('SELECT COUNT(*) FROM users');

    res.json({
      users: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    logger.error('Error getting users', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Получить все сборы с фильтрами
exports.getFundraisers = async (req, res) => {
  const { status, category, search, limit = 50, offset = 0 } = req.query;

  try {
    let query = `
      SELECT f.*, u.full_name as creator_name, u.phone as creator_phone,
             ROUND((f.current_amount / f.goal_amount) * 100, 2) as progress_percent,
             (SELECT COUNT(*) FROM donations WHERE fundraiser_id = f.id AND status = 'approved') as donors_count,
             f.completion_proof_url, f.completion_message, f.completion_submitted_at,
             f.completion_verified, f.completion_verified_at
      FROM fundraisers f
      JOIN users u ON f.user_id = u.id
      WHERE 1=1
    `;
    const values = [];
    let paramCount = 1;

    if (status) {
      query += ` AND f.status = $${paramCount}`;
      values.push(status);
      paramCount++;
    }

    if (category) {
      query += ` AND f.category = $${paramCount}`;
      values.push(category);
      paramCount++;
    }

    if (search) {
      query += ` AND (f.title ILIKE $${paramCount} OR f.description ILIKE $${paramCount})`;
      values.push(`%${search}%`);
      paramCount++;
    }

    query += ` ORDER BY f.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(limit, offset);

    const result = await pool.query(query, values);

    const countResult = await pool.query('SELECT COUNT(*) FROM fundraisers');

    res.json({
      fundraisers: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    logger.error('Error getting fundraisers', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Получить все донаты с фильтрами
exports.getDonations = async (req, res) => {
  const { status, limit = 50, offset = 0 } = req.query;

  try {
    let query = `
      SELECT d.*,
             u.full_name as donor_name, u.phone as donor_phone,
             f.title as fundraiser_title, f.payment_method,
             f.card_number, f.card_holder_name, f.bank_name,
             f.sbp_phone, f.sbp_bank,
             u2.full_name as recipient_name, u2.phone as recipient_phone
      FROM donations d
      JOIN users u ON d.donor_id = u.id
      JOIN fundraisers f ON d.fundraiser_id = f.id
      JOIN users u2 ON f.user_id = u2.id
      WHERE 1=1
    `;
    const values = [];
    let paramCount = 1;

    if (status) {
      query += ` AND d.status = $${paramCount}`;
      values.push(status);
      paramCount++;
    }

    query += ` ORDER BY d.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(limit, offset);

    const result = await pool.query(query, values);

    const countResult = await pool.query('SELECT COUNT(*) FROM donations');

    res.json({
      donations: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    logger.error('Error getting donations', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Получить статистику
exports.getStats = async (req, res) => {
  try {
    const stats = await pool.query(`
      SELECT
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM users WHERE is_verified = true) as verified_users,
        (SELECT COUNT(*) FROM fundraisers) as total_fundraisers,
        (SELECT COUNT(*) FROM fundraisers WHERE status = 'active') as active_fundraisers,
        (SELECT COUNT(*) FROM fundraisers WHERE status = 'completed') as completed_fundraisers,
        (SELECT COUNT(*) FROM donations) as total_donations,
        (SELECT COUNT(*) FROM donations WHERE status = 'approved') as approved_donations,
        (SELECT COUNT(*) FROM donations WHERE status = 'pending') as pending_donations,
        (SELECT COALESCE(SUM(amount), 0) FROM donations WHERE status = 'approved') as total_amount,
        (SELECT COALESCE(AVG(amount), 0) FROM donations WHERE status = 'approved') as avg_donation
    `);

    // Статистика по дням (последние 30 дней)
    const dailyStats = await pool.query(`
      SELECT
        DATE(created_at) as date,
        COUNT(*) as donations_count,
        SUM(amount) as total_amount
      FROM donations
      WHERE status = 'approved' AND created_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    `);

    // Топ категорий
    const topCategories = await pool.query(`
      SELECT
        category,
        COUNT(*) as count,
        SUM(current_amount) as total_raised
      FROM fundraisers
      GROUP BY category
      ORDER BY count DESC
    `);

    res.json({
      overview: stats.rows[0],
      daily_stats: dailyStats.rows,
      top_categories: topCategories.rows
    });
  } catch (error) {
    logger.error('Error getting stats', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Верифицировать пользователя
exports.verifyUser = async (req, res) => {
  const { id } = req.params;
  const { is_verified } = req.body;

  try {
    await pool.query(
      'UPDATE users SET is_verified = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [is_verified, id]
    );

    logger.info('User verification updated', { userId: id, isVerified: is_verified, adminId: req.userId });

    res.json({ message: 'Статус верификации обновлен' });
  } catch (error) {
    logger.error('Error updating user verification', { error: error.message, userId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Удалить сбор
exports.deleteFundraiser = async (req, res) => {
  const { id } = req.params;

  try {
    // Проверяем, есть ли одобренные донаты
    const donations = await pool.query(
      'SELECT COUNT(*) FROM donations WHERE fundraiser_id = $1 AND status = $2',
      [id, 'approved']
    );

    if (parseInt(donations.rows[0].count) > 0) {
      return res.status(400).json({
        error: 'Нельзя удалить сбор с одобренными донатами. Закройте сбор вместо удаления.'
      });
    }

    await pool.query('DELETE FROM fundraisers WHERE id = $1', [id]);

    logger.info('Fundraiser deleted', { fundraiserId: id, adminId: req.userId });

    res.json({ message: 'Сбор удален' });
  } catch (error) {
    logger.error('Error deleting fundraiser', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Закрыть сбор
exports.closeFundraiser = async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query(
      'UPDATE fundraisers SET status = $1, completed_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['closed', id]
    );

    logger.info('Fundraiser closed by admin', { fundraiserId: id, adminId: req.userId });

    res.json({ message: 'Сбор закрыт' });
  } catch (error) {
    logger.error('Error closing fundraiser', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Сделать сбор избранным
exports.featureFundraiser = async (req, res) => {
  const { id } = req.params;
  const { is_featured } = req.body;

  try {
    await pool.query(
      'UPDATE fundraisers SET is_featured = $1 WHERE id = $2',
      [is_featured, id]
    );

    logger.info('Fundraiser featured status updated', { fundraiserId: id, isFeatured: is_featured, adminId: req.userId });

    res.json({ message: 'Статус избранного обновлен' });
  } catch (error) {
    logger.error('Error updating featured status', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Заблокировать/разблокировать пользователя
exports.blockUser = async (req, res) => {
  const { id } = req.params;
  const { is_blocked, block_reason } = req.body;

  try {
    await pool.query(
      'UPDATE users SET is_blocked = $1, block_reason = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3',
      [is_blocked, block_reason || null, id]
    );

    logger.info('User block status updated', { userId: id, isBlocked: is_blocked, reason: block_reason, adminId: req.userId });

    res.json({ message: is_blocked ? 'Пользователь заблокирован' : 'Пользователь разблокирован' });
  } catch (error) {
    logger.error('Error updating user block status', { error: error.message, userId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Подтвердить донат (админ)
exports.approveDonation = async (req, res) => {
  const { id } = req.params;

  try {
    // Получаем информацию о донате
    const donationResult = await pool.query(
      'SELECT * FROM donations WHERE id = $1',
      [id]
    );

    if (donationResult.rows.length === 0) {
      return res.status(404).json({ error: 'Донат не найден' });
    }

    const donation = donationResult.rows[0];

    if (donation.status !== 'pending') {
      return res.status(400).json({ error: 'Донат уже обработан' });
    }

    // Начинаем транзакцию
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Обновляем статус доната
      await client.query(
        'UPDATE donations SET status = $1, verified_at = CURRENT_TIMESTAMP WHERE id = $2',
        ['approved', id]
      );

      // Обновляем сумму в сборе
      await client.query(
        'UPDATE fundraisers SET current_amount = current_amount + $1 WHERE id = $2',
        [donation.amount, donation.fundraiser_id]
      );

      // Обновляем статистику донора
      await client.query(
        'UPDATE users SET total_donated = total_donated + $1 WHERE id = $2',
        [donation.amount, donation.donor_id]
      );

      // Получаем информацию о сборе
      const fundraiserResult = await client.query(
        'SELECT user_id, current_amount, goal_amount FROM fundraisers WHERE id = $1',
        [donation.fundraiser_id]
      );

      const fundraiser = fundraiserResult.rows[0];

      // Обновляем статистику получателя
      await client.query(
        'UPDATE users SET total_received = total_received + $1, people_helped = people_helped + 1 WHERE id = $2',
        [donation.amount, fundraiser.user_id]
      );

      // Проверяем, достигнута ли цель
      if (parseFloat(fundraiser.current_amount) + parseFloat(donation.amount) >= parseFloat(fundraiser.goal_amount)) {
        await client.query(
          'UPDATE fundraisers SET status = $1, completed_at = CURRENT_TIMESTAMP WHERE id = $2',
          ['completed', donation.fundraiser_id]
        );
      }

      // Создаем уведомление для донора
      await client.query(
        `INSERT INTO notifications (user_id, type, title, message, related_id)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          donation.donor_id,
          'donation_approved',
          'Донат подтвержден!',
          `Ваше пожертвование на сумму ${donation.amount}₽ подтверждено администратором.`,
          id
        ]
      );

      await client.query('COMMIT');

      logger.info('Donation approved by admin', { donationId: id, amount: donation.amount, adminId: req.userId });

      res.json({ message: 'Донат подтвержден' });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Error approving donation', { error: error.message, donationId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Отклонить донат (админ)
exports.rejectDonation = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  try {
    const donationResult = await pool.query(
      'SELECT * FROM donations WHERE id = $1',
      [id]
    );

    if (donationResult.rows.length === 0) {
      return res.status(404).json({ error: 'Донат не найден' });
    }

    const donation = donationResult.rows[0];

    if (donation.status !== 'pending') {
      return res.status(400).json({ error: 'Донат уже обработан' });
    }

    await pool.query(
      'UPDATE donations SET status = $1 WHERE id = $2',
      ['rejected', id]
    );

    // Создаем уведомление для донора
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        donation.donor_id,
        'donation_rejected',
        'Донат отклонен',
        reason || 'Ваше пожертвование было отклонено администратором.',
        id
      ]
    );

    logger.info('Donation rejected by admin', { donationId: id, reason, adminId: req.userId });

    res.json({ message: 'Донат отклонен' });
  } catch (error) {
    logger.error('Error rejecting donation', { error: error.message, donationId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Подтвердить завершение сбора (админ)
exports.verifyCompletion = async (req, res) => {
  const { id } = req.params;

  try {
    const fundraiser = await pool.query(
      'SELECT * FROM fundraisers WHERE id = $1',
      [id]
    );

    if (fundraiser.rows.length === 0) {
      return res.status(404).json({ error: 'Сбор не найден' });
    }

    if (!fundraiser.rows[0].completion_submitted_at) {
      return res.status(400).json({ error: 'Подтверждение завершения не было отправлено' });
    }

    if (fundraiser.rows[0].completion_verified) {
      return res.status(400).json({ error: 'Завершение уже подтверждено' });
    }

    await pool.query(
      `UPDATE fundraisers
       SET completion_verified = TRUE,
           completion_verified_at = CURRENT_TIMESTAMP,
           completion_verified_by = $1,
           status = 'verified_completed'
       WHERE id = $2`,
      [req.userId, id]
    );

    logger.info('Fundraiser verified', { fundraiserId: id, verificationDetails: fundraiser.rows[0] });

    // Создаем уведомление для создателя сбора
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        fundraiser.rows[0].user_id,
        'completion_verified',
        'Завершение сбора подтверждено!',
        'Администратор подтвердил успешное завершение вашего сбора. Теперь все могут увидеть результат.',
        id
      ]
    );

    logger.info('Fundraiser completion verified', { fundraiserId: id, adminId: req.userId });

    res.json({ message: 'Завершение сбора подтверждено' });
  } catch (error) {
    logger.error('Error verifying completion', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Получить сборы на модерацию (pending)
exports.getPendingFundraisers = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT f.*, u.full_name as creator_name, u.phone as creator_phone,
              ROUND((f.current_amount / f.goal_amount) * 100, 2) as progress_percent
       FROM fundraisers f
       JOIN users u ON f.user_id = u.id
       WHERE f.status = 'pending'
       ORDER BY f.created_at DESC`
    );

    res.json(result.rows);
  } catch (error) {
    logger.error('Error getting pending fundraisers', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Одобрить сбор (опубликовать)
exports.approveFundraiser = async (req, res) => {
  const { id } = req.params;

  try {
    // Проверяем, существует ли сбор
    const fundraiserResult = await pool.query(
      'SELECT * FROM fundraisers WHERE id = $1',
      [id]
    );

    if (fundraiserResult.rows.length === 0) {
      return res.status(404).json({ error: 'Сбор не найден' });
    }

    const fundraiser = fundraiserResult.rows[0];

    if (fundraiser.status !== 'pending') {
      return res.status(400).json({ error: 'Сбор уже не на модерации' });
    }

    // Меняем статус на active
    await pool.query(
      'UPDATE fundraisers SET status = $1 WHERE id = $2',
      ['active', id]
    );

    // Создаем уведомление для автора
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        fundraiser.user_id,
        'fundraiser_approved',
        'Сбор опубликован!',
        `Ваш сбор "${fundraiser.title}" прошел модерацию и опубликован. Теперь его могут видеть все пользователи.`,
        id
      ]
    );

    logger.info('Fundraiser approved', { fundraiserId: id, adminId: req.userId });

    res.json({ message: 'Сбор опубликован' });
  } catch (error) {
    logger.error('Error approving fundraiser', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Отклонить сбор
exports.rejectFundraiser = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  try {
    // Проверяем, существует ли сбор
    const fundraiserResult = await pool.query(
      'SELECT * FROM fundraisers WHERE id = $1',
      [id]
    );

    if (fundraiserResult.rows.length === 0) {
      return res.status(404).json({ error: 'Сбор не найден' });
    }

    const fundraiser = fundraiserResult.rows[0];

    if (fundraiser.status !== 'pending') {
      return res.status(400).json({ error: 'Сбор уже не на модерации' });
    }

    // Меняем статус на rejected
    await pool.query(
      'UPDATE fundraisers SET status = $1, rejection_reason = $2 WHERE id = $3',
      ['rejected', reason || 'Нарушение правил платформы', id]
    );

    // Создаем уведомление для автора
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        fundraiser.user_id,
        'fundraiser_rejected',
        'Сбор отклонен',
        reason || 'Ваш сбор был отклонен модератором. Причина: нарушение правил платформы или некорректные данные.',
        id
      ]
    );

    logger.info('Fundraiser rejected', { fundraiserId: id, reason, adminId: req.userId });

    res.json({ message: 'Сбор отклонен' });
  } catch (error) {
    logger.error('Error rejecting fundraiser', { error: error.message, fundraiserId: id });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};
