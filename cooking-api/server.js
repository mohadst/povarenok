const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// === НАСТРОЙКИ CORS ===
app.use(cors({
  origin: '*', // Временно разрешаем все для тестов
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

app.options('*', cors()); // Обработка preflight запросов

// Middleware
app.use(express.json());

// КОРНЕВОЙ МАРШРУТ
app.get('/', (req, res) => {
  res.json({
    message: 'Cooking Assistant API работает!',
    status: 'OK',
    version: '1.0.0',
    endpoints: {
      auth: {
        register: 'POST /api/auth/register',
        login: 'POST /api/auth/login'
      },
      recipes: 'GET /api/recipes (требует токен)',
      check: 'GET /api/check (проверка токена)',
      health: 'GET /health'
    }
  });
});

// PostgreSQL connection pool
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'cooking_assistant',
  password: process.env.DB_PASSWORD || '12345',
  port: process.env.DB_PORT || 5432,
});

// Инициализация базы данных
async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        phone_number VARCHAR(20) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS recipes (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS recipe_ingredients (
        id SERIAL PRIMARY KEY,
        recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
        ingredient TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS recipe_steps (
        id SERIAL PRIMARY KEY,
        recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
        step_number INTEGER NOT NULL,
        instruction TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS favorites (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, recipe_id)
      );

      CREATE TABLE IF NOT EXISTS user_preferences (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE UNIQUE,
        allergies TEXT[],
        dietary_preferences TEXT[],
        forbidden_products TEXT[]
      );

      CREATE TABLE IF NOT EXISTS recipe_allergens (
        id SERIAL PRIMARY KEY,
        recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
        allergen TEXT NOT NULL
      );
    `);
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Database initialization error:', error);
  } finally {
    client.release();
  }
}

// Middleware для проверки JWT токена
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

// Проверка токена (публичный маршрут для теста)
app.get('/api/check', authenticateToken, (req, res) => {
  res.json({
    authenticated: true,
    userId: req.user.userId,
    message: 'Токен валиден'
  });
});

// ============ AUTH ENDPOINTS ============

// Регистрация
app.post('/api/auth/register', async (req, res) => {
  const { phone_number, password } = req.body;

  if (!phone_number || !password) {
    return res.status(400).json({ error: 'Phone number and password are required' });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  try {
    // Проверяем, существует ли пользователь
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE phone_number = $1',
      [phone_number]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'User with this phone number already exists' });
    }

    // Хешируем пароль
    const passwordHash = await bcrypt.hash(password, 10);

    // Создаем пользователя
    const result = await pool.query(
      'INSERT INTO users (phone_number, password_hash) VALUES ($1, $2) RETURNING id, phone_number, created_at',
      [phone_number, passwordHash]
    );

    const user = result.rows[0];

    // Создаем JWT токен
    const token = jwt.sign({ userId: user.id, phone: user.phone_number }, JWT_SECRET, {
      expiresIn: '30d'
    });

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        phone_number: user.phone_number,
        created_at: user.created_at
      },
      token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Server error during registration' });
  }
});

// Вход
app.post('/api/auth/login', async (req, res) => {
  const { phone_number, password } = req.body;

  if (!phone_number || !password) {
    return res.status(400).json({ error: 'Phone number and password are required' });
  }

  try {
    // Ищем пользователя
    const result = await pool.query(
      'SELECT id, phone_number, password_hash, created_at FROM users WHERE phone_number = $1',
      [phone_number]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    const user = result.rows[0];

    // Проверяем пароль
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    // Создаем JWT токен
    const token = jwt.sign({ userId: user.id, phone: user.phone_number }, JWT_SECRET, {
      expiresIn: '30d'
    });

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        phone_number: user.phone_number,
        created_at: user.created_at
      },
      token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
});

// ============ RECIPE ENDPOINTS ============

// Получить все рецепты пользователя
app.get('/api/recipes', authenticateToken, async (req, res) => {
  try {
    // 1. Получаем предпочтения пользователя
    const preferencesResult = await pool.query(
      'SELECT allergies FROM user_preferences WHERE user_id = $1',
      [req.user.userId]
    );

    const userAllergies = preferencesResult.rows[0]?.allergies || [];

    // 2. Получаем рецепты с фильтрацией
    let query = `
      SELECT DISTINCT r.* 
      FROM recipes r
      LEFT JOIN recipe_allergens ra ON r.id = ra.recipe_id
      WHERE r.user_id = $1
    `;

    const queryParams = [req.user.userId];

    // Если у пользователя есть аллергии, фильтруем
    if (userAllergies.length > 0) {
      query += ` AND (ra.allergen IS NULL OR ra.allergen NOT IN (SELECT unnest($2::text[])))`;
      queryParams.push(userAllergies);
    }

    query += ` ORDER BY r.created_at DESC`;

    const recipesResult = await pool.query(query, queryParams);

    const recipes = [];
    
    // 3. Для каждого рецепта получаем полную информацию
    for (const recipe of recipesResult.rows) {
      const ingredients = await pool.query(
        'SELECT ingredient FROM recipe_ingredients WHERE recipe_id = $1',
        [recipe.id]
      );
      
      const steps = await pool.query(
        'SELECT step_number, instruction FROM recipe_steps WHERE recipe_id = $1 ORDER BY step_number',
        [recipe.id]
      );

      const allergens = await pool.query(
        'SELECT allergen FROM recipe_allergens WHERE recipe_id = $1',
        [recipe.id]
      );

      // Проверяем, в избранном ли рецепт
      const favorite = await pool.query(
        'SELECT id FROM favorites WHERE user_id = $1 AND recipe_id = $2',
        [req.user.userId, recipe.id]
      );
      
      recipes.push({
        id: recipe.id,
        title: recipe.title,
        image_url: recipe.image_url,
        created_at: recipe.created_at,
        updated_at: recipe.updated_at,
        ingredients: ingredients.rows.map(r => r.ingredient),
        steps: steps.rows.map(r => ({
          step_number: r.step_number,
          instruction: r.instruction
        })),
        allergens: allergens.rows.map(r => r.allergen),
        is_favorite: favorite.rows.length > 0
      });
    }

    res.json(recipes);
  } catch (error) {
    console.error('Error fetching recipes:', error);
    res.status(500).json({ error: 'Server error: ' + error.message });
  }
});

// Создать рецепт
app.post('/api/recipes', authenticateToken, async (req, res) => {
  const { title, image_url, ingredients, steps, allergens } = req.body;

  if (!title || !ingredients || !steps) {
    return res.status(400).json({ error: 'Title, ingredients, and steps are required' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Создаем рецепт
    const recipeResult = await client.query(
      'INSERT INTO recipes (user_id, title, image_url) VALUES ($1, $2, $3) RETURNING *',
      [req.user.userId, title, image_url || null]
    );

    const recipe = recipeResult.rows[0];

    // Добавляем ингредиенты
    for (const ingredient of ingredients) {
      await client.query(
        'INSERT INTO recipe_ingredients (recipe_id, ingredient) VALUES ($1, $2)',
        [recipe.id, ingredient]
      );
    }

    // Добавляем шаги
    for (let i = 0; i < steps.length; i++) {
      await client.query(
        'INSERT INTO recipe_steps (recipe_id, step_number, instruction) VALUES ($1, $2, $3)',
        [recipe.id, i + 1, steps[i]]
      );
    }

    // Добавляем аллергены (если указаны)
    if (allergens && Array.isArray(allergens) && allergens.length > 0) {
      for (const allergen of allergens) {
        await client.query(
          'INSERT INTO recipe_allergens (recipe_id, allergen) VALUES ($1, $2)',
          [recipe.id, allergen]
        );
      }
    }

    await client.query('COMMIT');

    // Получаем полные данные созданного рецепта
    const recipeIngredients = await pool.query(
      'SELECT ingredient FROM recipe_ingredients WHERE recipe_id = $1',
      [recipe.id]
    );
    
    const recipeSteps = await pool.query(
      'SELECT step_number, instruction FROM recipe_steps WHERE recipe_id = $1 ORDER BY step_number',
      [recipe.id]
    );

    const recipeAllergens = await pool.query(
      'SELECT allergen FROM recipe_allergens WHERE recipe_id = $1',
      [recipe.id]
    );

    res.status(201).json({
      message: 'Recipe created successfully',
      recipe: {
        id: recipe.id,
        title: recipe.title,
        image_url: recipe.image_url,
        created_at: recipe.created_at,
        updated_at: recipe.updated_at,
        ingredients: recipeIngredients.rows.map(r => r.ingredient),
        steps: recipeSteps.rows.map(r => ({
          step_number: r.step_number,
          instruction: r.instruction
        })),
        allergens: recipeAllergens.rows.map(r => r.allergen),
        is_favorite: false
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating recipe:', error);
    res.status(500).json({ error: 'Server error creating recipe' });
  } finally {
    client.release();
  }
});

// Получить избранные рецепты
app.get('/api/favorites', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
        r.*,
        ARRAY_AGG(DISTINCT ri.ingredient) as ingredients,
        json_agg(DISTINCT jsonb_build_object('number', rs.step_number, 'instruction', rs.instruction) 
          ORDER BY rs.step_number) as steps,
        ARRAY_AGG(DISTINCT ra.allergen) as allergens
      FROM favorites f
      JOIN recipes r ON f.recipe_id = r.id
      LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      LEFT JOIN recipe_steps rs ON r.id = rs.recipe_id
      LEFT JOIN recipe_allergens ra ON r.id = ra.recipe_id
      WHERE f.user_id = $1
      GROUP BY r.id
      ORDER BY f.created_at DESC`,
      [req.user.userId]
    );

    res.json(result.rows.map(row => ({
      ...row,
      is_favorite: true
    })));
  } catch (error) {
    console.error('Error fetching favorites:', error);
    res.status(500).json({ error: 'Server error fetching favorites' });
  }
});

