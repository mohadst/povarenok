import 'package:flutter/material.dart';
class RecipeIngredient {
  final String name;
  final double? amount;
  final String? unit;

  RecipeIngredient({
    required this.name,
    this.amount,
    this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }

  @override
  String toString() {
    if (amount != null && unit != null) {
      return '$name - $amount $unit';
    } else if (amount != null) {
      return '$name - $amount';
    } else {
      return name;
    }
  }
}


class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<RecipeIngredient> ingredients;
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
    List<RecipeIngredient> ingredients = [];
    if (json['ingredients'] != null) {
      if (json['ingredients'][0] is Map) {
        ingredients = (json['ingredients'] as List)
            .map((item) => RecipeIngredient.fromJson(item))
            .toList();
      } else {
        ingredients = (json['ingredients'] as List<dynamic>)
            .map((item) => RecipeIngredient(name: item.toString()))
            .toList();
      }
    }

    return Recipe(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      ingredients: ingredients,
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
      'ingredients': ingredients.map((ing) => ing.toJson()).toList(),
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
          ingredients: [
            RecipeIngredient(name: 'Свекла', amount: 300, unit: 'г'),
            RecipeIngredient(name: 'Картофель', amount: 400, unit: 'г'),
            RecipeIngredient(name: 'Капуста', amount: 250, unit: 'г'),
            RecipeIngredient(name: 'Говядина', amount: 500, unit: 'г'),
            RecipeIngredient(name: 'Лук', amount: 2, unit: 'шт'),
            RecipeIngredient(name: 'Морковь', amount: 1, unit: 'шт'),
            RecipeIngredient(name: 'Томатная паста', amount: 2, unit: 'ст.л.'),
            RecipeIngredient(name: 'Сметана', unit: 'по вкусу'),
          ],
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
          ingredients: [
            RecipeIngredient(name: 'Картофель', amount: 4, unit: 'шт'),
            RecipeIngredient(name: 'Докторская колбаса', amount: 300, unit: 'г'),
            RecipeIngredient(name: 'Огурцы соленые', amount: 3, unit: 'шт'),
            RecipeIngredient(name: 'Горошек консервированный', amount: 200, unit: 'г'),
            RecipeIngredient(name: 'Яйца', amount: 4, unit: 'шт'),
            RecipeIngredient(name: 'Майонез', amount: 100, unit: 'г'),
            RecipeIngredient(name: 'Соль', unit: 'по вкусу'),
          ],
          steps: [
            RecipeStep(number: 1, instruction: 'Отварить картофель и яйца'),
            RecipeStep(number: 2, instruction: 'Нарезать все ингредиенты кубиками'),
            RecipeStep(number: 3, instruction: 'Смешать с горошком'),
            RecipeStep(number: 4, instruction: 'Заправить майонезом'),
          ],
        ),
        Recipe(
          id: '3',
          title: 'Шашлык из свинины',
          imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600',
          ingredients: [
            RecipeIngredient(name: 'Свинина (шейка)', amount: 1, unit: 'кг'),
            RecipeIngredient(name: 'Лук репчатый', amount: 3, unit: 'шт'),
            RecipeIngredient(name: 'Уксус яблочный', amount: 50, unit: 'мл'),
            RecipeIngredient(name: 'Специи для шашлыка', amount: 2, unit: 'ст.л.'),
            RecipeIngredient(name: 'Соль', amount: 1, unit: 'ч.л.'),
            RecipeIngredient(name: 'Зелень (петрушка, кинза)', amount: 1, unit: 'пучок'),
          ],
          steps: [
            RecipeStep(number: 1, instruction: 'Нарезать мясо на кубики'),
            RecipeStep(number: 2, instruction: 'Мариновать с луком и специями 3 часа'),
            RecipeStep(number: 3, instruction: 'Нанизать на шампуры'),
            RecipeStep(number: 4, instruction: 'Жарить на углях 15 минут'),
          ],
        ),
       Recipe(
          id: '4',
          title: 'Блины на молоке',
          imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w-600',
          ingredients: [
            RecipeIngredient(name: 'Молоко', amount: 500, unit: 'мл'),
            RecipeIngredient(name: 'Яйца', amount: 3, unit: 'шт'),
            RecipeIngredient(name: 'Мука', amount: 250, unit: 'г'),
            RecipeIngredient(name: 'Сахар', amount: 2, unit: 'ст.л.'),
            RecipeIngredient(name: 'Соль', amount: 0.5, unit: 'ч.л.'),
            RecipeIngredient(name: 'Масло растительное', amount: 2, unit: 'ст.л.'),
          ],
          steps: [
            RecipeStep(number: 1, instruction: 'Смешать яйца с сахаром и солью'),
            RecipeStep(number: 2, instruction: 'Добавить молоко и муку, взбить'),
            RecipeStep(number: 3, instruction: 'Выпекать на разогретой сковороде с маслом'),
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