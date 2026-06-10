import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/collection_provider.dart';
import '../../app_theme.dart';
import '../../models/character_sheet.dart';
import '../../models/character_template.dart';
import '../../models/combat_session.dart';
import '../../models/participant.dart';
import '../../providers/bestiary_provider.dart';
import '../../providers/character_sheet_provider.dart';
import '../../providers/combat_provider.dart';
import '../../widgets/dice_roller_sheet.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/participant_avatar.dart';
import '../bestiary/widgets/creature_detail_sheet.dart';
import '../combat/combat_screen.dart';

class SessionScreen extends StatefulWidget {
  final CombatSession session;

  const SessionScreen({super.key, required this.session});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CombatProvider>().loadParticipants(widget.session.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dans session_screen.dart, pour l'affichage :
    final int sessionId = widget.session.id ?? 0;
    // On utilise les premières lettres du nom de la session + l'ID pour créer un code unique par défaut
    final String prefix = widget.session.name.length >= 3
        ? widget.session.name.substring(0, 3).toUpperCase()
        : 'TAB';
    final String shortCode = widget.session.shareCode.toUpperCase();

    return Scaffold(
      endDrawer: const DiceRollerDrawer(),
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.session.name),
            Text(
              'Code Table : $shortCode',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.purpleAccent, // Corrigé avec une couleur standard de Flutter
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Text('🎲', style: TextStyle(fontSize: 20)),
              tooltip: 'Lancer des dés',
              onPressed: () => showDiceRollerSheet(ctx),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddParticipantSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
      body: Consumer<CombatProvider>(
        builder: (context, provider, _) {
          final participants = provider.participants;

          if (participants.isEmpty) {
            return _buildEmptyState(context);
          }

          final allies =
          participants.where((p) => p.isAlly).toList();
          final enemies =
          participants.where((p) => !p.isAlly).toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // 📢 BANDEAU DE PARTAGE RAPIDE POUR LE MJ
                    Card(
                      color: Colors.purple.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.share_rounded, color: Colors.purpleAccent),
                        title: const Text(
                          'Partage d\'écran spectateur actif',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Donnez ce code à vos joueurs : $shortCode',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.purpleAccent),
                          tooltip: 'Copier le code',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shortCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📋 Code $shortCode copié dans le presse-papiers !'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (allies.isNotEmpty) ...[
                      _sectionHeader(context, 'Aventuriers',
                          AppColors.allyPrimary, Icons.person),
                      const SizedBox(height: 8),
                      ...allies.map((p) => _participantTile(context, p, provider)),
                      const SizedBox(height: 16),
                    ],
                    if (enemies.isNotEmpty) ...[
                      _sectionHeader(context, 'Ennemis',
                          AppColors.enemyPrimary, Icons.dangerous),
                      const SizedBox(height: 8),
                      ...enemies.map((p) => _participantTile(context, p, provider)),
                    ],
                  ],
                ),
              ),
              _buildStartCombatButton(context, provider, participants),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _participantTile(
      BuildContext context, Participant p, CombatProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(p.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => provider.removeParticipant(p.id!),
        child: Card(
          child: ListTile(
            leading: ParticipantAvatar(
              name: p.name,
              isAlly: p.isAlly,
              imageUrl: p.imageUrl,
            ),
            title: Text(p.name,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              'Init: ${p.baseInitiative}  •  PV: ${p.maxHp}  •  DEF: ${p.def}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Icon(Icons.drag_handle, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildStartCombatButton(
      BuildContext context, CombatProvider provider, List<Participant> participants) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: participants.isEmpty
                ? null
                : () {
                    provider.rollInitiative();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CombatScreen(sessionName: widget.session.name),
                      ),
                    );
                  },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lancer le combat'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            'Aucun participant',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des aventuriers et des ennemis',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showAddParticipantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddParticipantSheet(sessionId: widget.session.id!),
    );
  }
}

class AddParticipantSheet extends StatefulWidget {
  final int sessionId;
  const AddParticipantSheet({super.key, required this.sessionId});

