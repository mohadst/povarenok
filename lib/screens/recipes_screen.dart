import 'package:flutter/material.dart';
import '../data/recipes_data.dart';
import '../theme/retro_colors.dart';
import 'recipe_detail_screen.dart';
import '../services/api_service.dart'; 
import 'dart:math';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  RecipesScreenState createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  final RecipeStorage _recipeStorage = RecipeStorage();
  List<Recipe> _recipes = [];
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  Future<void> refreshRecipes() async {
  await loadRecipes();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    loadRecipes();
     });
  }

  Future<void> loadRecipes() async {
  try {
    print('🔄 Загрузка рецептов...');
    
    // Загружаем демо-рецепты локально
    _recipeStorage.initializeWithDemoRecipes();
    final localRecipes = _recipeStorage.getAllRecipes();
    
    // Пытаемся загрузить рецепты с сервера
    print('🌐 Загрузка рецептов с сервера...');
    final serverRecipes = await ApiService.getRecipes();
    
    // Конвертируем серверные рецепты в нашу модель
    final convertedServerRecipes = serverRecipes.map((serverRecipe) {
      // Конвертируем ингредиенты
      final ingredients = (serverRecipe['ingredients'] as List? ?? [])
          .map((ing) {
            if (ing is Map) {
              return RecipeIngredient(
                name: ing['name']?.toString() ?? '',
                amount: ing['amount']?.toDouble(),
                unit: ing['unit']?.toString(),
              );
            } else if (ing is String) {
              return RecipeIngredient(name: ing);
            } else {
              return RecipeIngredient(name: ing?.toString() ?? '');
            }
          })
          .toList();
      
      final steps = (serverRecipe['steps'] as List? ?? [])
          .map((step) {
            if (step is Map) {
              return RecipeStep(
                number: step['number'] ?? 1,
                instruction: step['instruction']?.toString() ?? step['text']?.toString() ?? '',
              );
            } else {
              return RecipeStep(
                number: 1,
                instruction: step?.toString() ?? '',
              );
            }
          })
          .toList();
      
      return Recipe(
        id: serverRecipe['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: serverRecipe['title']?.toString() ?? '',
        imageUrl: serverRecipe['image_url']?.toString() ?? serverRecipe['imageUrl']?.toString() ?? '',
        ingredients: ingredients,
        steps: steps,
        isFavorite: false,
      );
    }).toList();
    
    final allRecipes = [...localRecipes, ...convertedServerRecipes];
    
    final uniqueRecipes = <String, Recipe>{};
    for (var recipe in allRecipes) {
      uniqueRecipes[recipe.id] = recipe;
    }
    
    setState(() {
      _recipes = uniqueRecipes.values.toList();
    });
    
    print('✅ Загружено рецептов: ${_recipes.length}');
  } catch (e) {
    print('❌ Ошибка загрузки рецептов: $e');
    // Если сервер недоступен, используем только локальные
    setState(() {
      _recipes = _recipeStorage.getAllRecipes();
    });
  }
}

  void _toggleFavorite(String recipeId) {
    _recipeStorage.toggleFavorite(recipeId);
    setState(() {
      _recipes = _recipeStorage.getAllRecipes();
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final filteredRecipes = _searchQuery.isEmpty
        ? _recipes
        : _recipeStorage.searchRecipes(_searchQuery);

    return Scaffold(
      backgroundColor: RetroColors.paper,
      appBar: AppBar(
        title: const Text(
          'Рецепты',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Поиск рецептов...',
                prefixIcon: const Icon(Icons.search, color: RetroColors.cocoa),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),
          filteredRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: RetroColors.mustard.withOpacity(0.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Нет рецептов'
                            : 'Рецепты не найдены',
                        style: const TextStyle(
                          fontSize: 20,
                          color: RetroColors.cocoa,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Создайте первый рецепт!'
                            : 'Попробуйте другой запрос',
                        style: TextStyle(
                          fontSize: 16,
                          color: RetroColors.cocoa.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    loadRecipes();
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 24,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final recipe = filteredRecipes[index];
                              final isLarge = index % 3 == 0;
                              
                              if (isLarge) {
                                return _LargeRecipeCard(
                                  recipe: recipe,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecipeDetailScreen(recipe: recipe),
                                      ),
                                    );
                                  },
                                  onToggleFavorite: () {
                                    _toggleFavorite(recipe.id);
                                  },
                                );
                              } else {
                                return _SmallRecipeCard(
                                  recipe: recipe,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecipeDetailScreen(recipe: recipe),
                                      ),
                                    );
                                  },
                                  onToggleFavorite: () {
                                    _toggleFavorite(recipe.id);
                                  },
                                );
                              }
                            },
                            childCount: filteredRecipes.length,
                          ),
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 100),
                      ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: filteredRecipes.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: RetroColors.cherryRed,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
              mini: true,
            )
          : null,
    );
  }
}

