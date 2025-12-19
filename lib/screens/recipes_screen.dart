import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  List<dynamic> _filteredRecipes = []; // Добавлен список для фильтрованных рецептов
  bool _isLoading = true;
  String? _error;
  bool _showOnlySafe = false;
  List<String> _userAllergies = [];
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController = TextEditingController(); // Контроллер поиска
  FocusNode _searchFocusNode = FocusNode(); // Фокус для поиска

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadData();
    _searchController.addListener(_onSearchChanged); // Слушатель изменений поиска
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ru-RU");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // Метод фильтрации рецептов по поисковому запросу
  void _filterRecipes() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      // Если поиск пустой, показываем все рецепты (уже отфильтрованные по безопасности)
      List<dynamic> filteredRecipes = _recipes;
      if (_showOnlySafe && _userAllergies.isNotEmpty) {
        filteredRecipes = _recipes.where((recipe) {
          final recipeAllergens = List<String>.from(recipe['allergens'] ?? []);
          return !recipeAllergens.any((allergen) => _userAllergies.contains(allergen));
        }).toList();
      }
      setState(() {
        _filteredRecipes = filteredRecipes;
      });
      return;
    }

    // Фильтруем по поисковому запросу
    List<dynamic> filteredRecipes = _recipes.where((recipe) {
      // Поиск по названию
      final title = recipe['title']?.toString().toLowerCase() ?? '';
      if (title.contains(query)) return true;
      
      // Поиск по ингредиентам
      final ingredients = List<String>.from(recipe['ingredients'] ?? []);
      final ingredientsText = ingredients.join(' ').toLowerCase();
      if (ingredientsText.contains(query)) return true;
      
      // Поиск по шагам
      final steps = List<dynamic>.from(recipe['steps'] ?? []);
      for (var step in steps) {
        final instruction = step['instruction']?.toString().toLowerCase() ?? '';
        if (instruction.contains(query)) return true;
      }
      
      return false;
    }).toList();

    // Дополнительная фильтрация по безопасности
    if (_showOnlySafe && _userAllergies.isNotEmpty) {
      filteredRecipes = filteredRecipes.where((recipe) {
        final recipeAllergens = List<String>.from(recipe['allergens'] ?? []);
        return !recipeAllergens.any((allergen) => _userAllergies.contains(allergen));
      }).toList();
    }

    setState(() {
      _filteredRecipes = filteredRecipes;
    });
  }

  // Обработчик изменений в поле поиска
  void _onSearchChanged() {
    _filterRecipes();
  }

  // Очистка поиска
  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Проверяем доступность API
      final isApiAvailable = await ApiService.checkApiHealth();
      if (!isApiAvailable) {
        setState(() {
          _error = 'API недоступен. Запустите сервер: docker-compose up --build';
          _isLoading = false;
        });
        return;
      }

      // Проверяем токен
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _error = 'Пожалуйста, войдите в систему';
          _isLoading = false;
        });
        return;
      }

      // Загружаем предпочтения пользователя
      final preferences = await ApiService.getPreferences();
      _userAllergies = List<String>.from(preferences['allergies'] ?? []);

      // Загружаем рецепты
      final recipes = await ApiService.getRecipes();
      
      setState(() {
        _recipes = recipes;
        _filterRecipes(); // Применяем фильтрацию после загрузки
        _isLoading = false;
      });

      print('✅ Загружено рецептов: ${recipes.length}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Ошибка загрузки рецептов: $e');
    }
  }

  Future<void> _toggleFavorite(int recipeId, bool isCurrentlyFavorite) async {
    try {
      bool success;
      if (isCurrentlyFavorite) {
        success = await ApiService.removeFromFavorites(recipeId);
      } else {
        success = await ApiService.addToFavorites(recipeId);
      }

      if (success) {
        // Обновляем локальное состояние
        setState(() {
          final index = _recipes.indexWhere((r) => r['id'] == recipeId);
          if (index != -1) {
            _recipes[index]['is_favorite'] = !isCurrentlyFavorite;
          }
          // Также обновляем filteredRecipes
          final filteredIndex = _filteredRecipes.indexWhere((r) => r['id'] == recipeId);
          if (filteredIndex != -1) {
            _filteredRecipes[filteredIndex]['is_favorite'] = !isCurrentlyFavorite;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyFavorite 
                ? 'Удалено из избранного' 
                : 'Добавлено в избранное'
            ),
            backgroundColor: isCurrentlyFavorite ? Colors.orange : Colors.green,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRecipeDetails(recipe),
    );
  }

  Widget _buildRecipeDetails(Map<String, dynamic> recipe) {
    final ingredients = List<String>.from(recipe['ingredients'] ?? []);
    final steps = List<Map<String, dynamic>>.from(recipe['steps'] ?? []);
    final allergens = List<String>.from(recipe['allergens'] ?? []);

    return DraggableScrollableSheet(
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                            );
                          },
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

                    // Быстрая информация
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(Icons.list, '${ingredients.length} ингр.'),
                        _buildInfoItem(Icons.timer, '${steps.length * 5} мин'),
                        _buildInfoItem(Icons.stairs, '${steps.length} шагов'),
                      ],
                    ),

                    const SizedBox(height: 24),

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

                    // Аллергены (если есть)
                    if (allergens.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.red.shade50,
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
                    ],

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final ingredients = List<String>.from(recipe['ingredients'] ?? []);
    final allergens = List<String>.from(recipe['allergens'] ?? []);
    final isFavorite = recipe['is_favorite'] ?? false;
    final hasAllergens = allergens.isNotEmpty && _userAllergies.any((a) => allergens.contains(a));

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
                    
                    const SizedBox(height: 4),
                    
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
                      ],
                    ),
                    
                    // Предупреждение об аллергенах
                    if (hasAllergens)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning, size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              'Содержит ваши аллергены',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Кнопка избранного
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () => _toggleFavorite(recipe['id'], isFavorite),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSafeFilter() {
    setState(() {
      _showOnlySafe = !_showOnlySafe;
    });
    _filterRecipes(); // Применяем фильтрацию при изменении фильтра безопасности
  }

  // Виджет строки поиска
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Поиск рецептов...',
          prefixIcon: Icon(Icons.search, color: Colors.orange),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  // Виджет информации о поиске
  Widget _buildSearchInfo() {
    if (_searchController.text.isEmpty) return SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: Colors.blue.shade700),
          SizedBox(width: 8),
          Text(
            'Найдено рецептов: ${_filteredRecipes.length}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Очистить',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои рецепты'),
        actions: [
          if (_userAllergies.isNotEmpty)
            IconButton(
              icon: Icon(
                _showOnlySafe ? Icons.check_circle : Icons.check_circle_outline,
                color: _showOnlySafe ? Colors.green : null,
              ),
              onPressed: _toggleSafeFilter,
              tooltip: _showOnlySafe ? 'Показать все рецепты' : 'Только безопасные',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                        'Ошибка',
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
                        onPressed: _loadData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Строка поиска
                    _buildSearchBar(),
                    
                    // Информация о поиске
                    _buildSearchInfo(),
                    
                    // Фильтр безопасности
                    if (_showOnlySafe)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.green.shade50,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Только безопасные рецепты',
                              style: TextStyle(color: Colors.green),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _toggleSafeFilter,
                              child: const Text('Показать все'),
                            ),
                          ],
                        ),
                      ),
                    
                    // Список рецептов
                    Expanded(
                      child: _filteredRecipes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'По запросу "${_searchController.text}" ничего не найдено'
                                        : (_showOnlySafe 
                                            ? 'Нет безопасных рецептов' 
                                            : 'Нет рецептов'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'Попробуйте изменить запрос'
                                        : (_showOnlySafe
                                            ? 'Создайте рецепт без аллергенов'
                                            : 'Создайте первый рецепт!'),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/create_recipe');
                                    },
                                    child: const Text('Создать рецепт'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: _filteredRecipes.length,
                                itemBuilder: (context, index) {
                                  return _buildRecipeCard(_filteredRecipes[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_recipe');
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}