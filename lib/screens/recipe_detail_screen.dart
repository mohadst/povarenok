import 'package:flutter/material.dart';
import 'package:cooking_assistant/services/api_service.dart'; // Изменено с povarenok на cooking_assistant

import '../services/tts_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _currentStepIndex = 0;
  bool _isSpeaking = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final recipeId = widget.recipe['id'];
      if (recipeId != null) {
        setState(() => _isLoadingFavorite = true);
        final isFav = await ApiService.isFavorite(recipeId);
        setState(() {
          _isFavorite = isFav;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Ошибка проверки избранного: $e');
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    
    final recipeId = widget.recipe['id'];
    if (recipeId == null) return;
    
    setState(() => _isLoadingFavorite = true);
    final bool success;
    
    if (_isFavorite) {
      success = await ApiService.removeFromFavorites(recipeId);
    } else {
      success = await ApiService.addToFavorites(recipeId);
    }
    
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoadingFavorite = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite 
              ? 'Добавлено в избранное' 
              : 'Удалено из избранного'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _isLoadingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении избранного'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startSpeaking() async {
    final steps = List<String>.from(widget.recipe['steps'] ?? []);
    if (steps.isEmpty) return;
    
    await _ttsService.speakSteps(steps);
    setState(() => _isSpeaking = true);
  }

  Future<void> _stopSpeaking() async {
    await _ttsService.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _nextStep() async {
    if (_isSpeaking && _currentStepIndex < (widget.recipe['steps']?.length ?? 0) - 1) {
      await _ttsService.nextStep();
      setState(() => _currentStepIndex = _ttsService.currentStepIndex);
    } else if (!_isSpeaking) {
      setState(() {
        _currentStepIndex++;
        if (_currentStepIndex >= (widget.recipe['steps']?.length ?? 0)) {
          _currentStepIndex = (widget.recipe['steps']?.length ?? 1) - 1;
        }
      });
    }
  }

  Future<void> _previousStep() async {
    if (_isSpeaking && _currentStepIndex > 0) {
      await _ttsService.previousStep();
      setState(() => _currentStepIndex = _ttsService.currentStepIndex);
    } else if (!_isSpeaking && _currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  Widget _buildStepIndicator() {
    final totalSteps = (widget.recipe['steps'] as List?)?.length ?? 0;
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStepIndex + 1) / totalSteps,
          backgroundColor: Colors.grey.shade200,
          color: Colors.orange,
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          'Шаг ${_currentStepIndex + 1} из $totalSteps',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Индикатор текущего шага для аудио
          if (_isSpeaking)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, size: 16, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Озвучивается шаг ${_currentStepIndex + 1}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Кнопки управления аудио
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Кнопка "Назад"
              IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: _previousStep,
                color: Theme.of(context).primaryColor,
                iconSize: 32,
              ),
              
              // Кнопка "Старт/Стоп"
              ElevatedButton(
                onPressed: _isSpeaking ? _stopSpeaking : _startSpeaking,
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(16),
                  backgroundColor: _isSpeaking ? Colors.red : Colors.green,
                ),
                child: Icon(
                  _isSpeaking ? Icons.stop : Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              
              // Кнопка "Вперед"
              IconButton(
                icon: Icon(Icons.skip_next),
                onPressed: _nextStep,
                color: Theme.of(context).primaryColor,
                iconSize: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Подписи к кнопкам
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Назад', style: TextStyle(color: Colors.grey.shade600)),
              Text(_isSpeaking ? 'Стоп' : 'Старт', style: TextStyle(color: Colors.grey.shade600)),
              Text('Вперед', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final title = recipe['title'] ?? 'Без названия';
    final ingredients = List<String>.from(recipe['ingredients'] ?? []);
    final steps = List<dynamic>.from(recipe['steps'] ?? []);
    final allergens = List<String>.from(recipe['allergens'] ?? []);
    final imageUrl = recipe['image_url']?.toString();
    final currentStep = _currentStepIndex < steps.length 
        ? (steps[_currentStepIndex] is Map ? steps[_currentStepIndex]['instruction']?.toString() ?? '' : steps[_currentStepIndex].toString())
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка избранного
          _isLoadingFavorite
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
                ),
        ],
      ),
      body: Column(
        children: [
          // Изображение рецепта
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: imageUrl == null || imageUrl.isEmpty ? Colors.grey.shade200 : null,
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Быстрая информация
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.timer, '${steps.length * 5} мин'),
                _buildInfoItem(Icons.restaurant, '${ingredients.length} ингр.'),
                _buildInfoItem(Icons.list, '${steps.length} шагов'),
              ],
            ),
          ),

          // Управление аудио
          _buildAudioControls(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ингредиенты
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.list, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  'Ингредиенты',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...ingredients.map(
                              (ingredient) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(ingredient)),
                                  ],
                                ),
                              ),
                            ).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Текущий шаг
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
                                      'Текущий шаг',
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
                                          'Озвучивается',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
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
                              currentStep,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Кнопки управления шагами (для ручной навигации)
                  if (!_isSpeaking)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _previousStep,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Предыдущий шаг'),
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
                              icon: const Text('Следующий шаг'),
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

                  // Прогресс
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildStepIndicator(),
                  ),

                  // Аллергены (если есть)
                  if (allergens.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Содержит аллергены',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allergens.map((allergen) => Chip(
                                  label: Text(allergen),
                                  backgroundColor: Colors.red.shade100,
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}