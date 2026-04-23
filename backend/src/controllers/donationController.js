const pool = require('../config/database');
const logger = require('../utils/logger');

exports.createDonation = async (req, res) => {
  logger.info('Create donation request', { body: req.body, userId: req.userId });

  const { fundraiser_id, amount, message } = req.body;
  const screenshot_url = req.file ? `/uploads/${req.file.filename}` : null;

  if (!screenshot_url) {
    logger.warn('No screenshot uploaded', { userId: req.userId });
    return res.status(400).json({ error: 'Необходимо прикрепить скриншот перевода' });
  }

  try {
    const fundraiser = await pool.query(
      'SELECT * FROM fundraisers WHERE id = $1 AND status = $2',
      [fundraiser_id, 'active']
    );

    if (fundraiser.rows.length === 0) {
      logger.warn('Fundraiser not found or inactive', { fundraiserId: fundraiser_id });
      return res.status(404).json({ error: 'Сбор не найден или неактивен' });
    }

    const result = await pool.query(
      `INSERT INTO donations (fundraiser_id, donor_id, amount, screenshot_url, message)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [fundraiser_id, req.userId, amount, screenshot_url, message]
    );

    logger.info('Donation created successfully', { donationId: result.rows[0].id, amount });

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        fundraiser.rows[0].user_id,
        'donation_received',
        'Новое пожертвование!',
        `Вам пришло пожертвование на сумму ${amount}₽. Проверьте и подтвердите.`,
        result.rows[0].id
      ]
    );

    res.status(201).json({
      message: 'Пожертвование отправлено на проверку',
      donation: result.rows[0]
    });
  } catch (error) {
    logger.error('Ошибка создания пожертвования', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.approveDonation = async (req, res) => {
  const { id } = req.params;

  logger.info('Approve donation request', { donationId: id, userId: req.userId });

  try {
    const donation = await pool.query(
      `SELECT d.*, f.user_id as fundraiser_owner
       FROM donations d
       JOIN fundraisers f ON d.fundraiser_id = f.id
       WHERE d.id = $1`,
      [id]
    );

    if (donation.rows.length === 0) {
      logger.warn('Donation not found', { donationId: id });
      return res.status(404).json({ error: 'Пожертвование не найдено' });
    }

    if (donation.rows[0].fundraiser_owner !== req.userId) {
      logger.warn('No permission to approve', {
        donationId: id,
        owner: donation.rows[0].fundraiser_owner,
        user: req.userId
      });
      return res.status(403).json({ error: 'Нет прав для подтверждения' });
    }

    if (donation.rows[0].status !== 'pending') {
      logger.warn('Donation already processed', { donationId: id, status: donation.rows[0].status });
      return res.status(400).json({ error: 'Пожертвование уже обработано' });
    }

    logger.debug('Starting transaction for donation approval', { donationId: id });
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        'UPDATE donations SET status = $1, verified_at = CURRENT_TIMESTAMP WHERE id = $2',
        ['approved', id]
      );

      await client.query(
        'UPDATE fundraisers SET current_amount = current_amount + $1 WHERE id = $2',
        [donation.rows[0].amount, donation.rows[0].fundraiser_id]
      );

      // Проверяем, достиг ли сбор 100%
      const fundraiserCheck = await client.query(
        'SELECT * FROM fundraisers WHERE id = $1',
        [donation.rows[0].fundraiser_id]
      );
      const fundraiser = fundraiserCheck.rows[0];

      if (fundraiser.current_amount >= fundraiser.target_amount && fundraiser.status === 'active') {
        await client.query(
          'UPDATE fundraisers SET status = $1, completed_at = CURRENT_TIMESTAMP WHERE id = $2',
          ['completed', donation.rows[0].fundraiser_id]
        );

        await client.query(
          `INSERT INTO notifications (user_id, type, title, message, related_id)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            fundraiser.user_id,
            'fundraiser_completed',
            'Сбор завершён! 🎉',
            `Поздравляем! Ваш сбор "${fundraiser.title}" достиг цели. Теперь отправьте подтверждающие документы.`,
            donation.rows[0].fundraiser_id
          ]
        );

        logger.info('Fundraiser auto-completed at 100%', { fundraiserId: donation.rows[0].fundraiser_id });
      }

      await client.query(
        'UPDATE users SET total_received = total_received + $1 WHERE id = $2',
        [donation.rows[0].amount, req.userId]
      );

      const donorUpdate = await client.query(
        `UPDATE users
         SET total_donated = total_donated + $1,
             people_helped = people_helped + 1
         WHERE id = $2
         RETURNING total_donated, people_helped`,
        [donation.rows[0].amount, donation.rows[0].donor_id]
      );

      // Получаем количество одобренных донатов
      const donationsCountResult = await client.query(
        'SELECT COUNT(*) as count FROM donations WHERE donor_id = $1 AND status = $2',
        [donation.rows[0].donor_id, 'approved']
      );
      const donationsCount = parseInt(donationsCountResult.rows[0].count);

      await client.query(
        `INSERT INTO notifications (user_id, type, title, message, related_id)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          donation.rows[0].donor_id,
          'donation_approved',
          'Пожертвование подтверждено!',
          `Ваше пожертвование на сумму ${donation.rows[0].amount}₽ подтверждено. Теперь вы можете создать свой сбор!`,
          id
        ]
      );
      console.log('Notification created');

      const checkAchievements = async (userId, totalDonated, peopleHelped, donationsCount) => {
        const achievements = await client.query(
          `SELECT a.* FROM achievements a
           WHERE a.id NOT IN (SELECT achievement_id FROM user_achievements WHERE user_id = $1)
           AND (
             (a.requirement_type = 'donation_amount' AND a.requirement_value <= $2::numeric) OR
             (a.requirement_type = 'people_helped' AND a.requirement_value <= $3) OR
             (a.requirement_type = 'donation_count' AND a.requirement_value <= $4)
           )`,
          [userId, totalDonated, peopleHelped, donationsCount]
        );

        logger.debug('Achievements check', { userId, totalDonated, peopleHelped, donationsCount, achievementsFound: achievements.rows.length });

        for (const achievement of achievements.rows) {
          logger.info('Awarding achievement', { userId, achievementTitle: achievement.title });
          await client.query(
            'INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2)',
            [userId, achievement.id]
          );

          await client.query(
            `INSERT INTO notifications (user_id, type, title, message, related_id)
             VALUES ($1, $2, $3, $4, $5)`,
            [userId, 'achievement_earned', `Достижение: ${achievement.title}`, achievement.description, achievement.id]
          );
        }
      };

      await checkAchievements(
        donation.rows[0].donor_id,
        donorUpdate.rows[0].total_donated,
        donorUpdate.rows[0].people_helped,
        donationsCount
      );

      await client.query('COMMIT');
      logger.info('Donation approved successfully', { donationId: id, amount: donation.rows[0].amount });

      res.json({ message: 'Пожертвование подтверждено' });
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Transaction error during approval', { error: error.message, donationId: id });
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Ошибка подтверждения пожертвования', {
      error: error.message,
      stack: error.stack,
      donationId: id
    });
    res.status(500).json({ error: 'Ошибка сервера', details: error.message });
  }
};

exports.rejectDonation = async (req, res) => {
  const { id } = req.params;

  try {
    const donation = await pool.query(
      `SELECT d.*, f.user_id as fundraiser_owner
       FROM donations d
       JOIN fundraisers f ON d.fundraiser_id = f.id
       WHERE d.id = $1`,
      [id]
    );

    if (donation.rows.length === 0) {
      return res.status(404).json({ error: 'Пожертвование не найдено' });
    }

    if (donation.rows[0].fundraiser_owner !== req.userId) {
      return res.status(403).json({ error: 'Нет прав для отклонения' });
    }

    await pool.query(
      'UPDATE donations SET status = $1 WHERE id = $2',
      ['rejected', id]
    );

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        donation.rows[0].donor_id,
        'donation_rejected',
        'Пожертвование отклонено',
        'К сожалению, ваше пожертвование было отклонено. Попробуйте снова.',
        id
      ]
    );

    res.json({ message: 'Пожертвование отклонено' });
  } catch (error) {
    console.error('Ошибка отклонения пожертвования:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getPendingDonations = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT d.*, u.full_name as donor_name, u.avatar_url as donor_avatar, f.title as fundraiser_title
       FROM donations d
       JOIN users u ON d.donor_id = u.id
       JOIN fundraisers f ON d.fundraiser_id = f.id
       WHERE f.user_id = $1 AND d.status = 'pending'
       ORDER BY d.created_at DESC`,
      [req.userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка получения ожидающих пожертвований:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getMyDonations = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT d.*, f.title as fundraiser_title, f.image_url as fundraiser_image,
              u.full_name as recipient_name
       FROM donations d
       JOIN fundraisers f ON d.fundraiser_id = f.id
       JOIN users u ON f.user_id = u.id
       WHERE d.donor_id = $1
       ORDER BY d.created_at DESC`,
      [req.userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка получения моих пожертвований:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Получить все подтвержденные донаты для конкретного сбора
exports.getFundraiserDonations = async (req, res) => {
  const { fundraiserId } = req.params;

  try {
    const result = await pool.query(
      `SELECT d.id, d.amount, d.message, d.created_at,
              u.id as donor_id, u.full_name as donor_name, u.avatar_url as donor_avatar
       FROM donations d
       JOIN users u ON d.donor_id = u.id
       WHERE d.fundraiser_id = $1 AND d.status = 'approved'
       ORDER BY d.created_at DESC`,
      [fundraiserId]
    );

    logger.info('Fundraiser donations fetched', { fundraiserId, count: result.rows.length });
    res.json(result.rows);
  } catch (error) {
    logger.error('Ошибка получения донатов сбора', { error: error.message, fundraiserId });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};
