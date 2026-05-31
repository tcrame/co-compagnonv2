import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/character_template.dart';
import '../../providers/bestiary_provider.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

int _modToScore(int mod) => 10 + mod * 2;

class _ArchEntry {
  final int ncMini;
  final bool ncMiniIsHalf;
  final int agiMod;
  final int conMod;
  final int forMod;
  final bool forSuperior;
  final int def;
  final int pv;
  final int att;
  final String dm;

  const _ArchEntry({
    required this.ncMini,
    this.ncMiniIsHalf = false,
    required this.agiMod,
    required this.conMod,
    required this.forMod,
    this.forSuperior = false,
    required this.def,
    required this.pv,
    required this.att,
    required this.dm,
  });
}

// Table archétypes par taille (source: Bestiaire COF2 pp.302-303)
const Map<CreatureTaille, Map<CreatureArchetype, _ArchEntry>> _archetypeTable = {
  CreatureTaille.petite: {
    CreatureArchetype.inferieur: _ArchEntry(
        ncMini: 0, agiMod: 2, conMod: -1, forMod: -1, def: 11, pv: 3, att: 2, dm: '1d4-1'),
    CreatureArchetype.standard: _ArchEntry(
        ncMini: 0, agiMod: 2, conMod: -1, forMod: -1, def: 11, pv: 3, att: 2, dm: '1d4-1'),
    CreatureArchetype.puissant: _ArchEntry(
        ncMini: 0, ncMiniIsHalf: true, agiMod: 1, conMod: 1, forMod: 1,
        forSuperior: true, def: 13, pv: 9, att: 3, dm: '1d6+1'),
  },
  CreatureTaille.moyenne: {
    CreatureArchetype.inferieur: _ArchEntry(
        ncMini: 0, agiMod: 2, conMod: -1, forMod: -1, def: 11, pv: 3, att: 2, dm: '1d4-1'),
    CreatureArchetype.standard: _ArchEntry(
        ncMini: 0, ncMiniIsHalf: true, agiMod: 1, conMod: 1, forMod: 1,
        forSuperior: true, def: 13, pv: 9, att: 3, dm: '1d6+1'),
    CreatureArchetype.puissant: _ArchEntry(
        ncMini: 1, agiMod: 0, conMod: 3, forMod: 3,
        forSuperior: true, def: 15, pv: 15, att: 4, dm: '1d6+3'),
  },
  CreatureTaille.grande: {
    CreatureArchetype.inferieur: _ArchEntry(
        ncMini: 1, agiMod: 0, conMod: 3, forMod: 3,
        forSuperior: true, def: 15, pv: 15, att: 4, dm: '1d6+3'),
    CreatureArchetype.standard: _ArchEntry(
        ncMini: 2, agiMod: 1, conMod: 6, forMod: 6, def: 17, pv: 30, att: 6, dm: '2d6+4'),
    CreatureArchetype.puissant: _ArchEntry(
        ncMini: 3, agiMod: 0, conMod: 8, forMod: 8,
        forSuperior: true, def: 18, pv: 50, att: 8, dm: '2d6+8'),
  },
  CreatureTaille.enorme: {
    CreatureArchetype.inferieur: _ArchEntry(
        ncMini: 4, agiMod: 0, conMod: 8, forMod: 8, def: 20, pv: 70, att: 10, dm: '2d8+10'),
    CreatureArchetype.standard: _ArchEntry(
        ncMini: 5, agiMod: 0, conMod: 10, forMod: 10, def: 21, pv: 90, att: 11, dm: '2d10+12'),
    CreatureArchetype.puissant: _ArchEntry(
        ncMini: 6, agiMod: -1, conMod: 12, forMod: 12,
        forSuperior: true, def: 22, pv: 110, att: 12, dm: '2d10+14'),
  },
  CreatureTaille.colossale: {
    CreatureArchetype.inferieur: _ArchEntry(
        ncMini: 7, agiMod: 0, conMod: 10, forMod: 10, def: 24, pv: 140, att: 13, dm: '2d12+16'),
    CreatureArchetype.standard: _ArchEntry(
        ncMini: 9, agiMod: 0, conMod: 14, forMod: 14, def: 26, pv: 180, att: 15, dm: '4d8+20'),
    CreatureArchetype.puissant: _ArchEntry(
        ncMini: 12, agiMod: -1, conMod: 16, forMod: 16,
        forSuperior: true, def: 29, pv: 240, att: 17, dm: '4d10+26'),
  },
};

