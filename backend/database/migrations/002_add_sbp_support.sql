-- Миграция: Добавление поддержки СБП и обновление полей карты
-- Дата: 2026-04-19

-- Создаём тип для метода оплаты
DO $$ BEGIN
    CREATE TYPE payment_method_enum AS ENUM ('sbp', 'card');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Добавляем новые поля
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS payment_method payment_method_enum DEFAULT 'card';
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS sbp_phone VARCHAR(20);
ALTER TABLE fundraisers ADD COLUMN IF NOT EXISTS sbp_bank VARCHAR(100);

-- Делаем поля карты nullable (теперь они опциональны)
ALTER TABLE fundraisers ALTER COLUMN card_number DROP NOT NULL;
ALTER TABLE fundraisers ALTER COLUMN card_holder_name DROP NOT NULL;

-- Обновляем существующие записи (устанавливаем payment_method = 'card')
UPDATE fundraisers SET payment_method = 'card' WHERE payment_method IS NULL;

-- Делаем payment_method обязательным
ALTER TABLE fundraisers ALTER COLUMN payment_method SET NOT NULL;

-- Добавляем комментарии
COMMENT ON COLUMN fundraisers.payment_method IS 'Метод получения средств: sbp (СБП) или card (карта)';
COMMENT ON COLUMN fundraisers.sbp_phone IS 'Номер телефона для СБП';
COMMENT ON COLUMN fundraisers.sbp_bank IS 'Банк для СБП';

-- Добавляем constraint для проверки корректности данных
ALTER TABLE fundraisers ADD CONSTRAINT check_payment_details CHECK (
    (payment_method = 'sbp' AND sbp_phone IS NOT NULL AND sbp_bank IS NOT NULL) OR
    (payment_method = 'card' AND card_number IS NOT NULL)
);
