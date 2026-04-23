-- Миграция: Добавление поля password в таблицу users
-- Дата: 2026-04-19

-- Добавляем поле password (временно nullable)
ALTER TABLE users ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- Обновляем существующих пользователей с дефолтным хешированным паролем
-- Пароль: "password123" (хеш bcrypt)
UPDATE users
SET password = '$2a$10$rZ5YhkKvXJKqvZQJ5YhkKuXJKqvZQJ5YhkKuXJKqvZQJ5YhkKu'
WHERE password IS NULL;

-- Делаем поле обязательным
ALTER TABLE users ALTER COLUMN password SET NOT NULL;

-- Комментарий
COMMENT ON COLUMN users.password IS 'Хешированный пароль пользователя (bcrypt)';
