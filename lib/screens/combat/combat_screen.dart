import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../constants/image_bank.dart';
import '../../widgets/dice_roller_sheet.dart';
import '../../constants/status_effects_data.dart';
import '../../models/participant.dart';
import '../../models/status_effect.dart';
import '../../providers/combat_provider.dart';
import '../../widgets/participant_avatar.dart';
import '../session/session_screen.dart';

class CombatScreen extends StatefulWidget {
  final String sessionName;
  const CombatScreen({super.key, required this.sessionName});
  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int index) =>
      _cardKeys.putIfAbsent(index, () => GlobalKey());

  void _scrollToActive(int index) {
    final key = _cardKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Consumer<CombatProvider>(
          builder: (_, provider, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.sessionName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (provider.combatStarted)
                Text(
                  'Tour ${provider.turnCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade300,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Text('🎲', style: TextStyle(fontSize: 20)),
              tooltip: 'Lancer des dés',
              onPressed: () => showDiceRollerSheet(ctx),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Nouveau tour',
            onPressed: () => _newTurn(context),
          ),
        ],
      ),
      floatingActionButton: Consumer<CombatProvider>(
        builder: (context, provider, _) {
          final sid = provider.sessionId;
          if (sid == null) return const SizedBox.shrink();
          // Hide FAB when turn tracker is active to avoid overlap
          if (provider.activeIndex != null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showAddParticipantSheet(context, sid),
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter'),
          );
        },
      ),
      bottomNavigationBar: Consumer<CombatProvider>(
        builder: (context, provider, _) {
          if (!provider.combatStarted) return const SizedBox.shrink();
          return _TurnControlBar(
            provider: provider,
            onStart: () {
              provider.startActiveTurn();
              _scrollToActive(0);
            },
            onNext: () {
              provider.nextActiveTurn();
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToActive(provider.activeIndex!));
            },
            onPrev: () {
              provider.prevActiveTurn();
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToActive(provider.activeIndex!));
            },
            onStop: () => provider.stopActiveTurn(),
          );
        },
      ),
      body: Consumer<CombatProvider>(
        builder: (context, provider, _) {
          final order = provider.turnOrder;

          if (order.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: order.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final participant = order[index];
              final isActive = provider.activeIndex == index;
              return Dismissible(
                key: ValueKey(participant.id),
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
                onDismissed: (_) =>
                    provider.removeParticipant(participant.id!),
                child: ParticipantCard(
                  key: _keyFor(index),
                  participant: participant,
                  rank: index + 1,
                  isActive: isActive,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _newTurn(BuildContext context) async {
    await context.read<CombatProvider>().rollInitiative();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎲 Nouveau tour ! Initiatives relancées.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddParticipantSheet(BuildContext context, int sessionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddParticipantSheet(sessionId: sessionId),
    );
  }
}

// ── Turn control bar ──────────────────────────────────────────────────────────

class _TurnControlBar extends StatelessWidget {
  final CombatProvider provider;
  final VoidCallback onStart;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onStop;

  const _TurnControlBar({
    required this.provider,
    required this.onStart,
    required this.onNext,
    required this.onPrev,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final active = provider.activeParticipant;
    final activeIdx = provider.activeIndex;
    final total = provider.turnOrder.length;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: active == null
            // ── Not started: show launch button ──
            ? SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Lancer le tour de combat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.allyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            // ── Active: show navigation ──
            : Row(
                children: [
                  // Stop button
                  IconButton(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded),
                    color: Colors.grey.shade500,
                    tooltip: 'Arrêter le suivi',
                  ),
                  // Prev
                  IconButton(
                    onPressed: onPrev,
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: AppColors.onSurface,
                    tooltip: 'Participant précédent',
                  ),
                  // Active participant info
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          active.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: active.isAlly
                                ? AppColors.allyPrimary
                                : AppColors.enemyPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(activeIdx! + 1)} / $total',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Next
                  IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: AppColors.onSurface,
                    tooltip: 'Participant suivant',
                  ),
                  const SizedBox(width: 36), // balance stop button
                ],
              ),
      ),
    );
  }
}

class ParticipantCard extends StatelessWidget {
  final Participant participant;
  final int rank;
  final bool isActive;

