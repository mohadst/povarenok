import 'package:flutter/material.dart';
import '../data/recipes.dart';
import '../theme/retro_colors.dart';
import 'recipe_detail_screen.dart';
import 'dart:math';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Для теста пока все рецепты считаем "избранными"
    final favoriteRecipes = demoRecipes;
    // TODO: заменить на фильтр: demoRecipes.where((r) => r.isFavorite).toList();

    return Scaffold(
      backgroundColor: RetroColors.paper,
      appBar: AppBar(
        title: const Text(
          'Избранное',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Stack(
        children: [
          // Фон с Painter
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainterFavorites(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: favoriteRecipes.isEmpty
                ? const _EmptyFavorites()
                : ListView.builder(
                    itemCount: favoriteRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = favoriteRecipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FavoriteRecipeCard(
                          recipe: recipe,
                          width: screenWidth - 32,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainterFavorites extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      colors: [RetroColors.cream.withOpacity(0.5), RetroColors.paper],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // линеееее
    paint.shader = null;
    paint.color = RetroColors.burntOrange.withOpacity(0.05);
    paint.strokeWidth = 1.5;
    const spacing = 20.0;
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }

    // кургеее
    paint.color = RetroColors.mustard.withOpacity(0.1);
    canvas.drawCircle(Offset(80, 150), 60, paint);
    paint.color = RetroColors.avocado.withOpacity(0.08);
    canvas.drawOval(
        Rect.fromLTWH(size.width - 140, size.height - 200, 120, 80), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 72,
              color: RetroColors.burntOrange,
            ),
            const SizedBox(height: 12),
            const Text(
              'Здесь пока пусто',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: RetroColors.cocoa,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Добавляйте любимые рецепты,\nчтобы не потерять',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RetroColors.cocoa.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final double width;

  const _FavoriteRecipeCard({required this.recipe, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: RetroColors.paper,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: RetroColors.mustard.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: RetroColors.cocoa.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  child: Image.network(
                    recipe.imageUrl,
                    width: width,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: width,
                      height: 180,
                      color: RetroColors.mustard.withOpacity(0.3),
                      child: const Icon(Icons.restaurant_menu),
                    ),
                  ),
                ),
                Container(
                  width: width,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  right: 12,
                  child: Text(
                    recipe.title,
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2)
                        ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
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
                  const SizedBox(width: 6),
                  Icon(Icons.favorite,
                      color: RetroColors.burntOrange, size: 28),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: RetroColors.cocoa),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
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
