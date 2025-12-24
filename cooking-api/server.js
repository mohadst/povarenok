const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json()); 
app.use(express.urlencoded({ extended: true }));

const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = [
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://localhost:56273',
      'http://127.0.0.1:56273',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://10.0.2.2:3000',
    ];
    
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));

app.use((req, res, next) => {
  console.log('\n' + '='.repeat(50));
  console.log(`📥 ${new Date().toISOString()} ${req.method} ${req.url}`);
  console.log(`📋 Headers:`, JSON.stringify(req.headers, null, 2));
  console.log(`📦 Body:`, JSON.stringify(req.body, null, 2));
  console.log(`🔍 Query:`, JSON.stringify(req.query, null, 2));
  next();
});

app.options('*', cors(corsOptions));

app.get('/api/health', (req, res) => {
  console.log('✅ Health check запрос');
  res.json({
    status: 'ok',
    server_time: new Date().toISOString(),
    api_version: '1.0',
    endpoints: [
      { method: 'POST', path: '/api/auth/login', description: 'Вход пользователя' },
      { method: 'POST', path: '/api/auth/register', description: 'Регистрация пользователя' },
      { method: 'GET', path: '/api/recipes', description: 'Получить все рецепты' },
    ]
  });
});

const users = [
  { 
    id: 1, 
    phone: '+79998882233', 
    username: 'test_user', 
    password_hash: 'test123',
    created_at: new Date().toISOString()
  }
];

const recipes = [
  { 
    id: 1, 
    title: 'Классический борщ', 
    image_url: 'https://example.com/borsh.jpg',
    ingredients: JSON.stringify(['свекла', 'картофель', 'капуста', 'мясо']),
    steps: JSON.stringify(['Почистить овощи', 'Сварить бульон', 'Добавить овощи']),
    created_at: new Date().toISOString()
  },
  { 
    id: 2, 
    title: 'Оливье', 
    image_url: 'https://example.com/olivier.jpg',
    ingredients: JSON.stringify(['картофель', 'колбаса', 'огурцы', 'горошек']),
    steps: JSON.stringify(['Отварить овощи', 'Нарезать ингредиенты', 'Заправить майонезом']),
    created_at: new Date().toISOString()
  }
];


app.post('/api/auth/register', (req, res) => {
  console.log('📨 Регистрация пользователя');
  
  try {
    const { phone, username, password } = req.body;
    
    if (!phone || !username || !password) {
      console.log('❌ Отсутствуют обязательные поля');
      return res.status(400).json({ 
        success: false,
        error: 'Все поля обязательны: phone, username, password' 
      });
    }
    
    const existingUser = users.find(u => 
      u.phone === phone || u.username === username
    );
    
    if (existingUser) {
      console.log('❌ Пользователь уже существует');
      return res.status(400).json({ 
        success: false,
        error: 'Пользователь с таким телефоном или именем уже существует' 
      });
    }
    
    const newUser = {
      id: users.length + 1,
      phone,
      username,
      password_hash: password, 
      created_at: new Date().toISOString()
    };
    
    users.push(newUser);
    console.log('✅ Пользователь создан:', newUser);
    
    res.status(201).json({
      success: true,
      message: 'Регистрация успешна',
      user: {
        id: newUser.id,
        phone: newUser.phone,
        username: newUser.username,
        created_at: newUser.created_at
      }
    });
    
  } catch (error) {
    console.error('💥 Ошибка регистрации:', error);
    res.status(500).json({ 
      success: false,
      error: 'Ошибка сервера при регистрации' 
    });
  }
});

