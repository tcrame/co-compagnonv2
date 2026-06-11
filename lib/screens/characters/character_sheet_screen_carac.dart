part of 'character_sheet_screen.dart';

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
      setState(
        () =>
            _s = _s.copyWith(
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
            ),
      );
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
        if (_s.pmMax > 0) ...[_buildManaSection(), const SizedBox(height: 16)],
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
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.0,
        ),
      ),
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
          ...labels.map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (trailingWidth > 0) SizedBox(width: trailingWidth),
        ],
      ),
    );
  }

  // Inline editable int field
  Widget _intCell(
    int value,
    ValueChanged<int> onChanged, {
    bool readOnly = false,
    Color? color,
  }) {
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
              color:
                  color ??
                  (readOnly ? const Color(0xFFCF6679) : AppColors.onSurface),
            ),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null) onChanged(n);
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              filled: true,
              fillColor:
                  readOnly ? AppColors.surface : AppColors.surfaceVariant,
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
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg ?? AppColors.onSurface,
          ),
        ),
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

    final bases = [
      _s.agiVal,
      _s.conVal,
      _s.forVal,
      _s.perVal,
      _s.chaVal,
      _s.intVal,
      _s.volVal,
    ];
    final peuples = [
      _s.agiRacial,
      _s.conRacial,
      _s.forRacial,
      _s.perRacial,
      _s.chaRacial,
      _s.intRacial,
      _s.volRacial,
    ];
    final bonuses = [
      _s.agiBonus,
      _s.conBonus,
      _s.forBonus,
      _s.perBonus,
      _s.chaBonus,
      _s.intBonus,
      _s.volBonus,
    ];
    final totals = [
      _s.agiTotal,
      _s.conTotal,
      _s.forTotal,
      _s.perTotal,
      _s.chaTotal,
      _s.intTotal,
      _s.volTotal,
    ];

    final presetLabel = switch (_s.statPreset) {
      'polyvalent' => 'Polyvalent',
      'expert' => 'Expert',
      'specialiste' => 'Spécialiste',
      _ => null,
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
              _colHeaders([
                'Base',
                'Peuple',
                'Bonus',
                'Total',
              ], trailingWidth: 72),
              ...List.generate(caracs.length, (i) {
                final abbr = caracs[i].$1;
                final label = caracs[i].$2;
                final key = abbr.toLowerCase();
                final isSuperior = _s.superiorStats.contains(key);
                return Column(
                  children: [
                    if (i > 0) _divider(),
                    Row(
                      children: [
                        _labelCell(abbr, fg: isSuperior ? Colors.amber : null),
                        _intCell(bases[i], (_) {}, readOnly: true),
                        _intCell(peuples[i], (_) {}, readOnly: true),
                        _intCell(bonuses[i], (v) {
                          _update(_updateCaracBonus(abbr, v));
                        }),
                        _intCell(
                          totals[i],
                          (_) {},
                          readOnly: true,
                          color:
                              totals[i] > 0
                                  ? const Color(0xFF1B5E20)
                                  : totals[i] < 0
                                  ? const Color(0xFFB71C1C)
                                  : null,
                        ),
                        // Superior toggle
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            icon: Text(
                              '⭐',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isSuperior
                                        ? Colors.amber
                                        : Colors.grey.shade700,
                              ),
                            ),
                            tooltip:
                                isSuperior
                                    ? 'Retirer la supériorité de $abbr'
                                    : 'Rendre $abbr supérieure (dé bonus)',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () {
                              final newSet = Set<String>.from(_s.superiorStats);
                              if (isSuperior) {
                                newSet.remove(key);
                              } else {
                                newSet.add(key);
                              }
                              _update(_s.copyWith(superiorStats: newSet));
                            },
                          ),
                        ),
                        // Dice roll
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            icon: const Icon(Icons.casino_outlined, size: 16),
                            tooltip:
                                'Test $abbr${isSuperior ? ' (Supérieure)' : ''}',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed:
                                widget.onDiceRoll == null
                                    ? null
                                    : () => _rollCaracTest(
                                      abbr,
                                      label,
                                      totals[i],
                                      isSuperior: isSuperior,
                                    ),
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
      case 'AGI':
        return _s.copyWith(agiBonus: v);
      case 'CON':
        return _s.copyWith(conBonus: v);
      case 'FOR':
        return _s.copyWith(forBonus: v);
      case 'PER':
        return _s.copyWith(perBonus: v);
      case 'CHA':
        return _s.copyWith(chaBonus: v);
      case 'INT':
        return _s.copyWith(intBonus: v);
      case 'VOL':
        return _s.copyWith(volBonus: v);
      default:
        return _s;
    }
  }

  void _rollCaracTest(
    String abbr,
    String label,
    int bonus, {
    bool isSuperior = false,
  }) {
    final die1 = Random().nextInt(20) + 1;
    // Pour AGI : appliquer le malus d'encombrement
    final enc = abbr == 'AGI' ? _s.encTotal : 0;
    final effectiveBonus = bonus - enc;

    int die;
    String detail;

    if (isSuperior) {
      final die2 = Random().nextInt(20) + 1;
      die = die1 > die2 ? die1 : die2;
      final total = die + effectiveBonus;
      final sign = effectiveBonus >= 0 ? '+$effectiveBonus' : '$effectiveBonus';
      detail = '⭐ Supérieure : d20($die1, $die2) → $die';
      if (effectiveBonus != 0) detail += ' $sign = $total';
      if (enc > 0) detail += ' (ENC -$enc)';
    } else {
      die = die1;
      final total = die + effectiveBonus;
      final sign = effectiveBonus >= 0 ? '+$effectiveBonus' : '$effectiveBonus';
      if (effectiveBonus == 0) {
        detail = 'd20 = $die';
      } else {
        detail = 'd20($die) $sign = $total';
      }
      if (enc > 0) detail += ' (ENC -$enc)';
    }

    final total = die + effectiveBonus;
    String lbl = 'Test $abbr';
    if (isSuperior) lbl += ' ⭐';
    if (die == 20) lbl += ' 🎯 Critique !';
    if (die == 1) lbl += ' 💀 Échec critique !';
    widget.onDiceRoll?.call(
      DiceLogEntry(
        die: 'd20',
        label: lbl,
        detail: detail,
        dieResult: die,
        bonus: effectiveBonus,
        total: total,
      ),
    );
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
              _attRow(
                'CONTACT\n(Niv.+FOR)',
                _s.attContactBase,
                _s.attContactBonus,
                _s.attContactMalus,
                _s.attContactTotal,
                (bo, m) => _update(
                  _s.copyWith(attContactBonus: bo, attContactMalus: m),
                ),
              ),
              _divider(),
              _attRow(
                'DISTANCE\n(Niv.+AGI)',
                _s.attDistanceBase,
                _s.attDistanceBonus,
                _s.attDistanceMalus,
                _s.attDistanceTotal,
                (bo, m) => _update(
                  _s.copyWith(attDistanceBonus: bo, attDistanceMalus: m),
                ),
              ),
              _divider(),
              _attRow(
                'MAGIQUE\n(Niv.+VOL)',
                _s.attMagiqueBase,
                _s.attMagiqueBonus,
                _s.attMagiqueMalus,
                _s.attMagiqueTotal,
                (bo, m) => _update(
                  _s.copyWith(attMagiqueBonus: bo, attMagiqueMalus: m),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attRow(
    String label,
    int base,
    int bonus,
    int malus,
    int total,
    void Function(int, int) onChanged,
  ) {
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
                  _intCell(
                    _s.initBonus,
                    (v) => _update(_s.copyWith(initBonus: v)),
                  ),
                  _intCell(
                    _s.initMalus,
                    (v) => _update(_s.copyWith(initMalus: v)),
                  ),
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
    final pct = _s.pvMax > 0 ? (_s.pvActuel / _s.pvMax).clamp(0.0, 1.0) : 0.0;
    final isDead = _s.pvActuel <= 0;
    final barColor =
        pct > 0.5
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
                    const Text(
                      'Bonus PV :',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: TextEditingController(
                          text: _s.pvBonus.toString(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
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
                      border: Border.all(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bedtime_outlined,
                          size: 16,
                          color: Color(0xFFB71C1C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Inconscient',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
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
                          Text(
                            '${_s.pvActuel} / ${_s.pvMax}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: barColor,
                            ),
                          ),
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
      builder:
          (ctx) => AlertDialog(
            title: Text(heal ? 'Soigner' : 'Infliger des dégâts'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    heal ? 'Points de vie récupérés' : 'Points de dégâts',
                prefixIcon: Icon(
                  heal ? Icons.favorite : Icons.remove_circle_outline,
                  color:
                      heal ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
                ),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      heal ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final v = int.tryParse(ctrl.text.trim()) ?? 0;
                  if (v > 0) {
                    final newPv =
                        heal
                            ? (_s.pvActuel + v).clamp(
                              0,
                              _s.pvMax > 0 ? _s.pvMax : 9999,
                            )
                            : (_s.pvActuel - v).clamp(
                              0,
                              _s.pvMax > 0 ? _s.pvMax : 9999,
                            );
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
    const healColor = Color(0xFF00695C);
    final drMax = _s.drMax.clamp(0, 20);
    final drActuel = _s.drActuel.clamp(0, drMax);
    final canRoll = drActuel > 0;

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
                Row(
                  children: [
                    _labelCell('DR'),
                    _intCell(
                      _s.drBonus,
                      (v) => _update(_s.copyWith(drBonus: v)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Jauge de dés ───────────────────────────────────────
                if (drMax == 0)
                  const Center(
                    child: Text(
                      'Aucun DR disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
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
                        color:
                            available ? accentColor : AppColors.onSurfaceMuted,
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.onSurfaceMuted.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.casino_outlined,
                            size: 14,
                            color: AppColors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'DV : ${_s.dvDerive}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+ ½ niv.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Boutons ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canRoll ? _rollDR : null,
                        icon: const Icon(Icons.favorite, size: 16),
                        label: const Text(
                          'Récupération rapide',
                          style: TextStyle(fontSize: 12),
                        ),
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
                        label: const Text(
                          'Récup. complète',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: const BorderSide(color: Color(0xFFE53935)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        drActuel > 0
                            ? () {
                              _update(_s.copyWith(drActuel: drActuel - 1));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🎲 DR perdu : ${drActuel - 1} / $drMax restants',
                                  ),
                                  backgroundColor: Colors.grey[700],
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                            : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text(
                      'Perdre un DR',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[400]!),
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
    widget.onDiceRoll?.call(
      DiceLogEntry(
        label: 'Récupération rapide',
        die: _s.dvDerive,
        dieResult: roll,
        bonus: halfLevel,
        total: soin,
        detail:
            'Dé (${_s.dvDerive}) = $roll$bonusStr = +$soin PV'
            '  •  PV : $newPv / ${_s.pvMax}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '❤️ Récupération rapide : +$soin PV — PV : $newPv / ${_s.pvMax}',
        ),
        backgroundColor: const Color(0xFF00695C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showRecuperationCompleteDialog() async {
    // Étape 1 : conditions de repos difficiles ?
    final difficult = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: Color(0xFFE53935),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text('Récupération Complète'),
              ],
            ),
            content: const Text(
              'Les conditions de repos sont-elles difficiles ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
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
      builder:
          (ctx) => AlertDialog(
            title: const Text('Test de Constitution'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CON : ${_s.conTotal >= 0 ? '+' : ''}${_s.conTotal}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceMuted,
                  ),
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
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.casino, size: 16),
                label: const Text('Lancer le test'),
                onPressed:
                    () => Navigator.pop(
                      ctx,
                      int.tryParse(diffCtrl.text.trim()) ?? 10,
                    ),
              ),
            ],
          ),
    );
    if (difficulty == null || !mounted) return;

    // Lancer D20 + CON
    final roll = Random().nextInt(20) + 1;
    final conBonus = _s.conTotal;
    final total = roll + conBonus;
    final success = total >= difficulty;
    final isCrit = roll == 20;
    final isFumble = roll == 1;

    widget.onDiceRoll?.call(
      DiceLogEntry(
        label: 'Test de CON (Repos)',
        die: 'D20',
        dieResult: roll,
        bonus: conBonus,
        total: total,
        detail:
            'D20=$roll + CON($conBonus) = $total'
            '  vs  Difficulté $difficulty'
            ' → ${isCrit
                ? "🎯 Critique !"
                : isFumble
                ? "💀 Fumble !"
                : success
                ? "Succès"
                : "Échec"}',
      ),
    );

    if (!mounted) return;

    if (!success && !isCrit) {
      // Échec : message et fin
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.bedtime, color: Colors.grey, size: 22),
                  SizedBox(width: 8),
                  Text('Repos perturbé'),
                ],
              ),
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
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isFumble)
                          const Text('💀 ', style: TextStyle(fontSize: 18)),
                        Text(
                          'D20 ($roll) + CON ($conBonus) = $total  /  Diff. $difficulty',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
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
                  child: const Text('Dommage…'),
                ),
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
      isCrit: isCrit,
    );
  }

  void _showRecuperationChoiceDialog({
    int? rollResult,
    int? difficulty,
    bool isCrit = false,
  }) {
    final drActuel = _s.drActuel.clamp(0, _s.drMax);
    final drMax = _s.drMax;
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: Color(0xFFE53935),
                  size: 22,
                ),
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00695C).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isCrit
                          ? '🎯 Critique ! ($rollResult vs $difficulty) — Repos réussi !'
                          : '✅ Test réussi ($rollResult vs $difficulty)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00695C),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Choisissez une option :',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                // Option 1: DR gratuit
                ElevatedButton.icon(
                  icon: const Icon(Icons.favorite, size: 18),
                  label: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lancer un DR gratuit'),
                      Text(
                        'Récupère des PV sans dépenser de DR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    disabledBackgroundColor: AppColors.surfaceVariant,
                  ),
                  onPressed:
                      drActuel < drMax
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
                child: const Text('Annuler'),
              ),
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
    widget.onDiceRoll?.call(
      DiceLogEntry(
        label: 'DR Gratuit (Récup. Complète)',
        die: _s.dvDerive,
        dieResult: roll,
        bonus: halfLevel,
        total: soin,
        detail:
            'Dé (${_s.dvDerive}) = $roll$bonusStr = +$soin PV  •  PV : $newPv / ${_s.pvMax}  •  PM restaurés',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🌿 DR gratuit : +$soin PV — PV : $newPv / ${_s.pvMax}  •  💧 PM restaurés',
        ),
        backgroundColor: const Color(0xFF00695C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _recupererDR() {
    if (_s.drActuel >= _s.drMax) return;
    final newDr = _s.drActuel + 1;
    // Récupération complète : mana restauré au max
    _update(_s.copyWith(drActuel: newDr, pmActuel: _s.pmMax));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎲 DR récupéré : $newDr / ${_s.drMax}  •  💧 PM restaurés',
        ),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 2),
      ),
    );
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
                  _intCell(
                    _s.defBonus,
                    (v) => _update(_s.copyWith(defBonus: v)),
                  ),
                  _intCell(
                    _s.defMalus,
                    (v) => _update(_s.copyWith(defMalus: v)),
                  ),
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
    final pct = _s.pmMax > 0 ? (_s.pmActuel / _s.pmMax).clamp(0.0, 1.0) : 0.0;
    final isEmpty = _s.pmActuel <= 0 || _s.pmMax <= 0;
    const barColor = Color(0xFF6A1B9A);

    // Compute magic count from provider for formula display
    final provider = context.watch<CharacterSheetProvider>();
    final magicCount =
        _s.id != null ? provider.getMagicCapacitesCount(_s.id!) : 0;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
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
                          'Sorts(*) $magicCount  +  VOL $vol  =  ${(magicCount + vol).clamp(0, 9999)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ),
                      Text(
                        'Base : ${_s.pmBase}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Bonus ─────────────────────────────────────────────────
                _colHeaders(['Bonus']),
                Row(
                  children: [
                    _labelCell('PM +'),
                    _intCell(
                      _s.pmBonus,
                      (v) => _update(_s.copyWith(pmBonus: v)),
                    ),
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
                      border: Border.all(
                        color: barColor.withValues(alpha: 0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 16,
                          color: Color(0xFF6A1B9A),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Mana épuisé',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
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
                          Text(
                            '${_s.pmActuel} / ${_s.pmMax}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 22,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            barColor,
                          ),
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
      builder:
          (ctx) => AlertDialog(
            title: Text(spend ? 'Dépenser du mana' : 'Récupérer du mana'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    spend
                        ? 'Points de mana dépensés'
                        : 'Points de mana récupérés',
                prefixIcon: Icon(
                  spend ? Icons.remove_circle_outline : Icons.water_drop,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final v = int.tryParse(ctrl.text.trim()) ?? 0;
                  if (v > 0) {
                    final newPm =
                        spend
                            ? (_s.pmActuel - v).clamp(
                              0,
                              _s.pmMax > 0 ? _s.pmMax : 9999,
                            )
                            : (_s.pmActuel + v).clamp(
                              0,
                              _s.pmMax > 0 ? _s.pmMax : 9999,
                            );
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
      builder:
          (ctx) => AlertDialog(
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
                    border: Border.all(
                      color: const Color(0xFFE65100).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Color(0xFFE65100),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Règle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Lorsqu\'il n\'a plus de points de mana, un personnage peut choisir de sacrifier son énergie vitale pour continuer à lancer des sorts.\n'
                        'Pour chaque PM dépensé, il subit des DM égaux à son dé de récupération (DR).\n'
                        'PV perdus = 1 DR par point de mana du sort.\n'
                        'Aucune RD ne s\'applique à cette perte de PV.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Chaque PM demandé coûte 1 jet de ${_s.dvDerive} en PV.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points de mana nécessaires',
                    prefixIcon: Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  onSubmitted: (_) => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
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
    final pmDispo = _s.pmActuel.clamp(0, nbPm);
    final pmManquants = nbPm - pmDispo;

    CharacterSheet updated = _s.copyWith(pmActuel: _s.pmActuel - pmDispo);

    if (pmManquants == 0) {
      // Tous les PM couverts par la mana, pas de brûlure
      _update(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ $nbPm PM dépensés depuis la mana  •  PM : ${updated.pmActuel} / ${updated.pmMax}',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF6A1B9A),
        ),
      );
      return;
    }

    // 2. Lancer les dés de brûlure uniquement pour les PM manquants
    final dv = _s.dvMaxValue;
    final rolls = List.generate(pmManquants, (_) => Random().nextInt(dv) + 1);
    final totalDmg = rolls.fold(0, (s, r) => s + r);
    final rollsStr = rolls.map((r) => '$r').join(' + ');
    final newPv = (updated.pvActuel - totalDmg).clamp(
      0,
      updated.pvMax > 0 ? updated.pvMax : 9999,
    );
    updated = updated.copyWith(pvActuel: newPv.toInt());
    _update(updated);

    final pmStr = pmDispo > 0 ? '$pmDispo PM dépensés + ' : '';
    final detail =
        '${pmStr}brûlure $pmManquants × ${_s.dvDerive} : $rollsStr = $totalDmg dégâts'
        '  •  PV : $newPv / ${_s.pvMax}';

    widget.onDiceRoll?.call(
      DiceLogEntry(
        die: _s.dvDerive,
        label: '🔥 Brûlure de mana ($nbPm PM)',
        detail: detail,
        dieResult: totalDmg,
        bonus: 0,
        total: totalDmg,
      ),
    );

    final snackPm = pmDispo > 0 ? '$pmDispo PM dépensés, ' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 ${snackPm}brûlure $pmManquants PM : $rollsStr = -$totalDmg PV  •  PV : $newPv / ${_s.pvMax}',
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFFE65100),
      ),
    );
  }

  Widget _buildRessourcesSection() {
    const accentColor = Color(0xFFFFB300);
    final pcMax = _s.pcMax.clamp(0, 20);
    final pcActuel = _s.pcActuel.clamp(0, pcMax);
    final isEmpty = pcActuel <= 0;

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
                Row(
                  children: [
                    _labelCell('PC'),
                    _intCell(
                      _s.pcBonus,
                      (v) => _update(_s.copyWith(pcBonus: v)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Jauge trèfles ─────────────────────────────────────────
                if (pcMax == 0)
                  const Center(
                    child: Text(
                      'Aucun PC disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
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
                        child: const Text('🍀', style: TextStyle(fontSize: 30)),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text(
                          'Provoquer le destin',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: const BorderSide(color: accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed:
                            pcActuel > 0
                                ? () {
                                  _update(_s.copyWith(pcActuel: pcActuel - 1));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Text('🍀 '),
                                          Text(
                                            'Destin provoqué — ${pcActuel - 1} / $pcMax PC restants',
                                          ),
                                        ],
                                      ),
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
                        label: const Text(
                          'Récupérer',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed:
                            pcActuel < pcMax
                                ? () =>
                                    _update(_s.copyWith(pcActuel: pcActuel + 1))
                                : null,
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
                    _s.encArmure,
                    (v) => _update(_s.copyWith(encArmure: v)),
                  ),
                  _intCell(
                    _s.encAutre,
                    (v) => _update(_s.copyWith(encAutre: v)),
                  ),
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
      'AGI': s.agiTotal,
      'CON': s.conTotal,
      'FOR': s.forTotal,
      'PER': s.perTotal,
      'CHA': s.chaTotal,
      'INT': s.intTotal,
      'VOL': s.volTotal,
    };
    final sorted =
        stats.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return [sorted[0].key, sorted[1].key];
  }

  int _getStatTotal(String stat) {
    final s = widget.currentSheet;
    switch (stat) {
      case 'AGI':
        return s.agiTotal;
      case 'CON':
        return s.conTotal;
      case 'FOR':
        return s.forTotal;
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

  CharacterSheet _applyRacial(String? bonusStat, String? malusStat) {
    final s = widget.currentSheet;
    int agi = 0, con = 0, fo = 0, per = 0, cha = 0, intel = 0, vol = 0;

    void apply(String? stat, int delta) {
      if (stat == null) return;
      switch (stat) {
        case 'AGI':
          agi += delta;
          break;
        case 'CON':
          con += delta;
          break;
        case 'FOR':
          fo += delta;
          break;
        case 'PER':
          per += delta;
          break;
        case 'CHA':
          cha += delta;
          break;
        case 'INT':
          intel += delta;
          break;
        case 'VOL':
          vol += delta;
          break;
      }
    }

    apply(bonusStat, 1);
    apply(widget.choice.malusFixed, -1);
    apply(malusStat, -1);

    return s.copyWith(
      agiRacial: agi,
      conRacial: con,
      forRacial: fo,
      perRacial: per,
      chaRacial: cha,
      intRacial: intel,
      volRacial: vol,
    );
  }

  @override
  Widget build(BuildContext context) {
    final choice = widget.choice;
    final humainOptions =
        choice.bonusSpecial ? _computeHumainOptions() : <String>[];
    final bonusOptions =
        choice.bonusSpecial ? humainOptions : choice.bonusOptions;

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
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              ...bonusOptions.map(
                (stat) => RadioListTile<String>(
                  title: Text(
                    '$stat (${_getStatTotal(stat)})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: stat,
                  groupValue: _bonusChoice,
                  dense: true,
                  onChanged: (v) => setState(() => _bonusChoice = v),
                ),
              ),
            ],
            if (choice.malusFixed != null) ...[
              const SizedBox(height: 8),
              Text(
                'Malus fixe : -1 ${choice.malusFixed}',
                style: const TextStyle(
                  color: AppColors.enemyLight,
                  fontSize: 13,
                ),
              ),
            ],
            if (choice.malusOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Choisir la carac. qui reçoit -1 :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              ...choice.malusOptions.map(
                (stat) => RadioListTile<String>(
                  title: Text(
                    '$stat (${_getStatTotal(stat)})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: stat,
                  groupValue: _malusChoice,
                  dense: true,
                  onChanged: (v) => setState(() => _malusChoice = v),
                ),
              ),
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
