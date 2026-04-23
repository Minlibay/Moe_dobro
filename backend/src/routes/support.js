const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const supportController = require('../controllers/supportController');

// Создать тикет
router.post('/', authMiddleware, supportController.createTicket);

// Мои тикеты
router.get('/my', authMiddleware, supportController.getMyTickets);

// Получить тикет с сообщениями
router.get('/:id', authMiddleware, supportController.getTicketById);

// Отправить сообщение в тикет
router.post('/:id/messages', authMiddleware, supportController.sendMessage);

// Закрыть тикет
router.patch('/:id/close', authMiddleware, supportController.closeTicket);

module.exports = router;