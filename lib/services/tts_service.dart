// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  int _currentStepIndex = 0;
  List<String> _steps = [];
  
  TTSService() {
    _initTTS();
  }
  
  Future<void> _initTTS() async {
    await _tts.setLanguage('ru-RU');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }
  
  Future<void> speakSteps(List<String> steps) async {
    if (_isSpeaking) return;
    
    _steps = steps;
    _currentStepIndex = 0;
    _isSpeaking = true;
    
    await _speakCurrentStep();
  }
  
  Future<void> _speakCurrentStep() async {
    if (_currentStepIndex >= _steps.length) {
      _isSpeaking = false;
      return;
    }
    
    final stepText = 'Шаг ${_currentStepIndex + 1}. ${_steps[_currentStepIndex]}';
    await _tts.speak(stepText);
    
    _tts.setCompletionHandler(() {
      // Ждем пока пользователь нажмет "Далее"
    });
  }
  
  Future<void> nextStep() async {
    if (!_isSpeaking) return;
    
    await _tts.stop();
    _currentStepIndex++;
    await _speakCurrentStep();
  }
  
  Future<void> previousStep() async {
    if (!_isSpeaking || _currentStepIndex <= 0) return;
    
    await _tts.stop();
    _currentStepIndex--;
    await _speakCurrentStep();
  }
  
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }
  
  bool get isSpeaking => _isSpeaking;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _steps.length;
}