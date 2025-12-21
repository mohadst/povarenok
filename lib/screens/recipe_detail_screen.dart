import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';
import '../data/recipes_data.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../widgets/retro_card.dart';

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
  bool _autoContinue = false;
  String _recognizedText = '';


  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await TtsService.init();
    await SpeechService.initialize();
  }

  void _speakCurrentStep() {
    final currentStep = widget.recipe.steps[_currentStepIndex];
    TtsService.speak(currentStep.instruction).then((_) {
      if (_autoContinue) _startListeningForContinue();
    });
    setState(() => _isSpeaking = true);
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

  void _startListeningForContinue() {
    setState(() {
      _isListening = true;
      _recognizedText = 'Слушаю...';
    });

    SpeechService.startListening((text) {
      setState(() {
        _recognizedText = text;
        _isListening = false;
      });

      if (text.contains('продолжить') ||
          text.contains('дальше') ||
          text.contains('next')) {
        _nextStep();
      } else if (text.contains('повторить') || text.contains('repeat')) {
        _speakCurrentStep();
      } else if (text.contains('назад') || text.contains('back')) {
        _previousStep();
      } else if (text.contains('стоп') || text.contains('stop')) {
        _stopSpeaking();
      } else {
        _speakCurrentStep();
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _isSpeaking = false;
        _isListening = false;
      });
      Future.delayed(
          const Duration(milliseconds: 500), () => _speakCurrentStep());
    } else {
      TtsService.speak('Рецепт завершен! Приятного аппетита!');
      setState(() {
        _isSpeaking = false;
        _isListening = false;
        _autoContinue = false;
      });
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _isSpeaking = false;
        _isListening = false;
      });
      Future.delayed(
          const Duration(milliseconds: 500), () => _speakCurrentStep());
    }
  }

  void _toggleAutoContinue() {
    setState(() => _autoContinue = !_autoContinue);
    if (_autoContinue && !_isSpeaking) _speakCurrentStep();
  }

  @override
  void dispose() {
    TtsService.stop();
    SpeechService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.recipe.steps[_currentStepIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: RetroColors.paper,
      appBar: AppBar(
        title: Text(widget.recipe.title,
            style: const TextStyle(fontFamily: 'Georgia')),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_autoContinue ? Icons.mic : Icons.mic_off,
                color: _autoContinue ? Colors.greenAccent : Colors.white),
            onPressed: _toggleAutoContinue,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? RetroColors.burntOrange : Colors.white,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopSpeaking,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Image.network(
                      widget.recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: RetroColors.mustard.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.restaurant_menu,
                              size: 50, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RetroColors.mustard.withOpacity(0.3),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RetroColors.avocado.withOpacity(0.3),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(6, (i) {
                    final top = (i * 40.0) % 200 + 10;
                    final left = (i * 50.0) % 300 + 10;
                    return Positioned(
                      top: top,
                      left: left,
                      child: Icon(Icons.star,
                          size: 12, color: Colors.white.withOpacity(0.5)),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: RetroColors.burntOrange, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                      child: CustomPaint(painter: _StepBackgroundPainter())),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: RetroColors.mustard,
                            child: Text('${_currentStepIndex + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Шаг',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isSpeaking)
                            _statusBadge('Говорит...', RetroColors.mustard),
                          if (_isListening)
                            _statusBadge('Слушает...', Colors.blue.shade400),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(currentStep.instruction,
                          style: const TextStyle(fontSize: 16, height: 1.5)),
                      if (_recognizedText.isNotEmpty && _isListening)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Распознано: "$_recognizedText"',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RetroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.mic, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Голосовые команды',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _voiceChip('Продолжить / Дальше'),
                      _voiceChip('Повторить'),
                      _voiceChip('Предыдущий'),
                      _voiceChip('Стоп'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _autoContinue
                        ? '✓ Авто-продолжение включено'
                        : 'Нажмите микрофон сверху для включения авто-продолжения',
                    style: TextStyle(
                        fontSize: 14,
                        color: _autoContinue ? Colors.green : Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Назад'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side:
                          BorderSide(color: RetroColors.cocoa.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Вперед'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side:
                          BorderSide(color: RetroColors.cocoa.withOpacity(0.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSpeaking ? _stopSpeaking : _speakCurrentStep,
              icon: Icon(_isSpeaking ? Icons.stop : Icons.record_voice_over),
              label: Text(_isSpeaking ? 'Остановить озвучку' : 'Озвучить шаг'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSpeaking ? Colors.redAccent : RetroColors.mustard,
                foregroundColor: RetroColors.cocoa,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  static Widget _voiceChip(String command) {
    return Chip(
      label: Text(command),
      backgroundColor: RetroColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: RetroColors.cocoa.withOpacity(0.3)),
      ),
    );
  }
}

class _StepBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = RetroColors.cocoa.withOpacity(0.03);

    // точкииравмпава потомдле
    for (int i = 0; i < 300; i++) {
      final dx = (size.width * (i % 20) / 20) + (i % 5);
      final dy = (size.height * (i ~/ 20) / 10) + (i % 5);
      canvas.drawCircle(Offset(dx, dy), 1, paint);
    }

    final linePaint = Paint()
      ..color = RetroColors.avocado.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}