// Добавить в избранное
app.post('/api/favorites/:recipeId', authenticateToken, async (req, res) => {
  const { recipeId } = req.params;

  try {
    await pool.query(
      'INSERT INTO favorites (user_id, recipe_id) VALUES ($1, $2) ON CONFLICT (user_id, recipe_id) DO NOTHING',
      [req.user.userId, recipeId]
    );

    res.json({ message: 'Recipe added to favorites' });
  } catch (error) {
    console.error('Error adding to favorites:', error);
    res.status(500).json({ error: 'Server error adding to favorites' });
  }
});

// Удалить из избранного
app.delete('/api/favorites/:recipeId', authenticateToken, async (req, res) => {
  const { recipeId } = req.params;

  try {
    await pool.query(
      'DELETE FROM favorites WHERE user_id = $1 AND recipe_id = $2',
      [req.user.userId, recipeId]
    );

    res.json({ message: 'Recipe removed from favorites' });
  } catch (error) {
    console.error('Error removing from favorites:', error);
    res.status(500).json({ error: 'Server error removing from favorites' });
  }
});

// ============ USER PREFERENCES ============

// Получить предпочтения
app.get('/api/preferences', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM user_preferences WHERE user_id = $1',
      [req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.json({ allergies: [], dietary_preferences: [], forbidden_products: [] });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching preferences:', error);
    res.status(500).json({ error: 'Server error fetching preferences' });
  }
});

// Обновить предпочтения
app.put('/api/preferences', authenticateToken, async (req, res) => {
  const { allergies, dietary_preferences, forbidden_products } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO user_preferences (user_id, allergies, dietary_preferences, forbidden_products)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id) 
       DO UPDATE SET 
         allergies = $2,
         dietary_preferences = $3,
         forbidden_products = $4
       RETURNING *`,
      [
        req.user.userId,
        allergies || [],
        dietary_preferences || [],
        forbidden_products || []
      ]
    );

    res.json({ message: 'Preferences updated successfully', preferences: result.rows[0] });
  } catch (error) {
    console.error('Error updating preferences:', error);
    res.status(500).json({ error: 'Server error updating preferences' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Запуск сервера
app.listen(PORT, async () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 API доступен по адресам:`);
  console.log(`   - http://localhost:${PORT}`);
  console.log(`   - http://127.0.0.1:${PORT}`);
  console.log(`   - http://192.168.121.177:${PORT}`);
  console.log(`   - http://10.0.2.2:${PORT} (для Android эмулятора)`);
  await initDatabase();
});