import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.121.177:3000/api';
  // Для отладки - показывать все запросы
  static bool debugMode = true;

  // Получить сохраненный токен
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (debugMode) print('📱 Получен токен: ${token != null ? "ЕСТЬ" : "НЕТ"}');
    return token;
  }

  // Сохранить токен
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('is_logged_in', true);
    if (debugMode) print('💾 Токен сохранен');
  }

  // Удалить токен
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_logged_in');
    if (debugMode) print('🗑️ Токен удален');
  }

  // Проверить авторизацию
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('is_logged_in') ?? false;
    if (debugMode) print('🔐 Пользователь авторизован: $isLogged');
    return isLogged;
  }

  // Получить заголовки с токеном
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (debugMode) {
      print('📤 Заголовки запроса:');
      print('  Content-Type: application/json');
      print('  Authorization: Bearer ${token != null ? "***${token.substring(token.length - 5)}" : "NULL"}');
    }
    return headers;
  }

  // ============ AUTH ============

  // Регистрация
  static Future<Map<String, dynamic>> register(
      String phoneNumber, String password) async {
    try {
      if (debugMode) {
        print('🚀 Регистрация пользователя:');
        print('  URL: $baseUrl/auth/register');
        print('  Телефон: $phoneNumber');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (debugMode) {
        print('📥 Ответ регистрации:');
        print('  Статус: ${response.statusCode}');
        print('  Тело: $data');
      }
      
      if (response.statusCode == 201) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user'], 'token': data['token']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      if (debugMode) print('❌ Ошибка регистрации: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Вход
  static Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    try {
      if (debugMode) {
        print('🚀 Вход пользователя:');
        print('  URL: $baseUrl/auth/login');
        print('  Телефон: $phoneNumber');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (debugMode) {
        print('📥 Ответ входа:');
        print('  Статус: ${response.statusCode}');
        print('  Тело: $data');
      }
      
      if (response.statusCode == 200) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user'], 'token': data['token']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      if (debugMode) print('❌ Ошибка входа: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Выход
  static Future<void> logout() async {
    if (debugMode) print('🚪 Выход из системы');
    await removeToken();
  }

  // ============ RECIPES ============

  // Получить все рецепты пользователя
  static Future<List<dynamic>> getRecipes() async {
    try {
      if (debugMode) print('📋 Запрос рецептов...');
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/recipes'),
        headers: headers,
      );

      if (debugMode) {
        print('📥 Ответ рецептов:');
        print('  Статус: ${response.statusCode}');
        print('  Тело: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}');
      }
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован. Пожалуйста, войдите снова.');
      } else {
        throw Exception('Ошибка загрузки рецептов: ${response.statusCode}');
      }
    } catch (e) {
      if (debugMode) print('❌ Ошибка в getRecipes(): $e');
      throw Exception('Не удалось загрузить рецепты: $e');
    }
  }

  // Создать рецепт
  static Future<Map<String, dynamic>> createRecipe({
    required String title,
    String? imageUrl,
    required List<String> ingredients,
    required List<String> steps,
    List<String> allergens = const [],
  }) async {
    try {
      if (debugMode) {
        print('🍳 Создание рецепта:');
        print('  URL: $baseUrl/recipes');
        print('  Название: $title');
        print('  Ингредиенты: $ingredients');
        print('  Шаги: $steps');
      }
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/recipes'),
        headers: headers,
        body: json.encode({
          'title': title,
          'image_url': imageUrl,
          'ingredients': ingredients,
          'steps': steps,
          'allergens': allergens,
        }),
      );

      if (debugMode) {
        print('📥 Ответ создания рецепта:');
        print('  Статус: ${response.statusCode}');
        print('  Тело: ${response.body}');
      }
      
      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'recipe': data['recipe']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create recipe'};
      }
    } catch (e) {
      if (debugMode) print('❌ Ошибка в createRecipe: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============ FAVORITES ============

  // Получить избранные рецепты
// В ApiService.dart обновите метод getFavorites:
static Future<List<dynamic>> getFavorites() async {
  try {
    if (debugMode) print('⭐ Запрос избранных рецептов...');
    final headers = await _getHeaders();
    
    // Добавьте отладку заголовков
    final token = await getToken();
    if (debugMode) {
      print('Токен: ${token != null ? "ЕСТЬ (${token.length} символов)" : "ОТСУТСТВУЕТ"}');
      print('Заголовки: $headers');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: headers,
    );

    if (debugMode) {
      print('📥 Ответ избранных:');
      print('  Статус: ${response.statusCode}');
      print('  Тело: ${response.body}'); // Показываем полное тело для 500 ошибки
    }
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Для 500 ошибки попробуем получить больше информации
      final errorBody = response.body;
      if (debugMode) print('Полный текст ошибки: $errorBody');
      throw Exception('Ошибка загрузки избранного: ${response.statusCode}. $errorBody');
    }
  } catch (e) {
    if (debugMode) print('❌ Исключение в getFavorites(): $e');
    throw Exception('Network error: $e');
  }
}

  // Добавьте в ApiService:
static Future<Map<String, dynamic>> testFavoritesEndpoint() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: headers,
    );
    
    return {
      'status': response.statusCode,
      'body': response.body,
      'headers': response.headers,
    };
  } catch (e) {
    return {'error': e.toString()};
  }
}
  // Добавить в избранное
  static Future<bool> addToFavorites(int recipeId) async {
    try {
      if (debugMode) print('➕ Добавление в избранное: $recipeId');
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$recipeId'),
        headers: headers,
      );

      if (debugMode) print('📥 Ответ добавления: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      if (debugMode) print('❌ Ошибка добавления в избранное: $e');
      return false;
    }
  }

  // Удалить из избранного
  static Future<bool> removeFromFavorites(int recipeId) async {
    try {
      if (debugMode) print('➖ Удаление из избранного: $recipeId');
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$recipeId'),
        headers: headers,
      );

      if (debugMode) print('📥 Ответ удаления: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      if (debugMode) print('❌ Ошибка удаления из избранного: $e');
      return false;
    }
  }

  // Проверить, в избранном ли рецепт
  static Future<bool> isFavorite(int recipeId) async {
    try {
      if (debugMode) print('🔍 Проверка избранного: $recipeId');
      final favorites = await getFavorites();
      final isFav = favorites.any((recipe) => recipe['id'] == recipeId);
      if (debugMode) print('📊 Результат проверки: $isFav');
      return isFav;
    } catch (e) {
      if (debugMode) print('❌ Ошибка проверки избранного: $e');
      return false;
    }
  }

