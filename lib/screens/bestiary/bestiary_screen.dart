import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 💡 INDISPENSABLE POUR LE PRESSE-PAPIERS (Clipboard)
import 'package:provider/provider.dart';

import '../../models/character_template.dart';
import '../../models/creature_collection.dart';
import '../../providers/bestiary_provider.dart';
import '../../providers/collection_provider.dart';
import '../../services/auth_service.dart';
import 'widgets/creature_detail_sheet.dart';
import 'creature_form_screen.dart'; // Import nécessaire pour l'édition de créature
import '../../widgets/participant_avatar.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  String _searchQuery = '';
  String _selectedType = 'Tous';
  String _selectedNc = 'Tous';
  String _selectedFaction = 'Tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BestiaryProvider>().loadTemplates();
      context.read<CollectionProvider>().loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bestiaire & Collections'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Importer une collection',
              onPressed: () => _showImportCollectionDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pets), text: 'Tous les monstres'),
              Tab(icon: Icon(Icons.folder_special), text: 'Mes Collections'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllMonstersTab(),
            _buildCollectionsTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                if (tabIndex == 0) {
                  // Ouvre le formulaire de création
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatureFormScreen()),
                  );
                } else {
                  _showCreateCollectionDialog(context);
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  // ── 🌐 Onglet 1 : Tout le Bestiaire Filtrable ─────────────────────────────

  Widget _buildAllMonstersTab() {
    return Consumer<BestiaryProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTypes = {
          'Tous',
          ...provider.templates
              .map((t) => t.creatureType.label)
              .where((text) => text.trim().isNotEmpty)
        };
        final sortedTypes = ['Tous', ...allTypes.where((t) => t != 'Tous').toList()..sort()];

        // 💡 FIX 1 : On extrait les NC sous forme de vrais chiffres (double), puis on les trie
        final uniqueNcs = provider.templates
            .map((t) => t.nc ?? 0.0)
            .toSet()
            .toList()
          ..sort();

        // 💡 FIX 2 : On réutilise la belle fonction de formatage pour le filtre
        String formatNc(double nc) {
          if (nc == 0.5) return '1/2';
          if (nc == 0.25) return '1/4';
          if (nc % 1 == 0) return nc.toInt().toString();
          return nc.toString();
        }

        // On crée la liste finale des filtres textuels ('Tous', '0', '1/2', '1', '4', etc.)
        final sortedNcs = ['Tous', ...uniqueNcs.map((nc) => formatNc(nc))];

        final filtered = provider.templates.where((t) {
          final matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesType = _selectedType == 'Tous' || t.creatureType.label == _selectedType;

          // 💡 FIX 3 : On compare la valeur sélectionnée avec la valeur formatée du monstre !
          final matchesNc = _selectedNc == 'Tous' || formatNc(t.nc ?? 0.0) == _selectedNc;

          final matchesFaction = _selectedFaction == 'Tous' ||
              (_selectedFaction == 'Alliés' && t.isAlly) ||
              (_selectedFaction == 'Ennemis' && !t.isAlly);
          return matchesSearch && matchesType && matchesNc && matchesFaction;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une créature...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterDropdown('Type', _selectedType, sortedTypes, (v) => setState(() => _selectedType = v!)),
                    const SizedBox(width: 8),
                    _buildFilterDropdown('NC', _selectedNc, sortedNcs, (v) => setState(() => _selectedNc = v!)),
                    const SizedBox(width: 8),
                    _buildFilterDropdown('Camp', _selectedFaction, ['Tous', 'Alliés', 'Ennemis'], (v) => setState(() => _selectedFaction = v!)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Aucune créature trouvée.'))
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 1),
                itemBuilder: (context, index) {
                  final template = filtered[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: ParticipantAvatar(
                      name: template.name,
                      isAlly: template.isAlly,
                      imageUrl: template.imageUrl,
                      radius: 20,
                    ),
                    title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: _buildMonsterSubtitle(template),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.create_new_folder_outlined, color: Colors.amber),
                          tooltip: 'Ranger dans un dossier',
                          onPressed: () => _showAddToCollectionDialog(context, template),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => provider.deleteTemplate(template.id!),
                        ),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => CreatureDetailSheet(template: template),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : 'Tous',
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item == 'Tous' ? '$label : Tout' : item, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── 📂 Onglet 2 : Liste des Collections (Dossiers) ───────────────────────

  Widget _buildCollectionsTab() {
    return Consumer<CollectionProvider>(
      builder: (context, colProd, child) {
        if (colProd.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (colProd.collections.isEmpty) {
          return const Center(child: Text('Créez votre première collection avec le bouton +'));
        }

        return ListView.builder(
          itemCount: colProd.collections.length,
          itemBuilder: (context, index) {
            final collection = colProd.collections[index];
            return ExpansionTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(collection.name),
              subtitle: Text('${collection.templates.length} créature(s)'),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                tooltip: 'Options de collection',
                color: const Color(0xFF2A2A2A), // Fond sombre assorti à ton thème
                onSelected: (value) {
                  switch (value) {
                    case 'copy':
                      Clipboard.setData(ClipboardData(text: collection.syncUuid));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 Code de la collection copié !')),
                      );
                      break;
                    case 'share':
                      _handleShareCollection(context, collection);
                      break;
                    case 'unshare':
                      _handleUnshareCollection(context, collection);
                      break;
                    case 'delete':
                      colProd.deleteCollection(collection.id!);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy, color: Colors.grey, size: 20),
                        SizedBox(width: 12),
                        Text('Copier le code', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Text('Mettre à jour le cloud', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'unshare',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Text('Retirer du cloud', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              children: collection.templates.map((template) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0), // Indentation pour l'effet "Dossier"
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ParticipantAvatar(
                      name: template.name,
                      isAlly: template.isAlly,
                      imageUrl: template.imageUrl,
                      radius: 20,
                    ),
                    title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: _buildMonsterSubtitle(template),
                    onTap: () {
                      // Clic sur un monstre du dossier -> Ouvre sa fiche
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => CreatureDetailSheet(template: template),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                      tooltip: 'Retirer du dossier',
                      onPressed: () => colProd.removeMonsterFromCollection(collection, template.id!),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ── 💬 Boîtes de dialogue ───────────────────────────

  void _showCreateCollectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom du dossier (ex: Scénario 1)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<CollectionProvider>().createCollection(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionDialog(BuildContext context, CharacterTemplate template) {
    showDialog(
      context: context,
      builder: (context) {
        final collections = context.watch<CollectionProvider>().collections;
        return AlertDialog(
          title: Text('Ajouter "${template.name}" à :'),
          content: collections.isEmpty
              ? const Text('Aucune collection existante. Créez-en une d\'abord.')
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final col = collections[index];
                final alreadyIn = col.templates.any((t) => t.id == template.id);

                return ListTile(
                  leading: Icon(Icons.folder, color: alreadyIn ? Colors.grey : Colors.amber),
                  title: Text(col.name),
                  trailing: alreadyIn ? const Icon(Icons.check, color: Colors.green) : null,
                  enabled: !alreadyIn,
                  onTap: () {
                    context.read<CollectionProvider>().addMonsterToCollection(col, template);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ajouté à la collection ${col.name}')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ],
        );
      },
    );
  }

  void _showImportCollectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer une Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Coller l\'UUID de partage'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final uuid = controller.text.trim();
              if (uuid.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Téléchargement...')));
                final success = await context.read<CollectionProvider>().importCollectionFromShare(uuid);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Importé avec succès ! 🎉' : 'Erreur d\'importation.')),
                );
              }
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShareCollection(BuildContext context, CreatureCollection collection) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter avec votre compte Cloud/Google pour partager.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mise à jour sur le Cloud...')));
    final uuidResult = await context.read<CollectionProvider>().shareCollection(collection, token);

    if (uuidResult != null && !uuidResult.contains('Erreur')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Collection partagée ! 🚀'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transmettez cet identifiant. Un autre MJ pourra l\'importer en un clic :'),
              const SizedBox(height: 12),
              // 💡 AJOUT : Conteneur propre avec Bouton de copie
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        uuidResult,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      tooltip: 'Copier',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: uuidResult));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📋 Code copié dans le presse-papiers !')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok'))],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uuidResult ?? 'Échec du partage.')));
    }
  }

  Future<void> _handleUnshareCollection(BuildContext context, CreatureCollection collection) async {
    // 1. Petite sécurité : demander confirmation pour éviter les clics accidentels
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer du Cloud ?'),
        content: const Text('Cette collection ne sera plus accessible pour les autres MJ. Elle restera intacte sur ton téléphone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Authentification et envoi de l'ordre
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour gérer le cloud.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suppression du cloud en cours...')));

    final errorResult = await context.read<CollectionProvider>().unshareCollection(collection.syncUuid, token);

    // 3. Résultat
    if (errorResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('☁️❌ Collection retirée du cloud avec succès !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorResult)),
      );
    }
  }
  Widget _buildMonsterSubtitle(CharacterTemplate template) {
    // Formatage intelligent du NC (conserve ton réglage précédent)
    String formatNc(double nc) {
      if (nc == 0.5) return '1/2';
      if (nc == 0.25) return '1/4';
      if (nc % 1 == 0) return nc.toInt().toString();
      return nc.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 💡 Aligne tout à gauche
        children: [
          // 1ère ligne : Les icônes de statistiques
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (template.nc != null)
                _buildStatIcon(Icons.star_border, formatNc(template.nc!), Colors.amber),
              _buildStatIcon(Icons.favorite, '${template.maxHp}', Colors.red),
              _buildStatIcon(Icons.shield, '${template.def}', Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 4), // 💡 Petit espace entre les stats et le type

          // 2ème ligne : Le type de créature à la ligne
          Text(
            template.creatureType.label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String value, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}