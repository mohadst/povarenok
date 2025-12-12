import 'package:flutter/material.dart';
import '../data/recipes.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart'; // Добавьте этот импорт

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _currentStepIndex = 0;
  bool _isSpeaking = false;
  bool _isFavorite = false;
  bool _isListening = false;
  String _recognizedText = '';
  
  // Добавьте переменную для автоматического продолжения
  bool _autoContinue = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await TtsService.init();
    await SpeechService.initialize();
    
    // Настроить callback для TTS
    // Этот метод будет вызван, когда TTS закончит говорить
    // В FlutterTts нет прямого callback, поэтому используем другой подход
  }

  void _speakCurrentStep() {
    final currentStep = widget.recipe.steps[_currentStepIndex];
    TtsService.speak(currentStep.instruction).then((_) {
      // Когда речь закончится, начинаем слушать команду "продолжить"
      if (_autoContinue) {
        _startListeningForContinue();
      }
    });
    
    setState(() {
      _isSpeaking = true;
    });
  }

  void _startListeningForContinue() {
    setState(() {
      _isListening = true;
      _recognizedText = 'Слушаю команду...';
    });

    SpeechService.startListening((text) {
      setState(() {
        _recognizedText = text;
        _isListening = false;
      });

      // Проверяем команды
      if (text.contains('продолжить') || 
          text.contains('дальше') || 
          text.contains('следующий') ||
          text.contains('next')) {
        _nextStep();
      } else if (text.contains('повторить') || 
                text.contains('еще раз') ||
                text.contains('repeat')) {
        _speakCurrentStep();
      } else if (text.contains('предыдущий') || 
                text.contains('назад') ||
                text.contains('back')) {
        _previousStep();
      } else if (text.contains('стоп') || 
                text.contains('остановить') ||
                text.contains('stop')) {
        _stopSpeaking();
      } else {
        // Если команда не распознана, повторяем шаг
        _speakCurrentStep();
      }
    });
  }

  void _stopSpeaking() {
    TtsService.stop();
    SpeechService.stopListening();
    
    setState(() {
      _isSpeaking = false;
      _isListening = false;
      _autoContinue = false;
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _isSpeaking = false;
        _isListening = false;
      });
      
      TtsService.stop();
      SpeechService.stopListening();
      
      // Автоматически начинаем говорить следующий шаг
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCurrentStep();
      });
    } else {
      // Если это последний шаг
      setState(() {
        _isSpeaking = false;
        _isListening = false;
        _autoContinue = false;
      });
      
      TtsService.speak('Рецепт завершен! Приятного аппетита!');
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _isSpeaking = false;
        _isListening = false;
      });
      
      TtsService.stop();
      SpeechService.stopListening();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCurrentStep();
      });
    }
  }

  // Метод для включения/выключения авто-продолжения
  void _toggleAutoContinue() {
    setState(() {
      _autoContinue = !_autoContinue;
    });
    
    if (_autoContinue && !_isSpeaking) {
      _speakCurrentStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.recipe.steps[_currentStepIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Переключатель авто-продолжения
          IconButton(
            icon: Icon(
              _autoContinue ? Icons.mic : Icons.mic_off,
              color: _autoContinue ? Colors.green : Colors.white,
            ),
            onPressed: _toggleAutoContinue,
            tooltip: _autoContinue ? 'Авто-продолжение включено' : 'Авто-продолжение выключено',
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          if (_isSpeaking)
            IconButton(
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.stop),
              tooltip: 'Остановить',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... существующий код изображения и информации ...

            // Текущий шаг (добавьте индикатор прослушивания)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.orange,
                                child: Text(
                                  '${_currentStepIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Шаг',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (_isSpeaking)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.volume_up, size: 16, color: Colors.green.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Говорит...',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isListening)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.mic, size: 16, color: Colors.blue.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Слушает...',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentStep.instruction,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      // Показать распознанный текст
                      if (_recognizedText.isNotEmpty && _isListening)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Распознано: "$_recognizedText"',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Голосовые команды (добавьте новую секцию)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mic, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Голосовые команды',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildVoiceCommandChip('Продолжить / Дальше'),
                          _buildVoiceCommandChip('Повторить'),
                          _buildVoiceCommandChip('Предыдущий'),
                          _buildVoiceCommandChip('Стоп'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _autoContinue 
                          ? '✓ Режим авто-продолжения включен. После каждого шага скажите "Продолжить"'
                          : 'Нажмите на иконку микрофона вверху для включения авто-продолжения',
                        style: TextStyle(
                          color: _autoContinue ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Управление шагами
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Назад'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _nextStep,
                      icon: const Text('Вперед'),
                      label: const Icon(Icons.arrow_forward),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Кнопки озвучивания
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Основная кнопка озвучки
                  ElevatedButton.icon(
                    onPressed: _isSpeaking ? _stopSpeaking : _speakCurrentStep,
                    icon: Icon(_isSpeaking ? Icons.stop : Icons.record_voice_over),
                    label: Text(_isSpeaking ? 'Остановить озвучку' : 'Озвучить этот шаг'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpeaking ? Colors.red : Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Кнопка для тестирования голосового управления
                  if (!_autoContinue)
                    OutlinedButton.icon(
                      onPressed: _startListeningForContinue,
                      icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                      label: Text(_isListening ? 'Остановить прослушивание' : 'Сказать "Продолжить"'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ... существующий код прогресса ...
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommandChip(String command) {
    return Chip(
      label: Text(command),
      backgroundColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue.shade200),
      ),
    );
  }

  @override
  void dispose() {
    TtsService.stop();
    SpeechService.stopListening();
    super.dispose();
  }
}