// В файле api_service.dart ДОБАВЬТЕ метод для диагностики:
static Future<Map<String, dynamic>> diagnoseFavoritesError() async {
  try {
    print('🔍 Диагностика ошибки избранного...');
    
    // 1. Проверка токена
    final token = await getToken();
    print('Токен: ${token != null ? "ЕСТЬ (${token.length} символов)" : "НЕТ"}');
    
    if (token == null) {
      return {'error': 'Token missing', 'solution': 'User needs to login again'};
    }
    
    // 2. Проверка эндпоинта
    print('Проверка эндпоинта: $baseUrl/favorites');
    
    // 3. Отправка тестового запроса
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: headers,
    );
    
    print('Ответ сервера: ${response.statusCode}');
    print('Тело ответа: ${response.body}');
    
    return {
      'status': response.statusCode,
      'body': response.body,
      'error': response.statusCode != 200 ? 'Server error' : null
    };
  } catch (e) {
    print('Ошибка диагностики: $e');
    return {'error': e.toString()};
  }
}

  // ============ PREFERENCES ============

  // Получить предпочтения пользователя
  static Future<Map<String, dynamic>> getPreferences() async {
    try {
      if (debugMode) print('⚙️ Запрос предпочтений...');
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/preferences'),
        headers: headers,
      );

      if (debugMode) {
        print('📥 Ответ предпочтений:');
        print('  Статус: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'allergies': [], 'dietary_preferences': [], 'forbidden_products': []};
      }
    } catch (e) {
      if (debugMode) print('❌ Ошибка получения предпочтений: $e');
      return {'allergies': [], 'dietary_preferences': [], 'forbidden_products': []};
    }
  }

  // Обновить предпочтения
  static Future<bool> updatePreferences({
    List<String>? allergies,
    List<String>? dietaryPreferences,
    List<String>? forbiddenProducts,
  }) async {
    try {
      if (debugMode) print('⚙️ Обновление предпочтений...');
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/preferences'),
        headers: headers,
        body: json.encode({
          'allergies': allergies ?? [],
          'dietary_preferences': dietaryPreferences ?? [],
          'forbidden_products': forbiddenProducts ?? [],
        }),
      );

      if (debugMode) print('📥 Ответ обновления: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      if (debugMode) print('❌ Ошибка обновления предпочтений: $e');
      return false;
    }
  }

  // ============ HEALTH CHECK ============

  // Проверить доступность API
  static Future<bool> checkApiHealth() async {
    try {
      if (debugMode) print('🏥 Проверка здоровья API...');
      final response = await http
          .get(Uri.parse('http://localhost:3000/health'))
          .timeout(const Duration(seconds: 5));
      
      if (debugMode) {
        print('📥 Ответ здоровья:');
        print('  Статус: ${response.statusCode}');
        print('  Тело: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (debugMode) print('❌ API недоступен: $e');
      return false;
    }
  }

  // Проверить токен
  static Future<bool> checkToken() async {
    try {
      if (debugMode) print('🔑 Проверка токена...');
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/check'),
        headers: headers,
      );
      
      if (debugMode) {
        print('📥 Ответ проверки токена:');
        print('  Статус: ${response.statusCode}');
        print('  Тело: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (debugMode) print('❌ Ошибка проверки токена: $e');
      return false;
    }
  }
  
  // ============ ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ ============
  
  // Очистить все логи
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (debugMode) print('🧹 Все данные очищены');
  }
  
  // Получить информацию о токене
  static Future<void> debugTokenInfo() async {
    final token = await getToken();
    final isLogged = await isLoggedIn();
    print('=== DEBUG TOKEN INFO ===');
    print('Токен присутствует: ${token != null}');
    print('Длина токена: ${token?.length ?? 0}');
    print('is_logged_in: $isLogged');
    print('=======================');
  }
}