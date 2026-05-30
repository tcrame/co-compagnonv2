import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../constants/cof2_data.dart';
import '../../constants/voies_data.dart';
import '../../models/character_sheet.dart';
import '../../models/combat_armor.dart';
import '../../models/combat_capacity.dart';
import '../../models/combat_weapon.dart';
import '../../models/inventory_item.dart';
import '../../models/item_effect.dart';
import '../../providers/character_sheet_provider.dart';
import '../../services/database_service.dart';

class CharacterSheetScreen extends StatefulWidget {
  final int sheetId;
  const CharacterSheetScreen({super.key, required this.sheetId});

  @override
  State<CharacterSheetScreen> createState() => _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends State<CharacterSheetScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  CharacterSheet? _sheet;
  bool _dirty = false;
  bool _saving = false;
  Timer? _saveTimer;

  // Key to allow reload of combat tab after voie rang changes
  final GlobalKey<_CombatTabState> _combatTabKey = GlobalKey<_CombatTabState>();

  // Dice roll log (in-memory, most recent first)
  final List<DiceLogEntry> _diceLog = [];

  // En-tête controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _levelCtrl;

  // Dropdown values
  String? _selectedPeuple;
  String? _selectedProfil;

  // Notes controllers
  late TextEditingController _descCtrl;
  late TextEditingController _combatCtrl;
  late TextEditingController _voiesCtrl;
  late TextEditingController _effetsCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSheet());
  }

  void _loadSheet() {
    final provider = context.read<CharacterSheetProvider>();
    final sheets = provider.sheets;
    final idx = sheets.indexWhere((s) => s.id == widget.sheetId);
    if (idx < 0) { Navigator.of(context).pop(); return; }
    final sheet = sheets[idx];
    _initControllers(sheet);
    setState(() => _sheet = sheet);
    if (sheet.id != null) {
      provider.loadVoieRangs(sheet.id!);
    }
  }

  Future<void> _onProfilChanged(String? newProfil) async {
    if (newProfil == null || _sheet == null) return;
    final sheetId = _sheet!.id;
    if (sheetId == null) return;

    final provider = context.read<CharacterSheetProvider>();
    final hasRangs = await provider.hasAnyRangUnlocked(sheetId);

    if (hasRangs && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Changer de profil ?'),
          content: const Text(
            'Changer de profil réinitialisera tous les rangs de voies débloqués. '
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _selectedProfil = newProfil;
      _sheet = _sheet!.copyWith(profile: newProfil);
    });
    _markDirty();
    await provider.initVoiesForProfil(sheetId, newProfil);
    _syncPmBase();
    _combatTabKey.currentState?.reload();
  }

  /// Auto-calcule pmBase = capacités magiques débloquées + VOL et met à jour la fiche.
  void _syncPmBase() {
    final id = _sheet?.id;
    if (id == null) return;
    final provider = context.read<CharacterSheetProvider>();
    final magicCount = provider.getMagicCapacitesCount(id);
    final newPmBase = magicCount + (_sheet!.volTotal);
    if (_sheet!.pmBase != newPmBase) {
      setState(() => _sheet = _sheet!.copyWith(pmBase: newPmBase));
      _markDirty();
    }
  }

  void _initControllers(CharacterSheet sheet) {
    _nameCtrl = TextEditingController(text: sheet.name);
    _levelCtrl = TextEditingController(text: sheet.level.toString());
    _selectedPeuple = sheet.race.isEmpty ? null : sheet.race;
    _selectedProfil = sheet.profile.isEmpty ? null : sheet.profile;
    _descCtrl = TextEditingController(text: sheet.description);
    _combatCtrl = TextEditingController(text: sheet.notesCombat);
    _voiesCtrl = TextEditingController(text: sheet.notesVoies);
    _effetsCtrl = TextEditingController(text: sheet.notesEffets);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _tabController.dispose();
    _nameCtrl.dispose();
    _levelCtrl.dispose();
    _descCtrl.dispose();
    _combatCtrl.dispose();
    _voiesCtrl.dispose();
    _effetsCtrl.dispose();
    super.dispose();
  }

  CharacterSheet _buildCurrentSheet() {
    return _sheet!.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? _sheet!.name : _nameCtrl.text.trim(),
      level: _sheet!.level, // géré via Level Up uniquement
      race: _selectedPeuple ?? '',
      profile: _selectedProfil ?? '',
      description: _descCtrl.text,
      notesCombat: _combatCtrl.text,
      notesVoies: _voiesCtrl.text,
      notesEffets: _effetsCtrl.text,
    );
  }

  Future<void> _save({bool silent = false}) async {
    if (_sheet == null) return;
    final updated = _buildCurrentSheet();
    await context.read<CharacterSheetProvider>().saveSheet(updated);
    if (!mounted) return;
    setState(() {
      _sheet = updated;
      _dirty = false;
      _saving = false;
    });
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiche sauvegardée'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _scheduleSave() {
    setState(() {
      _dirty = true;
      _saving = true;
    });
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _save(silent: true);
    });
  }

  void _markDirty() => _scheduleSave();

  void _confirmLevelUp() {
    if (_sheet == null) return;
    final nextLevel = (_sheet!.level + 1).clamp(1, 20);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Text('⭐ ', style: TextStyle(fontSize: 20)),
          Text('Monter de niveau ?'),
        ]),
        content: Text(
          '${_sheet!.name} va passer au niveau $nextLevel.\n\nConfirmes-tu la montée de niveau ?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton.icon(
            icon: const Text('⭐', style: TextStyle(fontSize: 14)),
            label: Text('Niveau $nextLevel !'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) _doLevelUp();
    });
  }

  void _doLevelDown() {
    if (_sheet == null || _sheet!.level <= 1) return;
    final downLevel = _sheet!.level - 1;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.arrow_downward, color: Colors.grey[500], size: 20),
          const SizedBox(width: 8),
          const Text('Rétrograder ?'),
        ]),
        content: Text(
          '${_sheet!.name} va repasser au niveau $downLevel.\n\nCette action est irréversible. Confirmes-tu la rétrogradation ?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          OutlinedButton.icon(
            icon: Icon(Icons.arrow_downward, size: 16, color: Colors.grey[600]),
            label: Text('Niveau $downLevel',
                style: TextStyle(color: Colors.grey[600])),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted || _sheet == null) return;
      final leveled = _sheet!.copyWith(
        level: downLevel,
        pointsCompetence: (_sheet!.pointsCompetence - 2).clamp(0, 999),
      );
      setState(() => _sheet = leveled.copyWith(
        pvActuel: leveled.pvMax,
        pmActuel: leveled.pmMax,
        drActuel: leveled.drMax,
        pcActuel: leveled.pcMax,
      ));
      _markDirty();
    });
  }

  void _doLevelUp() {
    if (_sheet == null) return;
    final old = _sheet!;
    final newLevel = (old.level + 1).clamp(1, 20);
    final leveled = old.copyWith(level: newLevel);
    // Gains
    final pvGain    = leveled.pvMax - old.pvMax;
    final oldAttC   = old.attContactTotal;
    final oldAttD   = old.attDistanceTotal;
    final oldAttM   = old.attMagiqueTotal;
    final totalPcOld = old.level * 2;
    final totalPcNew = newLevel * 2;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Text('⭐ ', style: TextStyle(fontSize: 22)),
          Expanded(
            child: Text(
              '${old.name} — Niveau $newLevel !',
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Félicitations ! Voici ce que tu gagnes :',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.onSurfaceMuted)),
              const SizedBox(height: 14),
              // PV
              _levelUpRow('❤️', 'Points de vie max',
                  '${old.pvMax} → ${leveled.pvMax}',
                  '+$pvGain PV',
                  const Color(0xFFE53935)),
              const SizedBox(height: 8),
              // Attaque Contact
              _levelUpRow('⚔️', 'Attaque Contact',
                  '$oldAttC → ${oldAttC + 1}', '+1', Colors.orange),
              const SizedBox(height: 8),
              // Attaque Distance
              _levelUpRow('🏹', 'Attaque Distance',
                  '$oldAttD → ${oldAttD + 1}', '+1', Colors.orange),
              const SizedBox(height: 8),
              // Attaque Magique
              _levelUpRow('✨', 'Attaque Magique',
                  '$oldAttM → ${oldAttM + 1}', '+1',
                  const Color(0xFF6A1B9A)),
              const Divider(height: 24),
              // Points de compétence
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Text('🎓 ', style: TextStyle(fontSize: 18)),
                      Text('Points de compétence',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Niv. ${old.level} × 2 = $totalPcOld  →  Niv. $newLevel × 2 = $totalPcNew',
                      style: const TextStyle(fontSize: 12,
                          color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total disponible : $totalPcNew pts',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB300)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton.icon(
            icon: const Text('⭐', style: TextStyle(fontSize: 14)),
            label: const Text('Confirmer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      final applied = leveled.copyWith(
        pvActuel: leveled.pvMax,
        pmActuel: leveled.pmMax,
        drActuel: leveled.drMax,
        pcActuel: leveled.pcMax,
      );
      setState(() => _sheet = applied);
      _markDirty();
    });
  }

  Widget _levelUpRow(
      String emoji, String label, String range, String gain, Color color) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Text(range,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceMuted)),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(gain,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_sheet == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_nameCtrl.text.isEmpty ? 'Fiche' : _nameCtrl.text),
        centerTitle: true,
        actions: [
          // Auto-save indicator
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                ),
              ),
            )
          else if (!_dirty)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(
                child: Icon(Icons.cloud_done_outlined, size: 20, color: Colors.white54),
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.casino_outlined),
                tooltip: 'Journal des dés',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _DiceLogScreen(log: List.from(_diceLog)),
                  ),
                ),
              ),
              if (_diceLog.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.enemyPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Carac.'),
            Tab(text: 'Description'),
            Tab(text: 'Combat'),
            Tab(text: 'Inventaire'),
            Tab(text: 'Voies'),
            Tab(text: 'Effets'),
          ],
        ),
      ),
      floatingActionButton: null,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CaracTab(
                  sheet: _sheet!,
                  onChanged: _onCaracChanged,
                  onDiceRoll: _addDiceLog,
                ),
                _NotesTab(controller: _descCtrl, hint: 'Notes biographiques, apparence, personnalité…', onChanged: _markDirty),
                _CombatTab(
                  key: _combatTabKey,
                  sheetId: widget.sheetId,
                  sheet: _sheet!,
                  onSheetChanged: (s) {
                    setState(() => _sheet = s);
                    _scheduleSave();
                  },
                  onDiceRoll: _addDiceLog,
                ),
                _InventaireTab(
                  sheetId: widget.sheetId,
                  sheet: _sheet!,
                  onSheetChanged: (s) {
                    setState(() => _sheet = s);
                    _scheduleSave();
                  },
                ),
                _VoiesTab(
                  sheet: _sheet!,
                  controller: _voiesCtrl,
                  onChanged: _markDirty,
                  voieRangs: context.watch<CharacterSheetProvider>().getVoieRangs(_sheet!.id ?? 0),
                  pcDepense: context.watch<CharacterSheetProvider>().getPcDepense(_sheet!.id ?? 0),
                  onSetRang: (voieId, rang) async {
                    final id = _sheet!.id;
                    if (id != null) {
                      await context.read<CharacterSheetProvider>().setVoieRang(id, voieId, rang);
                      _syncPmBase();
                      _combatTabKey.currentState?.reload();
                    }
                  },
                ),
                _NotesTab(controller: _effetsCtrl, hint: 'Effets actifs, malédictions, bénédictions…', onChanged: _markDirty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCaracChanged(CharacterSheet updated) {
    setState(() => _sheet = updated);
    _scheduleSave();
  }

  void _addDiceLog(DiceLogEntry entry) {
    setState(() => _diceLog.insert(0, entry));
    // Also show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎲 ${entry.label} — ${entry.detail}'),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF00695C),
        action: SnackBarAction(
          label: 'Journal',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _DiceLogScreen(log: List.from(_diceLog)),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Called when peuple changes: resets racial values then shows choice dialog.
  void _onPeupleChanged(String? newPeuple) {
    final resetSheet = _sheet!.copyWith(
      race: newPeuple ?? '',
      agiRacial: 0, conRacial: 0, forRacial: 0, perRacial: 0,
      chaRacial: 0, intRacial: 0, volRacial: 0,
    );
    setState(() {
      _selectedPeuple = newPeuple;
      _sheet = resetSheet;
    });
    _scheduleSave();
    if (newPeuple != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRacialDialog(newPeuple);
      });
    }
  }

  void _showRacialDialog(String peuple) {
    final choice = getRacialChoice(peuple);
    if (choice == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RacialDialog(
        peuple: peuple,
        choice: choice,
        currentSheet: _sheet!,
        onApply: (updated) {
          _onCaracChanged(updated);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _HeaderField(
                  label: 'Nom',
                  controller: _nameCtrl,
                  onChanged: (_) => _markDirty(),
                ),
              ),
              const SizedBox(width: 8),
              // ── Niveau (read-only + menu Level Up) ─────────────────
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Niveau',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceMuted,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (_sheet == null) return;
                        if (v == 'levelup') {
                          _confirmLevelUp();
                        } else if (v == 'leveldown') {
                          _doLevelDown();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'levelup',
                          enabled: (_sheet?.level ?? 1) < 20,
                          child: const Row(children: [
                            Text('⭐ ', style: TextStyle(fontSize: 16)),
                            Text('Level Up !'),
                          ]),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'leveldown',
                          enabled: (_sheet?.level ?? 1) > 1,
                          child: Row(children: [
                            Icon(Icons.arrow_downward,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Text('Rétrograder',
                                style: TextStyle(color: Colors.grey[500])),
                          ]),
                        ),
                      ],
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_sheet?.level ?? 1}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurface),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                size: 16,
                                color: AppColors.onSurfaceMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeaderDropdown<String>(
                  label: 'Peuple',
                  value: _selectedPeuple,
                  items: kPeuples.map((p) => p.nom).toList(),
                  onChanged: _onPeupleChanged,
                  onInfo: _selectedPeuple == null
                      ? null
                      : () => _showInfoDialog(
                            context,
                            'Peuple : $_selectedPeuple',
                            getPeupleData(_selectedPeuple!)?.description ?? '',
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderDropdown<String>(
                  label: 'Profil',
                  value: _selectedProfil,
                  items: kTousProfils,
                  onChanged: (v) => _onProfilChanged(v),
                  badge: _selectedProfil != null
                      ? getFamilleForProfil(_selectedProfil!)
                      : null,
                  onInfo: _selectedProfil == null
                      ? null
                      : () {
                          final f = getFamilleData(_selectedProfil!);
                          if (f == null) return;
                          _showInfoDialog(
                            context,
                            'Famille : ${f.nom}',
                            f.description,
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header Field ──────────────────────────────────────────────────────────────

class _HeaderField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _HeaderField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0.8)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header Dropdown ───────────────────────────────────────────────────────────

class _HeaderDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? badge;
  final VoidCallback? onInfo;

  const _HeaderDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.badge,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceMuted,
                    letterSpacing: 0.8)),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.allyPrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.allyPrimary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
            if (onInfo != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onInfo,
                child: const Icon(Icons.info_outline,
                    size: 14, color: AppColors.onSurfaceMuted),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text('—',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceMuted.withValues(alpha: 0.5))),
              dropdownColor: AppColors.surface,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.onSurfaceMuted, size: 20),
              onChanged: onChanged,
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(item.toString(),
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.onSurface)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _VoiesTab extends StatelessWidget {
  final CharacterSheet sheet;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final Map<String, int> voieRangs;
  final int pcDepense;
  final Future<void> Function(String voieId, int rang) onSetRang;

  const _VoiesTab({
    required this.sheet,
    required this.controller,
    required this.onChanged,
    required this.voieRangs,
    required this.pcDepense,
    required this.onSetRang,
  });

  @override
  Widget build(BuildContext context) {
    final totalPc = sheet.level * 2;
    final remaining = totalPc - pcDepense;
    final voies = getVoiesPourProfil(sheet.profile);

    return ScrollConfiguration(
      // On web, disable mouse-drag scrolling so ListView doesn't intercept
      // taps on InkWell children (mouse wheel scrolling still works).
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.stylus},
      ),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        // ── Compteur de points de compétence ────────────────────────
        _PcCounter(
          level: sheet.level,
          totalPc: totalPc,
          pcDepense: pcDepense,
          remaining: remaining,
        ),
        const SizedBox(height: 12),

        // ── Voies du profil ──────────────────────────────────────────
        if (voies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.menu_book_outlined,
                    size: 40, color: AppColors.onSurfaceMuted),
                const SizedBox(height: 8),
                Text(
                  sheet.profile.isEmpty
                      ? 'Sélectionne un profil pour voir les voies disponibles.'
                      : 'Aucune voie trouvée pour le profil "${sheet.profile}".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.onSurfaceMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...voies.map((voie) {
            final rangActuel = voieRangs[voie.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VoieCard(
                voie: voie,
                rangActuel: rangActuel,
                pcRestants: remaining,
                profil: sheet.profile,
                niveau: sheet.level,
                onSetRang: (r) => onSetRang(voie.id, r),
              ),
            );
          }),

        const SizedBox(height: 16),

        // ── Notes libres ─────────────────────────────────────────────
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Notes libres',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceMuted),
          ),
        ),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          maxLines: 6,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: 'Capacités spéciales, notes de progression…',
            alignLabelWithHint: true,
          ),
        ),
      ],
      ),
    );
  }
}

