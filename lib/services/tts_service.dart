import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> init() async {
    // Настраиваем параметры речи
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5); // Скорость речи (0.0 - 1.0)
    await _flutterTts.setVolume(1.0);     // Громкость (0.0 - 1.0)
    await _flutterTts.setPitch(1.0);      // Тон (0.5 - 2.0)
  }

  static Future<void> speak(String text) async {
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
}