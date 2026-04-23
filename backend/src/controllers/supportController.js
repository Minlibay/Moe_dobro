const pool = require('../config/database');
const logger = require('../utils/logger');

exports.createTicket = async (req, res) => {
  const { subject, message } = req.body;

  if (!subject || !message) {
    return res.status(400).json({ error: 'Укажите тему и сообщение' });
  }

  try {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      const ticketResult = await client.query(
        `INSERT INTO support_tickets (user_id, subject) VALUES ($1, $2) RETURNING *`,
        [req.userId, subject]
      );
      const ticket = ticketResult.rows[0];

      await client.query(
        `INSERT INTO support_messages (ticket_id, sender_id, message) VALUES ($1, $2, $3)`,
        [ticket.id, req.userId, message]
      );

      await client.query('COMMIT');

      logger.info('Support ticket created', { ticketId: ticket.id, userId: req.userId });

      res.status(201).json({
        message: 'Обращение создано',
        ticket: ticket
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Error creating support ticket', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getMyTickets = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT st.*, 
              (SELECT message FROM support_messages WHERE ticket_id = st.id ORDER BY created_at DESC LIMIT 1) as last_message
       FROM support_tickets st
       WHERE st.user_id = $1
       ORDER BY st.created_at DESC`,
      [req.userId]
    );

    res.json(result.rows);
  } catch (error) {
    logger.error('Error getting support tickets', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.getTicketById = async (req, res) => {
  const { id } = req.params;
  logger.info('getTicketById called', { id, userId: req.userId });

  try {
    const ticket = await pool.query(
      `SELECT st.*, u.full_name as user_name
       FROM support_tickets st
       JOIN users u ON st.user_id = u.id
       WHERE st.id = $1`,
      [id]
    );

    if (ticket.rows.length === 0) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    logger.info('Ticket found', { ticketId: id, ticketUserId: ticket.rows[0].user_id, requestUserId: req.userId });

    const isTicketOwner = req.userId === ticket.rows[0].user_id;
    const isUserAdmin = await pool.query(
      `SELECT is_admin FROM users WHERE id = $1`,
      [req.userId]
    );
    const isAdmin = isUserAdmin.rows[0]?.is_admin || false;

    logger.info('Permission check', { isTicketOwner, isAdmin });

    if (!isTicketOwner && !isAdmin) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    const messages = await pool.query(
      `SELECT sm.*, u.full_name as sender_name
       FROM support_messages sm
       JOIN users u ON sm.sender_id = u.id
       WHERE sm.ticket_id = $1
       ORDER BY sm.created_at ASC`,
      [id]
    );

    res.json({
      ...ticket.rows[0],
      messages: messages.rows
    });
  } catch (error) {
    logger.error('Error getting support ticket', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.sendMessage = async (req, res) => {
  const { id } = req.params;
  const { message } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'Введите сообщение' });
  }

  try {
    const ticket = await pool.query(
      'SELECT * FROM support_tickets WHERE id = $1',
      [id]
    );

    if (ticket.rows.length === 0) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    const isAdmin = await pool.query(
      `SELECT is_admin FROM users WHERE id = $1`,
      [req.userId]
    );

    if (ticket.rows[0].user_id !== req.userId && !isAdmin.rows[0]?.is_admin) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    if (ticket.rows[0].status === 'closed') {
      return res.status(400).json({ error: 'Обращение закрыто' });
    }

    await pool.query(
      `INSERT INTO support_messages (ticket_id, sender_id, message) VALUES ($1, $2, $3)`,
      [id, req.userId, message]
    );

    await pool.query(
      `UPDATE support_tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [id]
    );

    logger.info('Support message sent', { ticketId: id, userId: req.userId });

    res.json({ message: 'Сообщение отправлено' });
  } catch (error) {
    logger.error('Error sending support message', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

exports.closeTicket = async (req, res) => {
  const { id } = req.params;

  try {
    const ticket = await pool.query(
      'SELECT * FROM support_tickets WHERE id = $1',
      [id]
    );

    if (ticket.rows.length === 0) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    await pool.query(
      `UPDATE support_tickets SET status = 'closed', updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [id]
    );

    res.json({ message: 'Обращение закрыто' });
  } catch (error) {
    logger.error('Error closing support ticket', { error: error.message });
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};