// Table profils de combat par NC (source: Bestiaire COF2 pp.302-303)
class _NcEntry {
  final int nc;
  final int def;
  final int pv;
  final int att;
  final String dm;

  const _NcEntry(
      {required this.nc,
      required this.def,
      required this.pv,
      required this.att,
      required this.dm});
}

const List<_NcEntry> _ncTable = [
  _NcEntry(nc: 0, def: 11, pv: 3, att: 2, dm: '1d4-1'),
  _NcEntry(nc: 1, def: 15, pv: 15, att: 4, dm: '1d6+3'),
  _NcEntry(nc: 2, def: 17, pv: 30, att: 6, dm: '2d6+4'),
  _NcEntry(nc: 3, def: 18, pv: 50, att: 8, dm: '2d6+8'),
  _NcEntry(nc: 4, def: 20, pv: 70, att: 10, dm: '2d8+10'),
  _NcEntry(nc: 5, def: 21, pv: 90, att: 11, dm: '2d10+12'),
  _NcEntry(nc: 6, def: 22, pv: 110, att: 12, dm: '2d10+14'),
  _NcEntry(nc: 7, def: 24, pv: 140, att: 13, dm: '2d12+16'),
  _NcEntry(nc: 8, def: 25, pv: 160, att: 14, dm: '4d8+16'),
  _NcEntry(nc: 9, def: 26, pv: 180, att: 15, dm: '4d8+20'),
  _NcEntry(nc: 10, def: 28, pv: 200, att: 16, dm: '4d10+20'),
  _NcEntry(nc: 11, def: 29, pv: 220, att: 16, dm: '4d10+22'),
  _NcEntry(nc: 12, def: 29, pv: 240, att: 17, dm: '4d10+26'),
  _NcEntry(nc: 13, def: 30, pv: 260, att: 17, dm: '4d10+28'),
  _NcEntry(nc: 14, def: 30, pv: 280, att: 18, dm: '4d12+28'),
  _NcEntry(nc: 15, def: 31, pv: 300, att: 18, dm: '4d12+30'),
  _NcEntry(nc: 16, def: 31, pv: 320, att: 19, dm: '4d12+34'),
  _NcEntry(nc: 17, def: 32, pv: 340, att: 19, dm: '4d12+36'),
  _NcEntry(nc: 18, def: 32, pv: 360, att: 19, dm: '4d12+40'),
  _NcEntry(nc: 19, def: 33, pv: 380, att: 20, dm: '4d12+42'),
  _NcEntry(nc: 20, def: 33, pv: 400, att: 20, dm: '4d12+46'),
];

class _Qualifier {
  final String label;
  final int mod;
  const _Qualifier(this.label, this.mod);
}

const _perQuals = [
  _Qualifier('Absent', -4),
  _Qualifier('Distrait', -2),
  _Qualifier('Ordinaire', 0),
  _Qualifier('Vigilant', 2),
  _Qualifier('Hypersensible', 4),
  _Qualifier('Extralucide', 6),
];

const _chaQuals = [
  _Qualifier('Horrible', -4),
  _Qualifier('Effrayant / étrange', -2),
  _Qualifier('Quelconque', 0),
  _Qualifier('Convaincant', 2),
  _Qualifier('Magnifique', 4),
  _Qualifier('Fascinant', 6),
];

