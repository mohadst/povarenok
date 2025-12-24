-- Обновите таблицу users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Демо пользователь с телефоном
INSERT INTO users (phone, username, password_hash) VALUES
('+79998882233', 'demo_user', 'test123');

-- Таблица рецептов
CREATE TABLE IF NOT EXISTS recipes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    ingredients JSONB DEFAULT '[]',
    steps JSONB DEFAULT '[]',
    prep_time INTEGER DEFAULT 0,
    cook_time INTEGER DEFAULT 0,
    difficulty VARCHAR(20) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица избранного
CREATE TABLE IF NOT EXISTS favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, recipe_id)
);

-- Демо данные (опционально)
INSERT INTO users (email, username, password_hash) VALUES
('demo@example.com', 'demo_user', 'demo_password');

INSERT INTO recipes (title, image_url, ingredients, steps) VALUES
('Паста Карбонара', 'https://images.unsplash.com/photo-1621996346565-e3dbc353d2c5',
 '["Спагетти - 400г", "Бекон - 150г", "Яйца - 3 шт", "Пармезан - 100г", "Чеснок - 2 зубчика"]',
 '[{"number": 1, "instruction": "Отварить пасту в подсоленной воде"}, 
   {"number": 2, "instruction": "Обжарить бекон до хрустящей корочки"},
   {"number": 3, "instruction": "Смешать яйца с тертым пармезаном"},
   {"number": 4, "instruction": "Смешать пасту с беконом и яичной смесью"}]'),
   
('Омлет с овощами', 'https://images.unsplash.com/photo-1568401418173-9827f9ce7d5f',
 '["Яйца - 3 шт", "Молоко - 50 мл", "Помидор - 1 шт", "Лук - 1/2 шт", "Сыр - 50г"]',
 '[{"number": 1, "instruction": "Нарезать овощи мелкими кубиками"}, 
   {"number": 2, "instruction": "Взбить яйца с молоком и солью"},
   {"number": 3, "instruction": "Обжарить овощи на сковороде 5 минут"},
   {"number": 4, "instruction": "Залить яичной смесью, готовить под крышкой 7 минут"}]');