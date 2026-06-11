import 'package:flutter/material.dart';
import '../../constants/voies_data.dart';
import '../../constants/voies_prestige_data.dart'; // 💡 L'import magique pour le prestige
import 'voie_detail_screen.dart';

class GrimoireScreen extends StatefulWidget {
  const GrimoireScreen({super.key});

  @override
  State<GrimoireScreen> createState() => _GrimoireScreenState();
}

class _GrimoireScreenState extends State<GrimoireScreen> {
  bool _isSearching = false;
  String _searchQuery = '';

  bool _voieMatches(VoieCatalogue voie, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (voie.nom.toLowerCase().contains(q)) return true;
    return voie.capacites.any((cap) => cap.nom.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final allProfils = kVoiesParProfil.keys.toList()..sort();
    final allPeuples = kVoiesChoixPeuple.keys.toList()..sort();
    final allPrestiges = kVoiesDePrestigeParProfil.keys.toList()..sort(); // 💡 Les prestiges

    // Filtrage des Profils
    final filteredProfils = <String>[];
    final filteredVoiesParProfil = <String, List<VoieCatalogue>>{};
    for (final profil in allProfils) {
      final voies = kVoiesParProfil[profil]!.where((v) => _voieMatches(v, _searchQuery)).toList();
      if (voies.isNotEmpty) {
        filteredProfils.add(profil);
        filteredVoiesParProfil[profil] = voies;
      }
    }

    // Filtrage des Peuples
    final filteredPeuples = <String>[];
    final filteredVoiesParPeuple = <String, List<VoieCatalogue>>{};
    for (final peuple in allPeuples) {
      final voies = kVoiesChoixPeuple[peuple]!.where((v) => _voieMatches(v, _searchQuery)).toList();
      if (voies.isNotEmpty) {
        filteredPeuples.add(peuple);
        filteredVoiesParPeuple[peuple] = voies;
      }
    }
    final mageMatches = _voieMatches(kVoieDuMage, _searchQuery);

    // 💡 Filtrage des Prestiges
    final filteredPrestiges = <String>[];
    final filteredVoiesParPrestige = <String, List<VoieCatalogue>>{};
    for (final prestige in allPrestiges) {
      final voies = kVoiesDePrestigeParProfil[prestige]!.where((v) => _voieMatches(v, _searchQuery)).toList();
      if (voies.isNotEmpty) {
        filteredPrestiges.add(prestige);
        filteredVoiesParPrestige[prestige] = voies;
      }
    }

    return DefaultTabController(
      length: 3, // 💡 Passage à 3 onglets !
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Chercher un sort ou capacité...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          )
              : const Text('Grimoire des Voies'),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true, // 💡 Permet aux onglets de déborder proprement sur les petits écrans
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Profil'),
              Tab(icon: Icon(Icons.public), text: 'Peuple'),
              Tab(icon: Icon(Icons.star_border), text: 'Prestige'), // 💡 Nouvel onglet
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabsList(filteredProfils, filteredVoiesParProfil, Icons.shield, Colors.blueGrey),
            _buildPeuplesTab(filteredPeuples, filteredVoiesParPeuple, mageMatches),
            _buildTabsList(filteredPrestiges, filteredVoiesParPrestige, Icons.stars, Colors.amber), // 💡 La vue Prestige
          ],
        ),
      ),
    );
  }

  // 💡 Builder générique utilisé pour les Profils ET les Prestiges
  Widget _buildTabsList(List<String> categories, Map<String, List<VoieCatalogue>> voiesMap, IconData headerIcon, Color iconColor) {
    if (categories.isEmpty) return const Center(child: Text('Aucune capacité trouvée', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final voies = voiesMap[category]!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: const Color(0xFF2A2A2A),
          child: ExpansionTile(
            initiallyExpanded: _searchQuery.isNotEmpty,
            leading: Icon(headerIcon, color: iconColor),
            title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${voies.length} voies correspondantes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            children: voies.map<Widget>((voie) => _buildVoieTile(context, voie)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPeuplesTab(List<String> peuples, Map<String, List<VoieCatalogue>> voiesMap, bool mageMatches) {
    if (peuples.isEmpty && !mageMatches) return const Center(child: Text('Aucune capacité trouvée', style: TextStyle(color: Colors.grey)));

    return ListView(
      children: [
        ...peuples.map((peuple) {
          final voies = voiesMap[peuple]!;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF2A2A2A),
            child: ExpansionTile(
              initiallyExpanded: _searchQuery.isNotEmpty,
              leading: const Icon(Icons.nature_people, color: Colors.green),
              title: Text(peuple, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('${voies.length} voie(s) correspondante(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              children: voies.map<Widget>((voie) => _buildVoieTile(context, voie)).toList(),
            ),
          );
        }),
        if (mageMatches)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF2A2A2A),
            child: ExpansionTile(
              initiallyExpanded: _searchQuery.isNotEmpty,
              leading: const Icon(Icons.auto_fix_high, color: Colors.purpleAccent),
              title: const Text('Mages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text('Spécifique aux lanceurs de sorts', style: TextStyle(color: Colors.grey, fontSize: 12)),
              children: [_buildVoieTile(context, kVoieDuMage)],
            ),
          ),
      ],
    );
  }

  Widget _buildVoieTile(BuildContext context, VoieCatalogue voie) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 40, right: 16),
      title: Text(voie.nom, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VoieDetailScreen(voie: voie, searchQuery: _searchQuery)),
        );
      },
    );
  }
}