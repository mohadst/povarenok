import 'package:flutter/material.dart';
import '../data/recipes.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рецепты'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Быстрые категории
          Container(
            height: 70,
            color: Colors.orange.shade50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Завтрак', Icons.breakfast_dining),
                _buildCategoryChip('Обед', Icons.lunch_dining),
                _buildCategoryChip('Ужин', Icons.dinner_dining),
                _buildCategoryChip('Десерты', Icons.cake),
                _buildCategoryChip('Напитки', Icons.local_drink),
              ],
            ),
          ),
          // Список рецептов
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: demoRecipes.length,
              itemBuilder: (context, index) {
                final recipe = demoRecipes[index];
                return RecipeCard(recipe: recipe);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.orange.shade300),
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Изображение рецепта
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: Colors.grey.shade500,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Информация о рецепте
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.list, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ingredients.length} ингр.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.steps.length * 5} мин',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  color: Colors.grey.shade400,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}