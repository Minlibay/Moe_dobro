const express = require('express');
const router = express.Router();
const donationController = require('../controllers/donationController');
const authMiddleware = require('../middleware/auth');
const upload = require('../middleware/upload');
const rateLimit = require('express-rate-limit');

// Лимит для создания донатов
const donationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 час
  max: 10, // максимум 10 донатов в час
  message: { error: 'Слишком много донатов, попробуйте через час' }
});

router.post('/', authMiddleware, donationLimiter, upload.single('screenshot'), donationController.createDonation);
router.get('/pending', authMiddleware, donationController.getPendingDonations);
router.get('/my', authMiddleware, donationController.getMyDonations);
router.get('/fundraiser/:fundraiserId', donationController.getFundraiserDonations);
router.patch('/:id/approve', authMiddleware, donationController.approveDonation);
router.patch('/:id/reject', authMiddleware, donationController.rejectDonation);

module.exports = router;
