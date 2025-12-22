import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isListening = false;
  static bool _isInitialized = false;
  static Function(String)? _onResultCallback;
  static String _lastRecognizedText = '';
  static String get lastError => _lastError;
  static String _lastError = '';

  static String get lastRecognizedText => _lastRecognizedText;

  static Future<List<stt.LocaleName>> getAvailableLanguages() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      final locales = await _speech.locales();
      print('[SpeechService] Получено языков: ${locales.length}');
      return locales;
    } catch (e) {
      print('[SpeechService] Ошибка получения языков: $e');
      _lastError = e.toString();
      return [];
    }
  }

  static Future<bool> initialize() async {
    try {
      print('[SpeechService] Инициализация...');

      // Инициализируем с включенной отладкой
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('[SpeechService] Статус: $status');
        },
        onError: (error) {
          print('[SpeechService] Ошибка: ${error.errorMsg}');
        },
        debugLogging: true, // Включаем логирование
      );

      if (available) {
        // Проверяем доступные языки
        final locales = await _speech.locales();
        print('[SpeechService] Доступные языки:');
        for (var locale in locales) {
          print('  ${locale.localeId} - ${locale.name}');
        }

        // Проверяем русский язык
        bool hasRussian =
            locales.any((locale) => locale.localeId.startsWith('ru'));
        print('[SpeechService] Русский язык доступен: $hasRussian');
      }

      print('[SpeechService] Доступно: $available');
      _isInitialized = available;
      return available;
    } catch (e) {
      print('[SpeechService] Ошибка инициализации: $e');
      _isInitialized = false;
      return false;
    }
  }

  static Future<void> startListening(Function(String) onResult,
      {bool cancelOnError = true,
      bool partialResults = true,
      String localeId = 'ru-RU'}) async {
    print('[SpeechService] Запрос на начало прослушивания');

    // Проверяем инициализацию
    if (!_isInitialized) {
      print('[SpeechService] Инициализируем...');
      bool initialized = await initialize();
      if (!initialized) {
        print('[SpeechService] Не удалось инициализировать');
        return;
      }
    }

    // Если уже слушаем, останавливаем
    if (_isListening) {
      print('[SpeechService] Уже слушаю, останавливаю...');
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _onResultCallback = onResult;

    print('[SpeechService] Начинаю слушать с локалью: $localeId');

    try {
      bool started = await _speech.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          print('[SpeechService] Распознано: "${result.recognizedWords}"');
          print('[SpeechService] Финальный результат: ${result.finalResult}');

          // Если это финальный результат, вызываем колбэк
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            print(
                '[SpeechService] Вызываю колбэк с текстом: "${result.recognizedWords}"');
            onResult(result.recognizedWords.toLowerCase().trim());
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 5),
        localeId: localeId,
        cancelOnError: cancelOnError,
        partialResults: partialResults,
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (level) {
          if (level > 0.01) {
            print('[SpeechService] Уровень звука: ${level.toStringAsFixed(2)}');
          }
        },
      );

      _isListening = started;

      if (started) {
        print('[SpeechService] Прослушивание успешно запущено');
      } else {
        print('[SpeechService] Не удалось запустить прослушивание');
      }
    } catch (e, stackTrace) {
      print('[SpeechService] Ошибка при запуске прослушивания: $e');
      print('[SpeechService] Stack trace: $stackTrace');
      _isListening = false;
    }
  }

  static Future<void> stopListening() async {
    if (_isListening) {
      print('[SpeechService] Останавливаю прослушивание...');
      try {
        await _speech.stop();
        print('[SpeechService] Прослушивание остановлено');
      } catch (e) {
        print('[SpeechService] Ошибка при остановке: $e');
      }
      _isListening = false;
    }
  }

  static bool get isListening => _isListening;
  static bool get isInitialized => _isInitialized;

  static void dispose() {
    _isInitialized = false;
    _isListening = false;
    _onResultCallback = null;
  }
}
