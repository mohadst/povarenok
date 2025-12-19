import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onRegisterTap;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onRegisterTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String phoneNumber = '';
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _testLoginAndLoadRecipes() async {
    if (isLoading) return;
    
    setState(() => isLoading = true);
    
    try {
      print('🔄 Тестирование входа с +79998882233...');
      
      final loginResult = await ApiService.login('+79998882233', 'test123');
      
      if (loginResult['success'] == true) {
        print('✅ Вход успешен!');
        print('   Пользователь: ${loginResult['user']}');
        
        print('🔄 Загрузка рецептов...');   
        try {
          final recipes = await ApiService.getRecipes();
          print('✅ Успешно загружено рецептов: ${recipes.length}');
          
          if (recipes.isNotEmpty) {
            print('📋 Первый рецепт: ${recipes.first['title']}');
            for (var recipe in recipes) {
              print('   - ${recipe['title']} (ID: ${recipe['id']})');
            }
          }
          
          widget.onLoginSuccess();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Успешно! Загружено ${recipes.length} рецептов'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
        } catch (e) {
          print('❌ Ошибка загрузки рецептов: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Вход успешен, но ошибка рецептов: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print('❌ Ошибка входа: ${loginResult['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка теста: ${loginResult['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Общая ошибка теста: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сети: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> handleLogin() async {
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите корректный номер телефона")),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароль должен быть минимум 6 символов")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(phoneNumber, passwordController.text);

      if (!mounted) return;

      if (result['success']) {
        try {
          final recipes = await ApiService.getRecipes();
          print('✅ После входа загружено рецептов: ${recipes.length}');
        } catch (e) {
          print('⚠️ Вход успешен, но ошибка загрузки рецептов: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Вход выполнен успешно!"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Ошибка входа'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка подключения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Вход',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Телефон
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                border: OutlineInputBorder(),
              ),
              initialCountryCode: 'RU',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (phone) {
                phoneNumber = phone.completeNumber;
              },
            ),
            const SizedBox(height: 20),

            // Пароль
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Пароль',
              ),
            ),
            const SizedBox(height: 20),

            // ОСНОВНАЯ КНОПКА ВХОДА
            ElevatedButton(
              onPressed: isLoading ? null : handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Войти'),
            ),
            
            // КНОПКА ПРОВЕРКИ ПОДКЛЮЧЕНИЯ
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text(
                    'DEBUG: Проверка сервера',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      print('🔄 Тестирую подключение к серверу...');
                      
                      final urls = [
                        'http://localhost:3000/health',
                        'http://10.0.2.2:3000/health',
                        'http://127.0.0.1:3000/health',
                        'http://192.168.121.177:3000/health',
                      ];
                      
                      for (var url in urls) {
                        try {
                          print('🔄 Пробую: $url');
                          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
                          print('✅ Успех: ${response.statusCode} - ${response.body}');
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Сервер доступен по $url'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          return;
                        } catch (e) {
                          print('❌ $url: $e');
                        }
                      }
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('❌ Все адреса недоступны'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text(
                      '🔧 Проверить подключение (все адреса)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            // КНОПКА ТЕСТА ВХОДА
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: isLoading ? null : _testLoginAndLoadRecipes,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                side: const BorderSide(color: Colors.orange),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bug_report, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Тест: войти и загрузить рецепты',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
            ),
            
            const SizedBox(height: 10),

            TextButton(
              onPressed: widget.onRegisterTap,
              child: const Text('Нет аккаунта? Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }
}