import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app_theme.dart';
import '../backup/backup_screen.dart';
import '../bestiary/bestiary_screen.dart';
import '../characters/character_list_screen.dart';
import '../home/home_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Définition d'une couleur grise de secours si onSurfaceMuted est introuvable
    final Color mutedColor = Colors.grey.shade500;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(context),

                      const SizedBox(height: 32),

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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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

                      const Spacer(),
                      const SizedBox(height: 24),

                      Text(
                        'Pour Chroniques Oubliées Fantasy 2e édition',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedColor, // 🛠️ FIX : Utilisation de la couleur sécurisée
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 📢 EXTRACTEUR ASYNCHRONE DE LA VERSION
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final versionText = snapshot.hasData
                              ? 'v${snapshot.data!.version}'
                              : '...';
                          return Text(
                            versionText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: mutedColor.withOpacity(0.5), // 🛠️ FIX : Syntaxe universelle Flutter pour l'opacité
                              letterSpacing: 0.8,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      IconButton(
                        icon: Icon(Icons.backup_outlined,
                            color: mutedColor, size: 20),
                        tooltip: 'Sauvegarde & Restauration',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BackupScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                color: const Color(0xFFCF6679).withOpacity(0.4), // 🛠️ FIX : Changé de withValues à withOpacity
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
                color: gradientColors.last.withOpacity(0.3), // 🛠️ FIX : Changé de withValues à withOpacity
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
                    color: Colors.white.withOpacity(0.15), // 🛠️ FIX : Changé de withValues à withOpacity
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
                          color: Colors.white.withOpacity(0.8), // 🛠️ FIX : Changé de withValues à withOpacity
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7), // 🛠️ FIX : Changé de withValues à withOpacity
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