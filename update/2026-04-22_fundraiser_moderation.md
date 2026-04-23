# Новая функция: Модерация сборов

**Дата:** 22.04.2026  
**Описание:** Админ проверяет новые сборы перед публикацией

## Логика работы

1. При создании сбора → статус `pending` (на модерации)
2. Админ просматривает `pending` сборы
3. Админ может: одобрить → `active` или отклонить → `rejected`

## Изменения в БД

### 1. Добавь новый статус в таблицу (если нет)

```sql
-- Проверь текущие статусы
SELECT DISTINCT status FROM fundraisers;
```

Статусы должны быть: `pending`, `active`, `completed`, `rejected`

## Изменения в backend

### 1. fundraiserController.js - создание сбора

При создании сбора устанавливать `status = 'pending'` вместо `'active'`

### 2. adminController.js - новые эндпоинты

```javascript
// Получить сборы на модерацию
exports.getPendingFundraisers = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT f.*, u.full_name as creator_name
       FROM fundraisers f
       JOIN users u ON f.user_id = u.id
       WHERE f.status = 'pending'
       ORDER BY f.created_at DESC`
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка сервера' });
  }
};

// Одобрить сбор (опубликовать)
exports.approveFundraiser = async (req, res) => {
  const { id } = req.params;
  const { rejectReason } = req.body;

  // ... логика
};

// Отклонить сбор
exports.rejectFundraiser = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  // ... логика
};
```

### 3. routes/admin.js - новые роуты

```javascript
router.get('/fundraisers/pending', authMiddleware, adminMiddleware, adminController.getPendingFundraisers);
router.patch('/:id/approve', authMiddleware, adminMiddleware, adminController.approveFundraiser);
router.patch('/:id/reject', authMiddleware, adminMiddleware, adminController.rejectFundraiser);
```

### 4. Уведомления

При одобрении/отклонении → создать уведомление для автора

## Изменения во Flutter

### 1. admin_dashboard_screen.dart

Добавить вкладку "Модерация" с pending сборами

### 2. home_screen.dart

Показывать только статут `active` (как сейчас)

## Файлы для изменения

- `backend/src/controllers/fundraiserController.js`
- `backend/src/controllers/adminController.js`
- `backend/src/routes/admin.js`
- `mobile/lib/screens/admin/admin_dashboard_screen.dart`