import 'package:flutter/material.dart';
import '../data/recipes.dart';
import '../theme/retro_colors.dart';
import '../widgets/retro_card.dart';
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

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
      child: RetroCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: RetroColors.mustard.withOpacity(0.3),
                  child: const Icon(Icons.restaurant_menu),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RetroColors.cocoa,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.ingredients.length} ингредиентов • '
                    '${recipe.steps.length * 5} мин',
                    style: TextStyle(
                      fontSize: 14,
                      color: RetroColors.cocoa.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.7,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.favorite_border,
              color: RetroColors.burntOrange,
            ),
          ],
        ),
      ),
    );
  }
}