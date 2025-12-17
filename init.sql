-- Создаем пользователя postgres если его нет
DO
$$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles 
    WHERE rolname = 'postgres'
  ) THEN
    CREATE USER postgres WITH PASSWORD '12345';
    ALTER USER postgres WITH SUPERUSER;
  END IF;
END
$$;

-- Создаем базу данных
CREATE DATABASE cooking_assistant;

-- Даем права пользователю postgres
GRANT ALL PRIVILEGES ON DATABASE cooking_assistant TO postgres;

-- Подключаемся к базе
\c cooking_assistant;

-- Создаем таблицы
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы рецептов
CREATE TABLE IF NOT EXISTS recipes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    servings INTEGER,
    difficulty VARCHAR(20),
    category VARCHAR(50),
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы ингредиентов
CREATE TABLE IF NOT EXISTS ingredients (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    quantity VARCHAR(50),
    unit VARCHAR(20),
    order_index INTEGER DEFAULT 0
);

-- Создание таблицы шагов приготовления
CREATE TABLE IF NOT EXISTS recipe_steps (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    timer_duration INTEGER,
    order_index INTEGER DEFAULT 0
);

-- Создание таблицы избранного
CREATE TABLE IF NOT EXISTS favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, recipe_id)
);

-- Даем права пользователю на все таблицы
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cooking_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cooking_user;

-- Добавляем тестового пользователя
INSERT INTO users (phone, password_hash, username) VALUES
('+79991112233', '$2a$10$N9qo8uLOickgx2ZMRZoMye.RY9J5G.1nHZ8H3DqB6W7eYpOcXq1W2', 'Тестовый Пользователь')
ON CONFLICT (phone) DO NOTHING;

-- Добавляем тестовые рецепты
INSERT INTO recipes (user_id, title, description, category, difficulty, servings) VALUES
(1, 'Блины на молоке', 'Вкусные домашние блины', 'Завтрак', 'easy', 4),
(1, 'Салат Цезарь', 'Классический салат с курицей', 'Обед', 'medium', 2)
ON CONFLICT DO NOTHING; 