# Исправление: Достижения не начисляются

**Дата:** 22.04.2026  
**Файл:** `backend/src/controllers/donationController.js`

## Проблема

При подтверждении доната достижения не начисляются. Баг в SQL-запросе: для `donation_count` используется `peopleHelped` вместо реального количества донатов.

## Исправления

### 1. Добавь получение количества донатов (после `donorUpdate`, ~строка 116)

```javascript
// Получаем количество одобренных донатов
const donationsCountResult = await client.query(
  'SELECT COUNT(*) as count FROM donations WHERE donor_id = $1 AND status = $2',
  [donation.rows[0].donor_id, 'approved']
);
const donationsCount = parseInt(donationsCountResult.rows[0].count);
```

### 2. Исправить сигнатуру функции (строка ~131)

**Было:**
```javascript
const checkAchievements = async (userId, totalDonated, peopleHelped) => {
```

**Стало:**
```javascript
const checkAchievements = async (userId, totalDonated, peopleHelped, donationsCount) => {
```

### 3. Исправить SQL-запрос в `checkAchievements`

**Было:**
```javascript
(a.requirement_type = 'donation_count' AND a.requirement_value <= $3)
```

**Стало:**
```javascript
(a.requirement_type = 'donation_count' AND a.requirement_value <= $4)
```

### 4. Исправить вызов функции (строка ~159)

**Было:**
```javascript
await checkAchievements(
  donation.rows[0].donor_id,
  donorUpdate.rows[0].total_donated,
  donorUpdate.rows[0].people_helped
);
```

**Стало:**
```javascript
await checkAchievements(
  donation.rows[0].donor_id,
  donorUpdate.rows[0].total_donated,
  donorUpdate.rows[0].people_helped,
  donationsCount
);
```

## Проверка

После подтверждения доната в консоли сервера должно появиться:
```
[INFO] Awarding achievement { userId: X, achievementTitle: 'Первый шаг' }
```