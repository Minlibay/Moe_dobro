# Исправление: Достижения и статистика при подтверждении админом

**Дата:** 22.04.2026  
**Файл:** `backend/src/controllers/adminController.js`

## Проблема

Когда админ подтверждает донат через админ-панель:
1. `people_helped` для донора не обновляется
2. Достижения не начисляются

## Исправления

### 1. Добавь обновление people_helped (строка ~352)

**Было:**
```javascript
// Обновляем статистику донора
await client.query(
  'UPDATE users SET total_donated = total_donated + $1 WHERE id = $2',
  [donation.amount, donation.donor_id]
);
```

**Стало:**
```javascript
// Обновляем статистику донора
const donorUpdate = await client.query(
  `UPDATE users
   SET total_donated = total_donated + $1,
       people_helped = people_helped + 1
   WHERE id = $2
   RETURNING total_donated, people_helped`,
  [donation.amount, donation.donor_id]
);

// Получаем количество одобренных донатов
const donationsCountResult = await client.query(
  'SELECT COUNT(*) as count FROM donations WHERE donor_id = $1 AND status = $2',
  [donation.donor_id, 'approved']
);
const donationsCount = parseInt(donationsCountResult.rows[0].count);
```

### 2. Добавь проверку достижений (после строки ~388, перед COMMIT)

```javascript
// Проверяем достижения
const checkAchievements = async (userId, totalDonated, peopleHelped, donationsCount) => {
  const achievements = await client.query(
    `SELECT a.* FROM achievements a
     WHERE a.id NOT IN (SELECT achievement_id FROM user_achievements WHERE user_id = $1)
     AND (
       (a.requirement_type = 'donation_amount' AND a.requirement_value <= $2::numeric) OR
       (a.requirement_type = 'people_helped' AND a.requirement_value <= $3) OR
       (a.requirement_type = 'donation_count' AND a.requirement_value <= $4)
     )`,
    [userId, totalDonated, peopleHelped, donationsCount]
  );

  for (const achievement of achievements.rows) {
    logger.info('Awarding achievement', { userId, achievementTitle: achievement.title });
    await client.query(
      'INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2)',
      [userId, achievement.id]
    );

    await client.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, 'achievement_earned', `Достижение: ${achievement.title}`, achievement.description, achievement.id]
    );
  }
};

await checkAchievements(
  donation.donor_id,
  donorUpdate.rows[0].total_donated,
  donorUpdate.rows[0].people_helped,
  donationsCount
);
```

### 3. Исправь обновление получателя (строка ~365)

**Было:**
```javascript
await client.query(
  'UPDATE users SET total_received = total_received + $1, people_helped = people_helped + 1 WHERE id = $2',
  [donation.amount, fundraiser.user_id]
);
```

**Стано:** ( people_helped уже добавляется выше для получателя, дубликат не нужен, но убедись что `total_received` обновляется )

```javascript
await client.query(
  'UPDATE users SET total_received = total_received + $1 WHERE id = $2',
  [donation.amount, fundraiser.user_id]
);
// Примечание: people_helped получателя уже обновляется в donationController.js
```