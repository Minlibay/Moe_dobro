-- Миграция: Добавление поля is_admin для администраторов
-- Дата: 2026-04-19

-- Добавляем поле is_admin
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Создаем первого администратора (замените ID на нужный)
-- UPDATE users SET is_admin = TRUE WHERE id = 1;

-- Индекс для быстрого поиска админов
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin) WHERE is_admin = TRUE;
