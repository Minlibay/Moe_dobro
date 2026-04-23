const { body, validationResult } = require('express-validator');

// Валидация номера телефона (формат +7XXXXXXXXXX)
const validatePhone = () => {
  return body('phone')
    .matches(/^\+7\d{10}$/)
    .withMessage('Номер телефона должен быть в формате +7XXXXXXXXXX');
};

// Валидация полного имени
const validateFullName = () => {
  return body('full_name')
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Имя должно содержать от 2 до 255 символов');
};

// Валидация пароля
const validatePassword = () => {
  return body('password')
    .isLength({ min: 6 })
    .withMessage('Пароль должен содержать минимум 6 символов')
    .matches(/^(?=.*[a-zA-Z])(?=.*\d)/)
    .withMessage('Пароль должен содержать буквы и цифры');
};

// Middleware для проверки результатов валидации
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: errors.array()[0].msg,
      errors: errors.array()
    });
  }
  next();
};

module.exports = {
  validatePhone,
  validateFullName,
  validatePassword,
  handleValidationErrors
};
