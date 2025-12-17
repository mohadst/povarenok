import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Измените на IP вашего сервера
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Получить сохраненный токен
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Сохранить токен
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Удалить токен
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Регистрация
  static Future<Map<String, dynamic>> register(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Вход
  static Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Выход
  static Future<void> logout() async {
    await removeToken();
  }

  // Получить заголовки с токеном
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Получить все рецепты пользователя
// Получить все рецепты пользователя (ИСПРАВЛЕННАЯ ВЕРСИЯ)
static Future<List<dynamic>> getRecipes() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/recipes'),
      headers: headers,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Проверяем структуру ответа
      if (data is Map && data.containsKey('success')) {
        // Если ответ в формате {success: true, recipes: [...]}
        if (data['success'] == true) {
          return data['recipes'] ?? [];
        } else {
          throw Exception(data['error'] ?? 'Ошибка сервера');
        }
      } else if (data is List) {
        // Если ответ просто массив рецептов
        return data;
      } else {
        throw Exception('Неизвестный формат ответа');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Ошибка: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Ошибка в getRecipes(): $e');
    throw Exception('Ошибка сети: $e');
  }
}
  // Создать рецепт
  static Future<Map<String, dynamic>> createRecipe({
    required String title,
    String? imageUrl,
    required List<String> ingredients,
    required List<String> steps,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/recipes'),
        headers: headers,
        body: json.encode({
          'title': title,
          'image_url': imageUrl,
          'ingredients': ingredients,
          'steps': steps,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'recipe': data['recipe']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to create recipe'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Получить избранные рецепты
  static Future<List<dynamic>> getFavorites() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Добавить в избранное
  static Future<bool> addToFavorites(int recipeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$recipeId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Удалить из избранного
  static Future<bool> removeFromFavorites(int recipeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$recipeId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Получить предпочтения пользователя
  static Future<Map<String, dynamic>> getPreferences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/preferences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load preferences');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Обновить предпочтения
  static Future<bool> updatePreferences({
    List<String>? allergies,
    List<String>? dietaryPreferences,
    List<String>? forbiddenProducts,
  }) async {
    try {
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

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}