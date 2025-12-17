import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isListening = false;
  static Function(String)? _onResultCallback;

  // Инициализация
  static Future<bool> initialize() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        // Используем debugPrint вместо print для production
        debugPrint('Speech status: $status');
      },
      onError: (error) {
        debugPrint('Speech error: $error');
      },
    );
    return available;
  }

  // Начать слушать
  static Future<void> startListening(Function(String) onResult) async {
    if (!_isListening) {
      _onResultCallback = onResult;
      _isListening = true;
      
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _onResultCallback?.call(result.recognizedWords.toLowerCase());
            _isListening = false;
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: "ru_RU",
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    }
  }

  // Остановить прослушивание
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // Проверить, слушает ли сейчас
  static bool get isListening => _isListening;
  
  // Для корректной работы с Flutter, используем debugPrint из foundation
  static void debugPrint(String message) {
    // В продакшене можно использовать logging framework, например, logger
    // Здесь для простоты используем print только в режиме отладки
    assert(() {
      print(message);
      return true;
    }());
  }
}