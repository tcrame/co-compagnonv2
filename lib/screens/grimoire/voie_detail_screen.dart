import 'package:flutter/material.dart';
import '../../constants/voies_data.dart';

class VoieDetailScreen extends StatelessWidget {
  final VoieCatalogue voie;
  final String searchQuery; // 💡 On récupère la recherche !

  const VoieDetailScreen({super.key, required this.voie, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(voie.nom),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil : ${voie.profil} • Famille : ${voie.famille}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (voie.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    voie.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: voie.capacites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cap = voie.capacites[index];

                // 💡 NOUVEAU : Est-ce que cette capacité est celle qu'on recherche ?
                final bool isHighlighted = searchQuery.isNotEmpty &&
                    cap.nom.toLowerCase().contains(searchQuery.toLowerCase());

                return Card(
                  // Un fond très légèrement teinté et un bord doré si c'est la bonne capacité
                  color: isHighlighted ? const Color(0xFF332B1A) : const Color(0xFF222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isHighlighted ? Colors.amber : Colors.grey.shade800,
                      width: isHighlighted ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blueGrey.shade800,
                          child: Text('${cap.rang}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(cap.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (cap.type.isNotEmpty) _buildTypeBadge(cap.type),
                                  if (cap.isMagique) const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 16),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cap.description,
                                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color bgColor;
    switch (type.toUpperCase()) {
      case 'L': bgColor = Colors.red.shade900; break;
      case 'A': bgColor = Colors.orange.shade800; break;
      case 'G': bgColor = Colors.green.shade800; break;
      case 'M': bgColor = Colors.blue.shade800; break;
      default: bgColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}