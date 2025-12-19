import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  
  static Future<void> init() async {
    // Настраиваем параметры речи
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5); // Немного медленнее для кулинарии
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Настроить обработчик завершения речи
    _flutterTts.setCompletionHandler(() {});
    
    // Также настраиваем обработчик ошибок
    _flutterTts.setErrorHandler((error) {
      _debugPrint('TTS Error: $error');
    });
  }

  static Future<void> speak(String text, {Function? onComplete}) async {
    if (onComplete != null) {
      _flutterTts.setCompletionHandler(() {
        onComplete();
      });
    }
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  static Future<void> pause() async {
    await _flutterTts.pause();
  }

  static Future<void> resume() async {
    await _flutterTts.speak("");
  }
  
  // Приватный метод для логирования
  static void _debugPrint(String message) {
    // В production коде используйте logger package
    // ignore: avoid_print
    print(message);
  }
}