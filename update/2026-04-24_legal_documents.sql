-- Legal documents table
CREATE TABLE IF NOT EXISTS legal_documents (
  id SERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL UNIQUE, -- 'privacy', 'terms', 'offer'
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_by INTEGER REFERENCES users(id)
);

-- Insert default documents
INSERT INTO legal_documents (type, title, content) VALUES 
('privacy', 'Политика конфиденциальности', 'Политика конфиденциальности находится в разработке.'),
('terms', 'Пользовательское соглашение', 'Пользовательское соглашение находится в разработке.'),
('offer', 'Оферта', 'Оферта находится в разработке.')
ON CONFLICT (type) DO NOTHING;