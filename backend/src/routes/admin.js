const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middleware/auth');
const adminMiddleware = require('../middleware/admin');

// Все admin routes требуют авторизации и прав администратора
router.use(authMiddleware, adminMiddleware);

// Пользователи
router.get('/users', adminController.getUsers);
router.patch('/users/:id/verify', adminController.verifyUser);
router.patch('/users/:id/block', adminController.blockUser);

// Сборы
router.get('/fundraisers', adminController.getFundraisers);
router.delete('/fundraisers/:id', adminController.deleteFundraiser);
router.patch('/fundraisers/:id/close', adminController.closeFundraiser);
router.patch('/fundraisers/:id/feature', adminController.featureFundraiser);
router.patch('/fundraisers/:id/verify-completion', adminController.verifyCompletion);

// Модерация сборов
router.get('/fundraisers/pending', adminController.getPendingFundraisers);
router.patch('/fundraisers/:id/approve', adminController.approveFundraiser);
router.patch('/fundraisers/:id/reject', adminController.rejectFundraiser);

// Донаты
router.get('/donations', adminController.getDonations);
router.patch('/donations/:id/approve', adminController.approveDonation);
router.patch('/donations/:id/reject', adminController.rejectDonation);

// Статистика
router.get('/stats', adminController.getStats);

module.exports = router;
