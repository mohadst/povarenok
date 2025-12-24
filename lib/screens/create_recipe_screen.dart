import 'package:flutter/material.dart';
import '../data/recipes_data.dart';
import '../theme/retro_colors.dart';
import '../services/api_service.dart'; 
import '../widgets/retro_card.dart';
import 'dart:math';


class IngredientFormData {
  final TextEditingController nameController;
  final TextEditingController amountController;
  String selectedUnit;

  IngredientFormData({
    required this.nameController,
    required this.amountController,
    this.selectedUnit = 'шт',
  });
}


class CreateRecipeScreen extends StatefulWidget {
  final VoidCallback? onRecipeCreated;
  
  const CreateRecipeScreen({
    super.key,
    this.onRecipeCreated,
  });

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final List<IngredientFormData> _ingredientFormData = [
    IngredientFormData(
      nameController: TextEditingController(),
      amountController: TextEditingController(),
      selectedUnit: 'шт',
    )
  ];
  final List<TextEditingController> _stepControllers = [
    TextEditingController()
  ];

  late final AnimationController _animationController;
  final RecipeStorage _recipeStorage = RecipeStorage();
  bool _isSubmitting = false;

   final List<String> _unitOptions = [
    'шт',
    'г',
    'кг',
    'мл',
    'л',
    'ч.л.',
    'ст.л.',
    'стакан',
    'щепотка',
    'по вкусу'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _recipeStorage.initializeWithDemoRecipes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    for (final data in _ingredientFormData) {
      data.nameController.dispose();
      data.amountController.dispose();
    }
    for (final c in _stepControllers) c.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addIngredient() => setState(() {
    _ingredientFormData.add(
      IngredientFormData(
        nameController: TextEditingController(),
        amountController: TextEditingController(),
        selectedUnit: 'шт',
      )
    );
  });
  
  void _addStep() =>
      setState(() => _stepControllers.add(TextEditingController()));


  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() {
    _isSubmitting = true;
  });

  final ingredients = _ingredientFormData
      .where((data) => data.nameController.text.isNotEmpty)
      .map((data) {
        final name = data.nameController.text;
        final amountText = data.amountController.text;
        final unit = data.selectedUnit;
        
        double? amount;
        if (amountText.isNotEmpty) {
          amount = double.tryParse(amountText.replaceAll(',', '.'));
        }
        
        return {
          'name': name,
          'amount': amount,
          'unit': unit,
        };
      })
      .toList();

  final steps = _stepControllers
      .where((controller) => controller.text.isNotEmpty)
      .toList()
      .asMap()
      .entries
      .map((e) => {
            'number': e.key + 1,
            'instruction': e.value.text,
          })
      .toList();

  final recipeData = {
    'title': _titleController.text,
    'imageUrl': _imageUrlController.text.isNotEmpty
        ? _imageUrlController.text
        : 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=600',
    'ingredients': ingredients,
    'steps': steps,
  };

  print('🔄 Отправка рецепта на сервер...');
  
