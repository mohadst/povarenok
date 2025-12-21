import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/retro_colors.dart';
import '../widgets/retro_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroColors.paper,
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Шапка профиля
              RetroCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: RetroColors.mustard.withOpacity(0.1),
                          border: Border.all(
                            color: RetroColors.cocoa.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          // Если у вас PNG файл, используйте:
                          child: Image.asset(
                            'assets/cherry.png',
                            height: 80,
                            width: 80,
                            errorBuilder: (context, error, stackTrace) {
                              // Если изображение не загрузится, покажет иконку
                              return Icon(
                                Icons.restaurant,
                                size: 60,
                                color: RetroColors.cherryRed,
                              );
                            },
                          ),
                          // Или если это действительно SVG, убедитесь что используете правильный путь
                          // и что файл имеет расширение .svg
                          // child: SvgPicture.asset(
                          //   'assets/cherry.svg',
                          //   height: 80,
                          //   width: 80,
                          //   placeholderBuilder: (BuildContext context) => Container(
                          //     padding: const EdgeInsets.all(30.0),
                          //     child: const CircularProgressIndicator(),
                          //   ),
                          // ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Повар-любитель',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: RetroColors.cocoa,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Создано рецептов: 3',
                        style: TextStyle(
                          fontSize: 16,
                          color: RetroColors.cocoa.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4 фиксированные плашки
              Expanded(
                child: Column(
                  children: [
                    // Первый ряд
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.restaurant_menu,
                            title: 'Рецепты',
                            value: '3',
                            color: RetroColors.mustard,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.favorite,
                            title: 'Избранное',
                            value: '0',
                            color: RetroColors.cherryRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Второй ряд
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time,
                            title: 'Время готовки',
                            value: '12ч',
                            color: RetroColors.avocado,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star,
                            title: 'Рейтинг',
                            value: '4.5',
                            color: RetroColors.burntOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RetroColors.cocoa.withOpacity(0.3), width: 2),
        color: RetroColors.paper,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RetroColors.cocoa,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: RetroColors.cocoa,
            ),
          ),
        ],
      ),
    );
  }
}