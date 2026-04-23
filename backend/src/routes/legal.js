const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const adminMiddleware = require('../middleware/admin');
const pool = require('../config/database');
const logger = require('../utils/logger');

// Получить все документы (публичный)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT type, title FROM legal_documents ORDER BY id');
    res.json(result.rows);
  } catch (error) {
    logger.error('Error getting legal documents', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получить документ по типу (публичный)
router.get('/:type', async (req, res) => {
  const { type } = req.params;
  
  try {
    const result = await pool.query(
      'SELECT * FROM legal_documents WHERE type = $1',
      [type]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Документ не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Error getting legal document', { error: error.message, type });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Обновить документ (админ)
router.put('/:type', authMiddleware, adminMiddleware, async (req, res) => {
  const { type } = req.params;
  const { title, content } = req.body;
  
  if (!title || !content) {
    return res.status(400).json({ error: 'Укажите заголовок и содержание' });
  }
  
  try {
    const result = await pool.query(
      `INSERT INTO legal_documents (type, title, content, updated_by, updated_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
       ON CONFLICT (type) DO UPDATE SET title = $2, content = $3, updated_by = $4, updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [type, title, content, req.userId]
    );
    
    logger.info('Legal document updated', { type, userId: req.userId });
    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Error updating legal document', { error: error.message, type });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

module.exports = router;