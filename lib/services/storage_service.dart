import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Сохранить простые данные
  static Future<void> saveUserData(String phone, String username) async {
    await _prefs?.setString('user_phone', phone);
    await _prefs?.setString('user_username', username);
  }

  // Получить данные пользователя
  static Future<Map<String, String>> getUserData() async {
    return {
      'phone': _prefs?.getString('user_phone') ?? '',
      'username': _prefs?.getString('user_username') ?? '',
    };
  }

  // Проверить, есть ли сохраненный пользователь
  static Future<bool> hasUser() async {
    final phone = _prefs?.getString('user_phone');
    return phone != null && phone.isNotEmpty;
  }
}