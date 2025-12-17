class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final List<RecipeStep> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
  });
}

class RecipeStep {
  final int number;
  final String instruction;

  RecipeStep({
    required this.number,
    required this.instruction,
  });
}

// Демо-рецепты
final List<Recipe> demoRecipes = [
  Recipe(
    id: '1',
    title: 'Блины на молоке',
    imageUrl: 'https://img.spoonacular.com/recipes/716429-556x370.jpg',
    ingredients: [
      'Молоко - 500 мл',
      'Яйца - 2 шт',
      'Мука - 200 г',
      'Сахар - 2 ст.л.',
      'Соль - щепотка',
      'Масло для жарки'
    ],
    steps: [
      RecipeStep(number: 1, instruction: 'Взбейте яйца с сахаром и солью до однородной массы'),
      RecipeStep(number: 2, instruction: 'Добавьте молоко и тщательно перемешайте'),
      RecipeStep(number: 3, instruction: 'Постепенно всыпьте муку, постоянно помешивая чтобы не образовалось комочков'),
      RecipeStep(number: 4, instruction: 'Дайте тесту постоять 15-20 минут'),
      RecipeStep(number: 5, instruction: 'Разогрейте сковороду и смажьте ее небольшим количеством масла'),
      RecipeStep(number: 6, instruction: 'Выливайте тесто половником и распределите по сковороде'),
      RecipeStep(number: 7, instruction: 'Жарьте блин 1-2 минуты до золотистой корочки затем переверните'),
      RecipeStep(number: 8, instruction: 'Обжарьте с другой стороны еще 1 минуту'),
    ],
  ),
  Recipe(
    id: '2',
    title: 'Омлет с сыром',
    imageUrl: 'https://img.spoonacular.com/recipes/1096204-556x370.jpg',
    ingredients: [
      'Яйца - 3 шт',
      'Молоко - 50 мл',
      'Сыр - 50 г',
      'Соль - по вкусу',
      'Перец черный - по вкусу',
      'Масло сливочное - 1 ст.л.'
    ],
    steps: [
      RecipeStep(number: 1, instruction: 'Разбейте яйца в глубокую миску'),
      RecipeStep(number: 2, instruction: 'Добавьте молоко, соль и перец'),
      RecipeStep(number: 3, instruction: 'Взбейте вилкой или венчиком до однородности'),
      RecipeStep(number: 4, instruction: 'Натрите сыр на крупной терке'),
      RecipeStep(number: 5, instruction: 'Разогрейте сковороду и растопите масло'),
      RecipeStep(number: 6, instruction: 'Вылейте яичную смесь на сковороду'),
      RecipeStep(number: 7, instruction: 'Посыпьте тертым сыром'),
      RecipeStep(number: 8, instruction: 'Накройте крышкой и жарьте на среднем огне 5-7 минут'),
    ],
  ),
  Recipe(
    id: '3',
    title: 'Салат Цезарь',
    imageUrl: 'https://img.spoonacular.com/recipes/715415-556x370.jpg',
    ingredients: [
      'Куриное филе - 200 г',
      'Листья салата - 1 пучок',
      'Помидоры черри - 100 г',
      'Сухарики - 50 г',
      'Сыр Пармезан - 30 г',
      'Соус Цезарь - 2 ст.л.'
    ],
    steps: [
      RecipeStep(number: 1, instruction: 'Отварите куриное филе до готовности и нарежьте кубиками'),
      RecipeStep(number: 2, instruction: 'Промойте и обсушите листья салата'),
      RecipeStep(number: 3, instruction: 'Порвите салат руками на средние кусочки'),
      RecipeStep(number: 4, instruction: 'Помидоры черри разрежьте пополам'),
      RecipeStep(number: 5, instruction: 'Натрите сыр Пармезан на терке'),
      RecipeStep(number: 6, instruction: 'В большой миске смешайте салат, помидоры и курицу'),
      RecipeStep(number: 7, instruction: 'Заправьте соусом Цезарь и аккуратно перемешайте'),
      RecipeStep(number: 8, instruction: 'Перед подачей посыпьте сухариками и тертым сыром'),
    ],
  ),
];