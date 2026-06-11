part of 'character_sheet_screen.dart';

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
    final created = await _db.insertCombatWeapon(
      result.copyWith(
        characterSheetId: widget.sheetId,
        position: _weapons.length,
      ),
    );
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
    setState(
      () => _weapons[_weapons.indexWhere((x) => x.id == w.id)] = updated,
    );
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
    final porteeCtrl = TextEditingController(
      text: (existing?.portee ?? 0) == 0 ? '' : '${existing!.portee}',
    );
    final dmCtrl = TextEditingController(text: existing?.dm ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final result = await showDialog<CombatWeapon>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => AlertDialog(
                  title: Text(
                    existing == null ? 'Ajouter une arme' : 'Modifier l\'arme',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Type', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'contact',
                              label: Text('Contact'),
                              icon: Icon(Icons.sports_martial_arts, size: 16),
                            ),
                            ButtonSegment(
                              value: 'distance',
                              label: Text('Distance'),
                              icon: Icon(Icons.gps_fixed, size: 16),
                            ),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Portée (m)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final n = nameCtrl.text.trim();
                        if (n.isEmpty) return;
                        Navigator.pop(
                          ctx,
                          CombatWeapon(
                            id: existing?.id,
                            characterSheetId: widget.sheetId,
                            name: n,
                            type: type,
                            portee: int.tryParse(porteeCtrl.text) ?? 0,
                            equipped: existing?.equipped ?? false,
                            description: descCtrl.text,
                            position: existing?.position ?? 0,
                            dm: dmCtrl.text.trim(),
                          ),
                        );
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
    final created = await _db.insertCombatArmor(
      result.copyWith(characterSheetId: widget.sheetId),
    );
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => AlertDialog(
                  title: Text(
                    existing == null
                        ? 'Ajouter une armure'
                        : 'Modifier l\'armure',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              kArmorTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setS(() => type = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: matiere,
                          decoration: const InputDecoration(
                            labelText: 'Matière',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              kArmorMatieres
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
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
                                decoration: const InputDecoration(
                                  labelText: 'Bonus DEF',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged:
                                    (v) =>
                                        defBonus = int.tryParse(v) ?? defBonus,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: encCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'ENC base',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged:
                                    (v) => encBase = int.tryParse(v) ?? encBase,
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
                          onChanged:
                              (v) =>
                                  niveauMagie = int.tryParse(v) ?? niveauMagie,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final n = nameCtrl.text.trim();
                        if (n.isEmpty) return;
                        Navigator.pop(
                          ctx,
                          CombatArmor(
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
                          ),
                        );
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
    final created = await _db.insertCombatCapacity(
      result.copyWith(
        characterSheetId: widget.sheetId,
        position: _capacities.length,
      ),
    );
    setState(() => _capacities.add(created));
  }

  Future<void> _editCapacity(CombatCapacity c) async {
    final result = await _showCapacityDialog(c);
    if (result == null) return;
    await _db.updateCombatCapacity(result);
    setState(
      () => _capacities[_capacities.indexWhere((x) => x.id == c.id)] = result,
    );
    if (c.activated || result.activated) await _recalc();
  }

  Future<void> _toggleCapacityActivated(CombatCapacity c) async {
    final updated = c.copyWith(activated: !c.activated);
    await _db.updateCombatCapacity(updated);
    setState(
      () => _capacities[_capacities.indexWhere((x) => x.id == c.id)] = updated,
    );
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
    final porteeCtrl = TextEditingController(
      text: (existing?.portee ?? 0) == 0 ? '' : '${existing!.portee}',
    );
    final dmCtrl = TextEditingController(text: existing?.dm ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final result = await showDialog<CombatCapacity>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => AlertDialog(
                  title: Text(
                    existing == null
                        ? 'Ajouter une capacité'
                        : 'Modifier la capacité',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: voieCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Voie',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rang',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Slider(
                                    value: rang.toDouble(),
                                    min: 1,
                                    max: 8,
                                    divisions: 7,
                                    label: '$rang',
                                    onChanged:
                                        (v) => setS(() => rang = v.round()),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: porteeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Portée (m)',
                                  border: OutlineInputBorder(),
                                ),
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
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final n = nameCtrl.text.trim();
                        if (n.isEmpty) return;
                        Navigator.pop(
                          ctx,
                          CombatCapacity(
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
                          ),
                        );
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

  Future<void> _showEffectsDialog(
    String itemType,
    int itemId,
    String itemName,
    bool isActive,
  ) async {
    await showDialog(
      context: context,
      builder:
          (ctx) => _ItemEffectsDialog(
            db: _db,
            itemType: itemType,
            itemId: itemId,
            itemName: itemName,
          ),
    );
    if (isActive) await _recalc();
  }

  // ── Description dialog ────────────────────────────────────────────────────

  Future<void> _showDescDialog(
    String title,
    String current,
    ValueChanged<String> onSave,
  ) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
    if (result != null) onSave(result);
  }

  // ── Dice roll ─────────────────────────────────────────────────────────────

  /// Parses a DM string like "2d8+1d4+3" into individual rolls.
  /// Returns null if the string is empty or contains no valid dice/constants.
  ({int total, String detail})? _rollDm(String dm) {
    if (dm.trim().isEmpty) return null;
    // Tokenize: split on + keeping sign, then on - keeping sign
    final tokens = <String>[];
    final tokenRe = RegExp(
      r'([+-]?\s*\d+d\d+|[+-]?\s*\d+)',
      caseSensitive: false,
    );
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
      case 'FOR':
        return s.forTotal;
      case 'AGI':
        return s.agiTotal;
      case 'CON':
        return s.conTotal;
      case 'PER':
        return s.perTotal;
      case 'CHA':
        return s.chaTotal;
      case 'INT':
        return s.intTotal;
      case 'VOL':
        return s.volTotal;
      default:
        return 0;
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.casino_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lancer — $itemName',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modificateur d\'attaque',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'contact',
                            label: Text(
                              'Contact',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: 'distance',
                            label: Text(
                              'Distance',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: 'magique',
                            label: Text(
                              'Magique',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        selected: {attType},
                        onSelectionChanged:
                            (s) => setS(() => attType = s.first),
                      ),
                      if (dm.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Dégâts : $dm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String?>(
                          value: dmStat,
                          decoration: const InputDecoration(
                            labelText: 'Bonus caract. aux dégâts',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Aucun'),
                            ),
                            ...statOptions.map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            ),
                          ],
                          onChanged: (v) => setS(() => dmStat = v),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
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
    final attBonus =
        attType == 'contact'
            ? sheet.attContactTotal
            : attType == 'distance'
            ? sheet.attDistanceTotal
            : sheet.attMagiqueTotal;
    final attTotal = d20 + attBonus;
    final attLabel =
        'Attaque ${attType[0].toUpperCase()}${attType.substring(1)}';
    final attDetail =
        'd20($d20) + $attBonus ($attType) = $attTotal'
        '${d20 == 20
            ? ' 🎯 CRITIQUE !'
            : d20 == 1
            ? ' 💀 ÉCHEC CRITIQUE'
            : ''}';

    widget.onDiceRoll?.call(
      DiceLogEntry(
        label: '$itemName — $attLabel',
        die: 'd20',
        dieResult: d20,
        bonus: attBonus,
        total: attTotal,
        detail: attDetail,
      ),
    );

    // ── Jet de dégâts ──
    if (dm.isNotEmpty) {
      final dmRoll = _rollDm(dm);
      if (dmRoll != null) {
        final statBonus = dmStat != null ? _statValue(sheet, dmStat!) : 0;
        final dmTotal = dmRoll.total + statBonus;
        final statPart = dmStat != null ? ' + $dmStat($statBonus)' : '';
        final dmDetail = '${dmRoll.detail}$statPart = $dmTotal';

        widget.onDiceRoll?.call(
          DiceLogEntry(
            label: '$itemName — Dégâts ($dm)',
            die: dm,
            dieResult: dmRoll.total,
            bonus: statBonus,
            total: dmTotal,
            detail: dmDetail,
          ),
        );
      }
    }
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color color,
    VoidCallback onAdd,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
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
        _sectionHeader(
          'Armes',
          Icons.sports_martial_arts,
          AppColors.enemyPrimary,
          _addWeapon,
        ),
        if (_weapons.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Aucune arme — appuyer sur + pour ajouter',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          )
        else
          ..._weapons.map(
            (w) => _WeaponRow(
              weapon: w,
              onToggleEquip: () => _toggleWeaponEquipped(w),
              onEdit: () => _editWeapon(w),
              onDelete: () => _deleteWeapon(w),
              onRoll:
                  () => _showRollDialog(
                    itemName: w.name,
                    dm: w.dm,
                    defaultAttType:
                        w.type == 'distance' ? 'distance' : 'contact',
                  ),
              onDesc:
                  () => _showDescDialog(w.name, w.description, (v) async {
                    final updated = w.copyWith(description: v);
                    await _db.updateCombatWeapon(updated);
                    setState(
                      () =>
                          _weapons[_weapons.indexWhere((x) => x.id == w.id)] =
                              updated,
                    );
                  }),
              onEffects:
                  () => _showEffectsDialog('weapon', w.id!, w.name, w.equipped),
            ),
          ),
        const Divider(),

        // ── ARMURES ──────────────────────────────────────────────────────────
        _sectionHeader(
          'Armures',
          Icons.shield_outlined,
          AppColors.allyPrimary,
          _addArmor,
        ),
        if (_armors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Aucune armure — appuyer sur + pour ajouter',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          )
        else
          ..._armors.map(
            (a) => _ArmorRow(
              armor: a,
              onToggleEquip: () => _toggleArmorEquipped(a),
              onEdit: () => _editArmor(a),
              onDelete: () => _deleteArmor(a),
              onDesc:
                  () => _showDescDialog(a.name, a.description, (v) async {
                    final updated = a.copyWith(description: v);
                    await _db.updateCombatArmor(updated);
                    setState(
                      () =>
                          _armors[_armors.indexWhere((x) => x.id == a.id)] =
                              updated,
                    );
                  }),
              onEffects:
                  () => _showEffectsDialog('armor', a.id!, a.name, a.equipped),
            ),
          ),
        const Divider(),

        // ── CAPACITÉS ────────────────────────────────────────────────────────
        _sectionHeader(
          'Capacités',
          Icons.auto_awesome,
          Colors.purple,
          _addCapacity,
        ),
        if (_capacities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Aucune capacité — appuyer sur + pour ajouter',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          )
        else
          ..._capacities.map(
            (c) => _CapacityRow(
              capacity: c,
              onToggleActivate: () => _toggleCapacityActivated(c),
              onEdit: () => _editCapacity(c),
              onDelete: () => _deleteCapacity(c),
              onRoll:
                  () => _showRollDialog(
                    itemName: c.name,
                    dm: c.dm,
                    defaultAttType: c.isMagique ? 'magique' : 'contact',
                  ),
              onDesc:
                  () => _showDescDialog(c.name, c.description, (v) async {
                    final updated = c.copyWith(description: v);
                    await _db.updateCombatCapacity(updated);
                    setState(
                      () =>
                          _capacities[_capacities.indexWhere(
                                (x) => x.id == c.id,
                              )] =
                              updated,
                    );
                  }),
              onEffects:
                  () => _showEffectsDialog(
                    'capacity',
                    c.id!,
                    c.name,
                    c.activated,
                  ),
            ),
          ),
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
              color:
                  weapon.equipped
                      ? AppColors.enemyPrimary
                      : AppColors.onSurfaceMuted,
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
                Text(
                  weapon.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        weapon.equipped ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Row(
                  children: [
                    _inlineChip(
                      isContact ? 'Contact' : 'Distance',
                      bg:
                          isContact
                              ? AppColors.enemyPrimary.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                    ),
                    if (weapon.dm.isNotEmpty)
                      _inlineChip(
                        '⚔ ${weapon.dm}',
                        bg: AppColors.enemyPrimary.withValues(alpha: 0.2),
                      ),
                    if (!isContact && weapon.portee > 0)
                      _inlineChip('${weapon.portee} m'),
                    if (weapon.equipped)
                      _inlineChip(
                        'équipée',
                        bg: AppColors.enemyPrimary.withValues(alpha: 0.25),
                      ),
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
                case 'roll':
                  onRoll();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'effects':
                  onEffects();
                  break;
                case 'desc':
                  onDesc();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'roll',
                    child: ListTile(
                      leading: Icon(Icons.casino_outlined),
                      title: Text('Lancer les dés'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'effects',
                    child: ListTile(
                      leading: Icon(Icons.auto_awesome_outlined),
                      title: Text('Effets'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'desc',
                    child: ListTile(
                      leading: Icon(
                        weapon.description.isNotEmpty
                            ? Icons.description
                            : Icons.description_outlined,
                      ),
                      title: const Text('Description'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppColors.enemyPrimary,
                      ),
                      title: Text(
                        'Supprimer',
                        style: TextStyle(color: AppColors.enemyPrimary),
                      ),
                      dense: true,
                    ),
                  ),
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
                Text(
                  armor.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        armor.equipped ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Row(
                  children: [
                    _inlineChip(armor.type),
                    _inlineChip(armor.matiere),
                    if (armor.defBonus > 0)
                      _inlineChip(
                        '+${armor.defBonus} DEF',
                        bg: AppColors.allyPrimary.withValues(alpha: 0.2),
                      ),
                    if (enc > 0)
                      _inlineChip(
                        'ENC $enc',
                        bg: Colors.orange.withValues(alpha: 0.2),
                      ),
                    if (armor.niveauMagie > 0)
                      _inlineChip(
                        '✦ Mag.${armor.niveauMagie}',
                        bg: Colors.purple.withValues(alpha: 0.2),
                      ),
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
                case 'edit':
                  onEdit();
                  break;
                case 'effects':
                  onEffects();
                  break;
                case 'desc':
                  onDesc();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'effects',
                    child: ListTile(
                      leading: Icon(Icons.auto_awesome_outlined),
                      title: Text('Effets'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'desc',
                    child: ListTile(
                      leading: Icon(
                        armor.description.isNotEmpty
                            ? Icons.description
                            : Icons.description_outlined,
                      ),
                      title: const Text('Description'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppColors.enemyPrimary,
                      ),
                      title: Text(
                        'Supprimer',
                        style: TextStyle(color: AppColors.enemyPrimary),
                      ),
                      dense: true,
                    ),
                  ),
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
              color:
                  capacity.activated ? Colors.purple : AppColors.onSurfaceMuted,
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
                Text(
                  capacity.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        capacity.activated
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    if (isAuto)
                      _inlineChip(
                        '⚔ Voie',
                        bg: Colors.orange.withValues(alpha: 0.2),
                      ),
                    if (capacity.isMagique)
                      _inlineChip(
                        'Magique',
                        bg: Colors.purple.withValues(alpha: 0.2),
                      ),
                    if (capacity.voie.isNotEmpty) _inlineChip(capacity.voie),
                    _inlineChip('Rang ${capacity.rang}'),
                    if (capacity.dm.isNotEmpty)
                      _inlineChip(
                        '⚔ ${capacity.dm}',
                        bg: Colors.purple.withValues(alpha: 0.15),
                      ),
                    if (capacity.portee > 0)
                      _inlineChip('${capacity.portee} m'),
                    if (capacity.activated)
                      _inlineChip(
                        'actif',
                        bg: Colors.purple.withValues(alpha: 0.3),
                      ),
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
                case 'roll':
                  onRoll();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'effects':
                  onEffects();
                  break;
                case 'desc':
                  onDesc();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'roll',
                    child: ListTile(
                      leading: Icon(Icons.casino_outlined),
                      title: Text('Lancer les dés'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'effects',
                    child: ListTile(
                      leading: Icon(Icons.auto_awesome_outlined),
                      title: Text('Effets'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'desc',
                    child: ListTile(
                      leading: Icon(
                        capacity.description.isNotEmpty
                            ? Icons.description
                            : Icons.description_outlined,
                      ),
                      title: const Text('Description'),
                      dense: true,
                    ),
                  ),
                  if (!isAuto) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppColors.enemyPrimary,
                        ),
                        title: Text(
                          'Supprimer',
                          style: TextStyle(color: AppColors.enemyPrimary),
                        ),
                        dense: true,
                      ),
                    ),
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
  child: Text(
    label,
    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted),
  ),
);

Widget _iconBtn(
  IconData icon,
  VoidCallback onTap, {
  Color? color,
  String? tooltip,
}) => IconButton(
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
    final effects = await widget.db.getItemEffects(
      widget.itemType,
      widget.itemId,
    );
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => AlertDialog(
                  title: const Text('Ajouter un effet'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: statKey,
                        decoration: const InputDecoration(
                          labelText: 'Statistique',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            kEffectStatKeys
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.label),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setS(() => statKey = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valeur (+ ou -)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => value = int.tryParse(v) ?? 1,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
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
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_effects.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aucun effet',
                          style: TextStyle(color: AppColors.onSurfaceMuted),
                        ),
                      )
                    else
                      ..._effects.map((e) {
                        final label =
                            kEffectStatKeys
                                .firstWhere(
                                  (x) => x.key == e.statKey,
                                  orElse:
                                      () => (key: e.statKey, label: e.statKey),
                                )
                                .label;
                        final sign = e.modifierValue >= 0 ? '+' : '';
                        return ListTile(
                          dense: true,
                          title: Text(label),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$sign${e.modifierValue}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      e.modifierValue >= 0
                                          ? AppColors.allyPrimary
                                          : AppColors.enemyPrimary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                color: AppColors.enemyPrimary,
                                onPressed: () => _deleteEffect(e),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
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
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

/// Dialog to let the player choose their voie de peuple when multiple options exist
/// (e.g., Demi-elfe can choose Humain, Elfe sylvain, or Haut Elfe).
