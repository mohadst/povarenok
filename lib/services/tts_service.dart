import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('Инициализация TTS...');

      await _tts.setLanguage("ru-RU");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        print("TTS начал говорить");
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        print("TTS завершил");
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        print("TTS ошибка: $msg");
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('TTS инициализирован');
    } catch (e) {
      print('Ошибка инициализации TTS: $e');
    }
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      print('Озвучивание текста: $text');
      await _tts.speak(text);
      _isSpeaking = true;
    } catch (e) {
      print('Ошибка озвучивания: $e');
      _isSpeaking = false;
    }
  }

  static Future<void> stop() async {
    try {
      if (_isSpeaking) {
        await _tts.stop();
        _isSpeaking = false;
        print('TTS остановлен');
      }
    } catch (e) {
      print('Ошибка остановки TTS: $e');
    }
  }

  static bool get isSpeaking => _isSpeaking;
  static bool get isInitialized => _isInitialized;

  static void dispose() {
    _tts.stop();
    _isSpeaking = false;
  }
}