const _intQuals = [
  _Qualifier('Animal', -4),
  _Qualifier('Pas futé', -2),
  _Qualifier('Ordinaire', 0),
  _Qualifier('Futé', 2),
  _Qualifier('Intello', 4),
  _Qualifier('Génie', 6),
];

const _volQuals = [
  _Qualifier('Soumis / peureux', -4),
  _Qualifier('Obéissant / timoré', -2),
  _Qualifier('Indépendant / libre', 0),
  _Qualifier('Résolu / persévérant', 2),
  _Qualifier('Dominateur / entêté', 4),
  _Qualifier('Inflexible / inébranlable', 6),
];

// ── Wizard ────────────────────────────────────────────────────────────────────

enum _WizardStep { name, gabarit, nc, otherStats, review }

class CreatureWizardSheet extends StatefulWidget {
  const CreatureWizardSheet({super.key});

  @override
  State<CreatureWizardSheet> createState() => _CreatureWizardSheetState();
}

class _CreatureWizardSheetState extends State<CreatureWizardSheet> {
  _WizardStep _step = _WizardStep.name;
  bool _saving = false;

  // Step: name
  final _nameCtrl = TextEditingController();
  bool _isAlly = false;

  // Step: gabarit
  CreatureType _creatureType = CreatureType.vivant;
  CreatureTaille _taille = CreatureTaille.moyenne;
  CreatureArchetype _archetype = CreatureArchetype.standard;

  // Step: NC
  int _nc = 5;

  // Step: other stats (indices into qualifier lists)
  int _perIdx = 2; // ordinaire
  int _chaIdx = 2;
  int _intIdx = 2;
  int _volIdx = 2;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  static const _allSteps = [
    _WizardStep.name,
    _WizardStep.gabarit,
    _WizardStep.nc,
    _WizardStep.otherStats,
    _WizardStep.review,
  ];

  int get _stepIndex => _allSteps.indexOf(_step);
  int get _totalSteps => _allSteps.length;

  /// NC minimum imposed by the current taille + archétype.
  int get _ncMin {
    final entry = _archetypeTable[_taille]?[_archetype];
    if (entry == null) return 0;
    return entry.ncMiniIsHalf ? 0 : entry.ncMini;
  }

  void _next() {
    final idx = _stepIndex;
    if (idx < _allSteps.length - 1) setState(() => _step = _allSteps[idx + 1]);
  }

  void _back() {
    final idx = _stepIndex;
    if (idx > 0) setState(() => _step = _allSteps[idx - 1]);
  }

  bool get _canNext {
    if (_step == _WizardStep.name) return _nameCtrl.text.trim().isNotEmpty;
    return true;
  }

  // ── Stat computation ─────────────────────────────────────────────────────────

