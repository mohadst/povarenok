import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final recipes = await ApiService.getRecipes();
      
      setState(() {
        _recipes = recipes;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои рецепты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecipes,
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
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadRecipes,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _recipes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Нет рецептов',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Создайте первый рецепт!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: recipe['image_url'] != null && recipe['image_url'].isNotEmpty
                                ? Image.network(
                                    recipe['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.restaurant_menu);
                                    },
                                  )
                                : const Icon(Icons.restaurant_menu, size: 40),
                            title: Text(
                              recipe['title'] ?? 'Без названия',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (recipe['ingredients'] != null)
                                  Text('Ингредиентов: ${recipe['ingredients'].length}'),
                                if (recipe['created_at'] != null)
                                  Text(
                                    'Создан: ${DateTime.parse(recipe['created_at']).toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // TODO: Переход к деталям рецепта
                              print('Выбран рецепт: ${recipe['id']}');
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Переход к созданию рецепта
          Navigator.pushNamed(context, '/create_recipe');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}