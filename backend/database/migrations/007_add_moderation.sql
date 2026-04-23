-- Миграция: Добавить поле rejection_reason и статус pending

-- 1. Добавить поле для причины отклонения
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 2. Добавить statuses: pending, rejected (если ещё нет)
-- PostgreSQL автоматически проверит уникальность значений enum если используется enum тип
-- Для простого TEXT это не нужно

-- 3. Обновить существующие активные сборы, чтобы они оставались active
-- (по умолчанию уже active, так что ничего не делаем)

-- 4. Проверить текущие статусы
-- SELECT DISTINCT status FROM fundraisers;

-- 5. Индекс для быстрого поиска pending сборов
CREATE INDEX IF NOT EXISTS idx_fundraisers_status_pending ON fundraisers(status) WHERE status = 'pending';