  const ParticipantCard({
    super.key,
    required this.participant,
    required this.rank,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = participant;
    final color = p.isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;
    final hpColor = AppColors.hpColor(p.hpPercent);
    final isDead = !p.isAlive;

    return Opacity(
      opacity: isDead ? 0.5 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: Card(
          color: isActive
              ? color.withValues(alpha: 0.30)
              : color.withValues(alpha: 0.18),
          shape: isActive
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color, width: 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header row
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar — tappable pour changer l'icône
                  GestureDetector(
                    onTap: () => _pickImage(context, p),
                    child: Stack(
                      children: [
                        ParticipantAvatar(
                          name: p.name,
                          isAlly: p.isAlly,
                          imageUrl: p.imageUrl,
                          radius: 18,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isDead)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.cancel_outlined,
                                    size: 14, color: Colors.grey.shade500),
                              ),
                            Flexible(
                              child: Text(
                                p.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      decoration: isDead
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          p.isAlly ? 'Aventurier' : 'Ennemi',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                  // Initiative + DEF badges
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.shield, color: Colors.grey.shade500, size: 40),
                          Text(
                            '${p.def}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Column(
                        children: [
                          Text(
                            '${p.rolledInitiative}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'init',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // HP bar
              Row(
                children: [
                  Icon(Icons.favorite,
                      size: 14,
                      color: isDead ? Colors.grey : hpColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.maxHp > 0 ? p.currentHp / p.maxHp : 0,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation(
                            isDead ? Colors.grey.shade700 : hpColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.currentHp} / ${p.maxHp}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDead ? Colors.grey : hpColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Damage / Heal buttons
              _HpControls(participant: p),

              // Status effects row
              Consumer<CombatProvider>(
                builder: (context, provider, _) {
                  final effects = provider.statusEffectsFor(p.id!);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (effects.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: effects
                              .map((e) => _StatusChip(effect: e))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showStatusPicker(context, p.id!),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          label: const Text('Infliger un état'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade400,
                            side: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _pickImage(BuildContext context, Participant p) async {
    final provider = context.read<CombatProvider>();
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ImageEditSheet(participant: p),
    );
    if (url != null && p.id != null) {
      await provider.updateParticipantImage(p.id!, url.isEmpty ? null : url);
    }
  }

  void _showStatusPicker(BuildContext context, int participantId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CombatProvider>(),
        child: _StatusPickerSheet(participantId: participantId),
      ),
    );
  }
}

class _HpControls extends StatefulWidget {
  final Participant participant;
  const _HpControls({required this.participant});

  @override
  State<_HpControls> createState() => _HpControlsState();
}

class _HpControlsState extends State<_HpControls> {
  int _amount = 1;

  void _increment() => setState(() => _amount = (_amount + 1).clamp(1, 999));
  void _decrement() => setState(() => _amount = (_amount - 1).clamp(1, 999));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Montant',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Stepper − N +
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepButton(
                    icon: Icons.remove,
                    onTap: _decrement,
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$_amount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add,
                    onTap: _increment,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Damage button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _apply(context, damage: true),
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Dégâts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.enemyPrimary.withValues(alpha: 0.25),
                  foregroundColor: AppColors.enemyLight,
                  side: BorderSide(color: AppColors.enemyPrimary.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Heal button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _apply(context, damage: false),
                icon: const Icon(Icons.favorite, size: 16),
                label: const Text('Soigner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.allyPrimary.withValues(alpha: 0.25),
                  foregroundColor: AppColors.allyLight,
                  side: BorderSide(color: AppColors.allyPrimary.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _apply(BuildContext context, {required bool damage}) {
    if (_amount <= 0) return;
    final provider = context.read<CombatProvider>();
    if (damage) {
      provider.applyDamage(widget.participant.id!, _amount);
    } else {
      provider.applyHeal(widget.participant.id!, _amount);
    }
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(icon, size: 18, color: Colors.grey.shade300),
      ),
    );
  }
}

// ── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final StatusEffect effect;
  const _StatusChip({required this.effect});

  @override
  Widget build(BuildContext context) {
    final def = definitionFor(effect.name);
    final color = def?.color ?? Colors.orange;
    final icon = def?.icon ?? Icons.warning_amber;

    return GestureDetector(
      onTap: () => _showDetail(context, def),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              effect.name,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${effect.remainingTurns}t',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.read<CombatProvider>().removeStatusEffect(effect),
              child: Icon(Icons.close, size: 12, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, StatusEffectDefinition? def) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(def?.icon ?? Icons.warning_amber,
                color: def?.color ?? Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(effect.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def?.description ?? '', style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            Text(
              '${effect.remainingTurns} tour(s) restant(s)',
              style: TextStyle(
                  color: def?.color ?? Colors.orange,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<CombatProvider>().removeStatusEffect(effect);
              Navigator.pop(context);
            },
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ── Status Picker Sheet ──────────────────────────────────────────────────────

class _StatusPickerSheet extends StatefulWidget {
  final int participantId;
  const _StatusPickerSheet({required this.participantId});

  @override
  State<_StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<_StatusPickerSheet> {
  StatusEffectDefinition? _selected;
  int _turns = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Infliger un état',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Grid of state buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kStatusEffects.map((def) {
              final isSelected = _selected?.name == def.name;
              return GestureDetector(
                onTap: () => setState(() => _selected = def),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? def.color.withValues(alpha: 0.25)
                        : Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? def.color
                          : Colors.grey.shade700,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(def.icon,
                          size: 14,
                          color: isSelected ? def.color : Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Text(
                        def.name,
                        style: TextStyle(
                          color:
                              isSelected ? def.color : Colors.grey.shade300,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Description of selected state
          if (_selected != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selected!.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _selected!.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                _selected!.description,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Turns stepper
          Row(
            children: [
              Text('Durée :',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: () => setState(
                          () => _turns = (_turns - 1).clamp(1, 20)),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$_turns',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap: () => setState(
                          () => _turns = (_turns + 1).clamp(1, 20)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _turns == 1 ? 'tour' : 'tours',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selected == null ? null : _confirm,
              icon: const Icon(Icons.check),
              label: Text(_selected == null
                  ? 'Choisir un état'
                  : 'Appliquer "${_selected!.name}"'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _selected?.color.withValues(alpha: 0.3),
                foregroundColor: _selected?.color ?? Colors.grey,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    if (_selected == null) return;
    final effect = StatusEffect(
      participantId: widget.participantId,
      name: _selected!.name,
      description: _selected!.description,
      remainingTurns: _turns,
    );
    context.read<CombatProvider>().addStatusEffect(effect);
    Navigator.pop(context);
  }
}

// ── Image edit sheet (combat tracker) ──────────────────────────────────────

class _ImageEditSheet extends StatefulWidget {
  final Participant participant;
  const _ImageEditSheet({required this.participant});

  @override
  State<_ImageEditSheet> createState() => _ImageEditSheetState();
}

class _ImageEditSheetState extends State<_ImageEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TextEditingController _urlCtrl;
  final List<String> _categories = imageBankCategories;

  @override
  void initState() {
    super.initState();
    _urlCtrl =
        TextEditingController(text: widget.participant.imageUrl ?? '');
    _tabController =
        TabController(length: _categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _select(String url) => Navigator.pop(context, url);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Changer l\'icône — ${widget.participant.name}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            indicatorColor: Colors.purple,
            tabs: [
              ..._categories.map((c) => Tab(text: c)),
              const Tab(text: 'URL'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ..._categories.map((cat) => _BankGrid(
                      entries: imageBankForCategory(cat),
                      onSelect: _select,
                    )),
                // URL tab
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('URL de l\'image',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'https://...',
                                hintStyle:
                                    const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF2A2A3E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _select(_urlCtrl.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                      if (widget.participant.imageUrl != null) ...[
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: () => _select(''),
                          icon: const Icon(Icons.clear,
                              color: Colors.red),
                          label: const Text('Retirer l\'icône',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankGrid extends StatelessWidget {
  final List<ImageBankEntry> entries;
  final ValueChanged<String> onSelect;
  const _BankGrid({required this.entries, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return InkWell(
          onTap: () => onSelect(entry.url),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: entry.url.endsWith('.svg')
                    ? SvgPicture.network(
                        entry.url,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Image.network(entry.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                            )),
              ),
              const SizedBox(height: 4),
              Text(
                entry.name,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