  @override
  State<AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<AddParticipantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _initCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _defCtrl = TextEditingController(text: '10');
  bool _isAlly = true;
  int _quantity = 1;
  String? _imageUrl;
  int? _selectedTemplateId;
  int? _selectedCharacterSheetId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _initCtrl.dispose();
    _hpCtrl.dispose();
    _defCtrl.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; //
    final allyColor = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary; //

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset), //
      child: Form(
        key: _formKey, //
        // 💡 RENDRE LE FORMULAIRE SCROLLABLE POUR ÉVITER L'OVERFLOW AVEC LE CLAVIER
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, //
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, //
                children: [
                  Text('Ajouter un participant',
                      style: Theme.of(context).textTheme.titleLarge), //
                  IconButton(
                    onPressed: () => Navigator.pop(context), //
                    icon: const Icon(Icons.close), //
                  ),
                ],
              ),
              const SizedBox(height: 8), //
              // Bouton Personnages
              OutlinedButton.icon(
                onPressed: () => _pickFromCharacters(context), //
                icon: const Icon(Icons.person_pin, size: 18), //
                label: const Text('Depuis les personnages'), //
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40), //
                  side: BorderSide(
                      color: AppColors.allyPrimary.withValues(alpha: 0.6)), //
                  foregroundColor: AppColors.allyPrimary, //
                ),
              ),
              const SizedBox(height: 8), //
              // Bouton Bestiaire
              OutlinedButton.icon(
                onPressed: () => _pickFromBestiary(context), //
                icon: const Icon(Icons.auto_fix_high, size: 18), //
                label: const Text('Piocher dans le bestiaire'), //
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40), //
                  side: BorderSide(
                      color: const Color(0xFFCF6679).withValues(alpha: 0.6)), //
                  foregroundColor: const Color(0xFFCF6679), //
                ),
              ),
              const SizedBox(height: 16), //
              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: _typeButton(
                      label: 'Aventurier', //
                      icon: Icons.person, //
                      selected: _isAlly, //
                      color: AppColors.allyPrimary, //
                      onTap: () => setState(() => _isAlly = true), //
                    ),
                  ),
                  const SizedBox(width: 10), //
                  Expanded(
                    child: _typeButton(
                      label: 'Ennemi', //
                      icon: Icons.dangerous, //
                      selected: !_isAlly, //
                      color: AppColors.enemyPrimary, //
                      onTap: () => setState(() => _isAlly = false), //
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), //
              TextFormField(
                controller: _nameCtrl, //
                autofocus: true, //
                decoration: const InputDecoration(
                  labelText: 'Nom du personnage',
                  prefixIcon: Icon(Icons.badge), //
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requis' : null, //
              ),
              const SizedBox(height: 12), //
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _initCtrl, //
                      keyboardType: TextInputType.number, //
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], //
                      decoration: const InputDecoration(
                        labelText: 'Initiative de base',
                        prefixIcon: Icon(Icons.bolt), //
                      ),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null, //
                    ),
                  ),
                  const SizedBox(width: 12), //
                  Expanded(
                    child: TextFormField(
                      controller: _hpCtrl, //
                      keyboardType: TextInputType.number, //
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], //
                      decoration: const InputDecoration(
                        labelText: 'PV max',
                        prefixIcon: Icon(Icons.favorite), //
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis'; //
                        if (int.tryParse(v) == null || int.parse(v) <= 0) { //
                          return '> 0'; //
                        }
                        return null; //
                      },
                    ),
                  ),
                  const SizedBox(width: 12), //
                  Expanded(
                    child: TextFormField(
                      controller: _defCtrl, //
                      keyboardType: TextInputType.number, //
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], //
                      decoration: const InputDecoration(
                        labelText: 'DEF',
                        prefixIcon: Icon(Icons.shield_outlined), //
                      ),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null, //
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), //
              // Image picker
              ImagePickerField(
                initialUrl: _imageUrl, //
                participantName: _nameCtrl.text.isNotEmpty //
                    ? _nameCtrl.text //
                    : (_isAlly ? 'A' : 'E'), //
                isAlly: _isAlly, //
                onChanged: (url) => setState(() => _imageUrl = url), //
              ),
              const SizedBox(height: 16), //
              // Quantity selector
              Row(
                children: [
                  Text('Quantité', style: Theme.of(context).textTheme.bodyMedium), //
                  const Spacer(), //
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant, //
                      borderRadius: BorderRadius.circular(10), //
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1 //
                              ? () => setState(() => _quantity--) //
                              : null,
                          icon: const Icon(Icons.remove, size: 18), //
                          padding: const EdgeInsets.all(6), //
                          constraints: const BoxConstraints(), //
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$_quantity', //
                            textAlign: TextAlign.center, //
                            style: Theme.of(context).textTheme.titleMedium, //
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < 20 //
                              ? () => setState(() => _quantity++) //
                              : null,
                          icon: const Icon(Icons.add, size: 18), //
                          padding: const EdgeInsets.all(6), //
                          constraints: const BoxConstraints(), //
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), //
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit, //
                  icon: const Icon(Icons.add, color: Colors.white), //
                  label: Text(_quantity > 1 //
                      ? 'Ajouter $_quantity ${_isAlly ? 'aventuriers' : 'ennemis'}' //
                      : 'Ajouter l\'${_isAlly ? 'aventurier' : 'ennemi'}'), //
                  style: FilledButton.styleFrom(
                    backgroundColor: allyColor, //
                    padding: const EdgeInsets.symmetric(vertical: 14), //
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final maxHp = int.tryParse(_hpCtrl.text) ?? 1;
    final baseName = _nameCtrl.text.trim();
    final provider = context.read<CombatProvider>();

    for (int i = 1; i <= _quantity; i++) {
      final name = _quantity > 1 ? '$baseName $i' : baseName;
      provider.addParticipant(Participant(
        sessionId: widget.sessionId,
        name: name,
        isAlly: _isAlly,
        baseInitiative: int.tryParse(_initCtrl.text) ?? 0,
        maxHp: maxHp,
        currentHp: maxHp,
        def: int.tryParse(_defCtrl.text) ?? 10,
        imageUrl: _imageUrl,
        templateId: _selectedTemplateId,
        characterSheetId: _selectedCharacterSheetId,
      ));
    }
    Navigator.pop(context);
  }

  Future<void> _pickFromBestiary(BuildContext context) async {
    final bestiaryProvider = context.read<BestiaryProvider>();
    if (bestiaryProvider.templates.isEmpty) {
      await bestiaryProvider.loadTemplates();
    }

    if (!context.mounted) return;

    final templates = bestiaryProvider.templates;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le bestiaire est vide.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<CharacterTemplate>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BestiaryPickerSheet(templates: templates),
    );

    if (selected != null) {
      setState(() {
        _nameCtrl.text = selected.name;
        _initCtrl.text = '${selected.baseInitiative}';
        _hpCtrl.text = '${selected.maxHp}';
        _defCtrl.text = '${selected.def}';
        _isAlly = selected.isAlly;
        _imageUrl = selected.imageUrl;
        _selectedTemplateId = selected.id;
        _selectedCharacterSheetId = null;
      });
    }
  }

  Future<void> _pickFromCharacters(BuildContext context) async {
    final sheetProvider = context.read<CharacterSheetProvider>();
    if (sheetProvider.sheets.isEmpty) {
      await sheetProvider.loadSheets();
    }

    if (!context.mounted) return;

    final sheets = sheetProvider.sheets;
    if (sheets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun personnage créé.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<CharacterSheet>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CharacterPickerSheet(sheets: sheets),
    );

    if (selected != null) {
      setState(() {
        _nameCtrl.text = selected.name;
        _initCtrl.text = '${selected.initTotal}';
        _hpCtrl.text = '${selected.pvMax}';
        _defCtrl.text = '${selected.defTotal}';
        _isAlly = true;
        _selectedCharacterSheetId = selected.id;
        _selectedTemplateId = null;
      });
    }
  }
}
class _BestiaryPickerSheet extends StatefulWidget {
  final List<CharacterTemplate> templates;
  const _BestiaryPickerSheet({required this.templates});

