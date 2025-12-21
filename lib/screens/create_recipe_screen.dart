import 'package:flutter/material.dart';
import '../data/recipes.dart';
import '../theme/retro_colors.dart';
import '../widgets/retro_card.dart';
import 'dart:math';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredientControllers.map((c) => c.text).toList();
    final steps = _stepControllers
        .asMap()
        .entries
        .map((e) => RecipeStep(number: e.key + 1, instruction: e.value.text))
        .toList();

    demoRecipes.add(
      Recipe(
        id: DateTime.now().toString(),
        title: _titleController.text,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : 'https://via.placeholder.com/600x400',
        ingredients: ingredients,
        steps: steps,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Рецепт сохранён 💛')),
    );
    Navigator.pop(context);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroColors.cream,
      appBar: AppBar(
        title: const Text(
          'Создать рецепт',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
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
                              ? 'Введите название'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: _input(
                              'URL изображения (необязательно)', Icons.image),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _VibeRetroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Ингредиенты', _addIngredient),
                        const SizedBox(height: 12),
                        ..._ingredientControllers.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  controller: e.value,
                                  decoration: _input(
                                      'Ингредиент ${e.key + 1}', Icons.check),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Введите ингредиент'
                                      : null,
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
                        _sectionHeader('Шаги приготовления', _addStep),
                        const SizedBox(height: 12),
                        ..._stepControllers.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: TextFormField(
                                  controller: e.value,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: _input('Шаг ${e.key + 1}',
                                      Icons.format_list_numbered),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Введите шаг'
                                      : null,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить рецепт'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: RetroColors.mustard,
                      foregroundColor: RetroColors.cocoa,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Row(
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
        ),
      ],
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
          child: child,
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