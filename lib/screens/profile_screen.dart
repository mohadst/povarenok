import 'package:flutter/material.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final bool isSmallScreen = screenWidth < 600;
          final bool isLargeScreen = screenWidth > 900;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 32.0 : 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isLargeScreen ? 600.0 : double.infinity,
                    ),
                    child: RetroCard(
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                        child: Column(
                          children: [
                            Container(
                              width: isSmallScreen ? 100.0 : 120.0,
                              height: isSmallScreen ? 100.0 : 120.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: RetroColors.mustard.withOpacity(0.1),
                                border: Border.all(
                                  color: RetroColors.cocoa.withOpacity(0.3),
                                  width: 2.0,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/cherry.png',
                                  height: isSmallScreen ? 60.0 : 80.0,
                                  width: isSmallScreen ? 60.0 : 80.0,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.restaurant,
                                      size: isSmallScreen ? 50.0 : 60.0,
                                      color: RetroColors.cherryRed,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Повар-любитель',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20.0 : 24.0,
                                fontWeight: FontWeight.bold,
                                color: RetroColors.cocoa,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Создано рецептов: 3',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                color: RetroColors.cocoa.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _buildStatsSection(isSmallScreen, isLargeScreen, screenWidth),
                  if (isLargeScreen) ...[
                    const SizedBox(height: 32.0),
                    _buildAchievementsSection(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(
      bool isSmallScreen, bool isLargeScreen, double screenWidth) {
    final double cardSpacing = isSmallScreen ? 12.0 : 16.0;
    final int crossAxisCount = isLargeScreen ? 4 : 2;
    final double availableWidth = screenWidth -
        (isLargeScreen ? 64.0 : 32.0) -
        ((crossAxisCount - 1) * cardSpacing);

    final double cardWidth = availableWidth / crossAxisCount;

    final List<Map<String, dynamic>> stats = [
      {
        'icon': Icons.restaurant_menu,
        'title': 'Рецепты',
        'value': '3',
        'color': RetroColors.mustard,
      },
      {
        'icon': Icons.favorite,
        'title': 'Избранное',
        'value': '0',
        'color': RetroColors.cherryRed,
      },
      {
        'icon': Icons.access_time,
        'title': 'Время готовки',
        'value': '12ч',
        'color': RetroColors.avocado,
      },
      {
        'icon': Icons.star,
        'title': 'Рейтинг',
        'value': '4.5',
        'color': RetroColors.burntOrange,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: cardSpacing,
      mainAxisSpacing: cardSpacing,
      childAspectRatio: 0.8,
      padding: EdgeInsets.zero,
      children: stats.map((stat) {
        return _buildStatCard(
          icon: stat['icon'] as IconData,
          title: stat['title'] as String,
          value: stat['value'] as String,
          color: stat['color'] as Color,
          isSmallScreen: isSmallScreen,
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: RetroColors.cocoa.withOpacity(0.3),
          width: 2.0,
        ),
        color: RetroColors.paper,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2.0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 32.0 : 40.0,
            color: color,
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 20.0 : 24.0,
              fontWeight: FontWeight.bold,
              color: RetroColors.cocoa,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12.0 : 14.0,
              color: RetroColors.cocoa,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: RetroColors.cream,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: RetroColors.cocoa.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Достижения',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: RetroColors.cocoa,
            ),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              _buildAchievementBadge(
                title: 'Новичок',
                icon: Icons.emoji_events,
              ),
              _buildAchievementBadge(
                title: 'Первые 3 рецепта',
                icon: Icons.restaurant,
              ),
              _buildAchievementBadge(
                title: 'Активный пользователь',
                icon: Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: RetroColors.paper,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: RetroColors.mustard,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.0,
            color: RetroColors.mustard,
          ),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.0,
              color: RetroColors.cocoa,
            ),
          ),
        ],
      ),
    );
  }
}