class _SmallRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _SmallRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: RetroColors.paper.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: RetroColors.cocoa.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CustomPaint(
                  painter: _DoubleBorderPainter(),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Icon(Icons.star,
                  size: 10,
                  color: RetroColors.burntOrange.withOpacity(0.6)),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(Icons.star,
                  size: 10,
                  color: RetroColors.avocado.withOpacity(0.6)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  child: Image.network(
                    recipe.imageUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 120,
                      color: RetroColors.mustard.withOpacity(0.3),
                      child: const Icon(Icons.restaurant_menu),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: RetroColors.cocoa,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoBadge(
                                icon: Icons.kitchen,
                                text: '${recipe.ingredients.length} ингр.',
                                color: RetroColors.mustard.withOpacity(0.2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _InfoBadge(
                                icon: Icons.timer,
                                text: '${recipe.steps.length * 5} мин',
                                color: RetroColors.avocado.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    recipe.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: recipe.isFavorite
                        ? RetroColors.burntOrange
                        : RetroColors.cocoa,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _LargeRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: RetroColors.paper.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: RetroColors.cocoa.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CustomPaint(
                  painter: _DoubleBorderPainter(),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Icon(Icons.star,
                  size: 10,
                  color: RetroColors.burntOrange.withOpacity(0.6)),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(Icons.star,
                  size: 10,
                  color: RetroColors.avocado.withOpacity(0.6)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  child: Image.network(
                    recipe.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 180,
                      color: RetroColors.mustard.withOpacity(0.3),
                      child: const Icon(Icons.restaurant_menu),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RetroColors.cocoa,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoBadge(
                                icon: Icons.kitchen,
                                text: '${recipe.ingredients.length} ингредиентов',
                                color: RetroColors.mustard.withOpacity(0.2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _InfoBadge(
                                icon: Icons.timer,
                                text: '${recipe.steps.length * 5} мин',
                                color: RetroColors.avocado.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.7,
                            minHeight: 6,
                            backgroundColor:
                                RetroColors.mustard.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                RetroColors.mustard),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    recipe.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: recipe.isFavorite
                        ? RetroColors.burntOrange
                        : RetroColors.cocoa,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: RetroColors.cocoa),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: RetroColors.cocoa.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outerPaint = Paint()
      ..color = RetroColors.mustard.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(outerRect, outerPaint);

    final innerRect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final dashPaint = Paint()
      ..color = RetroColors.avocado.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = sqrt(dx * dx + dy * dy);
      final dashCount = (length / (dashWidth + dashSpace)).floor();
      final xStep = dx / dashCount;
      final yStep = dy / dashCount;

      for (int i = 0; i < dashCount; i += 2) {
        final x1 = start.dx + i * xStep;
        final y1 = start.dy + i * yStep;
        final x2 = start.dx + (i + 1).clamp(0, dashCount) * xStep;
        final y2 = start.dy + (i + 1).clamp(0, dashCount) * yStep;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
      }
    }

    drawDashedLine(innerRect.topLeft, innerRect.topRight);
    drawDashedLine(innerRect.topRight, innerRect.bottomRight);
    drawDashedLine(innerRect.bottomRight, innerRect.bottomLeft);
    drawDashedLine(innerRect.bottomLeft, innerRect.topLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = RetroColors.mustard.withOpacity(0.1);
    canvas.drawCircle(Offset(60, 80), 60, paint);

    paint.color = RetroColors.avocado.withOpacity(0.08);
    canvas.drawOval(
        Rect.fromLTWH(size.width - 120, size.height - 150, 120, 80), paint);

    paint.color = RetroColors.burntOrange.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width / 2, 200), 50, paint);

    paint.color = RetroColors.burntOrange.withOpacity(0.15);
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    paint.color = RetroColors.cocoa.withOpacity(0.02);
    for (int i = 0; i < 200; i++) {
      final dx = (size.width * (i % 20) / 20) + (i % 5);
      final dy = (size.height * (i ~/ 20) / 10) + (i % 5);
      canvas.drawCircle(Offset(dx, dy), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}