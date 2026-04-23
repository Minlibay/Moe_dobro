-- Создание таблиц для приложения "Моё добро"

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    total_donated DECIMAL(10, 2) DEFAULT 0,
    total_received DECIMAL(10, 2) DEFAULT 0,
    people_helped INTEGER DEFAULT 0,
    fundraisers_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создаём тип для метода оплаты
CREATE TYPE payment_method_enum AS ENUM ('sbp', 'card');

-- Таблица сборов
CREATE TABLE IF NOT EXISTS fundraisers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'mortgage', 'medical', 'education', 'other'
    goal_amount DECIMAL(10, 2) NOT NULL,
    current_amount DECIMAL(10, 2) DEFAULT 0,
    payment_method payment_method_enum NOT NULL DEFAULT 'card',
    card_number VARCHAR(20),
    card_holder_name VARCHAR(255),
    bank_name VARCHAR(100),
    sbp_phone VARCHAR(20),
    sbp_bank VARCHAR(100),
    image_url VARCHAR(500),
    image_urls TEXT[],
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'closed'
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT check_payment_details CHECK (
        (payment_method = 'sbp' AND sbp_phone IS NOT NULL AND sbp_bank IS NOT NULL) OR
        (payment_method = 'card' AND card_number IS NOT NULL)
    )
);

-- Таблица донатов
CREATE TABLE IF NOT EXISTS donations (
    id SERIAL PRIMARY KEY,
    fundraiser_id INTEGER NOT NULL REFERENCES fundraisers(id) ON DELETE CASCADE,
    donor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    screenshot_url VARCHAR(500) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP
);

-- Таблица достижений
CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'donor', 'fundraiser', 'community'
    requirement_type VARCHAR(50) NOT NULL, -- 'donation_count', 'donation_amount', 'people_helped', etc.
    requirement_value INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица полученных достижений пользователями
CREATE TABLE IF NOT EXISTS user_achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

-- Таблица уведомлений
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'donation_received', 'donation_approved', 'achievement_earned', etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    related_id INTEGER, -- ID связанной сущности (donation, achievement, etc.)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для оптимизации запросов
CREATE INDEX idx_fundraisers_user_id ON fundraisers(user_id);
CREATE INDEX idx_fundraisers_status ON fundraisers(status);
CREATE INDEX idx_fundraisers_category ON fundraisers(category);
CREATE INDEX idx_donations_fundraiser_id ON donations(fundraiser_id);
CREATE INDEX idx_donations_donor_id ON donations(donor_id);
CREATE INDEX idx_donations_status ON donations(status);
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Вставка базовых достижений
INSERT INTO achievements (code, title, description, icon, category, requirement_type, requirement_value) VALUES
('first_donation', 'Первый шаг', 'Совершите первое пожертвование', '🌱', 'donor', 'donation_count', 1),
('generous_heart', 'Щедрое сердце', 'Помогите 5 людям', '❤️', 'donor', 'people_helped', 5),
('philanthropist', 'Филантроп', 'Помогите 20 людям', '🌟', 'donor', 'people_helped', 20),
('hero', 'Герой добра', 'Помогите 50 людям', '🦸', 'donor', 'people_helped', 50),
('small_donor', 'Начинающий благотворитель', 'Пожертвуйте 1000 рублей', '💰', 'donor', 'donation_amount', 1000),
('big_donor', 'Большое сердце', 'Пожертвуйте 10000 рублей', '💎', 'donor', 'donation_amount', 10000),
('mega_donor', 'Меценат', 'Пожертвуйте 50000 рублей', '👑', 'donor', 'donation_amount', 50000),
('first_fundraiser', 'Первый сбор', 'Создайте свой первый сбор', '🎯', 'fundraiser', 'fundraiser_count', 1),
('successful_fundraiser', 'Успешный сбор', 'Закройте сбор на 100%', '🏆', 'fundraiser', 'fundraiser_completed', 1),
('community_star', 'Звезда сообщества', 'Получите 100 пожертвований', '⭐', 'community', 'donations_received', 100);
