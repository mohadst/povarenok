import 'dart:async';
import 'package:flutter/material.dart';
import 'tts_service.dart';

class TimerModel {
  final int id;
  final String name;
  final int totalSeconds;
  int remainingSeconds;
  bool isRunning;
  Timer? _timer;
  DateTime? _startTime;
  int? _elapsedSecondsWhenPaused;

  final VoidCallback onUpdate;
  final Function(TimerModel) onComplete;

  TimerModel({
    required this.id,
    required this.name,
    required this.totalSeconds,
    required this.onUpdate,
    required this.onComplete,
  })  : remainingSeconds = totalSeconds,
        isRunning = false;

  void start() {
    if (remainingSeconds <= 0) {
      remainingSeconds = totalSeconds;
    }

    if (_elapsedSecondsWhenPaused != null) {
      _startTime = DateTime.now().subtract(
        Duration(seconds: _elapsedSecondsWhenPaused!),
      );
      _elapsedSecondsWhenPaused = null;
    } else {
      _startTime = DateTime.now();
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final elapsed = now.difference(_startTime!).inSeconds;
      remainingSeconds = totalSeconds - elapsed;

      if (remainingSeconds <= 0) {
        remainingSeconds = 0;
        stop();
        onComplete(this);
      }

      onUpdate();
    });

    isRunning = true;
  }

  void pause() {
    if (isRunning && _startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      _elapsedSecondsWhenPaused = elapsed;
    }

    _timer?.cancel();
    _timer = null;
    isRunning = false;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    remainingSeconds = totalSeconds;
    _elapsedSecondsWhenPaused = null;
    _startTime = null;
  }

  void dispose() {
    _timer?.cancel();
  }
}

class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;
  TimerManager._internal();

  final List<TimerModel> _timers = [];
  List<TimerModel> get timers => List.unmodifiable(_timers);

  final StreamController<List<TimerModel>> _streamController =
      StreamController<List<TimerModel>>.broadcast();
  Stream<List<TimerModel>> get timerStream => _streamController.stream;

  int _nextId = 1;

  TimerModel addTimer({
    required String name,
    required int minutes,
    required int seconds,
  }) {
    final timer = TimerModel(
      id: _nextId++,
      name: name.isNotEmpty ? name : 'Таймер ${_timers.length + 1}',
      totalSeconds: minutes * 60 + seconds,
      onUpdate: () => _notifyListeners(),
      onComplete: (t) {
        TtsService.speak('Таймер "${t.name}" завершён');
        _notifyListeners();
      },
    );

    _timers.add(timer);
    _notifyListeners();
    return timer;
  }

  void startTimer(int id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    timer.start();
    _notifyListeners();
  }

  void pauseTimer(int id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    timer.pause();
    _notifyListeners();
  }

  void removeTimer(int id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    timer.dispose();
    _timers.removeWhere((t) => t.id == id);
    _notifyListeners();
  }

  void toggleTimer(int id) {
    final timer = _timers.firstWhere((t) => t.id == id);
    if (timer.isRunning) {
      timer.pause();
    } else {
      timer.start();
    }
    _notifyListeners();
  }

  void disposeAll() {
    for (final timer in _timers) {
      timer.dispose();
    }
    _timers.clear();
    _streamController.close();
  }

  void _notifyListeners() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_timers));
    }
  }
}
