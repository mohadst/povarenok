import 'package:flutter/material.dart';
import '../data/recipes.dart';
import '../theme/retro_colors.dart';
import 'recipe_detail_screen.dart';
import 'dart:math';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidthSmall = (screenWidth - 48) / 2;
    final cardWidthLarge = screenWidth - 32;

    return Scaffold(
      backgroundColor: RetroColors.paper,
      appBar: AppBar(
        title: const Text(
          'Рецепты',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 24,
                children: List.generate(demoRecipes.length, (index) {
                  final recipe = demoRecipes[index];
                  final isLarge = index % 3 == 0;
                  final cardWidth = isLarge ? cardWidthLarge : cardWidthSmall;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    child: Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: RetroColors.paper.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: RetroColors.cocoa.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CustomPaint(
                                painter: _DoubleBorderPainter(),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Icon(Icons.star,
                                size: 10,
                                color:
                                    RetroColors.burntOrange.withOpacity(0.6)),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Icon(Icons.star,
                                size: 10,
                                color: RetroColors.avocado.withOpacity(0.6)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12)),
                                child: Image.network(
                                  recipe.imageUrl,
                                  width: double.infinity,
                                  height: isLarge ? 180 : 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: double.infinity,
                                    height: isLarge ? 180 : 120,
                                    color: RetroColors.mustard.withOpacity(0.3),
                                    child: const Icon(Icons.restaurant_menu),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.title,
                                      style: const TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: RetroColors.cocoa,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InfoBadge(
                                            icon: Icons.kitchen,
                                            text:
                                                '${recipe.ingredients.length} ингредиентов',
                                            color: RetroColors.mustard
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _InfoBadge(
                                            icon: Icons.timer,
                                            text:
                                                '${recipe.steps.length * 5} мин',
                                            color: RetroColors.avocado
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: 0.7,
                                        minHeight: 6,
                                        backgroundColor: RetroColors.mustard
                                            .withOpacity(0.3),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                RetroColors.mustard),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.favorite_border,
                              color: RetroColors.burntOrange,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: RetroColors.cocoa),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: RetroColors.cocoa.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outerPaint = Paint()
      ..color = RetroColors.mustard.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(outerRect, outerPaint);

    final innerRect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final dashPaint = Paint()
      ..color = RetroColors.avocado.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = sqrt(dx * dx + dy * dy);
      final dashCount = (length / (dashWidth + dashSpace)).floor();
      final xStep = dx / dashCount;
      final yStep = dy / dashCount;

      for (int i = 0; i < dashCount; i += 2) {
        final x1 = start.dx + i * xStep;
        final y1 = start.dy + i * yStep;
        final x2 = start.dx + (i + 1).clamp(0, dashCount) * xStep;
        final y2 = start.dy + (i + 1).clamp(0, dashCount) * yStep;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
      }
    }

    drawDashedLine(innerRect.topLeft, innerRect.topRight);
    drawDashedLine(innerRect.topRight, innerRect.bottomRight);
    drawDashedLine(innerRect.bottomRight, innerRect.bottomLeft);
    drawDashedLine(innerRect.bottomLeft, innerRect.topLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = RetroColors.mustard.withOpacity(0.1);
    canvas.drawCircle(Offset(60, 80), 60, paint);

    paint.color = RetroColors.avocado.withOpacity(0.08);
    canvas.drawOval(
        Rect.fromLTWH(size.width - 120, size.height - 150, 120, 80), paint);

    paint.color = RetroColors.burntOrange.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width / 2, 200), 50, paint);

    paint.color = RetroColors.burntOrange.withOpacity(0.15);
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    paint.color = RetroColors.cocoa.withOpacity(0.02);
    for (int i = 0; i < 200; i++) {
      final dx = (size.width * (i % 20) / 20) + (i % 5);
      final dy = (size.height * (i ~/ 20) / 10) + (i % 5);
      canvas.drawCircle(Offset(dx, dy), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}