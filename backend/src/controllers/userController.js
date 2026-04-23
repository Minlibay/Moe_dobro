const pool = require('../config/database');
const logger = require('../utils/logger');

exports.getUserProfile = async (req, res) => {
  const { userId } = req.params;

  try {
    // Получаем информацию о пользователе
    const userResult = await pool.query(
      `SELECT id, full_name, bio, avatar_url, created_at
       FROM users
       WHERE id = $1`,
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const user = userResult.rows[0];

    // Получаем статистику пользователя
    const statsResult = await pool.query(
      `SELECT
        COUNT(DISTINCT CASE WHEN d.status = 'approved' THEN d.id END) as donations_count,
        COALESCE(SUM(CASE WHEN d.status = 'approved' THEN d.amount ELSE 0 END), 0) as total_donated,
        COUNT(DISTINCT f.id) as fundraisers_created,
        COALESCE(SUM(CASE WHEN f.status = 'completed' THEN f.current_amount ELSE 0 END), 0) as total_raised
       FROM users u
       LEFT JOIN donations d ON d.donor_id = u.id
       LEFT JOIN fundraisers f ON f.user_id = u.id
       WHERE u.id = $1`,
      [userId]
    );

    const stats = statsResult.rows[0];

    // Получаем последние донаты пользователя
    const recentDonationsResult = await pool.query(
      `SELECT d.id, d.amount, d.message, d.created_at,
              f.id as fundraiser_id, f.title as fundraiser_title, f.image_url as fundraiser_image
       FROM donations d
       JOIN fundraisers f ON d.fundraiser_id = f.id
       WHERE d.donor_id = $1 AND d.status = 'approved'
       ORDER BY d.created_at DESC
       LIMIT 5`,
      [userId]
    );

    // Получаем созданные сборы пользователя
    const fundraisersResult = await pool.query(
      `SELECT id, title, description, image_url, goal_amount, current_amount,
              status, category, created_at
       FROM fundraisers
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 5`,
      [userId]
    );

    res.json({
      user: {
        id: user.id,
        full_name: user.full_name,
        bio: user.bio,
        avatar_url: user.avatar_url,
        created_at: user.created_at,
      },
      stats: {
        donations_count: parseInt(stats.donations_count) || 0,
        total_donated: parseFloat(stats.total_donated) || 0,
        fundraisers_created: parseInt(stats.fundraisers_created) || 0,
        total_raised: parseFloat(stats.total_raised) || 0,
      },
      recent_donations: recentDonationsResult.rows,
      fundraisers: fundraisersResult.rows,
    });
  } catch (error) {
    logger.error('Ошибка получения профиля пользователя', { error: error.message, userId });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};
