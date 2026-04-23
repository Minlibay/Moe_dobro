const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const upload = require('../middleware/upload');
const { validatePhone, validateFullName, validatePassword, handleValidationErrors } = require('../middleware/validation');

router.post('/register',
  validatePhone(),
  validateFullName(),
  validatePassword(),
  handleValidationErrors,
  authController.register
);

router.post('/login',
  validatePhone(),
  validatePassword(),
  handleValidationErrors,
  authController.login
);

router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, upload.single('avatar'), authController.updateProfile);

module.exports = router;
