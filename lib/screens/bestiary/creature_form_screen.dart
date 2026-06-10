import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/character_template.dart';
import '../../providers/bestiary_provider.dart';

class CreatureFormScreen extends StatefulWidget {
  final CharacterTemplate? templateToEdit;

  const CreatureFormScreen({super.key, this.templateToEdit});

  @override
  State<CreatureFormScreen> createState() => _CreatureFormScreenState();
}

class _CreatureFormScreenState extends State<CreatureFormScreen> {
  // ── ONGLET 1 : GÉNÉRAL ──
  late TextEditingController _nameCtrl;
  late TextEditingController _initCtrl;
  late TextEditingController _hpCtrl;
  late TextEditingController _defCtrl;
  late TextEditingController _ncCtrl;

  bool _isAlly = false;
  CreatureType _selectedType = CreatureType.nonVivant;
  CreatureTaille _selectedTaille = CreatureTaille.moyenne;
  CreatureArchetype _selectedArchetype = CreatureArchetype.standard;

  // ── ONGLET 2 : STATS ──
  late TextEditingController _forCtrl, _agiCtrl, _conCtrl, _intCtrl, _perCtrl, _chaCtrl, _volCtrl;
  Set<String> _superiorStats = {};

  // ── ONGLETS 3 & 4 : ATTAQUES ET CAPACITÉS ──
  List<TemplateAttack> _attacks = [];
  List<TemplateCapacity> _capacities = [];

