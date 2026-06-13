import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../constants/cof2_data.dart';
import '../../constants/voies_data.dart';
import '../../constants/voies_prestige_data.dart';
import '../../models/character_sheet.dart';
import '../../models/combat_armor.dart';
import '../../models/combat_capacity.dart';
import '../../models/combat_weapon.dart';
import '../../models/inventory_item.dart';
import '../../models/item_effect.dart';
import '../../providers/character_sheet_provider.dart';
import '../../services/database_service.dart';

part 'character_sheet_screen_shared.dart';
part 'character_sheet_screen_voies.dart';
part 'character_sheet_screen_carac.dart';
part 'character_sheet_screen_inventaire.dart';
part 'character_sheet_screen_dice_log.dart';
part 'character_sheet_screen_combat.dart';
part 'character_sheet_screen_voie_peuple_dialog.dart';

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
    if (idx < 0) {
      Navigator.of(context).pop();
      return;
    }
    final sheet = sheets[idx];
    _initControllers(sheet);
    setState(() => _sheet = sheet);
    if (sheet.id != null) {
      provider.loadVoieRangs(sheet.id!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureSingleChoicePeupleVoie(sheet.id!);
      });
      // Repair mage origin if needed (for characters configured before this feature)
      if (sheet.voiePeupleId == 'peuple_voie-du-mage' &&
          sheet.voiePeupleOrigineId.isEmpty &&
          sheet.race.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureMageOrigineId(sheet.id!);
        });
      }
    }
  }

  /// Backfills voie de peuple for existing sheets that have a peuple but no voie.
  /// Applies only when there is a single obvious voie for that peuple.
  Future<void> _ensureSingleChoicePeupleVoie(int sheetId) async {
    if (!mounted || _sheet == null) return;
    if (_sheet!.race.isEmpty) return;
    final choices = getVoiesChoixPourPeuple(_sheet!.race);
    final isMageVoie = _sheet!.voiePeupleId == 'peuple_voie-du-mage';
    final hasValidVoieForRace =
        _sheet!.voiePeupleId.isNotEmpty &&
        (isMageVoie || choices.any((v) => v.id == _sheet!.voiePeupleId));
    if (hasValidVoieForRace) return;
    if (choices.length != 1) return;

    final voieId = choices.first.id;
    final provider = context.read<CharacterSheetProvider>();
    await provider.setVoiePeuple(sheetId, voieId);
    if (!mounted || _sheet == null) return;
    setState(() => _sheet = _sheet!.copyWith(voiePeupleId: voieId));
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
        builder:
            (ctx) => AlertDialog(
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

    // Restore all resources to max after profil change
    if (mounted && _sheet != null) {
      setState(
        () =>
            _sheet = _sheet!.copyWith(
              pvActuel: _sheet!.pvMax,
              pmActuel: _sheet!.pmMax,
              drActuel: _sheet!.drMax,
              pcActuel: _sheet!.pcMax,
            ),
      );
      _markDirty();
    }

    // Re-resolve voie de peuple after profil change (if a peuple is selected)
    if (mounted && _selectedPeuple != null) {
      await _resolvePeupleVoieForProfil(newProfil);
    }
  }

  /// Auto-calcule pmBase = capacités magiques débloquées + VOL et met à jour la fiche.
  void _syncPmBase() {
    final id = _sheet?.id;
    if (id == null) return;
    final provider = context.read<CharacterSheetProvider>();
    final magicCount = provider.getMagicCapacitesCount(id);
    // pmBase cannot go negative: a non-magical character always has 0 PM base
    final newPmBase = (magicCount + (_sheet!.volTotal)).clamp(0, 9999);
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
      name:
          _nameCtrl.text.trim().isEmpty ? _sheet!.name : _nameCtrl.text.trim(),
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
        const SnackBar(
          content: Text('Fiche sauvegardée'),
          duration: Duration(seconds: 1),
        ),
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
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Text('⭐ ', style: TextStyle(fontSize: 20)),
                Text('Monter de niveau ?'),
              ],
            ),
            content: Text(
              '${_sheet!.name} va passer au niveau $nextLevel.\n\nConfirmes-tu la montée de niveau ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
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
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.arrow_downward, color: Colors.grey[500], size: 20),
                const SizedBox(width: 8),
                const Text('Rétrograder ?'),
              ],
            ),
            content: Text(
              '${_sheet!.name} va repasser au niveau $downLevel.\n\nCette action est irréversible. Confirmes-tu la rétrogradation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: Colors.grey[600],
                ),
                label: Text(
                  'Niveau $downLevel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
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
      setState(
        () =>
            _sheet = leveled.copyWith(
              pvActuel: leveled.pvMax,
              pmActuel: leveled.pmMax,
              drActuel: leveled.drMax,
              pcActuel: leveled.pcMax,
            ),
      );
      _markDirty();
    });
  }

  void _doLevelUp() {
    if (_sheet == null) return;
    final old = _sheet!;
    final newLevel = (old.level + 1).clamp(1, 20);
    final leveled = old.copyWith(level: newLevel);
    // Gains
    final pvGain = leveled.pvMax - old.pvMax;
    final oldAttC = old.attContactTotal;
    final oldAttD = old.attDistanceTotal;
    final oldAttM = old.attMagiqueTotal;
    final totalPcOld = old.level * 2;
    final totalPcNew = newLevel * 2;

    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const Text('⭐ ', style: TextStyle(fontSize: 22)),
                Expanded(
                  child: Text(
                    '${old.name} — Niveau $newLevel !',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Félicitations ! Voici ce que tu gagnes :',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // PV
                  _levelUpRow(
                    '❤️',
                    'Points de vie max',
                    '${old.pvMax} → ${leveled.pvMax}',
                    '+$pvGain PV',
                    const Color(0xFFE53935),
                  ),
                  const SizedBox(height: 8),
                  // Attaque Contact
                  _levelUpRow(
                    '⚔️',
                    'Attaque Contact',
                    '$oldAttC → ${oldAttC + 1}',
                    '+1',
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  // Attaque Distance
                  _levelUpRow(
                    '🏹',
                    'Attaque Distance',
                    '$oldAttD → ${oldAttD + 1}',
                    '+1',
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  // Attaque Magique
                  _levelUpRow(
                    '✨',
                    'Attaque Magique',
                    '$oldAttM → ${oldAttM + 1}',
                    '+1',
                    const Color(0xFF6A1B9A),
                  ),
                  const Divider(height: 24),
                  // Points de compétence
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🎓 ', style: TextStyle(fontSize: 18)),
                            Text(
                              'Points de compétence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Niv. ${old.level} × 2 = $totalPcOld  →  Niv. $newLevel × 2 = $totalPcNew',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total disponible : $totalPcNew pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB300),
                          ),
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
                child: const Text('Annuler'),
              ),
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
    String emoji,
    String label,
    String range,
    String gain,
    Color color,
  ) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                range,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
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
          child: Text(
            gain,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            )
          else if (!_dirty)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(
                child: Icon(
                  Icons.cloud_done_outlined,
                  size: 20,
                  color: Colors.white54,
                ),
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.casino_outlined),
                tooltip: 'Journal des dés',
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => _DiceLogScreen(log: List.from(_diceLog)),
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
                _NotesTab(
                  controller: _descCtrl,
                  hint: 'Notes biographiques, apparence, personnalité…',
                  onChanged: _markDirty,
                ),
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
                  voieRangs: context
                      .watch<CharacterSheetProvider>()
                      .getVoieRangs(_sheet!.id ?? 0),
                  pcDepense: context
                      .watch<CharacterSheetProvider>()
                      .getPcDepense(_sheet!.id ?? 0),
                  voiePeupleId: _sheet!.voiePeupleId,
                  voiePeupleOrigineId: _sheet!.voiePeupleOrigineId,
                  voieMageRang2Pris: _sheet!.voieMageRang2Pris,
                  voiePrestigeId: _sheet!.voiePrestigeId,
                  onSetRang: (voieId, rang) async {
                    final id = _sheet!.id;
                    if (id != null) {
                      await context.read<CharacterSheetProvider>().setVoieRang(
                        id,
                        voieId,
                        rang,
                      );
                      _syncPmBase();
                      _combatTabKey.currentState?.reload();
                    }
                  },
                  onMageRang2Pris: () async {
                    final id = _sheet!.id;
                    if (id == null) return;
                    final provider = context.read<CharacterSheetProvider>();
                    await provider.setVoieMageRang2Pris(id, true);
                    if (mounted) {
                      setState(
                        () =>
                            _sheet = _sheet!.copyWith(voieMageRang2Pris: true),
                      );
                    }
                  },
                  onMageRang2Reset: () async {
                    final id = _sheet!.id;
                    if (id == null) return;
                    final provider = context.read<CharacterSheetProvider>();
                    await provider.setVoieMageRang2Pris(id, false);
                    if (mounted) {
                      setState(
                        () =>
                            _sheet = _sheet!.copyWith(voieMageRang2Pris: false),
                      );
                    }
                  },
                  onSetVoiePrestige: (voieId) async {
                    final id = _sheet!.id;
                    if (id != null) {
                      await context
                          .read<CharacterSheetProvider>()
                          .setVoiePrestige(id, voieId);
                      if (mounted) {
                        setState(
                          () => _sheet = _sheet!.copyWith(
                            voiePrestigeId: voieId,
                          ),
                        );
                        _markDirty();
                      }
                    }
                  },
                ),
                _NotesTab(
                  controller: _effetsCtrl,
                  hint: 'Effets actifs, malédictions, bénédictions…',
                  onChanged: _markDirty,
                ),
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
          onPressed:
              () => Navigator.of(context).push(
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
      builder:
          (_) => AlertDialog(
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
  void _onPeupleChanged(String? newPeuple) async {
    final resetSheet = _sheet!.copyWith(
      race: newPeuple ?? '',
      voiePeupleId: '',
      voiePeupleOrigineId: '',
      voieMageRang2Pris: false,
      agiRacial: 0,
      conRacial: 0,
      forRacial: 0,
      perRacial: 0,
      chaRacial: 0,
      intRacial: 0,
      volRacial: 0,
    );
    setState(() {
      _selectedPeuple = newPeuple;
      _sheet = resetSheet;
    });
    _scheduleSave();
    if (newPeuple != null) {
      final sheetId = _sheet?.id;
      if (sheetId != null) {
        final provider = context.read<CharacterSheetProvider>();
        await provider.setVoiePeuple(sheetId, '');
        await provider.setVoiePeupleOrigine(sheetId, '');
        await provider.setVoieMageRang2Pris(sheetId, false);
      }
      if (!mounted) return;
      await _showRacialDialog(newPeuple);
      if (!mounted) return;
      await _resolvePeupleVoie(newPeuple);
    } else {
      // Peuple cleared: clear voie de peuple and restore resources
      final sheetId = _sheet?.id;
      if (sheetId != null) {
        context.read<CharacterSheetProvider>().setVoiePeuple(sheetId, '');
      }
      setState(
        () =>
            _sheet = _sheet!.copyWith(
              voiePeupleId: '',
              pvActuel: _sheet!.pvMax,
              pmActuel: _sheet!.pmMax,
              drActuel: _sheet!.drMax,
              pcActuel: _sheet!.pcMax,
            ),
      );
      _scheduleSave();
    }
  }

  Future<void> _showRacialDialog(String peuple) async {
    final choice = getRacialChoice(peuple);
    if (choice == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _RacialDialog(
            peuple: peuple,
            choice: choice,
            currentSheet: _sheet!,
            onApply: (updated) {
              _onCaracChanged(updated);
              // Restore resources after racial bonuses are applied (pvMax etc. may have changed)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _sheet != null) {
                  setState(
                    () =>
                        _sheet = _sheet!.copyWith(
                          pvActuel: _sheet!.pvMax,
                          pmActuel: _sheet!.pmMax,
                          drActuel: _sheet!.drMax,
                          pcActuel: _sheet!.pcMax,
                        ),
                  );
                  _scheduleSave();
                }
              });
            },
          ),
    );
  }

  /// Resolves and assigns the voie de peuple when the peuple changes.
  /// Handles: Mage voie preservation dialog, multi-choice (demi-elfe), single-choice.
  Future<void> _resolvePeupleVoie(String peuple) async {
    if (!mounted || _sheet == null) return;
    final sheetId = _sheet!.id;
    if (sheetId == null) return;

    final choices = getVoiesChoixPourPeuple(peuple);
    if (choices.isEmpty) return;

    final currentVoiePeupleId = _sheet!.voiePeupleId;
    final isMageVoieActive = currentVoiePeupleId == 'peuple_voie-du-mage';

    // If voie du mage is active, ask whether to keep it or replace with peuple voie
    if (isMageVoieActive) {
      if (!mounted) return;
      final keepMage = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Voie du Mage active'),
              content: Text(
                'Ce personnage utilise la Voie du Mage à la place de sa voie de peuple. '
                'Voulez-vous conserver la Voie du Mage ou l\'remplacer par la voie de $peuple ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Conserver la Voie du Mage'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Appliquer voie de $peuple'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      if (keepMage == true) return; // keep voie du mage as-is
    }

    // Determine which voie to assign
    String selectedVoieId;
    if (choices.length == 1) {
      selectedVoieId = choices.first.id;
    } else {
      // Multiple choices: show selection dialog (e.g. demi-elfe)
      if (!mounted) return;
      final picked = await showDialog<VoieCatalogue>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => _VoiePeupleChoixDialog(peuple: peuple, choices: choices),
      );
      if (!mounted || picked == null) return;
      selectedVoieId = picked.id;
    }

    await context.read<CharacterSheetProvider>().setVoiePeuple(
      sheetId,
      selectedVoieId,
    );
    // Clear mage heritage data when assigning a normal peuple voie
    final provider = context.read<CharacterSheetProvider>();
    await provider.setVoiePeupleOrigine(sheetId, '');
    await provider.setVoieMageRang2Pris(sheetId, false);
    if (mounted) {
      setState(
        () =>
            _sheet = _sheet!.copyWith(
              voiePeupleId: selectedVoieId,
              voiePeupleOrigineId: '',
              voieMageRang2Pris: false,
            ),
      );
    }
  }

  /// Ensures voiePeupleOrigineId is populated for a Mage character (read-only display only).
  Future<void> _ensureMageOrigineId(int sheetId) async {
    if (_sheet == null) return;
    if (_sheet!.voiePeupleOrigineId.isNotEmpty) return;

    final choices = getVoiesChoixPourPeuple(_sheet!.race);
    if (choices.isEmpty) return;
    final origineId = choices.first.id;
    await context.read<CharacterSheetProvider>().setVoiePeupleOrigine(
      sheetId,
      origineId,
    );
    if (mounted) {
      setState(() => _sheet = _sheet!.copyWith(voiePeupleOrigineId: origineId));
    }
  }

  /// Resolves voie de peuple after a profil change.
  /// If new profil is Mage: offer Voie du Mage. If not Mage + voie du mage active: revert.
  Future<void> _resolvePeupleVoieForProfil(String newProfil) async {
    if (!mounted || _sheet == null || _selectedPeuple == null) return;
    final sheetId = _sheet!.id;
    if (sheetId == null) return;

    final isMageFamily = getFamilleForProfil(newProfil) == 'Mage';
    final currentVoiePeupleId = _sheet!.voiePeupleId;
    final isMageVoieActive = currentVoiePeupleId == 'peuple_voie-du-mage';

    if (isMageFamily) {
      if (isMageVoieActive) {
        // Already has Voie du Mage — just ensure origineId is populated (repair if empty)
        await _ensureMageOrigineId(sheetId);
        return;
      }
      // Offer to replace peuple voie with voie du mage
      if (!mounted) return;
      final useMage = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Voie du Mage disponible'),
              content: Text(
                'Le profil $_selectedProfil appartient à la famille des Mages. '
                'Voulez-vous remplacer votre voie de peuple par la Voie du Mage ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Conserver la voie de peuple'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Utiliser la Voie du Mage'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      if (useMage == true) {
        final provider = context.read<CharacterSheetProvider>();
        final rawOrigineId = _sheet!.voiePeupleId;
        final origineId =
            rawOrigineId == 'peuple_voie-du-mage' ? '' : rawOrigineId;
        await provider.setVoiePeuple(sheetId, 'peuple_voie-du-mage');
        String effectiveOrigineId = origineId;
        if (effectiveOrigineId.isEmpty && _sheet!.race.isNotEmpty) {
          final choices = getVoiesChoixPourPeuple(_sheet!.race);
          if (choices.isNotEmpty) effectiveOrigineId = choices.first.id;
        }
        await provider.setVoiePeupleOrigine(sheetId, effectiveOrigineId);
        setState(
          () =>
              _sheet = _sheet!.copyWith(
                voiePeupleId: 'peuple_voie-du-mage',
                voiePeupleOrigineId: effectiveOrigineId,
              ),
        );
        return;
      }
      // Fell through: assign normal peuple voie
      await _resolvePeupleVoie(_selectedPeuple!);
    } else {
      if (isMageVoieActive) {
        // Profil is not Mage anymore: remove voie du mage and apply normal peuple voie
        await _resolvePeupleVoie(_selectedPeuple!);
      } else {
        // Normal profil change: re-resolve peuple voie normally
        await _resolvePeupleVoie(_selectedPeuple!);
      }
    }
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
                    const Text(
                      'Niveau',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
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
                      itemBuilder:
                          (_) => [
                            PopupMenuItem(
                              value: 'levelup',
                              enabled: (_sheet?.level ?? 1) < 20,
                              child: const Row(
                                children: [
                                  Text('⭐ ', style: TextStyle(fontSize: 16)),
                                  Text('Level Up !'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'leveldown',
                              enabled: (_sheet?.level ?? 1) > 1,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rétrograder',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
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
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: AppColors.onSurfaceMuted,
                            ),
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
                  onInfo:
                      _selectedPeuple == null
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
                  badge:
                      _selectedProfil != null
                          ? getFamilleForProfil(_selectedProfil!)
                          : null,
                  onInfo:
                      _selectedProfil == null
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