  CharacterTemplate _buildTemplate() {
    final perMod = _perQuals[_perIdx].mod;
    final chaMod = _chaQuals[_chaIdx].mod;
    final intMod = _intQuals[_intIdx].mod;
    final volMod = _volQuals[_volIdx].mod;
    final init = 10 + perMod;

    final archEntry = _archetypeTable[_taille]![_archetype]!;
    final ncEntry = _ncTable.firstWhere((e) => e.nc == _nc, orElse: () => _ncTable.last);
    final superior = archEntry.forSuperior ? const {'for'} : const <String>{};

    return CharacterTemplate(
      name: _nameCtrl.text.trim(),
      isAlly: _isAlly,
      baseInitiative: init,
      maxHp: ncEntry.pv,
      def: ncEntry.def,
      nc: _nc,
      creatureType: _creatureType,
      taille: _taille,
      archetype: _archetype,
      forVal: _modToScore(archEntry.forMod),
      agiVal: _modToScore(archEntry.agiMod),
      conVal: _modToScore(archEntry.conMod),
      intVal: _modToScore(intMod),
      perVal: _modToScore(perMod),
      chaVal: _modToScore(chaMod),
      volVal: _modToScore(volMod),
      superiorStats: superior,
      attacks: [TemplateAttack(name: 'Attaque', bonusAtk: ncEntry.att, dm: ncEntry.dm)],
    );
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final template = _buildTemplate();
    await context.read<BestiaryProvider>().addTemplate(template);
    if (mounted) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    final progress = (_stepIndex + 1) / _totalSteps;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_stepIndex > 0) ...[
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Row(
                    children: [
                      const Text('✨ ', style: TextStyle(fontSize: 18)),
                      Text(
                        'Créature sur le pouce',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(2),
              minHeight: 3,
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: _buildStepContent(context),
            ),
          ),
          // Next button (hidden on review, which has its own confirm button)
          if (_step != _WizardStep.review)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canNext ? _next : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _step == _WizardStep.otherStats
                        ? 'Voir le récapitulatif'
                        : 'Suivant',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case _WizardStep.name:
        return _buildNameStep(context);
      case _WizardStep.gabarit:
        return _buildGabaritStep(context);
      case _WizardStep.nc:
        return _buildNcStep(context);
      case _WizardStep.otherStats:
        return _buildOtherStatsStep(context);
      case _WizardStep.review:
        return _buildReviewStep(context);
    }
  }

  // ── Step: Name ───────────────────────────────────────────────────────────────

