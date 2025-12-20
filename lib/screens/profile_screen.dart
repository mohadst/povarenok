import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';
import '../widgets/retro_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RetroCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: RetroColors.mustard.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: RetroColors.mustard,
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

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: screenWidth > 700
                  ? 4
                  : screenWidth > 500
                      ? 3
                      : 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  icon: Icons.restaurant_menu,
                  title: 'Рецепты',
                  value: '3',
                  color: RetroColors.mustard,
                ),
                _buildStatCard(
                  icon: Icons.favorite,
                  title: 'Избранное',
                  value: '0',
                  color: RetroColors.cherryRed,
                ),
                _buildStatCard(
                  icon: Icons.access_time,
                  title: 'Время готовки',
                  value: '12ч',
                  color: RetroColors.avocado,
                ),
                _buildStatCard(
                  icon: Icons.star,
                  title: 'Рейтинг',
                  value: '4.5',
                  color: RetroColors.burntOrange,
                ),
              ],
            ),
            const SizedBox(height: 24),

            RetroCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.settings,
                      title: 'Настройки',
                      onTap: () {},
                    ),
                    const Divider(color: RetroColors.cocoa, height: 1),
                    _buildSettingsSwitch(
                      icon: Icons.volume_up,
                      title: 'Голосовой помощник',
                      value: true,
                      onChanged: (val) {},
                    ),
                    const Divider(color: RetroColors.cocoa, height: 1),
                    _buildSettingsSwitch(
                      icon: Icons.notifications,
                      title: 'Уведомления',
                      value: true,
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // уехоло
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildActionCard(
                  icon: Icons.create,
                  label: 'Создать рецепт',
                  color: RetroColors.mustard,
                  width: screenWidth / 2 - 24,
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.favorite,
                  label: 'Мои избранные',
                  color: RetroColors.cherryRed,
                  width: screenWidth / 2 - 24,
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.timer,
                  label: 'История готовки',
                  color: RetroColors.avocado,
                  width: screenWidth / 2 - 24,
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.star,
                  label: 'Рейтинг',
                  color: RetroColors.burntOrange,
                  width: screenWidth / 2 - 24,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
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
    return RetroCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: RetroColors.cocoa.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: RetroColors.cocoa,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: RetroColors.cocoa,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: RetroColors.cocoa),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildSettingsSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: RetroColors.cocoa),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: RetroColors.mustard,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: RetroCard(
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: RetroColors.cocoa.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RetroColors.cocoa,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
