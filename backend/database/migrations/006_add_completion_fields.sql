-- Добавление полей для завершенных сборов с отчетными документами

ALTER TABLE fundraisers
ADD COLUMN IF NOT EXISTS completion_proof_url VARCHAR(500),
ADD COLUMN IF NOT EXISTS completion_message TEXT,
ADD COLUMN IF NOT EXISTS completion_submitted_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS completion_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS completion_verified_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS completion_verified_by INTEGER REFERENCES users(id);

-- Индекс для быстрого поиска завершенных сборов
CREATE INDEX IF NOT EXISTS idx_fundraisers_completion_verified ON fundraisers(completion_verified, completion_verified_at DESC);

-- Комментарии для документации
COMMENT ON COLUMN fundraisers.completion_proof_url IS 'URL отчетного документа (скриншот/фото подтверждения)';
COMMENT ON COLUMN fundraisers.completion_message IS 'Сообщение организатора о завершении сбора';
COMMENT ON COLUMN fundraisers.completion_submitted_at IS 'Дата отправки отчета на проверку';
COMMENT ON COLUMN fundraisers.completion_verified IS 'Подтвержден ли отчет администратором';
COMMENT ON COLUMN fundraisers.completion_verified_at IS 'Дата подтверждения отчета';
COMMENT ON COLUMN fundraisers.completion_verified_by IS 'ID администратора, подтвердившего отчет';