  Widget _buildNameStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(context, 'Qui est cette créature ?'),
        const SizedBox(height: 4),
        Text(
          'Donnez-lui un nom et définissez son camp.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade400),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _typeBtn(context, 'Aventurier', Icons.person, true)),
            const SizedBox(width: 10),
            Expanded(child: _typeBtn(context, 'Ennemi', Icons.dangerous, false)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nom de la créature',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ── Step: Gabarit ────────────────────────────────────────────────────────────

  Widget _buildGabaritStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(context, 'Gabarit de la créature'),
        const SizedBox(height: 4),
        Text(
          'Définissez le type, la taille et l\'archétype. Le NC minimum sera calculé automatiquement.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade400),
        ),
        const SizedBox(height: 24),
        _sectionLabel(context, 'Type de créature'),
        const SizedBox(height: 8),
        _chipGroup<CreatureType>(
          values: CreatureType.values,
          selected: _creatureType,
          labelOf: (e) => e.label,
          onSelected: (v) => setState(() => _creatureType = v),
        ),
        const SizedBox(height: 20),
        _sectionLabel(context, 'Taille'),
        const SizedBox(height: 8),
        _chipGroup<CreatureTaille>(
          values: CreatureTaille.values,
          selected: _taille,
          labelOf: (e) => e.label,
          onSelected: (v) {
            final newMin = _computeNcMin(v, _archetype);
            setState(() {
              _taille = v;
              if (_nc < newMin) _nc = newMin;
            });
          },
        ),
        const SizedBox(height: 20),
        _sectionLabel(context, 'Archétype'),
        const SizedBox(height: 8),
        ...CreatureArchetype.values.map((a) => _archetypeCard(context, a)),
        const SizedBox(height: 12),
        _gabaritPreview(context),
      ],
    );
  }

  int _computeNcMin(CreatureTaille taille, CreatureArchetype archetype) {
    final entry = _archetypeTable[taille]?[archetype];
    if (entry == null) return 0;
    return entry.ncMiniIsHalf ? 0 : entry.ncMini;
  }

  Widget _archetypeCard(BuildContext context, CreatureArchetype a) {
    final selected = _archetype == a;
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    const descriptions = {
      CreatureArchetype.inferieur:
          'Herbivore, peu armé, combat seulement pour se défendre ou à la limite inférieure de sa catégorie.',
      CreatureArchetype.standard:
          'Créature ordinaire, moyens d\'attaque efficaces mais pas particulièrement agressive.',
      CreatureArchetype.puissant:
          'Très agressif ou à la limite haute de sa catégorie, combat au-dessus de son gabarit.',
    };
    return GestureDetector(
      onTap: () {
        final newMin = _computeNcMin(_taille, a);
        setState(() {
          _archetype = a;
          if (_nc < newMin) _nc = newMin;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade700,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? color : Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(descriptions[a]!,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gabaritPreview(BuildContext context) {
    final entry = _archetypeTable[_taille]?[_archetype];
    if (entry == null) return const SizedBox.shrink();
    final ncLabel = entry.ncMiniIsHalf ? '½' : '${entry.ncMini}';
    final forStr =
        '${entry.forMod >= 0 ? '+' : ''}${entry.forMod}${entry.forSuperior ? '⭐' : ''}';
    final agiStr = '${entry.agiMod >= 0 ? '+' : ''}${entry.agiMod}';
    final conStr = '${entry.conMod >= 0 ? '+' : ''}${entry.conMod}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caractéristiques physiques & NC minimum',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _previewBadge('NC mini', ncLabel),
              _previewBadge('FOR', forStr),
              _previewBadge('AGI', agiStr),
              _previewBadge('CON', conStr),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Les stats de combat (DEF, PV, ATT, DM) seront déterminées par le NC choisi à l\'étape suivante.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Step: NC ─────────────────────────────────────────────────────────────────

  Widget _buildNcStep(BuildContext context) {
    final entry = _ncTable.firstWhere((e) => e.nc == _nc, orElse: () => _ncTable.first);
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    final archEntry = _archetypeTable[_taille]?[_archetype];
    final ncMinLabel = archEntry?.ncMiniIsHalf == true ? '½' : '$_ncMin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(context, 'Niveau de Danger (NC)'),
        const SizedBox(height: 4),
        Text(
          'Le gabarit impose un NC minimum. Choisissez le NC final de la créature.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade400),
        ),
        const SizedBox(height: 16),
        // NC minimum reminder
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                'NC minimum pour ${_taille.label} ${_archetype.label} : $ncMinLabel',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // NC picker
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _nc > _ncMin ? () => setState(() => _nc--) : null,
              icon: const Icon(Icons.remove_circle_outline, size: 28),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                'NC $_nc',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _nc < 20 ? () => setState(() => _nc++) : null,
              icon: const Icon(Icons.add_circle_outline, size: 28),
            ),
          ],
        ),
        Slider(
          value: _nc.toDouble(),
          min: _ncMin.toDouble(),
          max: 20,
          divisions: 20 - _ncMin,
          label: 'NC $_nc',
          onChanged: (v) => setState(() => _nc = v.round()),
          activeColor: color,
        ),
        const SizedBox(height: 16),
        // Stats preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stats de combat pour NC $_nc',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _previewBadge('DEF', '${entry.def}'),
                  _previewBadge('PV', '${entry.pv}'),
                  _previewBadge('ATT', '+${entry.att}'),
                  _previewBadge('DM', entry.dm),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step: Other stats ────────────────────────────────────────────────────────

  Widget _buildOtherStatsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(context, 'Caractéristiques secondaires'),
        const SizedBox(height: 4),
        Text(
          'Choisissez le qualificatif qui décrit le mieux la créature.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade400),
        ),
        const SizedBox(height: 24),
        _qualifierRow(context, 'PER', '👁',  _perQuals, _perIdx,
            (i) => setState(() => _perIdx = i)),
        _qualifierRow(context, 'CHA', '✨', _chaQuals, _chaIdx,
            (i) => setState(() => _chaIdx = i)),
        _qualifierRow(context, 'INT', '🧠', _intQuals, _intIdx,
            (i) => setState(() => _intIdx = i)),
        _qualifierRow(context, 'VOL', '🔥', _volQuals, _volIdx,
            (i) => setState(() => _volIdx = i)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'L\'Initiative sera calculée : 10 + bonus PER.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qualifierRow(
    BuildContext context,
    String statName,
    String emoji,
    List<_Qualifier> quals,
    int selectedIdx,
    ValueChanged<int> onChanged,
  ) {
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    final mod = quals[selectedIdx].mod;
    final modStr = mod >= 0 ? '+$mod' : '$mod';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$emoji  $statName',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text(modStr,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quals.asMap().entries.map((e) {
                final selected = e.key == selectedIdx;
                return GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color : Colors.grey.shade700,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      e.value.label,
                      style: TextStyle(
                        color: selected
                            ? color
                            : Colors.grey.shade300,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step: Review ──────────────────────────────────────────────────────────────

  Widget _buildReviewStep(BuildContext context) {
    final template = _buildTemplate();
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    final archEntry = _archetypeTable[_taille]?[_archetype];
    final ncMinLabel = archEntry?.ncMiniIsHalf == true ? '½' : '$_ncMin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(context, 'Récapitulatif'),
        const SizedBox(height: 4),
        Text(
          'Stats calculées. Vous pourrez les affiner en modifiant la créature.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade400),
        ),
        const SizedBox(height: 20),
        // Creature header
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                template.name.isNotEmpty
                    ? template.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    [
                      template.creatureType.label,
                      template.taille.label,
                      template.archetype.label,
                      'NC $_nc (mini $ncMinLabel)',
                    ].join('  •  '),
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Combat stats
        _reviewSection(context, 'Combat'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statBadge(context, '⚡ Init', '${template.baseInitiative}', color),
            _statBadge(context, '❤️ PV', '${template.maxHp}', color),
            _statBadge(context, '🛡 DEF', '${template.def}', color),
          ],
        ),
        const SizedBox(height: 16),
        // Characteristics
        _reviewSection(context, 'Caractéristiques'),
        const SizedBox(height: 8),
        _statsGrid(context, template),
        // Default attack
        if (template.attacks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _reviewSection(context, 'Attaque de base'),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(template.attacks.first.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '+${template.attacks.first.bonusAtk}',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  'DM ${template.attacks.first.dm}',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        // Confirm
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _confirm,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add, color: Colors.white),
            label: Text(_saving ? 'Ajout en cours…' : 'Ajouter au bestiaire'),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _stepTitle(BuildContext context, String title) => Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      );

  Widget _sectionLabel(BuildContext context, String label) => Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _reviewSection(BuildContext context, String label) => Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade400,
              letterSpacing: 0.8,
            ),
      );

  Widget _typeBtn(
      BuildContext context, String label, IconData icon, bool ally) {
    final selected = _isAlly == ally;
    final color = ally ? AppColors.allyPrimary : AppColors.enemyPrimary;
    return GestureDetector(
      onTap: () => setState(() => _isAlly = ally),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: selected ? color : Colors.grey,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _chipGroup<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) {
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade700,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              labelOf(v),
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade300,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _previewBadge(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statBadge(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _statsGrid(BuildContext context, CharacterTemplate t) {
    final stats = [
      ('FOR', 'for', t.forVal),
      ('AGI', 'agi', t.agiVal),
      ('CON', 'con', t.conVal),
      ('INT', 'int', t.intVal),
      ('PER', 'per', t.perVal),
      ('CHA', 'cha', t.chaVal),
      ('VOL', 'vol', t.volVal),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats.map((s) {
        final isSuperior = t.superiorStats.contains(s.$2);
        final mod = ((s.$3 - 10) / 2).floor();
        final modStr = mod >= 0 ? '+$mod' : '$mod';
        return Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSuperior
                ? Colors.amber.withValues(alpha: 0.08)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuperior
                  ? Colors.amber.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.$1,
                      style: TextStyle(
                          color: isSuperior
                              ? Colors.amber
                              : Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  if (isSuperior)
                    const Text('⭐', style: TextStyle(fontSize: 8)),
                ],
              ),
              Text('${s.$3}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(modStr,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
