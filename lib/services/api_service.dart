import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';


  static Future<String> getBaseUrl() async {
    final urls = [
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://10.0.2.2:3000',
    ];
    
    for (var url in urls) {
      try {
        final response = await http.get(Uri.parse('$url/api/health'))
          .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          print('✅ Выбран базовый URL: $url');
          return '$url/api';
        }
      } catch (e) {
        print('❌ $url недоступен');
      }
    }
    
    return 'http://localhost:3000/api';
  }



  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final apiBaseUrl = await getBaseUrl();
    
    try {
      print('🔄 Вход: $phone через $apiBaseUrl');
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30)); 
      
      print('📊 Статус входа: ${response.statusCode}');
      print('📦 Тело ответа: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          await StorageService.saveUserData(
            data['user']['phone'],
            data['user']['username']
          );
        }
        
        return data;
      } else {
        try {
          final error = jsonDecode(response.body);
          return error;
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.body}'
          };
        }
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> register(String phone, String username, String password) async {
    try {
      print('🔄 Регистрация: $phone, $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('📊 Статус регистрации: ${response.statusCode}');
      print('📦 Ответ: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        
        if (data['success'] == true && data['user'] != null) {
          await StorageService.saveUserData(
            data['user']['phone'],
            data['user']['username']
          );
        }
        
        return data;
      } else {
        final error = jsonDecode(response.body);
        return error;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e'
      };
    }
  }


static Future<Map<String, dynamic>> saveRecipe(Map<String, dynamic> recipeData) async {
  final apiBaseUrl = await getBaseUrl();
  
  try {
    print('🔄 Сохранение рецепта на сервер...');
    print('📦 Данные рецепта: ${recipeData['title']}');
    
    final response = await http.post(
      Uri.parse('$apiBaseUrl/recipes'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(recipeData),
    ).timeout(const Duration(seconds: 30));
    
    print('📊 Статус сохранения: ${response.statusCode}');
    print('📦 Ответ сервера: ${response.body}');
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'recipe': data,
      };
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'error': error['error'] ?? 'Ошибка сохранения'
      };
    }
  } catch (e) {
    print('❌ Ошибка сохранения рецепта: $e');
    return {
      'success': false,
      'error': 'Ошибка сети: $e'
    };
  }
}

static Future<List<dynamic>> getRecipes() async {
  final apiBaseUrl = await getBaseUrl();
  
  try {
    print('🔄 Загрузка рецептов с сервера...');
    
    final response = await http.get(
      Uri.parse('$apiBaseUrl/recipes'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    print('📊 Статус загрузки: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('📦 Загружено рецептов: ${(data is List ? data.length : 0)}');
      return data is List ? data : [];
    }
    return [];
  } catch (e) {
    print('❌ Ошибка загрузки рецептов: $e');
    return [];
  }
}

  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}