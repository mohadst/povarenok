import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static Function()? _onComplete;

  static Future<void> init() async {
    // Настраиваем параметры речи
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Настроить обработчик завершения речи
    _flutterTts.setCompletionHandler(() {
      _onComplete?.call();
      _onComplete = null;
    });
  }

  static Future<void> speak(String text, {Function()? onComplete}) async {
    _onComplete = onComplete;
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
    _onComplete = null;
  }

  static Future<void> pause() async {
    await _flutterTts.pause();
  }

  static Future<void> resume() async {
    await _flutterTts.speak("");
  }
  
  static Future<void> setOnComplete(Function() callback) async {
    _onComplete = callback;
  }
}