  try {
    final result = await ApiService.saveRecipe(recipeData);
    
    if (result['success'] == true) {
      final newRecipe = Recipe(
      id: (result['recipe']?['id']?.toString()) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      imageUrl: _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=600',
      ingredients: ingredients.map((ing) => RecipeIngredient(
        name: ing['name']?.toString() ?? '', 
        amount: (ing['amount'] as num?)?.toDouble(), 
        unit: ing['unit']?.toString(), 
      )).toList(),
      steps: steps.map((step) => RecipeStep(
        number: (step['number'] as int?) ?? 1, 
        instruction: step['instruction']?.toString() ?? '',
      )).toList(),
      isFavorite: false,
    );

      _recipeStorage.addRecipe(newRecipe);
      widget.onRecipeCreated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ Рецепт успешно создан и сохранен!',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          _clearForm();
        }
      });
    } else {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
           '❌ Ошибка сохранения: ${result['error']?.toString() ?? "Неизвестная ошибка"}',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isSubmitting = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '❌ Ошибка сети: ${e.toString()}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

   void _clearForm() {
    _titleController.clear();
    _imageUrlController.clear();
    for (var data in _ingredientFormData) {
      data.nameController.clear();
      data.amountController.clear();
    }
    for (var controller in _stepControllers) {
      controller.clear();
    }
    setState(() {
      _ingredientFormData.clear();
      _stepControllers.clear();
      _ingredientFormData.add(
        IngredientFormData(
          nameController: TextEditingController(),
          amountController: TextEditingController(),
          selectedUnit: 'шт',
        )
      );
      _stepControllers.add(TextEditingController());
    });
  }

   InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: RetroColors.cocoa),
      filled: true,
      fillColor: RetroColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: RetroColors.cocoa.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: RetroColors.cocoa.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: RetroColors.mustard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroColors.cream,
      appBar: AppBar(
        title: const Text(
          'Создать рецепт',
          style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _isSubmitting ? null : _clearForm,
            tooltip: 'Очистить форму',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, __) => CustomPaint(
                painter: _RetroVibePainter(_animationController.value),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _VibeRetroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Основная информация',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: RetroColors.cocoa),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration:
                              _input('Название рецепта', Icons.restaurant),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Введите название рецепта'
                              : null,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: _input(
                              'URL изображения (необязательно)', Icons.image),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.url,
                          enabled: !_isSubmitting,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _VibeRetroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Ингредиенты', 
                            _isSubmitting ? null : _addIngredient),
                        const SizedBox(height: 12),
                        ..._ingredientFormData.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: RetroColors.avocado.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${e.key + 1}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: RetroColors.avocado,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 3,
                                          child: TextFormField(
                                            controller: e.value.nameController,
                                            decoration: InputDecoration(
                                              labelText: 'Название ингредиента',
                                              filled: true,
                                              fillColor: RetroColors.paper,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            validator: (v) => v == null || v.isEmpty
                                                ? 'Введите название'
                                                : null,
                                            textInputAction: TextInputAction.next,
                                            enabled: !_isSubmitting,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: e.value.amountController,
                                            decoration: InputDecoration(
                                              labelText: 'Кол-во',
                                              filled: true,
                                              fillColor: RetroColors.paper,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                            textInputAction: TextInputAction.next,
                                            enabled: !_isSubmitting,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: DropdownButtonFormField<String>(
                                            value: e.value.selectedUnit,
                                            decoration: InputDecoration(
                                              labelText: 'Ед. изм.',
                                              filled: true,
                                              fillColor: RetroColors.paper,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            items: _unitOptions
                                                .map((unit) => DropdownMenuItem(
                                                      value: unit,
                                                      child: Text(unit),
                                                    ))
                                                .toList(),
                                            onChanged: _isSubmitting
                                                ? null
                                                : (value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        e.value.selectedUnit = value;
                                                      });
                                                    }
                                                  },
                                            isExpanded: true,
                                          ),
                                        ),
                                        if (_ingredientFormData.length > 1 && !_isSubmitting)
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                e.value.nameController.dispose();
                                                e.value.amountController.dispose();
                                                _ingredientFormData.removeAt(e.key);
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                    if (e.key < _ingredientFormData.length - 1)
                                      const Divider(height: 20, thickness: 1),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _VibeRetroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Шаги приготовления', 
                            _isSubmitting ? null : _addStep),
                        const SizedBox(height: 12),
                        ..._stepControllers.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: RetroColors.mustard,
                                      child: Text(
                                        '${e.key + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.value,
                                        minLines: 2,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          hintText: 'Опишите шаг ${e.key + 1}',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.all(12),
                                        ),
                                        validator: (v) =>
                                            v == null || v.isEmpty
                                                ? 'Введите описание шага'
                                                : null,
                                        enabled: !_isSubmitting,
                                      ),
                                    ),
                                    if (_stepControllers.length > 1 && !_isSubmitting)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _stepControllers.removeAt(e.key);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isSubmitting)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                RetroColors.mustard),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Сохраняю рецепт...',
                            style: TextStyle(
                              fontSize: 16,
                              color: RetroColors.cocoa,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Отмена'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              backgroundColor: Colors.white,
                              foregroundColor: RetroColors.cocoa,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(
                                  color: RetroColors.cocoa.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить рецепт'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              backgroundColor: RetroColors.mustard,
                              foregroundColor: RetroColors.cocoa,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback? onAdd) {
    return Container(
      decoration: BoxDecoration(
        color: RetroColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RetroColors.mustard.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RetroColors.cocoa),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle),
            color: RetroColors.burntOrange,
            iconSize: 28,
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _VibeRetroCard extends StatelessWidget {
  final Widget child;
  const _VibeRetroCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RetroCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        Positioned(
          top: -10,
          left: -10,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RetroColors.mustard.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: RetroColors.avocado.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _RetroVibePainter extends CustomPainter {
  final double animValue;
  _RetroVibePainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    final dotPaint = Paint()
      ..color = RetroColors.cocoa.withOpacity(0.03 + 0.05 * animValue);
    for (int i = 0; i < 250; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawCircle(
          Offset(dx, dy), 1 + random.nextDouble() * 1.5, dotPaint);
    }

    final linePaint = Paint()
      ..color = RetroColors.avocado.withOpacity(0.05 + 0.03 * animValue)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final circlePaint = Paint()
      ..color = RetroColors.mustard.withOpacity(0.05 + 0.05 * animValue);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.1), 50, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.8), 60, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _RetroVibePainter oldDelegate) => true;
}