  @override
  void initState() {
    super.initState();
    final t = widget.templateToEdit;

    // Initialisation Général
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _initCtrl = TextEditingController(text: '${t?.baseInitiative ?? 10}');
    _hpCtrl = TextEditingController(text: '${t?.maxHp ?? 10}');
    _defCtrl = TextEditingController(text: '${t?.def ?? 10}');
    _ncCtrl = TextEditingController(text: t?.nc != null ? '${t!.nc}' : '');

    if (t != null) {
      _isAlly = t.isAlly;
      _selectedType = t.creatureType;
      _selectedTaille = t.taille;
      _selectedArchetype = t.archetype;
    }

    // Initialisation Stats
    _forCtrl = TextEditingController(text: '${t?.forVal ?? 10}');
    _agiCtrl = TextEditingController(text: '${t?.agiVal ?? 10}');
    _conCtrl = TextEditingController(text: '${t?.conVal ?? 10}');
    _intCtrl = TextEditingController(text: '${t?.intVal ?? 10}');
    _perCtrl = TextEditingController(text: '${t?.perVal ?? 10}');
    _chaCtrl = TextEditingController(text: '${t?.chaVal ?? 10}');
    _volCtrl = TextEditingController(text: '${t?.volVal ?? 10}');
    _superiorStats = Set.from(t?.superiorStats ?? {});

    // Initialisation Attaques & Capacités
    _attacks = List.from(t?.attacks ?? []);
    _capacities = List.from(t?.capacities ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _initCtrl.dispose(); _hpCtrl.dispose(); _defCtrl.dispose(); _ncCtrl.dispose();
    _forCtrl.dispose(); _agiCtrl.dispose(); _conCtrl.dispose(); _intCtrl.dispose(); _perCtrl.dispose(); _chaCtrl.dispose(); _volCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(widget.templateToEdit == null ? 'Créer une créature' : 'Modifier la créature'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.redAccent,
            tabs: [Tab(text: 'Général'), Tab(text: 'Stats'), Tab(text: 'Attaques'), Tab(text: 'Capacités')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTab(),
            _buildStatsTab(),
            _buildAttacksTab(),
            _buildCapacitiesTab(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _saveCreature,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  // ── ONGLET 1 : GÉNÉRAL ──
  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isAlly = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isAlly ? Colors.grey.shade800 : Colors.transparent,
                    border: Border.all(color: _isAlly ? Colors.transparent : Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.person, color: Colors.grey, size: 18), SizedBox(width: 8), Text('Aventurier', style: TextStyle(color: Colors.grey))]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isAlly = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isAlly ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.transparent,
                    border: Border.all(color: !_isAlly ? Colors.red.shade700 : Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.dangerous, color: !_isAlly ? Colors.redAccent : Colors.grey, size: 18), const SizedBox(width: 8), Text('Ennemi', style: TextStyle(color: !_isAlly ? Colors.redAccent : Colors.grey))]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextField('Nom', _nameCtrl, icon: Icons.badge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Initiative', _initCtrl, icon: Icons.bolt, isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('PV max', _hpCtrl, icon: Icons.favorite, isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('DEF', _defCtrl, icon: Icons.shield, isNumber: true)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('NC (Niveau de Danger) — optionnel', _ncCtrl, icon: Icons.star_border, isNumber: true),
        const SizedBox(height: 16),
        _buildDropdown<CreatureType>('Type', _selectedType, CreatureType.values, (e) => e.label, (v) => setState(() => _selectedType = v!)),
        const SizedBox(height: 12),
        _buildDropdown<CreatureTaille>('Taille', _selectedTaille, CreatureTaille.values, (e) => e.label, (v) => setState(() => _selectedTaille = v!)),
        const SizedBox(height: 12),
        _buildDropdown<CreatureArchetype>('Archétype', _selectedArchetype, CreatureArchetype.values, (e) => e.label, (v) => setState(() => _selectedArchetype = v!)),
      ],
    );
  }

  // ── ONGLET 2 : STATS ──
  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('Valeur de base  •  ⭐ = Supérieure (dé bonus, garde le meilleur)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        _buildStatRow('for', 'FOR', _forCtrl),
        _buildStatRow('agi', 'AGI', _agiCtrl),
        _buildStatRow('con', 'CON', _conCtrl),
        _buildStatRow('int', 'INT', _intCtrl),
        _buildStatRow('per', 'PER', _perCtrl),
        _buildStatRow('cha', 'CHA', _chaCtrl),
        _buildStatRow('vol', 'VOL', _volCtrl),
      ],
    );
  }

  Widget _buildStatRow(String statKey, String label, TextEditingController ctrl) {
    final isSuperior = _superiorStats.contains(statKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 16))),
          SizedBox(
            width: 70,
            child: TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => isSuperior ? _superiorStats.remove(statKey) : _superiorStats.add(statKey)),
            icon: Icon(Icons.star, color: isSuperior ? Colors.amber : Colors.grey, size: 18),
            label: Text('Supérieure', style: TextStyle(color: isSuperior ? Colors.amber : Colors.grey)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isSuperior ? Colors.amber : Colors.grey.shade800),
              backgroundColor: isSuperior ? Colors.amber.withValues(alpha: 0.1) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  // ── ONGLET 3 : ATTAQUES ──
  Widget _buildAttacksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: () => _showAttackDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une attaque'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        ..._attacks.asMap().entries.map((entry) {
          final idx = entry.key;
          final atk = entry.value;
          return Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(atk.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Atk +${atk.bonusAtk} • DM ${atk.dm}\n${atk.additionalEffect}', style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => setState(() => _attacks.removeAt(idx)),
              ),
              onTap: () => _showAttackDialog(attack: atk, index: idx),
            ),
          );
        }),
      ],
    );
  }

  // ── ONGLET 4 : CAPACITÉS ──
  // ── ONGLET 4 : CAPACITÉS ──
  Widget _buildCapacitiesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: () => _showCapacityDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une capacité'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        ..._capacities.asMap().entries.map((entry) {
          final idx = entry.key;
          final cap = entry.value;

          // 💡 FIX 1 : On nettoie les anciens crochets potentiellement stockés en base,
          // puis on en remet un seul proprement autour du type d'action.
          String typeStr = cap.actionType.replaceAll('[', '').replaceAll(']', '').trim();
          String prefix = typeStr.isNotEmpty ? '[$typeStr] ' : '';

          return Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('$prefix${cap.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

              // 💡 FIX 2 : On supprime maxLines et overflow pour laisser le texte s'afficher entièrement
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  cap.description,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
              ),

              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => setState(() => _capacities.removeAt(idx)),
              ),
              onTap: () => _showCapacityDialog(capacity: cap, index: idx),
            ),
          );
        }),
      ],
    );
  }

  // ── DIALOGUES D'ÉDITION D'ATTAQUES ET CAPACITÉS ──
  void _showAttackDialog({TemplateAttack? attack, int? index}) {
    final nameCtrl = TextEditingController(text: attack?.name ?? '');
    final atkCtrl = TextEditingController(text: '${attack?.bonusAtk ?? 0}');
    final nbCtrl = TextEditingController(text: '${attack?.nbAttacks ?? 1}');
    final dmCtrl = TextEditingController(text: attack?.dm ?? '');
    final effectCtrl = TextEditingController(text: attack?.additionalEffect ?? '');
    final descCtrl = TextEditingController(text: attack?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(attack == null ? 'Nouvelle attaque' : 'Modifier l\'attaque', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Nom (ex: Morsure)', nameCtrl, icon: Icons.sports_martial_arts),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField('Atk (+)', atkCtrl, icon: Icons.add, isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('Nb Att.', nbCtrl, icon: Icons.repeat, isNumber: true)),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField('DM (ex: 1d6+3)', dmCtrl, icon: Icons.casino),
              const SizedBox(height: 8),
              _buildTextField('Effet secondaire (ex: Paralysie)', effectCtrl, icon: Icons.star_border),
              const SizedBox(height: 8),
              _buildTextField('Description / Portée', descCtrl, icon: Icons.description),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final newAtk = TemplateAttack(
                name: nameCtrl.text.trim(),
                bonusAtk: int.tryParse(atkCtrl.text) ?? 0,
                nbAttacks: int.tryParse(nbCtrl.text) ?? 1,
                dm: dmCtrl.text.trim(),
                additionalEffect: effectCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              setState(() {
                if (index == null) _attacks.add(newAtk);
                else _attacks[index] = newAtk;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showCapacityDialog({TemplateCapacity? capacity, int? index}) {
    final nameCtrl = TextEditingController(text: capacity?.name ?? '');
    final descCtrl = TextEditingController(text: capacity?.description ?? '');
    final dmCtrl = TextEditingController(text: capacity?.dm ?? '');

    // 💡 FIX 1 : On initialise avec une chaîne vide si aucune valeur n'existe (au lieu de 'A')
    String actionType = capacity?.actionType ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(capacity == null ? 'Nouvelle capacité' : 'Modifier la capacité', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sélecteur du type d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['A', 'M', 'L', '*'].map((type) {
                        final isSelected = actionType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: Colors.redAccent,
                          backgroundColor: Colors.grey.shade800,

                          // 💡 FIX 2 : Si val est vrai, on sélectionne. Si val est faux (on a recliqué), on vide le choix !
                          onSelected: (val) {
                            setDialogState(() {
                              actionType = val ? type : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Nom de la capacité', nameCtrl, icon: Icons.auto_awesome),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('DM (optionnel)', dmCtrl, icon: Icons.casino),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () {
                    final newCap = TemplateCapacity(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      actionType: actionType,
                      dm: dmCtrl.text.trim(),
                    );
                    setState(() {
                      if (index == null) _capacities.add(newCap);
                      else _capacities[index] = newCap;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          }
      ),
    );
  }

  // ── COMPOSANTS UI UTILITAIRES ──
  Widget _buildTextField(String label, TextEditingController ctrl, {required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, String Function(T) getLabel, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(getLabel(e)))).toList(),
      onChanged: onChanged,
    );
  }

  // ── SAUVEGARDE FINALE ──
  void _saveCreature() {
    final template = CharacterTemplate(
      id: widget.templateToEdit?.id,
      name: _nameCtrl.text.trim().isEmpty ? 'Sans nom' : _nameCtrl.text.trim(),
      isAlly: _isAlly,
      baseInitiative: int.tryParse(_initCtrl.text) ?? 10,
      maxHp: int.tryParse(_hpCtrl.text) ?? 10,
      def: int.tryParse(_defCtrl.text) ?? 10,
      nc: double.tryParse(_ncCtrl.text),
      creatureType: _selectedType,
      taille: _selectedTaille,
      archetype: _selectedArchetype,
      forVal: int.tryParse(_forCtrl.text) ?? 10,
      agiVal: int.tryParse(_agiCtrl.text) ?? 10,
      conVal: int.tryParse(_conCtrl.text) ?? 10,
      intVal: int.tryParse(_intCtrl.text) ?? 10,
      perVal: int.tryParse(_perCtrl.text) ?? 10,
      chaVal: int.tryParse(_chaCtrl.text) ?? 10,
      volVal: int.tryParse(_volCtrl.text) ?? 10,
      superiorStats: _superiorStats,
      attacks: _attacks,
      capacities: _capacities,
    );

    if (template.id == null) {
      context.read<BestiaryProvider>().addTemplate(template);
    } else {
      context.read<BestiaryProvider>().updateTemplate(template);
    }
    Navigator.pop(context);
  }
}