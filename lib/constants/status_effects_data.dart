import 'package:flutter/material.dart';

class StatusEffectDefinition {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const StatusEffectDefinition({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<StatusEffectDefinition> kStatusEffects = [
  StatusEffectDefinition(
    name: 'Aveuglé',
    description:
        '−5 en Init., attaque et DEF, −10 en attaque à distance. Les attaques magiques nécessitant de voir la cible sont impossibles.',
    icon: Icons.visibility_off,
    color: Color(0xFF9E9E9E),
  ),
  StatusEffectDefinition(
    name: 'Affaibli',
    description: 'Dé malus à tous les tests.',
    icon: Icons.trending_down,
    color: Color(0xFF7E57C2),
  ),
  StatusEffectDefinition(
    name: 'Essoufflé',
    description: 'Le déplacement est limité à 5 m par action de mouvement.',
    icon: Icons.air,
    color: Color(0xFF26C6DA),
  ),
  StatusEffectDefinition(
    name: 'Étourdi',
    description: 'Aucune action possible et −5 en DEF.',
    icon: Icons.blur_on,
    color: Color(0xFFFFCA28),
  ),
  StatusEffectDefinition(
    name: 'Immobilisé',
    description: 'Pas de déplacement et dé malus aux tests d\'attaque.',
    icon: Icons.lock_outline,
    color: Color(0xFFEF5350),
  ),
  StatusEffectDefinition(
    name: 'Invalide',
    description: 'Le déplacement est limité à 5 m par action de mouvement.',
    icon: Icons.personal_injury,
    color: Color(0xFFFF7043),
  ),
  StatusEffectDefinition(
    name: 'Paralysé',
    description:
        'Aucune action possible, en cas d\'attaque touché automatiquement et subit un critique.',
    icon: Icons.pause_circle_outline,
    color: Color(0xFFAB47BC),
  ),
  StatusEffectDefinition(
    name: 'Ralenti',
    description: 'Une seule action par round (action d\'attaque ou de mouvement).',
    icon: Icons.hourglass_bottom,
    color: Color(0xFF26A69A),
  ),
  StatusEffectDefinition(
    name: 'Renversé',
    description: '−5 en attaque et DEF, nécessite une action d\'attaque pour se relever.',
    icon: Icons.south,
    color: Color(0xFF8D6E63),
  ),
  StatusEffectDefinition(
    name: 'Surpris',
    description: 'Pas d\'action et −5 en DEF au premier round de combat.',
    icon: Icons.priority_high,
    color: Color(0xFFFF5722),
  ),
];

StatusEffectDefinition? definitionFor(String name) {
  try {
    return kStatusEffects.firstWhere((d) => d.name == name);
  } catch (_) {
    return null;
  }
}
