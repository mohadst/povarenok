import 'dart:async'; // Добавьте этот импорт для Timer
import 'package:flutter/material.dart';
import '../data/recipes.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';

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
  bool _autoContinue = false;
  Timer? _speechCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await TtsService.init();
    await SpeechService.initialize();
  }

  void _onSpeechComplete() {
    if (_autoContinue && mounted) {
      setState(() {
        _isSpeaking = false;
      });
      _startListeningForContinue();
    } else {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _speakCurrentStep() async {
    if (_currentStepIndex >= widget.recipe.steps.length) return;
    
    final currentStep = widget.recipe.steps[_currentStepIndex];
    
    setState(() {
      _isSpeaking = true;
      _isListening = false;
    });
    
    await TtsService.stop();
    await SpeechService.stopListening();
    
    // Ждем немного перед началом речи
    await Future.delayed(const Duration(milliseconds: 300));
    
    await TtsService.speak(currentStep.instruction, onComplete: _onSpeechComplete);
  }

  void _startListeningForContinue() {
    setState(() {
      _isListening = true;
      _recognizedText = 'Слушаю команду...';
    });

    SpeechService.startListening((text) {
      _processVoiceCommand(text);
    });
  }

  void _processVoiceCommand(String text) {
    if (!mounted) return;
    
    setState(() {
      _recognizedText = text;
      _isListening = false;
    });

    // Очищаем текст через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _recognizedText = '';
        });
      }
    });

    // Проверяем команды (более гибкое распознавание)
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('продолжи') || 
        lowerText.contains('дальше') || 
        lowerText.contains('следующий') ||
        lowerText.contains('next') ||
        lowerText.contains('вперёд') ||
        lowerText.contains('вперед')) {
      _nextStep();
    } else if (lowerText.contains('повтори') || 
              lowerText.contains('еще раз') ||
              lowerText.contains('ещё раз') ||
              lowerText.contains('repeat') ||
              lowerText.contains('заново')) {
      _repeatStep();
    } else if (lowerText.contains('предыдущий') || 
              lowerText.contains('назад') ||
              lowerText.contains('back') ||
              lowerText.contains('вернись')) {
      _previousStep();
    } else if (lowerText.contains('стоп') || 
              lowerText.contains('останови') ||
              lowerText.contains('stop') ||
              lowerText.contains('хватит')) {
      _stopAll();
    } else if (lowerText.contains('старт') ||
              lowerText.contains('начать') ||
              lowerText.contains('start')) {
      _speakCurrentStep();
    } else if (lowerText.contains('первый шаг') ||
              lowerText.contains('сначала')) {
      _goToFirstStep();
    } else if (lowerText.contains('сколько шагов') ||
              lowerText.contains('сколько осталось')) {
      _speakStepsInfo();
    } else if (lowerText.contains('что сейчас') ||
              lowerText.contains('текущий шаг')) {
      _speakCurrentStep();
    } else {
      // Если команда не распознана, ждем новую команду
      if (_autoContinue) {
        _startListeningForContinue();
      }
    }
  }

  void _repeatStep() {
    setState(() {
      _isSpeaking = false;
      _isListening = false;
    });
    
    TtsService.stop();
    SpeechService.stopListening();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCurrentStep();
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
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCurrentStep();
      });
    } else {
      _completeRecipe();
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
    } else {
      TtsService.speak('Это первый шаг', onComplete: () {
        if (_autoContinue) {
          _startListeningForContinue();
        }
      });
    }
  }

  void _goToFirstStep() {
    setState(() {
      _currentStepIndex = 0;
      _isSpeaking = false;
      _isListening = false;
    });
    
    TtsService.stop();
    SpeechService.stopListening();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCurrentStep();
    });
  }

  void _speakStepsInfo() {
    final remaining = widget.recipe.steps.length - (_currentStepIndex + 1);
    final message = remaining == 0 
        ? 'Это последний шаг'
        : 'Осталось $remaining ${_getStepsWord(remaining)}';
    
    TtsService.speak(message, onComplete: () {
      if (_autoContinue) {
        _startListeningForContinue();
      }
    });
  }

  String _getStepsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'шаг';
    if (count % 10 >= 2 && count % 10 <= 4 && 
        (count % 100 < 10 || count % 100 >= 20)) return 'шага';
    return 'шагов';
  }

  void _completeRecipe() {
    setState(() {
      _isSpeaking = false;
      _isListening = false;
      _autoContinue = false;
    });
    
    TtsService.stop();
    SpeechService.stopListening();
    
    TtsService.speak('Рецепт завершён! Приятного аппетита!');
    
    // Показываем сообщение о завершении
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Рецепт завершён!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _stopAll() {
    setState(() {
      _isSpeaking = false;
      _isListening = false;
      _autoContinue = false;
    });
    
    TtsService.stop();
    SpeechService.stopListening();
  }

  void _toggleAutoContinue() {
    setState(() {
      _autoContinue = !_autoContinue;
    });
    
    if (_autoContinue) {
      // Если включаем авто-продолжение и сейчас не говорим, начинаем
      if (!_isSpeaking) {
        _speakCurrentStep();
      }
    } else {
      // Если выключаем, останавливаем прослушивание
      SpeechService.stopListening();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStepIndex < widget.recipe.steps.length
        ? widget.recipe.steps[_currentStepIndex]
        : RecipeStep(number: 0, instruction: 'Рецепт завершён');

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
            tooltip: _autoContinue 
              ? 'Авто-продолжение включено. Скажите "продолжить" для следующего шага'
              : 'Включить авто-продолжение',
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение рецепта
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.network(
                  widget.recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Информация о рецепте
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.list, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.recipe.ingredients.length} ингредиентов',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.recipe.steps.length} шагов',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Прогресс-бар
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: (_currentStepIndex + 1) / widget.recipe.steps.length,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Шаг ${_currentStepIndex + 1} из ${widget.recipe.steps.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${((_currentStepIndex + 1) / widget.recipe.steps.length * 100).round()}%',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Текущий шаг
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.orange.shade50,
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
                                'Текущий шаг',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.volume_up, size: 16, color: Colors.green.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Говорит',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.mic, size: 16, color: Colors.blue.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Слушает',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                      if (_recognizedText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.mic, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Распознано: "$_recognizedText"',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade800,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Голосовые команды
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
                      Text(
                        'Скажите одну из команд после звукового сигнала:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildVoiceCommandChip('Продолжить / Дальше'),
                          _buildVoiceCommandChip('Повторить'),
                          _buildVoiceCommandChip('Предыдущий шаг'),
                          _buildVoiceCommandChip('Стоп'),
                          _buildVoiceCommandChip('Начать сначала'),
                          _buildVoiceCommandChip('Сколько осталось'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _autoContinue ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _autoContinue ? Colors.green.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _autoContinue ? Icons.check_circle : Icons.info,
                              color: _autoContinue ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _autoContinue 
                                  ? '✓ Авто-продолжение включено. После каждого шага скажите "Продолжить"'
                                  : 'Нажмите на иконку микрофона вверху для включения авто-продолжения',
                                style: TextStyle(
                                  color: _autoContinue ? Colors.green.shade800 : Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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
                      onPressed: _currentStepIndex > 0 ? _previousStep : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Назад'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentStepIndex < widget.recipe.steps.length - 1 ? _nextStep : null,
                      icon: const Text('Вперед'),
                      label: const Icon(Icons.arrow_forward),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                    onPressed: _isSpeaking ? _stopAll : _speakCurrentStep,
                    icon: Icon(_isSpeaking ? Icons.stop : Icons.record_voice_over),
                    label: Text(_isSpeaking ? 'Остановить' : 'Озвучить этот шаг'),
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
                      label: Text(_isListening ? 'Остановить' : 'Сказать команду'),
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

            const SizedBox(height: 32),
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
    _speechCheckTimer?.cancel();
    TtsService.stop();
    SpeechService.stopListening();
    super.dispose();
  }
}