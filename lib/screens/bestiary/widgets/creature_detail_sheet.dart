import 'package:flutter/material.dart';
import '../../../models/character_template.dart';
import '../creature_form_screen.dart';
import '../../../widgets/participant_avatar.dart';

class CreatureDetailSheet extends StatelessWidget {
  final CharacterTemplate template;

  const CreatureDetailSheet({super.key, required this.template});

  // 💡 Règle de calcul CO : Modificateur = (Valeur - 10) / 2 (arrondi à l'inférieur)
  int _getModifier(int value) {
    return ((value - 10) / 2).floor();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 On rapatrie la fonction de formatage intelligent ici aussi
    String formatNc(double nc) {
      if (nc == 0.5) return '1/2';
      if (nc == 0.25) return '1/4';
      if (nc % 1 == 0) return nc.toInt().toString();
      return nc.toString();
    }

    // 💡 SÉCURITÉ : On utilise les labels de tes Énumérations !
    final subtitleParts = <String>[
      template.creatureType.label,
      template.taille.label,
      template.archetype.label,
    ];

    // 💡 NOUVEAU : On applique le formatage propre au NC
    if (template.nc != null) subtitleParts.add('NC ${formatNc(template.nc!)}');

    final subtitleInfo = subtitleParts.join(' • ');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Fond sombre du screenshot
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // ── EN-TÊTE (Avatar + Nom + Sous-titre) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 💡 REMPLACE LE CircleAvatar PAR TON COMPOSANT DYMANIQUE
                  ParticipantAvatar(
                    radius: 28,
                    name: template.name,
                    isAlly: template.isAlly,
                    imageUrl: template.imageUrl,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleInfo,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // ✏️ Bouton Modifier
                  IconButton(
                    tooltip: 'Modifier',
                    onPressed: () {
                      Navigator.pop(context); // Ferme la fiche
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreatureFormScreen(templateToEdit: template)),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  ),
                  // ❌ Bouton Fermer
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── STATISTIQUES DE COMBAT ──
              const Text('Statistiques de combat', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [
                  _buildCombatChip(Icons.bolt, 'Init', '${template.baseInitiative}', Colors.amber),
                  _buildCombatChip(Icons.favorite, 'PV', '${template.maxHp}', Colors.red),
                  _buildCombatChip(Icons.shield, 'DEF', '${template.def}', Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 24),

              // ── CARACTÉRISTIQUES (FOR, AGI, etc.) ──
              const Text('Caractéristiques', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatBox('FOR', template.forVal),
                    _buildStatBox('AGI', template.agiVal),
                    _buildStatBox('CON', template.conVal),
                    _buildStatBox('INT', template.intVal),
                    _buildStatBox('PER', template.perVal),
                    _buildStatBox('CHA', template.chaVal),
                    _buildStatBox('VOL', template.volVal),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── ATTAQUES ──
              if (template.attacks.isNotEmpty) ...[
                const Text('Attaques', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                ...template.attacks.map((att) => _buildAttackCard(att)),
                const SizedBox(height: 24),
              ],

              // ── CAPACITÉS ──
              if (template.capacities.isNotEmpty) ...[
                const Text('Capacités', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                ...template.capacities.map((cap) => _buildCapacityCard(cap)),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  // Composant : Pillules de combat
  Widget _buildCombatChip(IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // Composant : Carré de caractéristique
  Widget _buildStatBox(String label, int value) {
    final mod = _getModifier(value);
    final modString = mod >= 0 ? '+$mod' : '$mod';
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(modString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // Composant : Ligne d'attaque
  Widget _buildAttackCard(TemplateAttack attack) {
    final nom = attack.name.isNotEmpty ? attack.name : 'Attaque';
    final atk = attack.bonusAtk;
    final dm = attack.dm.isNotEmpty ? attack.dm : '1d4';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(nom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Text(atk < 0 ? '$atk' : '+$atk', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text('DM $dm', style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
          if (attack.additionalEffect.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(attack.additionalEffect, style: const TextStyle(color: Colors.amber, fontSize: 12)),
          ]
        ],
      ),
    );
  }

  // Composant : Ligne de capacité
  Widget _buildCapacityCard(TemplateCapacity capacity) {
    final nom = capacity.name.isNotEmpty ? capacity.name : 'Capacité';
    final desc = capacity.description;
    final actionPrefix = capacity.actionType.isNotEmpty ? '[${capacity.actionType}] ' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$actionPrefix$nom', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          ]
        ],
      ),
    );
  }
}