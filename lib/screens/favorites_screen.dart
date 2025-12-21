import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favorites = [];
  bool _isLoading = true;
  String? _error;
  final FlutterTts _tts = FlutterTts();

  @override     
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ru-RU");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

// В методе _loadFavorites() добавьте перед вызовом getFavorites():
// В методе _loadFavorites() замените блок try-catch:
Future<void> _loadFavorites() async {
  try {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Временно возвращаем пустой список при ошибке 500
    try {
      final favorites = await ApiService.getFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('⚠️ Ошибка загрузки избранного (показываем пустой список): $e');
      setState(() {
        _favorites = []; // Пустой список вместо ошибки
        _isLoading = false;
      });
    }

    print('✅ Загружено избранных рецептов: ${_favorites.length}');
  } catch (e) {
    setState(() {
      _error = 'Ошибка загрузки: ${e.toString()}';
      _isLoading = false;
    });
    print('❌ Ошибка загрузки избранного: $e');
  }
}
  Future<void> _removeFromFavorites(int recipeId) async {
    try {
      final success = await ApiService.removeFromFavorites(recipeId);
      
      if (success) {
        setState(() {
          _favorites.removeWhere((recipe) => recipe['id'] == recipeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Удалено из избранного'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _speakRecipe(String title, List<String> ingredients, List<dynamic> steps) async {
    final ingredientsText = ingredients.join(', ');
    final stepsText = steps.map((step) => 'Шаг ${step['number']}: ${step['instruction']}').join('. ');
    final text = 'Рецепт: $title. Ингредиенты: $ingredientsText. Шаги приготовления: $stepsText';
    
    await _tts.speak(text);
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    final ingredients = List<String>.from(recipe['ingredients'] ?? []);
    final steps = List<Map<String, dynamic>>.from(recipe['steps'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  flexibleSpace: recipe['image_url'] != null && recipe['image_url'].toString().isNotEmpty
                      ? FlexibleSpaceBar(
                          background: Image.network(
                            recipe['image_url'].toString(),
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _speakRecipe(recipe['title'], ingredients, steps),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Заголовок
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          recipe['title'] ?? 'Без названия',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Ингредиенты
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ингредиенты',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...ingredients.map((ingredient) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(ingredient)),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Шаги приготовления
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Шаги приготовления',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...steps.map((step) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        step['number'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Шаг ${step['number']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(step['instruction'].toString()),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> recipe) {
    final ingredients = List<String>.from(recipe['ingredients'] ?? []);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey.shade200,
                ),
                child: recipe['image_url'] != null && recipe['image_url'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          recipe['image_url'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.restaurant_menu, color: Colors.grey.shade400);
                          },
                        ),
                      )
                    : Icon(Icons.restaurant_menu, size: 40, color: Colors.grey.shade400),
              ),
              
              const SizedBox(width: 12),
              
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? 'Без названия',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Информация
                    Row(
                      children: [
                        Icon(Icons.list, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${ingredients.length} ингр.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${(recipe['steps']?.length ?? 0) * 5} мин',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    // Дата создания
                    if (recipe['created_at'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Создан: ${DateTime.parse(recipe['created_at']).toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Кнопка удаления из избранного
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _removeFromFavorites(recipe['id']),
                tooltip: 'Удалить из избранного',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadFavorites,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Нет избранных рецептов',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Добавьте рецепты в избранное,\nнажав на сердечко в списке рецептов',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Переход к рецептам (первая вкладка)
                              DefaultTabController.of(context).animateTo(0);
                            },
                            child: const Text('Перейти к рецептам'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          return _buildFavoriteCard(_favorites[index]);
                        },
                      ),
                    ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}