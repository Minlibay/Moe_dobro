-- Создание тестовых донатов для демонстрации списка поддержавших

-- Добавляем тестовых пользователей-донаторов (если их нет)
INSERT INTO users (phone, password, full_name, total_donated, people_helped)
VALUES
  ('+79991111111', '$2b$10$test', 'Алексей Петров', 5000, 3),
  ('+79992222222', '$2b$10$test', 'Мария Иванова', 10000, 5),
  ('+79993333333', '$2b$10$test', 'Дмитрий Сидоров', 3000, 2),
  ('+79994444444', '$2b$10$test', 'Елена Козлова', 7500, 4),
  ('+79995555555', '$2b$10$test', 'Иван Смирнов', 2000, 1)
ON CONFLICT (phone) DO NOTHING;

-- Добавляем подтвержденные донаты для активных сборов
INSERT INTO donations (fundraiser_id, donor_id, amount, screenshot_url, status, message, created_at, verified_at)
SELECT
  f.id,
  u.id,
  donations.amount,
  '/uploads/screenshot_test.jpg',
  'approved',
  donations.message,
  donations.donation_created_at,
  donations.donation_created_at + INTERVAL '1 hour'
FROM fundraisers f
CROSS JOIN (
  SELECT id, full_name FROM users WHERE phone IN ('+79991111111', '+79992222222', '+79993333333', '+79994444444', '+79995555555')
) u
CROSS JOIN (VALUES
  (1000.00, 'Желаю успехов! Пусть всё получится 🙏', CURRENT_TIMESTAMP - INTERVAL '5 days'),
  (2500.00, 'Держитесь! Всё будет хорошо ❤️', CURRENT_TIMESTAMP - INTERVAL '4 days'),
  (500.00, 'Небольшая помощь, но от всего сердца', CURRENT_TIMESTAMP - INTERVAL '3 days'),
  (3000.00, 'Очень важное дело, рад помочь!', CURRENT_TIMESTAMP - INTERVAL '2 days'),
  (1500.00, NULL, CURRENT_TIMESTAMP - INTERVAL '1 day')
) AS donations(amount, message, donation_created_at)
WHERE f.status = 'active'
LIMIT 15
ON CONFLICT DO NOTHING;

-- Обновляем суммы в сборах
UPDATE fundraisers f
SET current_amount = (
  SELECT COALESCE(SUM(d.amount), 0)
  FROM donations d
  WHERE d.fundraiser_id = f.id AND d.status = 'approved'
)
WHERE f.status = 'active';

-- Показываем результат
SELECT
  f.id as fundraiser_id,
  f.title,
  COUNT(d.id) as donations_count,
  SUM(d.amount) as total_amount
FROM fundraisers f
LEFT JOIN donations d ON f.id = d.fundraiser_id AND d.status = 'approved'
WHERE f.status = 'active'
GROUP BY f.id, f.title
ORDER BY f.id;
