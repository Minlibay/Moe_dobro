const express = require('express');
const router = express.Router();
const achievementController = require('../controllers/achievementController');
const authMiddleware = require('../middleware/auth');

router.get('/my', authMiddleware, achievementController.getUserAchievements);
router.get('/all', authMiddleware, achievementController.getAllAchievements);

module.exports = router;
