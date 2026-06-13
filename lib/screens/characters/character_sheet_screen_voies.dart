part of 'character_sheet_screen.dart';

class _VoiesTab extends StatelessWidget {
  final CharacterSheet sheet;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final Map<String, int> voieRangs;
  final int pcDepense;
  final String voiePeupleId;
  final String voiePeupleOrigineId;
  final bool voieMageRang2Pris;
  final String voiePrestigeId;
  final Future<void> Function(String voieId, int rang) onSetRang;
  final Future<void> Function() onMageRang2Pris;
  final Future<void> Function() onMageRang2Reset;
  final Future<void> Function(String voieId) onSetVoiePrestige;

  const _VoiesTab({
    required this.sheet,
    required this.controller,
    required this.onChanged,
    required this.voieRangs,
    required this.pcDepense,
    required this.voiePeupleId,
    required this.voiePeupleOrigineId,
    required this.voieMageRang2Pris,
    required this.voiePrestigeId,
    required this.onSetRang,
    required this.onMageRang2Pris,
    required this.onMageRang2Reset,
    required this.onSetVoiePrestige,
  });

  @override
  Widget build(BuildContext context) {
    final totalPc = sheet.level * 2;
    final remaining = totalPc - pcDepense;
    final voies = getVoiesPourProfil(sheet.profile);
    final peupleChoices = getVoiesChoixPourPeuple(sheet.race);
    String effectiveVoiePeupleId = voiePeupleId;
    VoieCatalogue? voiePeuple =
        voiePeupleId.isNotEmpty ? getVoieById(voiePeupleId) : null;
    final isMageVoieSelected = voiePeupleId == 'peuple_voie-du-mage';
    final voieCorrespondAuPeuple = peupleChoices.any(
      (v) => v.id == voiePeupleId,
    );
    if (!isMageVoieSelected && voiePeuple != null && !voieCorrespondAuPeuple) {
      voiePeuple = null;
      effectiveVoiePeupleId = '';
    }
    if (voiePeuple == null && sheet.race.isNotEmpty) {
      if (peupleChoices.length == 1) {
        effectiveVoiePeupleId = peupleChoices.first.id;
        voiePeuple = peupleChoices.first;
      }
    }
    final isMageVoie = effectiveVoiePeupleId == 'peuple_voie-du-mage';
    final voieOrigine =
        (isMageVoie && voiePeupleOrigineId.isNotEmpty)
            ? getVoieById(voiePeupleOrigineId)
            : null;
    final mageRang2Disponible = isMageVoie && !voieMageRang2Pris;

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

          // ── Voie de peuple ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Voie de peuple',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (voiePeuple != null)
            Padding(
              padding: EdgeInsets.only(bottom: voieOrigine != null ? 8 : 12),
              child: _VoieCard(
                voie: voiePeuple,
                rangActuel: max(1, voieRangs[effectiveVoiePeupleId] ?? 0),
                rangMin: 1, // rang 1 always free & locked
                pcRestants: 999, // voie de peuple has no PC cost
                profil: sheet.profile,
                niveau: sheet.level,
                onSetRang: (r) => onSetRang(effectiveVoiePeupleId, r),
                mageRang2Disponible: mageRang2Disponible,
                onMageRang2Pris: onMageRang2Pris,
                onMageRang2Reset: onMageRang2Reset,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.onSurfaceMuted.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  sheet.race.isEmpty
                      ? 'Sélectionne un peuple pour voir ta voie de peuple.'
                      : 'Aucune voie de peuple disponible pour "${sheet.race}".',
                  style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),

          // ── Héritage du Peuple (Mage uniquement) ─────────────────────
          if (voieOrigine != null)
            _MageHeritageSection(
              voieOrigine: voieOrigine,
              profil: sheet.profile,
            ),
          const SizedBox(height: 12),

          // ── Voies du profil ──────────────────────────────────────────
          if (voies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 40,
                    color: AppColors.onSurfaceMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sheet.profile.isEmpty
                        ? 'Sélectionne un profil pour voir les voies disponibles.'
                        : 'Aucune voie trouvée pour le profil "${sheet.profile}".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.onSurfaceMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...voies.map((voie) {
              final rangActuel = voieRangs[voie!.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _VoieCard(
                  voie: voie,
                  rangActuel: rangActuel,
                  pcRestants: remaining,
                  profil: sheet.profile,
                  niveau: sheet.level,
                  onSetRang: (r) => onSetRang(voie.id, r),
                  mageRang2Disponible: mageRang2Disponible,
                  onMageRang2Pris: onMageRang2Pris,
                  onMageRang2Reset: onMageRang2Reset,
                ),
              );
            }),

          const SizedBox(height: 16),

          // ── Voie de prestige ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Voie de prestige',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (voiePrestigeId.isNotEmpty)
            Builder(
              builder: (context) {
                VoieCatalogue? voie = getVoieById(voiePrestigeId);

                if (voie == null) {
                  for (final listVoies in kVoiesDePrestigeParProfil.values) {
                    for (final v in listVoies) {
                      if (v.id == voiePrestigeId) {
                        voie = v;
                        break;
                      }
                    }
                    if (voie != null) break;
                  }
                }

                if (voie == null) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.onSurfaceMuted.withOpacity(0.2)),
                    ),
                    child: const Text('Voie de prestige introuvable', style: TextStyle(color: AppColors.enemyPrimary, fontSize: 13)),
                  );
                }

                final rangActuel = voieRangs[voie.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VoieCard(
                    voie: voie, // On passe l'objet original (avec sa description)
                    rangActuel: rangActuel,
                    pcRestants: remaining,
                    profil: sheet.profile,
                    niveau: sheet.level,
                    onSetRang: (r) => onSetRang(voie!.id, r),
                    mageRang2Disponible: false,
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Retirer la voie'),
                          onTap: () => onSetVoiePrestige(''),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PrestigeVoieSelector(
                profile: sheet.profile,
                onSelectVoie: onSetVoiePrestige,
              ),
            ),
          const Divider(height: 1),

          const SizedBox(height: 12),

          // ── Notes libres ─────────────────────────────────────────────
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Notes libres',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceMuted,
              ),
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
    final accentColor = isOverBudget ? Colors.red : const Color(0xFFFFB300);

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
                const Text(
                  'Points de compétence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Niv. $level × 2 = $totalPc pts   •   Dépensés : $pcDepense',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$remaining',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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

// ── Mage Heritage Section ──────────────────────────────────────────────────────

/// Read-only display of rang 1 of the mage's original peuple voie.
/// The mage only keeps rang 1 — this is purely informational.
class _MageHeritageSection extends StatelessWidget {
  final VoieCatalogue voieOrigine;
  final String profil;

  const _MageHeritageSection({required this.voieOrigine, required this.profil});

  @override
  Widget build(BuildContext context) {
    final color = _couleurFamille(profil);
    final cap1 = voieOrigine.capacites.where((c) => c.rang == 1).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: AppColors.onSurfaceMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Héritage du Peuple — ${voieOrigine.nom}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cap1 != null)
                    _HeritageRangRow(
                      capacite: cap1,
                      unlocked: true,
                      accentColor: color,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeritageRangRow extends StatelessWidget {
  final CapaciteCatalogue capacite;
  final bool unlocked;
  final Color accentColor;
  final bool freeButton;
  final Future<void> Function()? onFree;

  const _HeritageRangRow({
    required this.capacite,
    required this.unlocked,
    required this.accentColor,
    this.freeButton = false,
    this.onFree,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rang badge
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1, right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                unlocked
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
            border: Border.all(
              color:
                  unlocked
                      ? accentColor
                      : AppColors.onSurfaceMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              '${capacite.rang}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: unlocked ? accentColor : AppColors.onSurfaceMuted,
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
                        fontWeight: FontWeight.w600,
                        color:
                            unlocked
                                ? AppColors.onSurface
                                : AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  if (freeButton && onFree != null)
                    TextButton.icon(
                      onPressed: () => onFree!(),
                      icon: const Icon(Icons.star_border, size: 14),
                      label: const Text(
                        'Gratuit',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.allyPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (unlocked && !freeButton)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.lock_open,
                        size: 12,
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
              if (capacite.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    capacite.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoieCard extends StatefulWidget {
  final VoieCatalogue voie;
  final int rangActuel;
  final int rangMin; // minimum rang (cannot decrease below this)
  final int pcRestants;
  final String profil;
  final int niveau;
  final Future<void> Function(int rang) onSetRang;
  final bool mageRang2Disponible;
  final Future<void> Function()? onMageRang2Pris;
  final Future<void> Function()? onMageRang2Reset;
  final Widget? trailing;

  const _VoieCard({
    required this.voie,
    required this.rangActuel,
    this.rangMin = 0,
    required this.pcRestants,
    required this.profil,
    required this.niveau,
    required this.onSetRang,
    this.mageRang2Disponible = false,
    this.onMageRang2Pris,
    this.onMageRang2Reset,
    this.trailing,
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
      // Un-buy: decrease by one, but not below rangMin
      newRang = rang - 1;
      if (newRang < widget.rangMin) return;
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
      // Mage free rang 2: bypass PC check
      final isMageFreeRang2 = rang == 2 && widget.mageRang2Disponible;
      if (!isMageFreeRang2) {
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
      }
      newRang = rang;
    } else {
      return; // Cannot skip ranks or jump backward more than 1
    }
    setState(() => _saving = true);
    try {
      await widget.onSetRang(newRang);
      if (newRang == 2 && widget.mageRang2Disponible) {
        await widget.onMageRang2Pris?.call();
      } else if (newRang == 1 && rang == 2 && widget.onMageRang2Reset != null) {
        await widget.onMageRang2Reset!.call();
      }
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.voie.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
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
                            color:
                                unlocked
                                    ? color
                                    : color.withValues(alpha: 0.15),
                            border: Border.all(
                              color: color.withValues(
                                alpha: unlocked ? 1.0 : 0.35,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),

                  if (widget.trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: widget.trailing!,
                    ),

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
                          fontStyle: FontStyle.italic,
                        ),
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
                    final isMageFreeRang2 =
                        cap.rang == 2 &&
                        isNext &&
                        levelOk &&
                        widget.mageRang2Disponible;

                    return _RangRow(
                      capacite: cap,
                      isUnlocked: isUnlocked,
                      isNext: isNext,
                      canBuy: canBuy || isMageFreeRang2,
                      levelOk: levelOk,
                      niveauRequis: niveauRequis,
                      saving: _saving,
                      accentColor: color,
                      isMageFreeRang2: isMageFreeRang2,
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
  final bool isMageFreeRang2;
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
    this.isMageFreeRang2 = false,
  });

  @override
  Widget build(BuildContext context) {
    final lockedByLevel = !isUnlocked && !levelOk;
    final textColor =
        isUnlocked
            ? AppColors.onSurface
            : (isNext && canBuy)
            ? AppColors.onSurface.withValues(alpha: 0.75)
            : AppColors.onSurfaceMuted;

    final effectiveOnTap =
        (isUnlocked || (isNext && canBuy)) && !saving ? onTap : null;

    return InkWell(
      onTap: effectiveOnTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color:
              isUnlocked
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.transparent,
          border:
              isUnlocked
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
                color:
                    isUnlocked
                        ? accentColor
                        : accentColor.withValues(alpha: 0.10),
                border: Border.all(
                  color:
                      isUnlocked
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
                            fontWeight:
                                isUnlocked
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
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: accentColor.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            capacite.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      if (capacite.isMagique)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(
                              0xFF6A1B9A,
                            ).withValues(alpha: 0.18),
                          ),
                          child: const Text(
                            '✨ Sort',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                        ),
                      if (isMageFreeRang2)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.allyPrimary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                          child: Text(
                            '⭐ Gratuit',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.allyPrimary,
                            ),
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
                          const Icon(
                            Icons.lock_clock,
                            size: 11,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Niveau $niveauRequis requis',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
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
                child: Icon(Icons.lock_open, size: 14, color: accentColor),
              )
            else if (isNext && canBuy)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 14,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              )
            else if (lockedByLevel)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.lock_clock, size: 14, color: Colors.orange),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.onSurfaceMuted.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget to select a prestige path
/// Widget to select a prestige path
class _PrestigeVoieSelector extends StatelessWidget {
  final String profile;
  final Future<void> Function(String voieId) onSelectVoie;

  const _PrestigeVoieSelector({
    required this.profile,
    required this.onSelectVoie,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.onSurfaceMuted.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optionnel : tu peux choisir une voie de prestige',
            style: const TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final voie = await showDialog<VoieCatalogue>(
                context: context,
                builder: (context) => _ChoosePrestigeVoieDialog(
                  profile: profile,
                ),
              );
              if (voie != null) {
                // CORRECTION : On extrait l'id (selectedVoie.id) au lieu de passer
                // l'instance complète du catalogue de la voie.
                await onSelectVoie(voie.id);
              }
            },
            icon: const Icon(Icons.star_outline),
            label: const Text('Choisir une voie de prestige'),
          ),
        ],
      ),
    );
  }
}

/// Widget to display the selected prestige path with capacity selection
/// Widget to display the selected prestige path with capacity selection
/// Widget to display the selected prestige path with capacity selection
class _PrestigeVoieCard extends StatelessWidget {
  final String voieId;
  final Map<String, int> voieRangs;
  final int pcRestants;
  final int niveau;
  final Future<void> Function(int rang) onSetRang;
  final Future<void> Function() onRemove;

  const _PrestigeVoieCard({
    required this.voieId,
    required this.voieRangs,
    required this.pcRestants,
    required this.niveau,
    required this.onSetRang,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Tente de récupérer via la méthode globale standard
    VoieCatalogue? voie = getVoieById(voieId);

    // 2. Si non trouvée, cherche manuellement dans le catalogue de prestige
    if (voie == null) {
      for (final listVoies in kVoiesDePrestigeParProfil.values) {
        for (final v in listVoies) {
          if (v.id == voieId) {
            voie = v;
            break;
          }
        }
        if (voie != null) break;
      }
    }

    // 3. Si elle reste introuvable, affiche l'erreur
    if (voie == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.onSurfaceMuted.withOpacity(0.2),
          ),
        ),
        child: const Text(
          'Voie de prestige non trouvée',
          style: TextStyle(
            color: AppColors.enemyPrimary,
            fontSize: 13,
          ),
        ),
      );
    }

    final rangActuel = voieRangs[voieId] ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.onSurfaceMuted.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voie.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (voie.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            voie.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Retirer'),
                      onTap: () => onRemove(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (voie.capacites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...voie.capacites.map((cap) {
                    final isUnlocked = niveau >= cap.rang;
                    final isSelected = rangActuel >= cap.rang;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.allyPrimary.withOpacity(0.1)
                              : AppColors.surface,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.allyPrimary
                                : AppColors.onSurfaceMuted.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${cap.nom} (rang ${cap.rang})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (cap.type.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.allyPrimary
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      3),
                                                ),
                                                child: Text(
                                                  cap.type,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                    AppColors.allyPrimary,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (cap.description.isNotEmpty)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(top: 6),
                                          child: Text(
                                            cap.description,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                              AppColors.onSurfaceMuted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: isSelected && isUnlocked,
                                  onChanged: isUnlocked
                                      ? (val) {
                                    if (val ?? false) {
                                      onSetRang(cap.rang);
                                    } else {
                                      // SOLUTION COMPILATION : Séparation propre de la récupération des rangs
                                      final previousRangs = voie!.capacites
                                          .where((c) => c.rang < cap.rang)
                                          .map((c) => c.rang)
                                          .toList();

                                      // Tri manuel sécurisé
                                      previousRangs.sort();

                                      final newRang = previousRangs.isEmpty
                                          ? 0
                                          : previousRangs.last;
                                      onSetRang(newRang);
                                    }
                                  }
                                      : null,
                                ),
                              ],
                            ),
                            if (!isUnlocked)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Nécessite niveau ${cap.rang}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.onSurfaceMuted
                                        .withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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

/// Dialog to choose a prestige path
/// Dialog to choose a prestige path
class _ChoosePrestigeVoieDialog extends StatelessWidget {
  final String profile;

  const _ChoosePrestigeVoieDialog({required this.profile});

  @override
  Widget build(BuildContext context) {
    // 1. Récupère la famille du profil au singulier (ex: 'Aventurier', 'Combattant'...)
    final familleProfil = getFamilleForProfil(profile) ?? '';

    // Normalisation de la famille pour éviter les problèmes de casse/pluriel
    final familleNormalisee = familleProfil.toLowerCase().trim();

    // 2. Recherche des voies de la famille avec une correspondance permissive (ex: 'Aventurier' match avec 'Aventuriers')
    List<VoieCatalogue> voiesFamille = [];
    for (final entry in kVoiesDePrestigeParProfil.entries) {
      final keyNormalisee = entry.key.toLowerCase().trim();
      if (keyNormalisee.contains(familleNormalisee) || familleNormalisee.contains(keyNormalisee)) {
        voiesFamille = entry.value;
        break;
      }
    }

    // 3. Récupère les voies génériques accessibles à tous ('Tout profil')
    final voiesGeneriques = kVoiesDePrestigeParProfil['Tout profil'] ?? [];

    // 4. Fusionne les deux listes pour avoir toutes les options éligibles
    final prestigeVoies = [...voiesFamille, ...voiesGeneriques];

    if (prestigeVoies.isEmpty) {
      return AlertDialog(
        title: const Text('Voies de prestige'),
        content: Text(
          'Aucune voie de prestige disponible pour le profil "$profile".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Choisir une voie de prestige'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: prestigeVoies.length,
          itemBuilder: (context, index) {
            final voie = prestigeVoies[index];
            final estGenerique = voie.profil == 'Tout profil';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                estGenerique
                    ? Icons.star_purple500_outlined // Étoile pleine pour les voies universelles
                    : Icons.star_outline,           // Étoile vide pour la famille
              ),
              title: Text(voie.nom),
              subtitle: Text(
                voie.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () => Navigator.pop(context, voie),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
