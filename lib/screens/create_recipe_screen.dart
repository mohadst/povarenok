import 'package:flutter/material.dart';
import '../data/recipes_data.dart';
import '../theme/retro_colors.dart';
import '../widgets/retro_card.dart';
import 'dart:math';

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
  final List<TextEditingController> _ingredientControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _stepControllers = [
    TextEditingController()
  ];

  late final AnimationController _animationController;
  final RecipeStorage _recipeStorage = RecipeStorage();
  bool _isSubmitting = false;

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
    for (final c in _ingredientControllers) c.dispose();
    for (final c in _stepControllers) c.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addIngredient() =>
      setState(() => _ingredientControllers.add(TextEditingController()));
  
  void _addStep() =>
      setState(() => _stepControllers.add(TextEditingController()));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    // Небольшая задержка для анимации
    await Future.delayed(const Duration(milliseconds: 500));

    final ingredients = _ingredientControllers
        .where((controller) => controller.text.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => e.value.text)
        .toList();

    final steps = _stepControllers
        .where((controller) => controller.text.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => RecipeStep(
              number: e.key + 1,
              instruction: e.value.text,
            ))
        .toList();

    // Создаем новый рецепт
    final newRecipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      imageUrl: _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=600',
      ingredients: ingredients,
      steps: steps,
      isFavorite: false,
    );

    // Сохраняем рецепт
    _recipeStorage.addRecipe(newRecipe);

    // Уведомляем о создании рецепта
    widget.onRecipeCreated?.call();

    // Простое уведомление без кнопки действия
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✅ Рецепт успешно создан!',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3), // Автоматически исчезает через 3 секунды
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Очищаем форму через 1 секунду
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _clearForm();
      }
    });
  }

  void _clearForm() {
    _titleController.clear();
    _imageUrlController.clear();
    for (var controller in _ingredientControllers) {
      controller.clear();
    }
    for (var controller in _stepControllers) {
      controller.clear();
    }
    setState(() {
      _ingredientControllers.clear();
      _stepControllers.clear();
      _ingredientControllers.add(TextEditingController());
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
                        ..._ingredientControllers.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: e.value,
                                        decoration: _input(
                                            'Ингредиент ${e.key + 1}', Icons.check),
                                        validator: (v) =>
                                            v == null || v.isEmpty
                                                ? 'Введите ингредиент'
                                                : null,
                                        textInputAction: e.key ==
                                                _ingredientControllers.length - 1
                                            ? TextInputAction.done
                                            : TextInputAction.next,
                                        enabled: !_isSubmitting,
                                      ),
                                    ),
                                    if (_ingredientControllers.length > 1 && !_isSubmitting)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _ingredientControllers
                                                .removeAt(e.key);
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