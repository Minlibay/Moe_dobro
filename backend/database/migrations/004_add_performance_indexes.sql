-- Миграция: Добавление индексов для оптимизации производительности
-- Дата: 2026-04-19
-- Описание: Индексы для часто используемых запросов

-- Индекс для сортировки донатов по дате
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON donations(created_at DESC);

-- Индекс для сортировки сборов по дате
CREATE INDEX IF NOT EXISTS idx_fundraisers_created_at ON fundraisers(created_at DESC);

-- Составной индекс для фильтрации уведомлений по пользователю и статусу прочтения
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);

-- Индекс для быстрого поиска достижений пользователя
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);

-- Индекс для поиска донатов по статусу (для pending donations)
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status) WHERE status = 'pending';

-- Индекс для поиска сборов по категории и статусу
CREATE INDEX IF NOT EXISTS idx_fundraisers_category_status ON fundraisers(category, status) WHERE status = 'active';