app.post('/api/auth/login', (req, res) => {
  console.log('\n' + '🔐 ЗАПРОС НА ВХОД ==========');
  console.log('Полный req объект:', {
    method: req.method,
    url: req.url,
    headers: req.headers,
    body: req.body,
    bodyType: typeof req.body,
    bodyKeys: Object.keys(req.body || {})
  });
  
  try {
    if (!req.body || Object.keys(req.body).length === 0) {
      console.log('❌ Тело запроса пустое или undefined');
      return res.status(400).json({
        success: false,
        error: 'Тело запроса пустое. Отправьте JSON с phone и password'
      });
    }
    
    const { phone, password } = req.body;
    console.log('📱 Парсинг данных:', { phone, password });
    
    if (!phone || !password) {
      console.log('❌ Отсутствуют phone или password');
      return res.status(400).json({
        success: false,
        error: 'Требуются phone и password'
      });
    }
    
    const user = users.find(u => u.phone === phone);
    console.log('👤 Найден пользователь:', user);
    
    if (!user) {
      console.log('❌ Пользователь не найден:', phone);
      return res.status(401).json({
        success: false,
        error: 'Пользователь не найден'
      });
    }
    
    if (user.password_hash !== password) {
      console.log('❌ Неверный пароль для:', phone);
      return res.status(401).json({
        success: false,
        error: 'Неверный пароль'
      });
    }
    
    console.log('✅ Успешный вход для:', phone);
    
    res.json({
      success: true,
      token: 'token_' + Date.now(),
      user: {
        id: user.id,
        phone: user.phone,
        username: user.username,
        created_at: user.created_at
      }
    });
    
  } catch (error) {
    console.error('💥 Критическая ошибка входа:', error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Внутренняя ошибка сервера: ' + error.message
    });
  }
});

app.get('/api/recipes', (req, res) => {
  console.log('📨 Запрос рецептов');
  
  try {
    const formattedRecipes = recipes.map(recipe => ({
      ...recipe,
      ingredients: JSON.parse(recipe.ingredients),
      steps: JSON.parse(recipe.steps)
    }));
    
    res.json(formattedRecipes);
  } catch (error) {
    console.error('💥 Ошибка получения рецептов:', error);
    res.status(500).json({ error: 'Ошибка получения рецептов' });
  }
});

app.post('/api/recipes', (req, res) => {
  console.log('📨 Сохранение нового рецепта');
  console.log('📦 Данные рецепта:', req.body);
  
  try {
    const { 
      title, 
      imageUrl, 
      ingredients, 
      steps
    } = req.body;
    
    if (!title || !ingredients || !steps) {
      console.log('❌ Отсутствуют обязательные поля');
      return res.status(400).json({ 
        success: false,
        error: 'Обязательные поля: title, ingredients, steps' 
      });
    }
    
    const newRecipe = {
      id: recipes.length + 1,
      title,
      image_url: imageUrl || 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=600',
      ingredients: JSON.stringify(ingredients),
      steps: JSON.stringify(steps),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    recipes.push(newRecipe);
    console.log('✅ Рецепт сохранен:', newRecipe.id, newRecipe.title);
    
    const formattedRecipe = {
      ...newRecipe,
      ingredients: JSON.parse(newRecipe.ingredients),
      steps: JSON.parse(newRecipe.steps)
    };
    
    res.status(201).json({
      success: true,
      message: 'Рецепт успешно сохранен',
      recipe: formattedRecipe
    });
    
  } catch (error) {
    console.error('💥 Ошибка сохранения рецепта:', error);
    res.status(500).json({ 
      success: false,
      error: 'Ошибка сервера при сохранении рецепта' 
    });
  }
});


app.use((err, req, res, next) => {
  console.error('🔥 Глобальная ошибка:', err);
  res.status(500).json({
    success: false,
    error: 'Внутренняя ошибка сервера',
    details: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(port, () => {
  console.log('\n' + '='.repeat(50));
  console.log(`🚀 Сервер запущен на http://localhost:${port}`);
  console.log('📊 Доступные эндпоинты:');
  console.log(`   POST http://localhost:${port}/api/auth/login`);
  console.log(`   POST http://localhost:${port}/api/auth/register`);
  console.log(`   GET  http://localhost:${port}/api/health`);
  console.log(`   GET  http://localhost:${port}/api/recipes`);
  console.log('='.repeat(50) + '\n');
});