class _PcCounter extends StatelessWidget {
  final int level;
  final int totalPc;
  final int pcDepense;
  final int remaining;

  const _PcCounter({
    required this.level,
    required this.totalPc,
    required this.pcDepense,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = remaining < 0;
    final accentColor =
        isOverBudget ? Colors.red : const Color(0xFFFFB300);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Text('🎓', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Points de compétence',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                  'Niv. $level × 2 = $totalPc pts   •   Dépensés : $pcDepense',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$remaining',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voie Card ─────────────────────────────────────────────────────────────────

/// Niveau de personnage requis pour débloquer un rang donné.
/// Rang: 1→1, 2→2, 3→3, 4→5, 5→7
int niveauRequisPourRang(int rang) {
  const Map<int, int> _requis = {1: 1, 2: 2, 3: 3, 4: 5, 5: 7};
  return _requis[rang] ?? 1;
}

Color _couleurFamille(String profil) {
  final famille = getFamilleForProfil(profil);
  switch (famille) {
    case 'Aventurier':
      return const Color(0xFF2E7D32);
    case 'Combattant':
      return const Color(0xFFC62828);
    case 'Mage':
      return const Color(0xFF1565C0);
    case 'Mystique':
      return const Color(0xFF6A1B9A);
    default:
      return AppColors.onSurfaceMuted;
  }
}

class _VoieCard extends StatefulWidget {
  final VoieCatalogue voie;
  final int rangActuel;
  final int pcRestants;
  final String profil;
  final int niveau;
  final Future<void> Function(int rang) onSetRang;

  const _VoieCard({
    required this.voie,
    required this.rangActuel,
    required this.pcRestants,
    required this.profil,
    required this.niveau,
    required this.onSetRang,
  });

  @override
  State<_VoieCard> createState() => _VoieCardState();
}

class _VoieCardState extends State<_VoieCard> {
  bool _expanded = false;
  bool _saving = false;

  /// Coût en PC pour passer du rang actuel au rang N.
  int _coutPourRang(int rang) {
    int cost = 0;
    for (int r = widget.rangActuel + 1; r <= rang; r++) {
      cost += r <= 2 ? 1 : 2;
    }
    return cost;
  }

  Future<void> _toggleRang(int rang) async {
    if (_saving) return;
    int newRang;
    if (rang == widget.rangActuel) {
      // Un-buy: decrease by one
      newRang = rang - 1;
    } else if (rang == widget.rangActuel + 1) {
      // Check level requirement
      final niveauRequis = niveauRequisPourRang(rang);
      if (widget.niveau < niveauRequis) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Niveau $niveauRequis requis pour ce rang.'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      // Check PC budget
      final cout = _coutPourRang(rang);
      if (widget.pcRestants < cout) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pas assez de points de compétence.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      newRang = rang;
    } else {
      return; // Cannot skip ranks or jump backward more than 1
    }
    setState(() => _saving = true);
    try {
      await widget.onSetRang(newRang);
    } catch (e) {
      debugPrint('[VoieCard] onSetRang error: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _couleurFamille(widget.profil);
    final rang = widget.rangActuel;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header (tappable) ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              color: color.withValues(alpha: 0.07),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.voie.nom,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color),
                    ),
                  ),
                  // Rang dots
                  Row(
                    children: List.generate(5, (i) {
                      final r = i + 1;
                      final unlocked = r <= rang;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: unlocked
                                ? color
                                : color.withValues(alpha: 0.15),
                            border: Border.all(
                              color: color.withValues(
                                  alpha: unlocked ? 1.0 : 0.35),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Body (expanded) ──────────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.voie.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        widget.voie.description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ...widget.voie.capacites.map((cap) {
                    final isUnlocked = cap.rang <= rang;
                    final isNext = cap.rang == rang + 1;
                    final coutNext = isNext ? _coutPourRang(cap.rang) : 0;
                    final niveauRequis = niveauRequisPourRang(cap.rang);
                    final levelOk = widget.niveau >= niveauRequis;
                    final canBuy =
                        isNext && levelOk && widget.pcRestants >= coutNext;

                    return _RangRow(
                      capacite: cap,
                      isUnlocked: isUnlocked,
                      isNext: isNext,
                      canBuy: canBuy,
                      levelOk: levelOk,
                      niveauRequis: niveauRequis,
                      saving: _saving,
                      accentColor: color,
                      onTap: () => _toggleRang(cap.rang),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Rang Row ──────────────────────────────────────────────────────────────────

class _RangRow extends StatelessWidget {
  final CapaciteCatalogue capacite;
  final bool isUnlocked;
  final bool isNext;
  final bool canBuy;
  final bool levelOk;
  final int niveauRequis;
  final bool saving;
  final Color accentColor;
  final VoidCallback onTap;

  const _RangRow({
    required this.capacite,
    required this.isUnlocked,
    required this.isNext,
    required this.canBuy,
    required this.levelOk,
    required this.niveauRequis,
    required this.saving,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lockedByLevel = !isUnlocked && !levelOk;
    final textColor = isUnlocked
        ? AppColors.onSurface
        : (isNext && canBuy)
            ? AppColors.onSurface.withValues(alpha: 0.75)
            : AppColors.onSurfaceMuted;

    final effectiveOnTap = (isUnlocked || (isNext && canBuy)) && !saving ? onTap : null;

    return InkWell(
      onTap: effectiveOnTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isUnlocked
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          border: isUnlocked
              ? Border.all(color: accentColor.withValues(alpha: 0.30))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rang badge
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? accentColor
                    : accentColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: isUnlocked
                      ? accentColor
                      : accentColor.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Text(
                  '${capacite.rang}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : textColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          capacite.nom,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnlocked
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (capacite.type.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: accentColor.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            capacite.type,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentColor),
                          ),
                        ),
                      if (capacite.isMagique)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFF6A1B9A).withValues(alpha: 0.18),
                          ),
                          child: const Text(
                            '✨ Sort',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C27B0)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    capacite.description,
                    style: TextStyle(fontSize: 11, color: textColor),
                  ),
                  // Level requirement badge
                  if (lockedByLevel)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_clock,
                              size: 11, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                            'Niveau $niveauRequis requis',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Unlock/lock icon
            if (isUnlocked)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.lock_open,
                    size: 14, color: accentColor),
              )
            else if (isNext && canBuy)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.add_circle_outline,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.7)),
              )
            else if (lockedByLevel)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.lock_clock,
                    size: 14, color: Colors.orange),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.lock_outline,
                    size: 14,
                    color: AppColors.onSurfaceMuted.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  const _NotesTab({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hint,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}


// ── Carac Tab ─────────────────────────────────────────────────────────────────

class _CaracTab extends StatefulWidget {
  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;
  final ValueChanged<DiceLogEntry>? onDiceRoll;

  const _CaracTab({
    required this.sheet,
    required this.onChanged,
    this.onDiceRoll,
  });

  @override
  State<_CaracTab> createState() => _CaracTabState();
}

class _CaracTabState extends State<_CaracTab> {
  late CharacterSheet _s;

  @override
  void initState() {
    super.initState();
    _s = widget.sheet;
  }

  @override
  void didUpdateWidget(_CaracTab old) {
    super.didUpdateWidget(old);
    if (old.sheet.id != widget.sheet.id) {
      setState(() => _s = widget.sheet);
    } else if (widget.sheet != old.sheet) {
      setState(() => _s = _s.copyWith(
        level: widget.sheet.level,
        race: widget.sheet.race,
        profile: widget.sheet.profile,
        agiRacial: widget.sheet.agiRacial,
        conRacial: widget.sheet.conRacial,
        forRacial: widget.sheet.forRacial,
        perRacial: widget.sheet.perRacial,
        chaRacial: widget.sheet.chaRacial,
        intRacial: widget.sheet.intRacial,
        volRacial: widget.sheet.volRacial,
        // Bonus d'équipement et encombrement mis à jour depuis l'onglet Combat
        encArmure: widget.sheet.encArmure,
        encAutre: widget.sheet.encAutre,
        equipmentBonusesJson: widget.sheet.equipmentBonusesJson,
        // PM base auto-calculé depuis les voies
        pmBase: widget.sheet.pmBase,
        pmBonus: widget.sheet.pmBonus,
        // Jauges actuel synchronisées depuis le parent (level-up, combat, etc.)
        pvActuel: widget.sheet.pvActuel,
        pmActuel: widget.sheet.pmActuel,
        drActuel: widget.sheet.drActuel,
        pcActuel: widget.sheet.pcActuel,
        pointsCompetence: widget.sheet.pointsCompetence,
      ));
    }
  }

  void _update(CharacterSheet updated) {
    setState(() => _s = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildVitaliteSection(),
        const SizedBox(height: 16),
        _buildManaSection(),
        const SizedBox(height: 16),
        _buildRecuperationSection(),
        const SizedBox(height: 16),
        _buildRessourcesSection(),
        const SizedBox(height: 16),
        _buildCaracSection(),
        const SizedBox(height: 16),
        _buildAttaqueSection(),
        const SizedBox(height: 16),
        _buildInitiativeSection(),
        const SizedBox(height: 16),
        _buildDefenseSection(),
        const SizedBox(height: 16),
        _buildEncombrementSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.0)),
    );
  }

  Widget _tableContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: child,
    );
  }

  Widget _colHeaders(List<String> labels, {double trailingWidth = 0}) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 80),
          ...labels.map((l) => Expanded(
                child: Center(
                    child: Text(l,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.w600))),
              )),
          if (trailingWidth > 0) SizedBox(width: trailingWidth),
        ],
      ),
    );
  }

  // Inline editable int field
  Widget _intCell(int value, ValueChanged<int> onChanged, {bool readOnly = false, Color? color}) {
    final ctrl = TextEditingController(text: value.toString());
    return Expanded(
      child: Center(
        child: SizedBox(
          width: 52,
          child: TextField(
            controller: ctrl,
            readOnly: readOnly,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
                color: color ?? (readOnly ? const Color(0xFFCF6679) : AppColors.onSurface)),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null) onChanged(n);
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              filled: true,
              fillColor: readOnly
                  ? AppColors.surface
                  : AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelCell(String text, {Color? bg, Color? fg}) {
    return SizedBox(
      width: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: bg,
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg ?? AppColors.onSurface)),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.surface);

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildCaracSection() {
    const caracs = [
      ('AGI', 'Agilité'),
      ('CON', 'Constitution'),
      ('FOR', 'Force'),
      ('PER', 'Perception'),
      ('CHA', 'Charisme'),
      ('INT', 'Intelligence'),
      ('VOL', 'Volonté'),
    ];

    final bases   = [_s.agiVal,    _s.conVal,    _s.forVal,    _s.perVal,    _s.chaVal,    _s.intVal,    _s.volVal];
    final peuples = [_s.agiRacial, _s.conRacial, _s.forRacial, _s.perRacial, _s.chaRacial, _s.intRacial, _s.volRacial];
    final bonuses = [_s.agiBonus,  _s.conBonus,  _s.forBonus,  _s.perBonus,  _s.chaBonus,  _s.intBonus,  _s.volBonus];
    final totals  = [_s.agiTotal,  _s.conTotal,  _s.forTotal,  _s.perTotal,  _s.chaTotal,  _s.intTotal,  _s.volTotal];

    final presetLabel = switch (_s.statPreset) {
      'polyvalent'  => 'Polyvalent',
      'expert'      => 'Expert',
      'specialiste' => 'Spécialiste',
      _             => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('CARACTÉRISTIQUES', const Color(0xFF1565C0)),
        // Preset chooser button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.tune, size: 16),
            label: Text(
              presetLabel != null
                  ? 'Série : $presetLabel  (modifier)'
                  : 'Choisir une série de répartition',
              style: const TextStyle(fontSize: 13),
            ),
            onPressed: _showPresetDialog,
          ),
        ),
        _tableContainer(
          child: Column(
            children: [
              _colHeaders(['Base', 'Peuple', 'Bonus', 'Total'], trailingWidth: 36),
              ...List.generate(caracs.length, (i) {
                final abbr  = caracs[i].$1;
                final label = caracs[i].$2;
                return Column(
                  children: [
                    if (i > 0) _divider(),
                    Row(
                      children: [
                        _labelCell(abbr),
                        _intCell(bases[i],   (_) {}, readOnly: true),
                        _intCell(peuples[i], (_) {}, readOnly: true),
                        _intCell(bonuses[i], (v) {
                          _update(_updateCaracBonus(abbr, v));
                        }),
                        _intCell(totals[i], (_) {}, readOnly: true,
                            color: totals[i] > 0
                                ? const Color(0xFF1B5E20)
                                : totals[i] < 0
                                    ? const Color(0xFFB71C1C)
                                    : null),
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            icon: const Icon(Icons.casino_outlined, size: 16),
                            tooltip: 'Test $abbr',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: widget.onDiceRoll == null ? null : () => _rollCaracTest(abbr, label, totals[i]),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showPresetDialog() async {
    final result = await showDialog<CharacterSheet>(
      context: context,
      builder: (_) => _StatPresetDialog(sheet: _s),
    );
    if (result != null) _update(result);
  }

  CharacterSheet _updateCaracBonus(String abbr, int v) {
    switch (abbr) {
      case 'AGI': return _s.copyWith(agiBonus: v);
      case 'CON': return _s.copyWith(conBonus: v);
      case 'FOR': return _s.copyWith(forBonus: v);
      case 'PER': return _s.copyWith(perBonus: v);
      case 'CHA': return _s.copyWith(chaBonus: v);
      case 'INT': return _s.copyWith(intBonus: v);
      case 'VOL': return _s.copyWith(volBonus: v);
      default:    return _s;
    }
  }

  void _rollCaracTest(String abbr, String label, int bonus) {
    final die = Random().nextInt(20) + 1;
    // Pour AGI : appliquer le malus d'encombrement
    final enc = abbr == 'AGI' ? _s.encTotal : 0;
    final effectiveBonus = bonus - enc;
    final total = die + effectiveBonus;
    final sign  = effectiveBonus >= 0 ? '+$effectiveBonus' : '$effectiveBonus';
    String detail;
    if (effectiveBonus == 0) {
      detail = 'd20 = $die';
    } else {
      detail = 'd20($die) $sign = $total';
    }
    if (enc > 0) detail += ' (ENC -$enc)';
    String lbl = 'Test $abbr';
    if (die == 20) lbl += ' 🎯 Critique !';
    if (die == 1)  lbl += ' 💀 Échec critique !';
    widget.onDiceRoll?.call(DiceLogEntry(
      die: 'd20',
      label: lbl,
      detail: detail,
      dieResult: die,
      bonus: effectiveBonus,
      total: total,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎲 $lbl — $detail'),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildAttaqueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('ATTAQUE', const Color(0xFFB71C1C)),
        _tableContainer(
          child: Column(
            children: [
              _colHeaders(['Base (Niv.+Stat)', 'Bonus', 'Malus', 'Total']),
              _attRow('CONTACT\n(Niv.+FOR)', _s.attContactBase, _s.attContactBonus,
                  _s.attContactMalus, _s.attContactTotal,
                  (bo, m) => _update(_s.copyWith(
                      attContactBonus: bo,
                      attContactMalus: m))),
              _divider(),
              _attRow('DISTANCE\n(Niv.+AGI)', _s.attDistanceBase, _s.attDistanceBonus,
                  _s.attDistanceMalus, _s.attDistanceTotal,
                  (bo, m) => _update(_s.copyWith(
                      attDistanceBonus: bo,
                      attDistanceMalus: m))),
              _divider(),
              _attRow('MAGIQUE\n(Niv.+VOL)', _s.attMagiqueBase, _s.attMagiqueBonus,
                  _s.attMagiqueMalus, _s.attMagiqueTotal,
                  (bo, m) => _update(_s.copyWith(
                      attMagiqueBonus: bo,
                      attMagiqueMalus: m))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attRow(String label, int base, int bonus, int malus, int total,
      void Function(int, int) onChanged) {
    return Row(
      children: [
        _labelCell(label),
        _intCell(base, (_) {}, readOnly: true),
        _intCell(bonus, (v) => onChanged(v, malus)),
        _intCell(malus, (v) => onChanged(bonus, v)),
        _intCell(total, (_) {}, readOnly: true),
      ],
    );
  }

  Widget _buildInitiativeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('COMBAT', const Color(0xFFE65100)),
        _tableContainer(
          child: Column(
            children: [
              _colHeaders(['Base (10+PER)', 'Bonus', 'Malus', 'Total']),
              Row(
                children: [
                  _labelCell('INIT.'),
                  _intCell(_s.initDerive, (_) {}, readOnly: true),
                  _intCell(_s.initBonus,
                      (v) => _update(_s.copyWith(initBonus: v))),
                  _intCell(_s.initMalus,
                      (v) => _update(_s.copyWith(initMalus: v))),
                  _intCell(_s.initTotal, (_) {}, readOnly: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVitaliteSection() {
    final pct      = _s.pvMax > 0 ? (_s.pvActuel / _s.pvMax).clamp(0.0, 1.0) : 0.0;
    final isDead   = _s.pvActuel <= 0;
    final barColor = pct > 0.5
        ? const Color(0xFF2E7D32)
        : pct > 0.25
            ? const Color(0xFFF57F17)
            : const Color(0xFFB71C1C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('VITALITÉ', const Color(0xFF2E7D32)),
        _tableContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Bonus PV + rappel Max ─────────────────────────────────
                Row(
                  children: [
                    const Text('Bonus PV :',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: TextEditingController(text: _s.pvBonus.toString()),
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null) _update(_s.copyWith(pvBonus: n));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Barre de vie ou "Inconscient" ─────────────────────────
                if (isDead)
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFB71C1C).withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bedtime_outlined, size: 16, color: Color(0xFFB71C1C)),
                        SizedBox(width: 6),
                        Text('Inconscient',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB71C1C))),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${_s.pvActuel} / ${_s.pvMax}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: barColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 22,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                // ── Boutons ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Blesser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB71C1C),
                          side: const BorderSide(color: Color(0xFFB71C1C)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showHpDialog(heal: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Soigner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showHpDialog(heal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showHpDialog({required bool heal}) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(heal ? 'Soigner' : 'Infliger des dégâts'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: heal ? 'Points de vie récupérés' : 'Points de dégâts',
            prefixIcon: Icon(heal ? Icons.favorite : Icons.remove_circle_outline,
                color: heal ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C)),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: heal ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? 0;
              if (v > 0) {
                final newPv = heal
                    ? (_s.pvActuel + v).clamp(0, _s.pvMax > 0 ? _s.pvMax : 9999)
                    : (_s.pvActuel - v).clamp(0, _s.pvMax > 0 ? _s.pvMax : 9999);
                _update(_s.copyWith(pvActuel: newPv.toInt()));
              }
              Navigator.of(ctx).pop();
            },
            child: Text(heal ? 'Soigner' : 'Appliquer'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecuperationSection() {
    const accentColor = Color(0xFFE53935);
    const healColor   = Color(0xFF00695C);
    final drMax    = _s.drMax.clamp(0, 20);
    final drActuel = _s.drActuel.clamp(0, drMax);
    final canRoll  = drActuel > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('RÉCUPÉRATION', healColor),
        _tableContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Bonus ──────────────────────────────────────────────
                _colHeaders(['Bonus']),
                Row(children: [
                  _labelCell('DR'),
                  _intCell(_s.drBonus, (v) => _update(_s.copyWith(drBonus: v))),
                ]),
                const SizedBox(height: 12),
                // ── Jauge de dés ───────────────────────────────────────
                if (drMax == 0)
                  const Center(
                    child: Text('Aucun DR disponible',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: List.generate(drMax, (i) {
                      final available = i < drActuel;
                      return Icon(
                        available ? Icons.casino : Icons.casino_outlined,
                        color: available
                            ? accentColor
                            : AppColors.onSurfaceMuted,
                        size: 30,
                      );
                    }),
                  ),
                const SizedBox(height: 6),
                // ── DV chip ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.onSurfaceMuted
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.casino_outlined,
                              size: 14,
                              color: AppColors.onSurfaceMuted),
                          const SizedBox(width: 4),
                          Text('DV : ${_s.dvDerive}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          const Text('+ ½ niv.',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Boutons ────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canRoll ? _rollDR : null,
                      icon: const Icon(Icons.favorite, size: 16),
                      label: const Text('Récupération rapide',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: healColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.surfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showRecuperationCompleteDialog,
                      icon: const Icon(Icons.nightlight_round, size: 16),
                      label: const Text('Récup. complète',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: const BorderSide(color: Color(0xFFE53935)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: drActuel > 0
                        ? () {
                            _update(_s.copyWith(drActuel: drActuel - 1));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '🎲 DR perdu : ${drActuel - 1} / $drMax restants'),
                              backgroundColor: Colors.grey[700],
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Perdre un DR',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(
                          color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _rollDR() {
    if (_s.drActuel <= 0) return;
    final dieMax = _s.dvMaxValue.clamp(1, 100);
    final roll = Random().nextInt(dieMax) + 1;
    final halfLevel = (_s.level.clamp(1, 100)) ~/ 2;
    final soin = roll + halfLevel;
    final pvMax = _s.pvMax > 0 ? _s.pvMax : 9999;
    final newPv = (_s.pvActuel + soin).clamp(0, pvMax);
    _update(_s.copyWith(pvActuel: newPv, drActuel: _s.drActuel - 1));

    final bonusStr = halfLevel > 0 ? ' + ½ niv. ($halfLevel)' : '';
    widget.onDiceRoll?.call(DiceLogEntry(
      label: 'Récupération rapide',
      die: _s.dvDerive,
      dieResult: roll,
      bonus: halfLevel,
      total: soin,
      detail: 'Dé (${_s.dvDerive}) = $roll$bonusStr = +$soin PV'
          '  •  PV : $newPv / ${_s.pvMax}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('❤️ Récupération rapide : +$soin PV — PV : $newPv / ${_s.pvMax}'),
      backgroundColor: const Color(0xFF00695C),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _showRecuperationCompleteDialog() async {
    // Étape 1 : conditions de repos difficiles ?
    final difficult = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.nightlight_round, color: Color(0xFFE53935), size: 22),
          SizedBox(width: 8),
          Text('Récupération Complète'),
        ]),
        content: const Text(
            'Les conditions de repos sont-elles difficiles ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Conditions normales'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.warning_amber_rounded, size: 16),
            label: const Text('Difficiles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE64A19),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (difficult == null || !mounted) return;

    if (!difficult) {
      _showRecuperationChoiceDialog();
      return;
    }

    // Étape 2 : saisie de la difficulté + test de CON
    final diffCtrl = TextEditingController(text: '10');
    final difficulty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test de Constitution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CON : ${_s.conTotal >= 0 ? '+' : ''}${_s.conTotal}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 12),
            const Text('Difficulté du test :'),
            const SizedBox(height: 6),
            TextField(
              controller: diffCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ex : 10',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton.icon(
            icon: const Icon(Icons.casino, size: 16),
            label: const Text('Lancer le test'),
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(diffCtrl.text.trim()) ?? 10),
          ),
        ],
      ),
    );
    if (difficulty == null || !mounted) return;

    // Lancer D20 + CON
    final roll     = Random().nextInt(20) + 1;
    final conBonus = _s.conTotal;
    final total    = roll + conBonus;
    final success  = total >= difficulty;
    final isCrit   = roll == 20;
    final isFumble = roll == 1;

    widget.onDiceRoll?.call(DiceLogEntry(
      label: 'Test de CON (Repos)',
      die: 'D20',
      dieResult: roll,
      bonus: conBonus,
      total: total,
      detail: 'D20=$roll + CON($conBonus) = $total'
          '  vs  Difficulté $difficulty'
          ' → ${isCrit ? "🎯 Critique !" : isFumble ? "💀 Fumble !" : success ? "Succès" : "Échec"}',
    ));

    if (!mounted) return;

    if (!success && !isCrit) {
      // Échec : message et fin
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.bedtime, color: Colors.grey, size: 22),
            SizedBox(width: 8),
            Text('Repos perturbé'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Résultat du dé
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isFumble)
                      const Text('💀 ',
                          style: TextStyle(fontSize: 18)),
                    Text(
                      'D20 ($roll) + CON ($conBonus) = $total  /  Diff. $difficulty',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Le personnage n\'a pas réussi à se reposer correctement. Aucun bénéfice de récupération.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Dommage…')),
          ],
        ),
      );
      return;
    }

    // Succès (ou critique) : passer au choix
    if (!mounted) return;
    _showRecuperationChoiceDialog(
        rollResult: total,
        difficulty: difficulty,
        isCrit: isCrit);
  }

  void _showRecuperationChoiceDialog(
      {int? rollResult, int? difficulty, bool isCrit = false}) {
    final drActuel = _s.drActuel.clamp(0, _s.drMax);
    final drMax = _s.drMax;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: Color(0xFFE53935), size: 22),
            SizedBox(width: 8),
            Text('Récupération Complète'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge succès si test de CON effectué
            if (rollResult != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF00695C)
                          .withValues(alpha: 0.4)),
                ),
                child: Text(
                  isCrit
                      ? '🎯 Critique ! ($rollResult vs $difficulty) — Repos réussi !'
                      : '✅ Test réussi ($rollResult vs $difficulty)',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00695C),
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('Choisissez une option :',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            // Option 1: DR gratuit
            ElevatedButton.icon(
              icon: const Icon(Icons.favorite, size: 18),
              label: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lancer un DR gratuit'),
                  Text('Récupère des PV sans dépenser de DR',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.normal)),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _rollDRFree();
              },
            ),
            const SizedBox(height: 10),
            // Option 2: Récupérer 1 DR
            ElevatedButton.icon(
              icon: const Icon(Icons.casino, size: 18),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Récupérer un DR'),
                  Text(
                    '$drActuel → ${(drActuel + 1).clamp(0, drMax)} / $drMax DR',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                disabledBackgroundColor: AppColors.surfaceVariant,
              ),
              onPressed: drActuel < drMax
                  ? () {
                      Navigator.pop(ctx);
                      _recupererDR();
                    }
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  void _rollDRFree() {
    final dieMax = _s.dvMaxValue.clamp(1, 100);
    final roll = Random().nextInt(dieMax) + 1;
    final halfLevel = (_s.level.clamp(1, 100)) ~/ 2;
    final soin = roll + halfLevel;
    final pvMax = _s.pvMax > 0 ? _s.pvMax : 9999;
    final newPv = (_s.pvActuel + soin).clamp(0, pvMax);
    // Récupération complète : mana restauré au max
    _update(_s.copyWith(pvActuel: newPv, pmActuel: _s.pmMax));

    final bonusStr = halfLevel > 0 ? ' + ½ niv. ($halfLevel)' : '';
    widget.onDiceRoll?.call(DiceLogEntry(
      label: 'DR Gratuit (Récup. Complète)',
      die: _s.dvDerive,
      dieResult: roll,
      bonus: halfLevel,
      total: soin,
      detail: 'Dé (${_s.dvDerive}) = $roll$bonusStr = +$soin PV  •  PV : $newPv / ${_s.pvMax}  •  PM restaurés',
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🌿 DR gratuit : +$soin PV — PV : $newPv / ${_s.pvMax}  •  💧 PM restaurés'),
      backgroundColor: const Color(0xFF00695C),
      duration: const Duration(seconds: 3),
    ));
  }

  void _recupererDR() {
    if (_s.drActuel >= _s.drMax) return;
    final newDr = _s.drActuel + 1;
    // Récupération complète : mana restauré au max
    _update(_s.copyWith(drActuel: newDr, pmActuel: _s.pmMax));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎲 DR récupéré : $newDr / ${_s.drMax}  •  💧 PM restaurés'),
      backgroundColor: const Color(0xFFE53935),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildDefenseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('DÉFENSE', const Color(0xFF1565C0)),
        _tableContainer(
          child: Column(
            children: [
              _colHeaders(['Base (10+AGI)', 'Bonus', 'Malus', 'Total']),
              Row(
                children: [
                  _labelCell('DEF'),
                  _intCell(_s.defDerive, (_) {}, readOnly: true),
                  _intCell(_s.defBonus, (v) => _update(_s.copyWith(defBonus: v))),
                  _intCell(_s.defMalus, (v) => _update(_s.copyWith(defMalus: v))),
                  _intCell(_s.defTotal, (_) {}, readOnly: true),
                ],
              ),
              _divider(),
              Row(
                children: [
                  _labelCell('RD'),
                  _intCell(_s.rdBase, (v) => _update(_s.copyWith(rdBase: v))),
                  _intCell(_s.rdBonus, (v) => _update(_s.copyWith(rdBonus: v))),
                  _intCell(_s.rdMalus, (v) => _update(_s.copyWith(rdMalus: v))),
                  _intCell(_s.rdTotal, (_) {}, readOnly: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManaSection() {
    final pct      = _s.pmMax > 0 ? (_s.pmActuel / _s.pmMax).clamp(0.0, 1.0) : 0.0;
    final isEmpty  = _s.pmActuel <= 0;
    const barColor = Color(0xFF6A1B9A);

    // Compute magic count from provider for formula display
    final provider = context.watch<CharacterSheetProvider>();
    final magicCount = _s.id != null ? provider.getMagicCapacitesCount(_s.id!) : 0;
    final vol = _s.volTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('MANA (PM)', barColor),
        _tableContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Formule auto-calculée ─────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: barColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sorts(*) $magicCount  +  VOL $vol  =  ${magicCount + vol}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceMuted),
                        ),
                      ),
                      Text(
                        'Base : ${_s.pmBase}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
                // ── Bonus ─────────────────────────────────────────────────
                _colHeaders(['Bonus']),
                Row(
                  children: [
                    _labelCell('PM +'),
                    _intCell(_s.pmBonus, (v) => _update(_s.copyWith(pmBonus: v))),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Barre de mana ─────────────────────────────────────────
                if (isEmpty)
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: barColor.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF6A1B9A)),
                        SizedBox(width: 6),
                        Text('Mana épuisé',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A1B9A))),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${_s.pmActuel} / ${_s.pmMax}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: barColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 22,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                // ── Boutons ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Dépenser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: barColor,
                          side: const BorderSide(color: Color(0xFF6A1B9A)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showManaDialog(spend: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.water_drop, size: 18),
                        label: const Text('Récupérer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: barColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showManaDialog(spend: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Brûlure de mana ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.local_fire_department, size: 18),
                    label: const Text('Brûlure de mana'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      side: const BorderSide(color: Color(0xFFE65100)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: _showManaBurnDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showManaDialog({required bool spend}) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(spend ? 'Dépenser du mana' : 'Récupérer du mana'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: spend ? 'Points de mana dépensés' : 'Points de mana récupérés',
            prefixIcon: Icon(spend ? Icons.remove_circle_outline : Icons.water_drop,
                color: const Color(0xFF6A1B9A)),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? 0;
              if (v > 0) {
                final newPm = spend
                    ? (_s.pmActuel - v).clamp(0, _s.pmMax > 0 ? _s.pmMax : 9999)
                    : (_s.pmActuel + v).clamp(0, _s.pmMax > 0 ? _s.pmMax : 9999);
                _update(_s.copyWith(pmActuel: newPm.toInt()));
              }
              Navigator.of(ctx).pop();
            },
            child: Text(spend ? 'Dépenser' : 'Récupérer'),
          ),
        ],
      ),
    );
  }

  void _showManaBurnDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Text('Brûlure de mana'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avertissement règle ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFE65100)),
                      SizedBox(width: 4),
                      Text('Règle',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Lorsqu\'il n\'a plus de points de mana, un personnage peut choisir de sacrifier son énergie vitale pour continuer à lancer des sorts.\n'
                    'Pour chaque PM dépensé, il subit des DM égaux à son dé de récupération (DR).\n'
                    'PV perdus = 1 DR par point de mana du sort.\n'
                    'Aucune RD ne s\'applique à cette perte de PV.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chaque PM demandé coûte 1 jet de ${_s.dvDerive} en PV.',
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points de mana nécessaires',
                prefixIcon: Icon(Icons.local_fire_department, color: Color(0xFFE65100)),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final nbPm = int.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.of(ctx).pop();
              if (nbPm > 0) _resolveManaBurn(nbPm);
            },
            child: const Text('Brûler'),
          ),
        ],
      ),
    );
  }

  void _resolveManaBurn(int nbPm) {
    // 1. D'abord dépenser les PM disponibles
    final pmDispo  = _s.pmActuel.clamp(0, nbPm);
    final pmManquants = nbPm - pmDispo;

    CharacterSheet updated = _s.copyWith(pmActuel: _s.pmActuel - pmDispo);

    if (pmManquants == 0) {
      // Tous les PM couverts par la mana, pas de brûlure
      _update(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ $nbPm PM dépensés depuis la mana  •  PM : ${updated.pmActuel} / ${updated.pmMax}'),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF6A1B9A),
        ),
      );
      return;
    }

    // 2. Lancer les dés de brûlure uniquement pour les PM manquants
    final dv    = _s.dvMaxValue;
    final rolls = List.generate(pmManquants, (_) => Random().nextInt(dv) + 1);
    final totalDmg  = rolls.fold(0, (s, r) => s + r);
    final rollsStr  = rolls.map((r) => '$r').join(' + ');
    final newPv = (updated.pvActuel - totalDmg).clamp(0, updated.pvMax > 0 ? updated.pvMax : 9999);
    updated = updated.copyWith(pvActuel: newPv.toInt());
    _update(updated);

    final pmStr  = pmDispo > 0 ? '$pmDispo PM dépensés + ' : '';
    final detail = '${pmStr}brûlure $pmManquants × ${_s.dvDerive} : $rollsStr = $totalDmg dégâts'
        '  •  PV : $newPv / ${_s.pvMax}';

    widget.onDiceRoll?.call(DiceLogEntry(
      die: _s.dvDerive,
      label: '🔥 Brûlure de mana ($nbPm PM)',
      detail: detail,
      dieResult: totalDmg,
      bonus: 0,
      total: totalDmg,
    ));

    final snackPm = pmDispo > 0 ? '$pmDispo PM dépensés, ' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 ${snackPm}brûlure $pmManquants PM : $rollsStr = -$totalDmg PV  •  PV : $newPv / ${_s.pvMax}'),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFFE65100),
      ),
    );
  }

  Widget _buildRessourcesSection() {
    const accentColor = Color(0xFFFFB300);
    final pcMax    = _s.pcMax.clamp(0, 20);
    final pcActuel = _s.pcActuel.clamp(0, pcMax);
    final isEmpty  = pcActuel <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('POINTS DE CHANCE (PC)', accentColor),
        _tableContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Bonus ─────────────────────────────────────────────────
                _colHeaders(['Bonus']),
                Row(children: [
                  _labelCell('PC'),
                  _intCell(_s.pcBonus, (v) => _update(_s.copyWith(pcBonus: v))),
                ]),
                const SizedBox(height: 12),
                // ── Jauge trèfles ─────────────────────────────────────────
                if (pcMax == 0)
                  const Center(
                    child: Text('Aucun PC disponible',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: List.generate(pcMax, (i) {
                      final filled = i < pcActuel;
                      return Opacity(
                        opacity: filled ? 1.0 : 0.18,
                        child: const Text('🍀',
                            style: TextStyle(fontSize: 30)),
                      );
                    }),
                  ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    isEmpty ? 'Pas de chance restante' : '$pcActuel / $pcMax',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isEmpty ? Colors.grey : accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ── Boutons ───────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Provoquer le destin',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: const BorderSide(color: accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: pcActuel > 0
                          ? () {
                              _update(_s.copyWith(pcActuel: pcActuel - 1));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(children: [
                                    const Text('🍀 '),
                                    Text('Destin provoqué — ${pcActuel - 1} / $pcMax PC restants'),
                                  ]),
                                  backgroundColor: accentColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Text('🍀', style: TextStyle(fontSize: 15)),
                      label: const Text('Récupérer',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: pcActuel < pcMax
                          ? () => _update(_s.copyWith(pcActuel: pcActuel + 1))
                          : null,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncombrementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('ENCOMBREMENT', const Color(0xFF4E342E)),
        _tableContainer(
          child: Column(
            children: [
              _colHeaders(['Armure', 'Autre', 'Total']),
              Row(
                children: [
                  _labelCell('ENC.'),
                  _intCell(
                      _s.encArmure, (v) => _update(_s.copyWith(encArmure: v))),
                  _intCell(
                      _s.encAutre, (v) => _update(_s.copyWith(encAutre: v))),
                  _intCell(_s.encTotal, (_) {}, readOnly: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Racial Dialog ─────────────────────────────────────────────────────────────

class _RacialDialog extends StatefulWidget {
  final String peuple;
  final RacialChoiceData choice;
  final CharacterSheet currentSheet;
  final ValueChanged<CharacterSheet> onApply;

  const _RacialDialog({
    required this.peuple,
    required this.choice,
    required this.currentSheet,
    required this.onApply,
  });

  @override
  State<_RacialDialog> createState() => _RacialDialogState();
}

class _RacialDialogState extends State<_RacialDialog> {
  String? _bonusChoice;
  String? _malusChoice;

  @override
  void initState() {
    super.initState();
    if (widget.choice.bonusOptions.isNotEmpty) {
      _bonusChoice = widget.choice.bonusOptions.first;
    }
    if (widget.choice.malusOptions.isNotEmpty) {
      _malusChoice = widget.choice.malusOptions.first;
    }
  }

  /// Compute bonus target for Humain: +1 to one of the 2 weakest caracs.
  List<String> _computeHumainOptions() {
    final s = widget.currentSheet;
    final stats = {
      'AGI': s.agiTotal, 'CON': s.conTotal, 'FOR': s.forTotal,
      'PER': s.perTotal, 'CHA': s.chaTotal, 'INT': s.intTotal, 'VOL': s.volTotal,
    };
    final sorted = stats.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [sorted[0].key, sorted[1].key];
  }

  int _getStatTotal(String stat) {
    final s = widget.currentSheet;
    switch (stat) {
      case 'AGI': return s.agiTotal;
      case 'CON': return s.conTotal;
      case 'FOR': return s.forTotal;
      case 'PER': return s.perTotal;
      case 'CHA': return s.chaTotal;
      case 'INT': return s.intTotal;
      case 'VOL': return s.volTotal;
      default: return 0;
    }
  }

  CharacterSheet _applyRacial(String? bonusStat, String? malusStat) {
    final s = widget.currentSheet;
    int agi = 0, con = 0, fo = 0, per = 0, cha = 0, intel = 0, vol = 0;

    void apply(String? stat, int delta) {
      if (stat == null) return;
      switch (stat) {
        case 'AGI': agi += delta; break;
        case 'CON': con += delta; break;
        case 'FOR': fo += delta; break;
        case 'PER': per += delta; break;
        case 'CHA': cha += delta; break;
        case 'INT': intel += delta; break;
        case 'VOL': vol += delta; break;
      }
    }

    apply(bonusStat, 1);
    apply(widget.choice.malusFixed, -1);
    apply(malusStat, -1);

    return s.copyWith(
      agiRacial: agi, conRacial: con, forRacial: fo, perRacial: per,
      chaRacial: cha, intRacial: intel, volRacial: vol,
    );
  }

  @override
  Widget build(BuildContext context) {
    final choice = widget.choice;
    final humainOptions =
        choice.bonusSpecial ? _computeHumainOptions() : <String>[];
    final bonusOptions = choice.bonusSpecial ? humainOptions : choice.bonusOptions;

    if (_bonusChoice == null && bonusOptions.isNotEmpty) {
      _bonusChoice = bonusOptions.first;
    }

    return AlertDialog(
      title: Text('Bonus racial — ${widget.peuple}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bonusOptions.isNotEmpty) ...[
              Text(
                choice.bonusSpecial
                    ? '+1 à l\'une des 2 carac. les plus faibles :'
                    : 'Choisir la carac. qui reçoit +1 :',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              ...bonusOptions.map((stat) => RadioListTile<String>(
                    title: Text('$stat (${_getStatTotal(stat)})',
                        style: const TextStyle(fontSize: 13)),
                    value: stat,
                    groupValue: _bonusChoice,
                    dense: true,
                    onChanged: (v) => setState(() => _bonusChoice = v),
                  )),
            ],
            if (choice.malusFixed != null) ...[
              const SizedBox(height: 8),
              Text(
                'Malus fixe : -1 ${choice.malusFixed}',
                style: const TextStyle(
                    color: AppColors.enemyLight, fontSize: 13),
              ),
            ],
            if (choice.malusOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Choisir la carac. qui reçoit -1 :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              ...choice.malusOptions.map((stat) => RadioListTile<String>(
                    title: Text('$stat (${_getStatTotal(stat)})',
                        style: const TextStyle(fontSize: 13)),
                    value: stat,
                    groupValue: _malusChoice,
                    dense: true,
                    onChanged: (v) => setState(() => _malusChoice = v),
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final updated = _applyRacial(
              bonusOptions.isEmpty ? null : _bonusChoice,
              choice.malusOptions.isEmpty ? null : _malusChoice,
            );
            widget.onApply(updated);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

// ── Inventaire Tab ────────────────────────────────────────────────────────────

class _InventaireTab extends StatefulWidget {
  final int sheetId;
  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onSheetChanged;
  const _InventaireTab({required this.sheetId, required this.sheet, required this.onSheetChanged});

  @override
  State<_InventaireTab> createState() => _InventaireTabState();
}

class _InventaireTabState extends State<_InventaireTab>
    with AutomaticKeepAliveClientMixin {
  final _db = DatabaseService();
  List<InventoryItem> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getInventoryItems(widget.sheetId);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _addItem() async {
    final item = await _db.insertInventoryItem(InventoryItem(
      characterSheetId: widget.sheetId,
      name: '',
      position: _items.length,
    ));
    if (!mounted) return;
    setState(() => _items.add(item));
  }

  Future<void> _deleteItem(InventoryItem item) async {
    if (item.id == null) { setState(() => _items.remove(item)); return; }
    await _db.deleteInventoryItem(item.id!);
    if (!mounted) return;
    setState(() => _items.remove(item));
  }

  Future<void> _updateItem(InventoryItem updated) async {
    if (updated.id == null) return;
    await _db.updateInventoryItem(updated);
    if (!mounted) return;
    setState(() {
      final idx = _items.indexWhere((i) => i.id == updated.id);
      if (idx >= 0) _items[idx] = updated;
    });
  }

  Future<void> _showDescriptionDialog(InventoryItem item) async {
    final ctrl = TextEditingController(text: item.description);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name.isEmpty ? 'Description' : item.name),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: 'Description de l\'objet…',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    // result == null → Annuler pressed; save even empty string (clears description)
    if (result != null) {
      await _updateItem(item.copyWith(description: result));
    }
  }

  Future<void> _saveMonnaie(CharacterSheet updated) async {
    await DatabaseService().updateCharacterSheet(updated);
    widget.onSheetChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = widget.sheet;

    return Column(
      children: [
        // ── Monnaie ──────────────────────────────────────────────────────────
        _MonnaieWidget(
          sheet: s,
          onChanged: _saveMonnaie,
        ),
        const Divider(height: 1),
        // Header row
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              const SizedBox(width: 36), // delete btn space
              const Expanded(
                flex: 5,
                child: Text('Objet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(
                width: 110,
                child: Center(
                  child: Text('Qté', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 40), // desc btn space
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: AppColors.onSurfaceMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Inventaire vide',
                          style: TextStyle(color: AppColors.onSurfaceMuted)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter un objet'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ItemRow(
                    item: _items[i],
                    onDelete: () => _deleteItem(_items[i]),
                    onNameChanged: (v) =>
                        _updateItem(_items[i].copyWith(name: v)),
                    onQtyChanged: (v) =>
                        _updateItem(_items[i].copyWith(quantity: v)),
                    onDescTap: () => _showDescriptionDialog(_items[i]),
                  ),
                ),
        ),
        if (_items.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un objet'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Monnaie Widget ────────────────────────────────────────────────────────────

class _MonnaieWidget extends StatelessWidget {
  final CharacterSheet sheet;
  final Future<void> Function(CharacterSheet) onChanged;

  const _MonnaieWidget({required this.sheet, required this.onChanged});

  // Total fortune en PC
  int get _totalPC =>
      sheet.monnaiePC + sheet.monnaiePA * 10 + sheet.monnaiePO * 100 + sheet.monnaiePP * 1000;

  /// Normalise vers les grosses pièces :
  /// PC→PA dès 10 PC, PA→PO dès 10 PA, PO→PP seulement à partir de 100 PO.
  static ({int pc, int pa, int po, int pp}) _normalize(int pc, int pa, int po, int pp) {
    if (pc >= 10) { pa += pc ~/ 10; pc = pc % 10; }
    if (pa >= 10) { po += pa ~/ 10; pa = pa % 10; }
    if (po >= 100) { pp += po ~/ 10; po = po % 10; }
    return (pc: pc, pa: pa, po: po, pp: pp);
  }

  void _edit(BuildContext context, String label, Color color, int current,
      Future<void> Function(int) onSave) async {
    final ctrl = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12, height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Text(label),
          ],
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Quantité',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? current;
              Navigator.pop(ctx, v.clamp(0, 999999));
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (result != null) await onSave(result);
  }

  Future<void> _pay(BuildContext context) async {
    // Dialog d'entrée : montant + dénomination
    String denom = 'PC';
    final amountCtrl = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final mult = {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
        final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
        final costPC = amount * mult;
        final enough = costPC <= _totalPC;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payments_outlined, size: 20),
              SizedBox(width: 8),
              Text('Payer'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onChanged: (_) => setS(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: denom,
                    items: const [
                      DropdownMenuItem(value: 'PC', child: Text('PC')),
                      DropdownMenuItem(value: 'PA', child: Text('PA')),
                      DropdownMenuItem(value: 'PO', child: Text('PO')),
                      DropdownMenuItem(value: 'PP', child: Text('PP')),
                    ],
                    onChanged: (v) { if (v != null) setS(() => denom = v); },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (amount > 0) ...[
                Text(
                  'Coût : $costPC PC équivalents',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                ),
                Text(
                  'Bourse : ${_totalPC} PC disponibles',
                  style: TextStyle(
                    fontSize: 12,
                    color: enough ? AppColors.onSurfaceMuted : Colors.red,
                  ),
                ),
                if (!enough)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Fonds insuffisants', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final a = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (a <= 0) return;
                final m = {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
                Navigator.pop(ctx, {'costPC': a * m});
              },
              child: const Text('Payer'),
            ),
          ],
        );
      }),
    );

    if (result == null) return;
    final costPC = result['costPC'] as int;

    if (costPC > _totalPC) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fonds insuffisants pour effectuer ce paiement.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Déduire en priorisant les petites pièces ; le change reste en PC (pas de regroupement)
    int rem = costPC;
    int newPC = sheet.monnaiePC;
    int newPA = sheet.monnaiePA;
    int newPO = sheet.monnaiePO;
    int newPP = sheet.monnaiePP;

    // 1. Utiliser les PC existants
    final usePC = newPC.clamp(0, rem);
    newPC -= usePC; rem -= usePC;

    // 2. Casser des PA si besoin
    if (rem > 0 && newPA > 0) {
      final paUsed = ((rem + 9) ~/ 10).clamp(0, newPA);
      final pcBroken = paUsed * 10;
      final used = rem.clamp(0, pcBroken);
      newPA -= paUsed;
      newPC += pcBroken - used; // change rendu en PC
      rem -= used;
    }

    // 3. Casser des PO si besoin
    if (rem > 0 && newPO > 0) {
      final poUsed = ((rem + 99) ~/ 100).clamp(0, newPO);
      final pcBroken = poUsed * 100;
      final used = rem.clamp(0, pcBroken);
      newPO -= poUsed;
      newPC += pcBroken - used;
      rem -= used;
    }

    // 4. Casser des PP si besoin
    if (rem > 0 && newPP > 0) {
      final ppUsed = ((rem + 999) ~/ 1000).clamp(0, newPP);
      final pcBroken = ppUsed * 1000;
      final used = rem.clamp(0, pcBroken);
      newPP -= ppUsed;
      newPC += pcBroken - used;
      rem -= used;
    }

    // 5. Normaliser le change vers les grosses pièces (seuils : 10 PC→PA, 10 PA→PO, 100 PO→PP)
    final n = _normalize(newPC, newPA, newPO, newPP);
    newPC = n.pc; newPA = n.pa; newPO = n.po; newPP = n.pp;

    await onChanged(sheet.copyWith(
      monnaiePC: newPC, monnaiePA: newPA,
      monnaiePO: newPO, monnaiePP: newPP,
    ));

    if (context.mounted) {
      final parts = [
        if (newPP > 0) '$newPP PP',
        if (newPO > 0) '$newPO PO',
        if (newPA > 0) '$newPA PA',
        if (newPC > 0) '$newPC PC',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement effectué — reste : ${parts.isEmpty ? "0 PC" : parts.join("  ")}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _gain(BuildContext context) async {
    String denom = 'PC';
    final amountCtrl = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final mult = {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
        final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
        final gainPC = amount * mult;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text('Gain d\'argent'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onChanged: (_) => setS(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: denom,
                    items: const [
                      DropdownMenuItem(value: 'PC', child: Text('PC')),
                      DropdownMenuItem(value: 'PA', child: Text('PA')),
                      DropdownMenuItem(value: 'PO', child: Text('PO')),
                      DropdownMenuItem(value: 'PP', child: Text('PP')),
                    ],
                    onChanged: (v) { if (v != null) setS(() => denom = v); },
                  ),
                ],
              ),
              if (amount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Gain : $gainPC PC équivalents',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () {
                final a = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (a <= 0) return;
                final m = {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
                Navigator.pop(ctx, {'gainPC': a * m});
              },
              child: const Text('Recevoir'),
            ),
          ],
        );
      }),
    );

    if (result == null) return;
    final gainPC = result['gainPC'] as int;

    // Ajouter en PC puis normaliser vers les grosses pièces
    int newPC = sheet.monnaiePC + gainPC;
    int newPA = sheet.monnaiePA;
    int newPO = sheet.monnaiePO;
    int newPP = sheet.monnaiePP;

    final n = _normalize(newPC, newPA, newPO, newPP);
    newPC = n.pc; newPA = n.pa; newPO = n.po; newPP = n.pp;

    await onChanged(sheet.copyWith(
      monnaiePC: newPC, monnaiePA: newPA,
      monnaiePO: newPO, monnaiePP: newPP,
    ));

    if (context.mounted) {
      final parts = [
        if (newPP > 0) '$newPP PP',
        if (newPO > 0) '$newPO PO',
        if (newPA > 0) '$newPA PA',
        if (newPC > 0) '$newPC PC',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Argent reçu — bourse : ${parts.isEmpty ? "0 PC" : parts.join("  ")}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Monnaie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceMuted)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _gain(context),
                icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
                label: const Text('Gain', style: TextStyle(fontSize: 12, color: Colors.green)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _pay(context),
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: const Text('Payer', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _CoinTile(
                label: 'PC', sublabel: 'Cuivre', color: const Color(0xFFB87333),
                value: sheet.monnaiePC,
                onTap: () => _edit(context, 'Pièces de Cuivre (PC)', const Color(0xFFB87333), sheet.monnaiePC,
                    (v) => onChanged(sheet.copyWith(monnaiePC: v))),
              ),
              const SizedBox(width: 8),
              _CoinTile(
                label: 'PA', sublabel: 'Argent', color: const Color(0xFF9E9E9E),
                value: sheet.monnaiePA,
                onTap: () => _edit(context, 'Pièces d\'Argent (PA)', const Color(0xFF9E9E9E), sheet.monnaiePA,
                    (v) => onChanged(sheet.copyWith(monnaiePA: v))),
              ),
              const SizedBox(width: 8),
              _CoinTile(
                label: 'PO', sublabel: 'Or', color: const Color(0xFFFFD700),
                value: sheet.monnaiePO,
                onTap: () => _edit(context, 'Pièces d\'Or (PO)', const Color(0xFFFFD700), sheet.monnaiePO,
                    (v) => onChanged(sheet.copyWith(monnaiePO: v))),
              ),
              const SizedBox(width: 8),
              _CoinTile(
                label: 'PP', sublabel: 'Platine', color: const Color(0xFF90CAF9),
                value: sheet.monnaiePP,
                onTap: () => _edit(context, 'Pièces de Platine (PP)', const Color(0xFF90CAF9), sheet.monnaiePP,
                    (v) => onChanged(sheet.copyWith(monnaiePP: v))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('1 PP = 10 PO  •  1 PO = 10 PA  •  1 PA = 10 PC',
              style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _CoinTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final int value;
  final VoidCallback onTap;

  const _CoinTile({
    required this.label, required this.sublabel,
    required this.color, required this.value, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(sublabel, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback onDelete;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onDescTap;

  const _ItemRow({
    required this.item,
    required this.onDelete,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onDescTap,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
  }

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);
    if (old.item.name != widget.item.name &&
        _nameCtrl.text != widget.item.name) {
      _nameCtrl.text = widget.item.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDesc = widget.item.description.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.enemyPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onDelete,
          ),
          // Name field
          Expanded(
            flex: 5,
            child: TextField(
              controller: _nameCtrl,
              onChanged: widget.onNameChanged,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Nom de l\'objet',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quantity stepper
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.item.quantity > 0
                      ? () => widget.onQtyChanged(widget.item.quantity - 1)
                      : null,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.remove_circle_outline, size: 22),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${widget.item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onQtyChanged(widget.item.quantity + 1),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add_circle_outline, size: 22),
                  ),
                ),
              ],
            ),
          ),
          // Description button
          IconButton(
            icon: Icon(
              hasDesc ? Icons.description : Icons.description_outlined,
              size: 20,
              color: hasDesc ? AppColors.allyPrimary : AppColors.onSurfaceMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
            tooltip: hasDesc ? 'Voir / modifier la description' : 'Ajouter une description',
            onPressed: widget.onDescTap,
          ),
        ],
      ),
    );
  }
}

// ── Stat Preset Dialog ────────────────────────────────────────────────────────

class _StatPresetDialog extends StatefulWidget {
  final CharacterSheet sheet;
  const _StatPresetDialog({required this.sheet});

  @override
  State<_StatPresetDialog> createState() => _StatPresetDialogState();
}

class _StatPresetDialogState extends State<_StatPresetDialog> {
  static const _presets = {
    'polyvalent':  [2, 2, 2, 1, 1, 0, -1],
    'expert':      [3, 2, 1, 1, 0, 0, -1],
    'specialiste': [4, 2, 1, 0, 0, -1, -1],
  };
  static const _presetLabels = {
    'polyvalent':  'Polyvalent  (+2, +2, +2, +1, +1, 0, -1)',
    'expert':      'Expert  (+3, +2, +1, +1, 0, 0, -1)',
    'specialiste': 'Spécialiste  (+4, +2, +1, 0, 0, -1, -1)',
  };
  static const _caracs = [
    ('AGI', 'Agilité'),
    ('CON', 'Constitution'),
    ('FOR', 'Force'),
    ('PER', 'Perception'),
    ('CHA', 'Charisme'),
    ('INT', 'Intelligence'),
    ('VOL', 'Volonté'),
  ];

  String _preset = '';
  // Assignments: stat abbr → index into preset list (null = unassigned)
  final Map<String, int?> _assignments = {
    for (final c in _caracs) c.$1: null,
  };

  @override
  void initState() {
    super.initState();
    _preset = widget.sheet.statPreset;
    if (_preset.isNotEmpty) {
      // Restore previous assignments from sheet vals
      final vals = _presets[_preset]!;
      final used = List<bool>.filled(vals.length, false);
      for (final (abbr, _) in _caracs) {
        final v = _getSheetVal(abbr);
        final idx = vals.indexWhere((x) => x == v && !used[vals.indexOf(x)]);
        if (idx >= 0) { _assignments[abbr] = idx; used[idx] = true; }
      }
    }
  }

  int _getSheetVal(String abbr) => switch (abbr) {
    'AGI' => widget.sheet.agiVal,
    'CON' => widget.sheet.conVal,
    'FOR' => widget.sheet.forVal,
    'PER' => widget.sheet.perVal,
    'CHA' => widget.sheet.chaVal,
    'INT' => widget.sheet.intVal,
    'VOL' => widget.sheet.volVal,
    _ => 0,
  };

  List<int> _availableFor(String abbr) {
    if (_preset.isEmpty) return [];
    final vals = _presets[_preset]!;
    final used = <int>{};
    for (final e in _assignments.entries) {
      if (e.key != abbr && e.value != null) used.add(e.value!);
    }
    return [
      for (var i = 0; i < vals.length; i++)
        if (!used.contains(i)) i,
    ];
  }

  bool get _allAssigned =>
      _preset.isNotEmpty &&
      _assignments.values.every((v) => v != null);

  CharacterSheet _buildResult() {
    final vals = _presets[_preset]!;
    int valFor(String abbr) => vals[_assignments[abbr]!];
    return widget.sheet.copyWith(
      statPreset: _preset,
      agiVal: valFor('AGI'),
      conVal: valFor('CON'),
      forVal: valFor('FOR'),
      perVal: valFor('PER'),
      chaVal: valFor('CHA'),
      intVal: valFor('INT'),
      volVal: valFor('VOL'),
    );
  }

  void _onPresetChanged(String preset) {
    setState(() {
      _preset = preset;
      for (final k in _assignments.keys) { _assignments[k] = null; }
    });
  }

  String _formatVal(int v) => v > 0 ? '+$v' : '$v';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Série de répartition'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Step 1: preset selection
              ...(_presets.keys.map((p) => RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_presetLabels[p]!, style: const TextStyle(fontSize: 13)),
                value: p,
                groupValue: _preset,
                onChanged: (v) => _onPresetChanged(v!),
              ))),
              if (_preset.isNotEmpty) ...[
                const Divider(height: 20),
                const Text(
                  'Répartissez les valeurs entre vos caractéristiques :',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Step 2: assignments
                ...(_caracs.map((c) {
                  final abbr = c.$1;
                  final label = c.$2;
                  final available = _availableFor(abbr);
                  final current = _assignments[abbr];
                  final vals = _presets[_preset]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            '$abbr – $label',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            isDense: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('—', style: TextStyle(fontSize: 13)),
                            value: current,
                            items: [
                              if (current != null)
                                DropdownMenuItem(
                                  value: current,
                                  child: Text(_formatVal(vals[current]),
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ...available
                                  .where((i) => i != current)
                                  .map((i) => DropdownMenuItem(
                                        value: i,
                                        child: Text(_formatVal(vals[i]),
                                            style: const TextStyle(fontSize: 13)),
                                      )),
                            ],
                            onChanged: (idx) =>
                                setState(() => _assignments[abbr] = idx),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _allAssigned
              ? () => Navigator.pop(context, _buildResult())
              : null,
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

// ── Dice Log ──────────────────────────────────────────────────────────────────

class DiceLogEntry {
  final String label;
  final String die;
  final int dieResult;
  final int bonus;
  final int total;
  final String detail;
  final DateTime timestamp;

  DiceLogEntry({
    required this.label,
    required this.die,
    required this.dieResult,
    required this.bonus,
    required this.total,
    required this.detail,
  }) : timestamp = DateTime.now();
}

class _DiceLogScreen extends StatelessWidget {
  final List<DiceLogEntry> log;

  const _DiceLogScreen({required this.log});

  String _elapsed(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.casino_outlined, size: 22),
            const SizedBox(width: 8),
            const Text('Journal des dés'),
            const SizedBox(width: 8),
            if (log.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.allyPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${log.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.allyPrimary,
                  ),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: log.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.casino_outlined,
                    size: 64,
                    color: AppColors.onSurfaceMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun lancer pour l\'instant',
                    style: TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: log.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = log[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppColors.allyPrimary.withValues(alpha: 0.15),
                    child: Text(
                      e.die,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.allyPrimary,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.allyPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${e.total}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.allyPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      e.detail,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  trailing: Text(
                    _elapsed(e.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Combat Tab ────────────────────────────────────────────────────────────────

class _CombatTab extends StatefulWidget {
  final int sheetId;
  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onSheetChanged;
  final ValueChanged<DiceLogEntry>? onDiceRoll;

  const _CombatTab({
    super.key,
    required this.sheetId,
    required this.sheet,
    required this.onSheetChanged,
    this.onDiceRoll,
  });

  @override
  State<_CombatTab> createState() => _CombatTabState();
}

class _CombatTabState extends State<_CombatTab>
    with AutomaticKeepAliveClientMixin {
  late DatabaseService _db;
  List<CombatWeapon> _weapons = [];
  List<CombatArmor> _armors = [];
  List<CombatCapacity> _capacities = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
    _load();
  }

  Future<void> _load() async {
    final ws = await _db.getCombatWeapons(widget.sheetId);
    final as_ = await _db.getCombatArmors(widget.sheetId);
    final cs = await _db.getCombatCapacities(widget.sheetId);
    if (!mounted) return;
    setState(() {
      _weapons = ws;
      _armors = as_;
      _capacities = cs;
      _loading = false;
    });
  }

  /// Called externally (e.g. after voie rang changes) to refresh the capacities list.
  Future<void> reload() => _load();

  Future<void> _recalc() async {
    final updated = await _db.recalculateEquipmentBonuses(widget.sheetId);
    if (updated != null && mounted) {
      widget.onSheetChanged(updated);
    }
  }

  // ── Weapons ──────────────────────────────────────────────────────────────

  Future<void> _addWeapon() async {
    final result = await _showWeaponDialog(null);
    if (result == null) return;
    final created = await _db.insertCombatWeapon(result.copyWith(
      characterSheetId: widget.sheetId,
      position: _weapons.length,
    ));
    setState(() => _weapons.add(created));
  }

  Future<void> _editWeapon(CombatWeapon w) async {
    final result = await _showWeaponDialog(w);
    if (result == null) return;
    await _db.updateCombatWeapon(result);
    setState(() => _weapons[_weapons.indexWhere((x) => x.id == w.id)] = result);
    if (w.equipped || result.equipped) await _recalc();
  }

  Future<void> _toggleWeaponEquipped(CombatWeapon w) async {
    final updated = w.copyWith(equipped: !w.equipped);
    await _db.updateCombatWeapon(updated);
    setState(() => _weapons[_weapons.indexWhere((x) => x.id == w.id)] = updated);
    await _recalc();
  }

  Future<void> _deleteWeapon(CombatWeapon w) async {
    await _db.deleteCombatWeapon(w.id!);
    setState(() => _weapons.removeWhere((x) => x.id == w.id));
    await _recalc();
  }

  Future<CombatWeapon?> _showWeaponDialog(CombatWeapon? existing) async {
    String type = existing?.type ?? 'contact';
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final porteeCtrl = TextEditingController(text: (existing?.portee ?? 0) == 0 ? '' : '${existing!.portee}');
    final dmCtrl = TextEditingController(text: existing?.dm ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final result = await showDialog<CombatWeapon>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Ajouter une arme' : 'Modifier l\'arme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Type', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'contact', label: Text('Contact'), icon: Icon(Icons.sports_martial_arts, size: 16)),
                    ButtonSegment(value: 'distance', label: Text('Distance'), icon: Icon(Icons.gps_fixed, size: 16)),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setS(() => type = s.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dmCtrl,
                        decoration: const InputDecoration(
                          labelText: 'DM (ex: 1d6, 2d8+3)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (type == 'distance') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: porteeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Portée (m)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(ctx, CombatWeapon(
                  id: existing?.id,
                  characterSheetId: widget.sheetId,
                  name: n,
                  type: type,
                  portee: int.tryParse(porteeCtrl.text) ?? 0,
                  equipped: existing?.equipped ?? false,
                  description: descCtrl.text,
                  position: existing?.position ?? 0,
                  dm: dmCtrl.text.trim(),
                ));
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  // ── Armors ──────────────────────────────────────────────────────────────

  Future<void> _addArmor() async {
    final result = await _showArmorDialog(null);
    if (result == null) return;
    final created = await _db.insertCombatArmor(result.copyWith(characterSheetId: widget.sheetId));
    setState(() => _armors.add(created));
    if (created.equipped) await _recalc();
  }

  Future<void> _editArmor(CombatArmor a) async {
    final result = await _showArmorDialog(a);
    if (result == null) return;
    await _db.updateCombatArmor(result);
    setState(() => _armors[_armors.indexWhere((x) => x.id == a.id)] = result);
    if (a.equipped || result.equipped) await _recalc();
  }

  Future<void> _toggleArmorEquipped(CombatArmor a) async {
    final updated = a.copyWith(equipped: !a.equipped);
    await _db.updateCombatArmor(updated);
    setState(() => _armors[_armors.indexWhere((x) => x.id == a.id)] = updated);
    await _recalc();
  }

  Future<void> _deleteArmor(CombatArmor a) async {
    await _db.deleteCombatArmor(a.id!);
    setState(() => _armors.removeWhere((x) => x.id == a.id));
    if (a.equipped) await _recalc();
  }

  Future<CombatArmor?> _showArmorDialog(CombatArmor? existing) async {
    String name = existing?.name ?? '';
    String type = existing?.type ?? 'principale';
    String matiere = existing?.matiere ?? 'cuir souple';
    final defaults = kMatiereDefaults[matiere]!;
    int defBonus = existing?.defBonus ?? defaults.def;
    int encBase = existing?.encBase ?? defaults.enc;
    int niveauMagie = existing?.niveauMagie ?? 0;
    String desc = existing?.description ?? '';
    final nameCtrl = TextEditingController(text: name);
    final defCtrl = TextEditingController(text: '$defBonus');
    final encCtrl = TextEditingController(text: '$encBase');
    final magieCtrl = TextEditingController(text: '$niveauMagie');
    final descCtrl = TextEditingController(text: desc);

    final result = await showDialog<CombatArmor>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Ajouter une armure' : 'Modifier l\'armure'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: kArmorTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setS(() => type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: matiere,
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  items: kArmorMatieres.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {
                    setS(() {
                      matiere = v!;
                      final d = kMatiereDefaults[matiere]!;
                      defBonus = d.def;
                      encBase = d.enc;
                      defCtrl.text = '$defBonus';
                      encCtrl.text = '$encBase';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: defCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bonus DEF', border: OutlineInputBorder()),
                        onChanged: (v) => defBonus = int.tryParse(v) ?? defBonus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: encCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ENC base', border: OutlineInputBorder()),
                        onChanged: (v) => encBase = int.tryParse(v) ?? encBase,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: magieCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Niveau magie (réduit ENC)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => niveauMagie = int.tryParse(v) ?? niveauMagie,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(ctx, CombatArmor(
                  id: existing?.id,
                  characterSheetId: widget.sheetId,
                  name: n,
                  type: type,
                  matiere: matiere,
                  defBonus: int.tryParse(defCtrl.text) ?? 0,
                  encBase: int.tryParse(encCtrl.text) ?? 0,
                  niveauMagie: int.tryParse(magieCtrl.text) ?? 0,
                  equipped: existing?.equipped ?? false,
                  description: descCtrl.text,
                ));
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  // ── Capacities ──────────────────────────────────────────────────────────

  Future<void> _addCapacity() async {
    final result = await _showCapacityDialog(null);
    if (result == null) return;
    final created = await _db.insertCombatCapacity(result.copyWith(
      characterSheetId: widget.sheetId,
      position: _capacities.length,
    ));
    setState(() => _capacities.add(created));
  }

  Future<void> _editCapacity(CombatCapacity c) async {
    final result = await _showCapacityDialog(c);
    if (result == null) return;
    await _db.updateCombatCapacity(result);
    setState(() => _capacities[_capacities.indexWhere((x) => x.id == c.id)] = result);
    if (c.activated || result.activated) await _recalc();
  }

  Future<void> _toggleCapacityActivated(CombatCapacity c) async {
    final updated = c.copyWith(activated: !c.activated);
    await _db.updateCombatCapacity(updated);
    setState(() => _capacities[_capacities.indexWhere((x) => x.id == c.id)] = updated);
    await _recalc();
  }

  Future<void> _deleteCapacity(CombatCapacity c) async {
    await _db.deleteCombatCapacity(c.id!);
    setState(() => _capacities.removeWhere((x) => x.id == c.id));
    if (c.activated) await _recalc();
  }

  Future<CombatCapacity?> _showCapacityDialog(CombatCapacity? existing) async {
    bool isMagique = existing?.isMagique ?? false;
    int rang = existing?.rang ?? 1;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final voieCtrl = TextEditingController(text: existing?.voie ?? '');
    final porteeCtrl = TextEditingController(text: (existing?.portee ?? 0) == 0 ? '' : '${existing!.portee}');
    final dmCtrl = TextEditingController(text: existing?.dm ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final result = await showDialog<CombatCapacity>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Ajouter une capacité' : 'Modifier la capacité'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: voieCtrl,
                  decoration: const InputDecoration(labelText: 'Voie', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rang', style: TextStyle(fontSize: 12)),
                          Slider(
                            value: rang.toDouble(),
                            min: 1,
                            max: 8,
                            divisions: 7,
                            label: '$rang',
                            onChanged: (v) => setS(() => rang = v.round()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: porteeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Portée (m)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'DM (ex: 1d6, 2d8+3)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Capacité magique'),
                  value: isMagique,
                  onChanged: (v) => setS(() => isMagique = v),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(ctx, CombatCapacity(
                  id: existing?.id,
                  characterSheetId: widget.sheetId,
                  name: n,
                  isMagique: isMagique,
                  voie: voieCtrl.text.trim(),
                  rang: rang,
                  portee: int.tryParse(porteeCtrl.text) ?? 0,
                  activated: existing?.activated ?? false,
                  description: descCtrl.text,
                  position: existing?.position ?? 0,
                  dm: dmCtrl.text.trim(),
                  isFromVoie: existing?.isFromVoie ?? false,
                  voieCatalogueId: existing?.voieCatalogueId ?? '',
                ));
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  // ── Effects dialog ────────────────────────────────────────────────────────

  Future<void> _showEffectsDialog(String itemType, int itemId, String itemName, bool isActive) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ItemEffectsDialog(
        db: _db,
        itemType: itemType,
        itemId: itemId,
        itemName: itemName,
      ),
    );
    if (isActive) await _recalc();
  }

  // ── Description dialog ────────────────────────────────────────────────────

  Future<void> _showDescDialog(String title, String current, ValueChanged<String> onSave) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          textAlignVertical: TextAlignVertical.top,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Description…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Valider')),
        ],
      ),
    );
    if (result != null) onSave(result);
  }

  // ── Dice roll ─────────────────────────────────────────────────────────────

  /// Parses a DM string like "2d8+1d4+3" into individual rolls.
  /// Returns null if the string is empty or contains no valid dice/constants.
  ({int total, String detail})? _rollDm(String dm) {
    if (dm.trim().isEmpty) return null;
    // Tokenize: split on + keeping sign, then on - keeping sign
    final tokens = <String>[];
    final tokenRe = RegExp(r'([+-]?\s*\d+d\d+|[+-]?\s*\d+)', caseSensitive: false);
    for (final m in tokenRe.allMatches(dm.replaceAll(' ', ''))) {
      tokens.add(m.group(0)!);
    }
    if (tokens.isEmpty) return null;

    int total = 0;
    final parts = <String>[];
    final rand = Random();

    for (final raw in tokens) {
      final t = raw.replaceAll(' ', '');
      final diceRe = RegExp(r'^([+-]?)(\d+)d(\d+)$', caseSensitive: false);
      final constRe = RegExp(r'^([+-]?\d+)$');
      final dm = diceRe.firstMatch(t);
      if (dm != null) {
        final sign = dm.group(1) == '-' ? -1 : 1;
        final count = int.parse(dm.group(2)!);
        final sides = int.parse(dm.group(3)!);
        if (sides < 1 || count < 1) continue;
        int rollSum = 0;
        final rolls = <int>[];
        for (int i = 0; i < count; i++) {
          final r = rand.nextInt(sides) + 1;
          rolls.add(r);
          rollSum += r;
        }
        total += sign * rollSum;
        final signStr = sign < 0 ? '-' : (parts.isEmpty ? '' : '+');
        parts.add('$signStr${count}d$sides[${rolls.join(',')}]=$rollSum');
      } else {
        final cm = constRe.firstMatch(t);
        if (cm != null) {
          final val = int.parse(cm.group(1)!);
          total += val;
          final signStr = val >= 0 && parts.isNotEmpty ? '+$val' : '$val';
          parts.add(signStr);
        }
      }
    }
    if (parts.isEmpty) return null;
    return (total: total, detail: parts.join(' '));
  }

  int _statValue(CharacterSheet s, String stat) {
    switch (stat) {
      case 'FOR': return s.forTotal;
      case 'AGI': return s.agiTotal;
      case 'CON': return s.conTotal;
      case 'PER': return s.perTotal;
      case 'CHA': return s.chaTotal;
      case 'INT': return s.intTotal;
      case 'VOL': return s.volTotal;
      default: return 0;
    }
  }

  Future<void> _showRollDialog({
    required String itemName,
    required String dm,
    required String defaultAttType, // 'contact' | 'distance' | 'magique'
  }) async {
    String attType = defaultAttType;
    String? dmStat; // null = pas de bonus stat aux DM
    const statOptions = ['FOR', 'AGI', 'CON', 'PER', 'CHA', 'INT', 'VOL'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.casino_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Lancer — $itemName', overflow: TextOverflow.ellipsis)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modificateur d\'attaque', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'contact',  label: Text('Contact',  style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'distance', label: Text('Distance', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'magique',  label: Text('Magique',  style: TextStyle(fontSize: 12))),
                ],
                selected: {attType},
                onSelectionChanged: (s) => setS(() => attType = s.first),
              ),
              if (dm.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Dégâts : $dm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  value: dmStat,
                  decoration: const InputDecoration(
                    labelText: 'Bonus caract. aux dégâts',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucun')),
                    ...statOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setS(() => dmStat = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.casino, size: 18),
              label: const Text('Lancer !'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final sheet = widget.sheet;
    final rand = Random();

    // ── Jet d'attaque ──
    final d20 = rand.nextInt(20) + 1;
    final attBonus = attType == 'contact'
        ? sheet.attContactTotal
        : attType == 'distance'
            ? sheet.attDistanceTotal
            : sheet.attMagiqueTotal;
    final attTotal = d20 + attBonus;
    final attLabel = 'Attaque ${attType[0].toUpperCase()}${attType.substring(1)}';
    final attDetail = 'd20($d20) + $attBonus ($attType) = $attTotal'
        '${d20 == 20 ? ' 🎯 CRITIQUE !' : d20 == 1 ? ' 💀 ÉCHEC CRITIQUE' : ''}';

    widget.onDiceRoll?.call(DiceLogEntry(
      label: '$itemName — $attLabel',
      die: 'd20',
      dieResult: d20,
      bonus: attBonus,
      total: attTotal,
      detail: attDetail,
    ));

    // ── Jet de dégâts ──
    if (dm.isNotEmpty) {
      final dmRoll = _rollDm(dm);
      if (dmRoll != null) {
        final statBonus = dmStat != null ? _statValue(sheet, dmStat!) : 0;
        final dmTotal = dmRoll.total + statBonus;
        final statPart = dmStat != null ? ' + $dmStat($statBonus)' : '';
        final dmDetail = '${dmRoll.detail}$statPart = $dmTotal';

        widget.onDiceRoll?.call(DiceLogEntry(
          label: '$itemName — Dégâts ($dm)',
          die: dm,
          dieResult: dmRoll.total,
          bonus: statBonus,
          total: dmTotal,
          detail: dmDetail,
        ));
      }
    }
  }

  Widget _sectionHeader(String title, IconData icon, Color color, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Ajouter',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // ── ARMES ────────────────────────────────────────────────────────────
        _sectionHeader('Armes', Icons.sports_martial_arts, AppColors.enemyPrimary, _addWeapon),
        if (_weapons.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Aucune arme — appuyer sur + pour ajouter',
                style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
          )
        else
          ..._weapons.map((w) => _WeaponRow(
                weapon: w,
                onToggleEquip: () => _toggleWeaponEquipped(w),
                onEdit: () => _editWeapon(w),
                onDelete: () => _deleteWeapon(w),
                onRoll: () => _showRollDialog(
                  itemName: w.name,
                  dm: w.dm,
                  defaultAttType: w.type == 'distance' ? 'distance' : 'contact',
                ),
                onDesc: () => _showDescDialog(w.name, w.description, (v) async {
                  final updated = w.copyWith(description: v);
                  await _db.updateCombatWeapon(updated);
                  setState(() => _weapons[_weapons.indexWhere((x) => x.id == w.id)] = updated);
                }),
                onEffects: () => _showEffectsDialog('weapon', w.id!, w.name, w.equipped),
              )),
        const Divider(),

        // ── ARMURES ──────────────────────────────────────────────────────────
        _sectionHeader('Armures', Icons.shield_outlined, AppColors.allyPrimary, _addArmor),
        if (_armors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Aucune armure — appuyer sur + pour ajouter',
                style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
          )
        else
          ..._armors.map((a) => _ArmorRow(
                armor: a,
                onToggleEquip: () => _toggleArmorEquipped(a),
                onEdit: () => _editArmor(a),
                onDelete: () => _deleteArmor(a),
                onDesc: () => _showDescDialog(a.name, a.description, (v) async {
                  final updated = a.copyWith(description: v);
                  await _db.updateCombatArmor(updated);
                  setState(() => _armors[_armors.indexWhere((x) => x.id == a.id)] = updated);
                }),
                onEffects: () => _showEffectsDialog('armor', a.id!, a.name, a.equipped),
              )),
        const Divider(),

        // ── CAPACITÉS ────────────────────────────────────────────────────────
        _sectionHeader('Capacités', Icons.auto_awesome, Colors.purple, _addCapacity),
        if (_capacities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Aucune capacité — appuyer sur + pour ajouter',
                style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
          )
        else
          ..._capacities.map((c) => _CapacityRow(
                capacity: c,
                onToggleActivate: () => _toggleCapacityActivated(c),
                onEdit: () => _editCapacity(c),
                onDelete: () => _deleteCapacity(c),
                onRoll: () => _showRollDialog(
                  itemName: c.name,
                  dm: c.dm,
                  defaultAttType: c.isMagique ? 'magique' : 'contact',
                ),
                onDesc: () => _showDescDialog(c.name, c.description, (v) async {
                  final updated = c.copyWith(description: v);
                  await _db.updateCombatCapacity(updated);
                  setState(() => _capacities[_capacities.indexWhere((x) => x.id == c.id)] = updated);
                }),
                onEffects: () => _showEffectsDialog('capacity', c.id!, c.name, c.activated),
              )),
      ],
    );
  }
}

// ── Combat row widgets ────────────────────────────────────────────────────────

class _WeaponRow extends StatelessWidget {
  final CombatWeapon weapon;
  final VoidCallback onToggleEquip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDesc;
  final VoidCallback onEffects;
  final VoidCallback onRoll;

  const _WeaponRow({
    required this.weapon,
    required this.onToggleEquip,
    required this.onEdit,
    required this.onDelete,
    required this.onDesc,
    required this.onEffects,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    final isContact = weapon.type == 'contact';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isContact ? Icons.sports_martial_arts : Icons.gps_fixed,
              size: 20,
              color: weapon.equipped ? AppColors.enemyPrimary : AppColors.onSurfaceMuted,
            ),
            onPressed: onToggleEquip,
            tooltip: weapon.equipped ? 'Déséquiper' : 'Équiper',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weapon.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: weapon.equipped ? FontWeight.bold : FontWeight.normal)),
                Row(
                  children: [
                    _inlineChip(isContact ? 'Contact' : 'Distance',
                        bg: isContact
                            ? AppColors.enemyPrimary.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.15)),
                    if (weapon.dm.isNotEmpty)
                      _inlineChip('⚔ ${weapon.dm}', bg: AppColors.enemyPrimary.withValues(alpha: 0.2)),
                    if (!isContact && weapon.portee > 0)
                      _inlineChip('${weapon.portee} m'),
                    if (weapon.equipped) _inlineChip('équipée', bg: AppColors.enemyPrimary.withValues(alpha: 0.25)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Actions',
            onSelected: (v) {
              switch (v) {
                case 'roll': onRoll(); break;
                case 'edit': onEdit(); break;
                case 'effects': onEffects(); break;
                case 'desc': onDesc(); break;
                case 'delete': onDelete(); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'roll', child: ListTile(leading: Icon(Icons.casino_outlined), title: Text('Lancer les dés'), dense: true)),
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Modifier'), dense: true)),
              const PopupMenuItem(value: 'effects', child: ListTile(leading: Icon(Icons.auto_awesome_outlined), title: Text('Effets'), dense: true)),
              PopupMenuItem(value: 'desc', child: ListTile(leading: Icon(weapon.description.isNotEmpty ? Icons.description : Icons.description_outlined), title: const Text('Description'), dense: true)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: AppColors.enemyPrimary), title: Text('Supprimer', style: TextStyle(color: AppColors.enemyPrimary)), dense: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArmorRow extends StatelessWidget {
  final CombatArmor armor;
  final VoidCallback onToggleEquip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDesc;
  final VoidCallback onEffects;

  const _ArmorRow({
    required this.armor,
    required this.onToggleEquip,
    required this.onEdit,
    required this.onDelete,
    required this.onDesc,
    required this.onEffects,
  });

  @override
  Widget build(BuildContext context) {
    final enc = armor.encEffectif;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: armor.equipped,
            onChanged: (_) => onToggleEquip(),
            activeColor: AppColors.allyPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(armor.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: armor.equipped ? FontWeight.bold : FontWeight.normal)),
                Row(
                  children: [
                    _inlineChip(armor.type),
                    _inlineChip(armor.matiere),
                    if (armor.defBonus > 0) _inlineChip('+${armor.defBonus} DEF', bg: AppColors.allyPrimary.withValues(alpha: 0.2)),
                    if (enc > 0) _inlineChip('ENC $enc', bg: Colors.orange.withValues(alpha: 0.2)),
                    if (armor.niveauMagie > 0) _inlineChip('✦ Mag.${armor.niveauMagie}', bg: Colors.purple.withValues(alpha: 0.2)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Actions',
            onSelected: (v) {
              switch (v) {
                case 'edit': onEdit(); break;
                case 'effects': onEffects(); break;
                case 'desc': onDesc(); break;
                case 'delete': onDelete(); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Modifier'), dense: true)),
              const PopupMenuItem(value: 'effects', child: ListTile(leading: Icon(Icons.auto_awesome_outlined), title: Text('Effets'), dense: true)),
              PopupMenuItem(value: 'desc', child: ListTile(leading: Icon(armor.description.isNotEmpty ? Icons.description : Icons.description_outlined), title: const Text('Description'), dense: true)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: AppColors.enemyPrimary), title: Text('Supprimer', style: TextStyle(color: AppColors.enemyPrimary)), dense: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapacityRow extends StatelessWidget {
  final CombatCapacity capacity;
  final VoidCallback onToggleActivate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDesc;
  final VoidCallback onEffects;
  final VoidCallback onRoll;

  const _CapacityRow({
    required this.capacity,
    required this.onToggleActivate,
    required this.onEdit,
    required this.onDelete,
    required this.onDesc,
    required this.onEffects,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    final isAuto = capacity.isFromVoie;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              capacity.isMagique ? Icons.auto_fix_high : Icons.flash_on,
              size: 20,
              color: capacity.activated ? Colors.purple : AppColors.onSurfaceMuted,
            ),
            onPressed: onToggleActivate,
            tooltip: capacity.activated ? 'Désactiver' : 'Activer',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(capacity.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: capacity.activated ? FontWeight.bold : FontWeight.normal)),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    if (isAuto)
                      _inlineChip('⚔ Voie', bg: Colors.orange.withValues(alpha: 0.2)),
                    if (capacity.isMagique) _inlineChip('Magique', bg: Colors.purple.withValues(alpha: 0.2)),
                    if (capacity.voie.isNotEmpty) _inlineChip(capacity.voie),
                    _inlineChip('Rang ${capacity.rang}'),
                    if (capacity.dm.isNotEmpty)
                      _inlineChip('⚔ ${capacity.dm}', bg: Colors.purple.withValues(alpha: 0.15)),
                    if (capacity.portee > 0) _inlineChip('${capacity.portee} m'),
                    if (capacity.activated) _inlineChip('actif', bg: Colors.purple.withValues(alpha: 0.3)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Actions',
            onSelected: (v) {
              switch (v) {
                case 'roll': onRoll(); break;
                case 'edit': onEdit(); break;
                case 'effects': onEffects(); break;
                case 'desc': onDesc(); break;
                case 'delete': onDelete(); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'roll', child: ListTile(leading: Icon(Icons.casino_outlined), title: Text('Lancer les dés'), dense: true)),
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Modifier'), dense: true)),
              const PopupMenuItem(value: 'effects', child: ListTile(leading: Icon(Icons.auto_awesome_outlined), title: Text('Effets'), dense: true)),
              PopupMenuItem(value: 'desc', child: ListTile(leading: Icon(capacity.description.isNotEmpty ? Icons.description : Icons.description_outlined), title: const Text('Description'), dense: true)),
              if (!isAuto) ...[
                const PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: AppColors.enemyPrimary), title: Text('Supprimer', style: TextStyle(color: AppColors.enemyPrimary)), dense: true)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Widget _inlineChip(String label, {Color? bg}) => Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted)),
    );

Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color, String? tooltip}) => IconButton(
      icon: Icon(icon, size: 18),
      color: color ?? AppColors.onSurfaceMuted,
      onPressed: onTap,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );

// ── Item Effects Dialog ───────────────────────────────────────────────────────

class _ItemEffectsDialog extends StatefulWidget {
  final DatabaseService db;
  final String itemType;
  final int itemId;
  final String itemName;

  const _ItemEffectsDialog({
    required this.db,
    required this.itemType,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<_ItemEffectsDialog> createState() => _ItemEffectsDialogState();
}

class _ItemEffectsDialogState extends State<_ItemEffectsDialog> {
  List<ItemEffect> _effects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final effects = await widget.db.getItemEffects(widget.itemType, widget.itemId);
    if (!mounted) return;
    setState(() {
      _effects = effects;
      _loading = false;
    });
  }

  Future<void> _addEffect() async {
    String statKey = kEffectStatKeys.first.key;
    int value = 1;
    final valueCtrl = TextEditingController(text: '1');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ajouter un effet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: statKey,
                decoration: const InputDecoration(labelText: 'Statistique', border: OutlineInputBorder()),
                items: kEffectStatKeys
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.label)))
                    .toList(),
                onChanged: (v) => setS(() => statKey = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Valeur (+ ou -)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => value = int.tryParse(v) ?? 1,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    final effect = ItemEffect(
      itemType: widget.itemType,
      itemId: widget.itemId,
      statKey: statKey,
      modifierValue: value,
    );
    final created = await widget.db.insertItemEffect(effect);
    setState(() => _effects.add(created));
  }

  Future<void> _deleteEffect(ItemEffect e) async {
    await widget.db.deleteItemEffect(e.id!);
    setState(() => _effects.removeWhere((x) => x.id == e.id));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Effets — ${widget.itemName}'),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_effects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Aucun effet', style: TextStyle(color: AppColors.onSurfaceMuted)),
                    )
                  else
                    ..._effects.map((e) {
                      final label = kEffectStatKeys
                          .firstWhere((x) => x.key == e.statKey,
                              orElse: () => (key: e.statKey, label: e.statKey))
                          .label;
                      final sign = e.modifierValue >= 0 ? '+' : '';
                      return ListTile(
                        dense: true,
                        title: Text(label),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$sign${e.modifierValue}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: e.modifierValue >= 0
                                      ? AppColors.allyPrimary
                                      : AppColors.enemyPrimary,
                                )),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: AppColors.enemyPrimary,
                              onPressed: () => _deleteEffect(e),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addEffect,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter un effet'),
                  ),
                ],
              ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ],
    );
  }
}
