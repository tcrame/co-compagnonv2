import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../bestiary/bestiary_screen.dart';
import '../characters/character_list_screen.dart';
import '../home/home_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildHeader(context),
              const Spacer(flex: 2),
              _buildNavCard(
                context,
                title: 'Tracker de Combat',
                subtitle: 'Gérez vos sessions de combat,\nl\'initiative et les points de vie',
                icon: Icons.shield,
                gradientColors: const [Color(0xFF8B1A2E), Color(0xFFCF6679)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildNavCard(
                context,
                title: 'Bestiaire',
                subtitle: 'Consultez et gérez\nvos créatures et personnages',
                icon: Icons.auto_fix_high,
                gradientColors: const [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BestiaryScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildNavCard(
                context,
                title: 'Fiches de Personnages',
                subtitle: 'Créez et gérez vos\nfiches de personnages COF2',
                icon: Icons.person,
                gradientColors: const [Color(0xFF311B92), Color(0xFF7B1FA2)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CharacterListScreen()),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'Chronique Oublié V2',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCF6679).withValues(alpha: 0.4),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'images/icons/Icon-512.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CO Compagnon',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Votre compagnon de jeu',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 0.8,
              ),
        ),
      ],
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