  @override
  State<_BestiaryPickerSheet> createState() => _BestiaryPickerSheetState();
}

class _BestiaryPickerSheetState extends State<_BestiaryPickerSheet> {
  String _search = '';
  int? _selectedCollectionId; // 💡 Stocke la collection sélectionnée (null = Tout le bestiaire)

  @override
  Widget build(BuildContext context) {
    // 1. Récupération des dossiers/collections disponibles
    final collections = context.watch<CollectionProvider>().collections;

    // 2. Filtrage : On prend soit tous les monstres, soit uniquement ceux de la collection sélectionnée
    List<CharacterTemplate> poolSource = widget.templates;
    if (_selectedCollectionId != null) {
      final activeCol = collections.firstWhere((c) => c.id == _selectedCollectionId);
      poolSource = activeCol.templates;
    }

    // 3. Application de la barre de recherche textuelle
    final filtered = poolSource
        .where((t) => t.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Choisir dans le bestiaire', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 📂 AJOUT : Menu déroulant pour filtrer par dossier / collection
            DropdownButtonFormField<int?>(
              value: _selectedCollectionId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.folder, color: Colors.amber),
                labelText: 'Filtrer par Collection / Dossier',
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('🌐 Tout le Bestiaire global')),
                ...collections.map((col) => DropdownMenuItem<int?>(
                  value: col.id,
                  child: Text('📂 ${col.name} (${col.templates.length})'),
                )),
              ],
              onChanged: (id) => setState(() => _selectedCollectionId = id),
            ),
            const SizedBox(height: 10),

            TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Rechercher un monstre…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * (keyboardOpen ? 0.25 : 0.40),
              ),
              child: filtered.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucune créature trouvée dans ce dossier'),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final t = filtered[i];
                  return Card(
                    child: ListTile(
                      leading: ParticipantAvatar(
                        name: t.name,
                        isAlly: t.isAlly,
                        imageUrl: t.imageUrl,
                        radius: 20,
                      ),
                      title: Text(t.name, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        [
                          'Init: ${t.baseInitiative}',
                          'PV: ${t.maxHp}',
                          'DEF: ${t.def}',
                          if (t.nc != null) 'NC ${t.nc}',
                        ].join('  •  '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppColors.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => CreatureDetailSheet(template: t),
                          );
                        },
                      ),
                      onTap: () => Navigator.pop(ctx, t),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterPickerSheet extends StatefulWidget {
  final List<CharacterSheet> sheets;
  const _CharacterPickerSheet({required this.sheets});

  @override
  State<_CharacterPickerSheet> createState() => _CharacterPickerSheetState();
}

class _CharacterPickerSheetState extends State<_CharacterPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.sheets
        .where((s) => s.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    // 💡 Détection de la hauteur prise par le clavier
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SingleChildScrollView( // 🔗 1. Ajout du ScrollView global
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Choisir un personnage',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                // 🔗 2. Hauteur dynamique : 30% si le clavier est sorti, 45% s'il est caché
                maxHeight: MediaQuery.of(context).size.height * (keyboardOpen ? 0.30 : 0.45),
              ),
              child: filtered.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucun résultat'),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final s = filtered[i];
                  return Card(
                    child: ListTile(
                      leading: ParticipantAvatar(
                        name: s.name,
                        isAlly: true,
                        radius: 20,
                      ),
                      title: Text(s.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        'Niv. ${s.level}  •  ${s.profile.isNotEmpty ? s.profile : 'Sans profil'}  •  Init: ${s.initTotal}  •  PV: ${s.pvMax}  •  DEF: ${s.defTotal}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => Navigator.pop(ctx, s),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
