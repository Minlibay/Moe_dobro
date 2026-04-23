const pool = require('../config/database');

exports.getUserAchievements = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT a.*, ua.earned_at
       FROM user_achievements ua
       JOIN achievements a ON ua.achievement_id = a.id
       WHERE ua.user_id = $1
       ORDER BY ua.earned_at DESC`,
      [req.userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка получения достижений:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getAllAchievements = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT a.*,
              CASE WHEN ua.user_id IS NOT NULL THEN true ELSE false END as is_earned,
              ua.earned_at
       FROM achievements a
       LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = $1
       ORDER BY a.category, a.requirement_value`,
      [req.userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка получения всех достижений:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};
