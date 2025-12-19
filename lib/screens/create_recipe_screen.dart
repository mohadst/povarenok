import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  final List<TextEditingController> _stepControllers = [TextEditingController()];
  bool _isLoading = false;

  // Список распространенных аллергенов
  final List<String> _commonAllergens = [
    'Молоко',
    'Яйца',
    'Рыба',
    'Ракообразные',
    'Орехи',
    'Арахис',
    'Пшеница',
    'Соя',
    'Кунжут',
    'Глютен',
    'Лактоза',
    'Морепродукты',
  ];

  // Выбранные аллергены
  final Set<String> _selectedAllergens = {};

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredientField() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredientField(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        _ingredientControllers.removeAt(index).dispose();
      });
    }
  }

  void _addStepField() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStepField(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers.removeAt(index).dispose();
      });
    }
  }

  void _addCustomAllergen() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить аллерген'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Название аллергена',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _selectedAllergens.add(text);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем авторизацию
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Пожалуйста, войдите в систему');
      }

      final ingredients = _ingredientControllers
          .where((c) => c.text.isNotEmpty)
          .map((c) => c.text.trim())
          .toList();
      
      final steps = _stepControllers
          .where((c) => c.text.isNotEmpty)
          .map((c) => c.text.trim())
          .toList();

      final allergens = _selectedAllergens.toList();

      final result = await ApiService.createRecipe(
        title: _titleController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isNotEmpty 
            ? _imageUrlController.text.trim() 
            : null,
        ingredients: ingredients,
        steps: steps,
        allergens: allergens,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Рецепт "${_titleController.text}" успешно создан!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Очистка формы
        _formKey.currentState!.reset();
        _titleController.clear();
        _imageUrlController.clear();
        setState(() {
          _ingredientControllers.clear();
          _stepControllers.clear();
          _selectedAllergens.clear();
          _ingredientControllers.add(TextEditingController());
          _stepControllers.add(TextEditingController());
        });

        // Возвращаемся на предыдущий экран
        Navigator.pop(context);
      } else {
        throw Exception(result['error'] ?? 'Неизвестная ошибка');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать рецепт'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitRecipe,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Основная информация',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Название рецепта *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите название рецепта';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL изображения (опционально)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.image),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Ингредиенты
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ингредиенты *',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addIngredientField,
                                  tooltip: 'Добавить ингредиент',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._ingredientControllers.asMap().entries.map((entry) {
                              int index = entry.key;
                              TextEditingController controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          labelText: 'Ингредиент ${index + 1} *',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.check_box_outline_blank),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Введите ингредиент';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (_ingredientControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () => _removeIngredientField(index),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Шаги приготовления
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Шаги приготовления *',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addStepField,
                                  tooltip: 'Добавить шаг',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._stepControllers.asMap().entries.map((entry) {
                              int index = entry.key;
                              TextEditingController controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.orange,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Шаг ${index + 1} *',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              hintText: 'Опишите этот шаг приготовления...',
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Введите описание шага';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        if (_stepControllers.length > 1)
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () => _removeStepField(index),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Аллергены
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Аллергены в рецепте',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Отметьте аллергены, которые содержит рецепт',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),

                            // Распространенные аллергены
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _commonAllergens.map((allergen) {
                                final isSelected = _selectedAllergens.contains(allergen);
                                return FilterChip(
                                  label: Text(allergen),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedAllergens.add(allergen);
                                      } else {
                                        _selectedAllergens.remove(allergen);
                                      }
                                    });
                                  },
                                  selectedColor: Colors.orange.withOpacity(0.2),
                                  checkmarkColor: Colors.orange,
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),

                            // Кнопка добавления своего аллергена
                            OutlinedButton.icon(
                              onPressed: _addCustomAllergen,
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить свой аллерген'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),

                            // Выбранные аллергены
                            if (_selectedAllergens.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Выбранные аллергены:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedAllergens.map((allergen) {
                                  return Chip(
                                    label: Text(allergen),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedAllergens.remove(allergen);
                                      });
                                    },
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Кнопка сохранения
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitRecipe,
                        icon: const Icon(Icons.save),
                        label: const Text('Сохранить рецепт'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}