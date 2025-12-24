import 'package:flutter/material.dart';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final List<RecipeStep> steps;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: (json['steps'] as List?)?.map((step) {
            if (step is Map<String, dynamic>) {
              return RecipeStep.fromJson(step);
            } else {
              return RecipeStep(
                number: 1,
                instruction: step.toString(),
              );
            }
          }).toList() ??
          [],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'steps': steps.map((step) => step.toJson()).toList(),
      'isFavorite': isFavorite,
    };
  }
}

class RecipeStep {
  final int number;
  final String instruction;

  RecipeStep({
    required this.number,
    required this.instruction,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      number: json['number'] ?? 1,
      instruction: json['instruction'] ?? json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'instruction': instruction,
    };
  }
}

class RecipeStorage {
  static final RecipeStorage _instance = RecipeStorage._internal();
  factory RecipeStorage() => _instance;
  RecipeStorage._internal();

  final List<Recipe> _recipes = [];
  final List<String> _favoriteRecipeIds = [];

  void initializeWithDemoRecipes() {
    if (_recipes.isEmpty) {
      _recipes.addAll([
        Recipe(
          id: '1',
          title: 'Классический борщ',
          imageUrl: 'https://images.unsplash.com/photo-1607523997461-0479e79d5f80?w=600',
          ingredients: ['Свекла', 'Картофель', 'Капуста', 'Мясо', 'Лук', 'Морковь'],
          steps: [
            RecipeStep(number: 1, instruction: 'Почистить и нарезать овощи'),
            RecipeStep(number: 2, instruction: 'Сварить бульон из мяса'),
            RecipeStep(number: 3, instruction: 'Добавить овощи в бульон'),
            RecipeStep(number: 4, instruction: 'Варить 40 минут'),
          ],
        ),
        Recipe(
          id: '2',
          title: 'Оливье',
          imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600',
          ingredients: ['Картофель', 'Колбаса', 'Огурцы', 'Горошек', 'Яйца', 'Майонез'],
          steps: [
            RecipeStep(number: 1, instruction: 'Отварить картофель и яйца'),
            RecipeStep(number: 2, instruction: 'Нарезать все ингредиенты кубиками'),
            RecipeStep(number: 3, instruction: 'Смешать с горошком'),
            RecipeStep(number: 4, instruction: 'Заправить майонезом'),
          ],
        ),
        Recipe(
          id: '3',
          title: 'Шашлык',
          imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600',
          ingredients: ['Свинина', 'Лук', 'Уксус', 'Специи', 'Зелень'],
          steps: [
            RecipeStep(number: 1, instruction: 'Нарезать мясо на кубики'),
            RecipeStep(number: 2, instruction: 'Мариновать с луком и специями 3 часа'),
            RecipeStep(number: 3, instruction: 'Нанизать на шампуры'),
            RecipeStep(number: 4, instruction: 'Жарить на углях 15 минут'),
          ],
        ),
        Recipe(
          id: '4',
          title: 'Блины',
          imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w-600',
          ingredients: ['Молоко', 'Яйца', 'Мука', 'Сахар', 'Соль', 'Масло'],
          steps: [
            RecipeStep(number: 1, instruction: 'Смешать яйца с сахаром и солью'),
            RecipeStep(number: 2, instruction: 'Добавить молоко и муку'),
            RecipeStep(number: 3, instruction: 'Выпекать на разогретой сковороде'),
            RecipeStep(number: 4, instruction: 'Подавать с вареньем или сметаной'),
          ],
        ),
      ]);
    }
  }

  List<Recipe> getAllRecipes() {
    return List.from(_recipes);
  }

  List<Recipe> getFavoriteRecipes() {
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }

  void addRecipe(Recipe recipe) {
    _recipes.insert(0, recipe); 
  }

  void removeRecipe(String recipeId) {
    _recipes.removeWhere((recipe) => recipe.id == recipeId);
  }

  void toggleFavorite(String recipeId) {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      _recipes[index].isFavorite = !_recipes[index].isFavorite;
    }
  }

  List<Recipe> searchRecipes(String query) {
    if (query.isEmpty) return getAllRecipes();
    return _recipes
        .where((recipe) =>
            recipe.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}