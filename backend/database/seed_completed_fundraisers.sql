-- Создание тестовых завершенных сборов для демонстрации

-- Обновляем существующий сбор как завершенный (если есть)
UPDATE fundraisers
SET
    status = 'completed',
    completion_proof_url = '/uploads/completion_proof_1.jpg',
    completion_message = 'Спасибо всем, кто помог! Благодаря вашей поддержке мы смогли оплатить первый взнос по ипотеке. Прикладываю документы из банка.',
    completion_submitted_at = CURRENT_TIMESTAMP - INTERVAL '2 days',
    completion_verified = true,
    completion_verified_at = CURRENT_TIMESTAMP - INTERVAL '1 day',
    completed_at = CURRENT_TIMESTAMP - INTERVAL '1 day'
WHERE id = 1 AND EXISTS (SELECT 1 FROM fundraisers WHERE id = 1);

-- Если нет сборов, создадим тестовые
INSERT INTO fundraisers (
    user_id, title, description, category, goal_amount, current_amount,
    payment_method, card_number, card_holder_name, bank_name,
    status, completion_proof_url, completion_message,
    completion_submitted_at, completion_verified, completion_verified_at, completed_at
)
SELECT
    1,
    'Помощь на лечение мамы',
    'Собрали необходимую сумму на операцию. Операция прошла успешно!',
    'medical',
    150000.00,
    150000.00,
    'card',
    '2202 **** **** 1234',
    'Иванов Иван Иванович',
    'Сбербанк',
    'completed',
    '/uploads/medical_completion.jpg',
    'Огромное спасибо всем, кто помог! Операция прошла успешно, мама уже идет на поправку. Прикладываю выписку из больницы и чеки.',
    CURRENT_TIMESTAMP - INTERVAL '5 days',
    true,
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '3 days'
WHERE EXISTS (SELECT 1 FROM users WHERE id = 1)
AND NOT EXISTS (SELECT 1 FROM fundraisers WHERE title = 'Помощь на лечение мамы');

INSERT INTO fundraisers (
    user_id, title, description, category, goal_amount, current_amount,
    payment_method, sbp_phone, sbp_bank,
    status, completion_proof_url, completion_message,
    completion_submitted_at, completion_verified, completion_verified_at, completed_at
)
SELECT
    1,
    'Оплата обучения в университете',
    'Собрали деньги на первый семестр. Учусь на отлично!',
    'education',
    80000.00,
    85000.00,
    'sbp',
    '+7 999 123-45-67',
    'Тинькофф',
    'completed',
    '/uploads/education_completion.jpg',
    'Благодарю всех за помощь! Успешно оплатил первый семестр, учусь на отлично. Прикладываю справку из университета.',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    true,
    CURRENT_TIMESTAMP - INTERVAL '7 days',
    CURRENT_TIMESTAMP - INTERVAL '7 days'
WHERE EXISTS (SELECT 1 FROM users WHERE id = 1)
AND NOT EXISTS (SELECT 1 FROM fundraisers WHERE title = 'Оплата обучения в университете');

INSERT INTO fundraisers (
    user_id, title, description, category, goal_amount, current_amount,
    payment_method, card_number, card_holder_name, bank_name,
    status, completion_proof_url, completion_message,
    completion_submitted_at, completion_verified, completion_verified_at, completed_at
)
SELECT
    1,
    'Первый взнос по ипотеке',
    'Мечта сбылась - у нас есть своя квартира!',
    'mortgage',
    500000.00,
    520000.00,
    'card',
    '2202 **** **** 5678',
    'Петрова Мария',
    'ВТБ',
    'completed',
    '/uploads/mortgage_completion.jpg',
    'Невероятно! Благодаря вашей поддержке мы внесли первый взнос и получили ключи от квартиры. Это настоящее чудо! Прикладываю договор купли-продажи.',
    CURRENT_TIMESTAMP - INTERVAL '15 days',
    true,
    CURRENT_TIMESTAMP - INTERVAL '12 days',
    CURRENT_TIMESTAMP - INTERVAL '12 days'
WHERE EXISTS (SELECT 1 FROM users WHERE id = 1)
AND NOT EXISTS (SELECT 1 FROM fundraisers WHERE title = 'Первый взнос по ипотеке');

-- Выводим результат
SELECT
    id, title, category, current_amount,
    completion_verified, completion_verified_at
FROM fundraisers
WHERE completion_verified = true
ORDER BY completion_verified_at DESC;
