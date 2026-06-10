import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/character_template.dart';
import '../../providers/bestiary_provider.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/participant_avatar.dart';
import 'creature_wizard_sheet.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BestiaryProvider>().loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bestiaire'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: Consumer<BestiaryProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_fix_high,
                      size: 72, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  Text(
                    'Bestiaire vide',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des monstres et personnages',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          final allies =
              provider.templates.where((t) => t.isAlly).toList();
          final enemies =
              provider.templates.where((t) => !t.isAlly).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (allies.isNotEmpty) ...[
                _sectionHeader(context, 'Aventuriers',
                    AppColors.allyPrimary, Icons.person),
                const SizedBox(height: 8),
                ...allies.map((t) => _templateTile(context, t, provider)),
                const SizedBox(height: 16),
              ],
              if (enemies.isNotEmpty) ...[
                _sectionHeader(context, 'Monstres & Ennemis',
                    AppColors.enemyPrimary, Icons.dangerous),
                const SizedBox(height: 8),
                ...enemies.map((t) => _templateTile(context, t, provider)),
              ],
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

  Widget _templateTile(
      BuildContext context, CharacterTemplate t, BestiaryProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(t.id),
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
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => provider.deleteTemplate(t.id!),
        child: Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: ParticipantAvatar(
              name: t.name,
              isAlly: t.isAlly,
              imageUrl: t.imageUrl,
              radius: 20,
            ),
            title: Text(t.name,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Init: ${t.baseInitiative}  •  PV: ${t.maxHp}  • ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Icon(Icons.shield, color: Colors.grey.shade500, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '${t.def}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (t.nc != null)
                        Text(
                          '  •  NC ${t.nc! % 1 == 0 ? t.nc!.toStringAsFixed(0) : t.nc!}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${t.creatureType.label}  •  ${t.taille.label}  •  ${t.archetype.label}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline,
                      color: Colors.grey.shade500, size: 20),
                  onPressed: () => _showDetailSheet(context, t),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: Colors.grey.shade500, size: 20),
                  onPressed: () => _showTemplateSheet(context, t),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Ce personnage sera retiré du bestiaire.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showTemplateSheet(BuildContext context, CharacterTemplate? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TemplateFormSheet(existing: existing),
    );
  }

  void _showDetailSheet(BuildContext context, CharacterTemplate t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreatureDetailSheet(template: t),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Ajouter une créature',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.enemyPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_fix_high,
                      color: AppColors.enemyPrimary),
                ),
                title: const Text('Créature sur le pouce',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Assistant guidé : questions → stats auto-calculées',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showWizard(context);
                },
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.edit_note, color: Colors.grey.shade400),
                ),
                title: const Text('Saisie manuelle'),
                subtitle: Text(
                  'Remplir toutes les stats à la main',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTemplateSheet(context, null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreatureWizardSheet(),
    );
  }
}

// ── Creature Detail Sheet ─────────────────────────────────────────────────────

class CreatureDetailSheet extends StatelessWidget {
  final CharacterTemplate template;
  const CreatureDetailSheet({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final t = template;
    final color = t.isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                ParticipantAvatar(
                    name: t.name,
                    isAlly: t.isAlly,
                    imageUrl: t.imageUrl,
                    radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        [
                          t.creatureType.label,
                          t.taille.label,
                          t.archetype.label,
                          if (t.nc != null) 'NC ${t.nc}',
                        ].join('  •  '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Combat stats
            _sectionTitle(context, 'Statistiques de combat'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _statBadge(context, '⚡ Init', '${t.baseInitiative}', color),
                _statBadge(context, '❤️ PV', '${t.maxHp}', color),
                _statBadge(context, '🛡 DEF', '${t.def}', color),
              ],
            ),
            const SizedBox(height: 16),
            // Characteristics
            _sectionTitle(context, 'Caractéristiques'),
            const SizedBox(height: 8),
            _statsGrid(context, t),
            // Attacks
            if (t.attacks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Attaques'),
              const SizedBox(height: 8),
              ...t.attacks.map((a) => _attackRow(context, a)),
            ],
            // Capacities
            if (t.capacities.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Capacités'),
              const SizedBox(height: 8),
              ...t.capacities.map((c) => _capacityRow(context, c)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade400,
              letterSpacing: 0.8,
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
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
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
          width: 76,
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
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text('⭐', style: TextStyle(fontSize: 9)),
                    ),
                ],
              ),
              Text('${s.$3}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(modStr,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _attackRow(BuildContext context, TemplateAttack a) {
    final bonusStr = a.bonusAtk >= 0 ? '+${a.bonusAtk}' : '${a.bonusAtk}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                a.name +
                    (a.nbAttacks > 1 ? ' (×${a.nbAttacks})' : ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              bonusStr,
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold),
            ),
            if (a.dm.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                'DM ${a.dm}',
                style: TextStyle(
                    color: Colors.red.shade300, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _capacityRow(BuildContext context, TemplateCapacity c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (c.actionType.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.5)),
                    ),
                    child: Text(c.actionType,
                        style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                Expanded(
                  child: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (c.dm.isNotEmpty)
                  Text('DM ${c.dm}',
                      style: TextStyle(
                          color: Colors.red.shade300, fontSize: 12)),
              ],
            ),
            if (c.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(c.description,
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Template Form Sheet ───────────────────────────────────────────────────────

class TemplateFormSheet extends StatefulWidget {
  final CharacterTemplate? existing;
  const TemplateFormSheet({super.key, this.existing});

  @override
  State<TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<TemplateFormSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _initCtrl;
  late final TextEditingController _hpCtrl;
  late final TextEditingController _defCtrl;
  late final TextEditingController _ncCtrl;
  // Stats controllers
  late final TextEditingController _forCtrl;
  late final TextEditingController _agiCtrl;
  late final TextEditingController _conCtrl;
  late final TextEditingController _intCtrl;
  late final TextEditingController _perCtrl;
  late final TextEditingController _chaCtrl;
  late final TextEditingController _volCtrl;

  late bool _isAlly;
  late CreatureType _creatureType;
  late CreatureTaille _taille;
  late CreatureArchetype _archetype;
  String? _imageUrl;
  late Set<String> _superiorStats;
  late List<TemplateAttack> _attacks;
  late List<TemplateCapacity> _capacities;

  late TabController _tabController;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final t = widget.existing;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _initCtrl =
        TextEditingController(text: t != null ? '${t.baseInitiative}' : '');
    _hpCtrl = TextEditingController(text: t != null ? '${t.maxHp}' : '');
    _defCtrl = TextEditingController(text: t != null ? '${t.def}' : '10');
    _ncCtrl = TextEditingController(text: t?.nc != null ? '${t!.nc}' : '');
    _forCtrl = TextEditingController(text: '${t?.forVal ?? 10}');
    _agiCtrl = TextEditingController(text: '${t?.agiVal ?? 10}');
    _conCtrl = TextEditingController(text: '${t?.conVal ?? 10}');
    _intCtrl = TextEditingController(text: '${t?.intVal ?? 10}');
    _perCtrl = TextEditingController(text: '${t?.perVal ?? 10}');
    _chaCtrl = TextEditingController(text: '${t?.chaVal ?? 10}');
    _volCtrl = TextEditingController(text: '${t?.volVal ?? 10}');
    _isAlly = t?.isAlly ?? true;
    _creatureType = t?.creatureType ?? CreatureType.vivant;
    _taille = t?.taille ?? CreatureTaille.moyenne;
    _archetype = t?.archetype ?? CreatureArchetype.standard;
    _imageUrl = t?.imageUrl;
    _superiorStats = Set.from(t?.superiorStats ?? {});
    _attacks = List.from(t?.attacks ?? []);
    _capacities = List.from(t?.capacities ?? []);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _initCtrl.dispose();
    _hpCtrl.dispose();
    _defCtrl.dispose();
    _ncCtrl.dispose();
    _forCtrl.dispose();
    _agiCtrl.dispose();
    _conCtrl.dispose();
    _intCtrl.dispose();
    _perCtrl.dispose();
    _chaCtrl.dispose();
    _volCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Form(
        key: _formKey,
        child: Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Modifier la créature' : 'Nouvelle créature',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: color,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: color,
              tabs: const [
                Tab(text: 'Général'),
                Tab(text: 'Stats'),
                Tab(text: 'Attaques'),
                Tab(text: 'Capacités'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(context, ctrl),
                  _buildStatsTab(context, ctrl),
                  _buildAttacksTab(context, ctrl),
                  _buildCapacitiesTab(context, ctrl),
                ],
              ),
            ),
            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(_isEdit ? Icons.save : Icons.add,
                      color: Colors.white),
                  label:
                      Text(_isEdit ? 'Enregistrer' : 'Ajouter au bestiaire'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: General ──────────────────────────────────────────────────────────
  Widget _buildGeneralTab(BuildContext context, ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ally / Enemy toggle
          Row(
            children: [
              Expanded(child: _typeBtn('Aventurier', Icons.person, true)),
              const SizedBox(width: 10),
              Expanded(child: _typeBtn('Ennemi', Icons.dangerous, false)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            autofocus: !_isEdit,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _initCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Initiative',
                    prefixIcon: Icon(Icons.bolt),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _hpCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'PV max',
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((int.tryParse(v) ?? 0) <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _defCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'DEF',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ncCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'NC (Niveau de Danger) — optionnel',
              prefixIcon: Icon(Icons.star_border),
            ),
          ),
          const SizedBox(height: 16),
          // Type
          _dropdownRow<CreatureType>(
            label: 'Type',
            value: _creatureType,
            items: CreatureType.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _creatureType = v!),
          ),
          const SizedBox(height: 12),
          // Taille
          _dropdownRow<CreatureTaille>(
            label: 'Taille',
            value: _taille,
            items: CreatureTaille.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _taille = v!),
          ),
          const SizedBox(height: 12),
          // Archétype
          _dropdownRow<CreatureArchetype>(
            label: 'Archétype',
            value: _archetype,
            items: CreatureArchetype.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _archetype = v!),
          ),
          const SizedBox(height: 16),
          ImagePickerField(
            initialUrl: _imageUrl,
            participantName:
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : (_isAlly ? 'A' : 'E'),
            isAlly: _isAlly,
            onChanged: (url) => setState(() => _imageUrl = url),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Stats ────────────────────────────────────────────────────────────
  Widget _buildStatsTab(BuildContext context, ScrollController ctrl) {
    final stats = [
      ('FOR', 'for', _forCtrl),
      ('AGI', 'agi', _agiCtrl),
      ('CON', 'con', _conCtrl),
      ('INT', 'int', _intCtrl),
      ('PER', 'per', _perCtrl),
      ('CHA', 'cha', _chaCtrl),
      ('VOL', 'vol', _volCtrl),
    ];
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valeur de base  •  ⭐ = Supérieure (dé bonus, garde le meilleur)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          ...stats.map((s) => _statRow(context, s.$1, s.$2, s.$3)),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String key,
      TextEditingController ctrl) {
    final isSuperior = _superiorStats.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: TextStyle(
                color: isSuperior ? Colors.amber : Colors.grey.shade400,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          // Value field
          SizedBox(
            width: 72,
            child: TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                filled: true,
                fillColor: isSuperior
                    ? Colors.amber.withValues(alpha: 0.08)
                    : AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isSuperior
                        ? Colors.amber.withValues(alpha: 0.6)
                        : Colors.transparent,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isSuperior
                        ? Colors.amber.withValues(alpha: 0.6)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Legendary toggle
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSuperior) {
                  _superiorStats.remove(key);
                } else {
                  _superiorStats.add(key);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSuperior
                    ? Colors.amber.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSuperior
                      ? Colors.amber.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⭐',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSuperior ? Colors.amber : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Supérieure',
                    style: TextStyle(
                      color:
                          isSuperior ? Colors.amber : Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: isSuperior
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Attacks ──────────────────────────────────────────────────────────
  Widget _buildAttacksTab(BuildContext context, ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          if (_attacks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Aucune attaque',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
          ..._attacks.asMap().entries.map((e) =>
              _attackEditor(context, e.key, e.value)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _attacks
                .add(const TemplateAttack(name: '', bonusAtk: 0, nbAttacks: 1, dm: ''))),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une attaque'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }

  Widget _attackEditor(BuildContext context, int index, TemplateAttack a) {
    final nameCtrl = TextEditingController(text: a.name);
    final bonusCtrl = TextEditingController(text: a.bonusAtk.toString());
    final nbCtrl = TextEditingController(text: a.nbAttacks.toString());
    final dmCtrl = TextEditingController(text: a.dm);
    // 💡 NOUVEAU : Contrôleurs pour tes nouveaux champs
    final effectCtrl = TextEditingController(text: a.additionalEffect);
    final descCtrl = TextEditingController(text: a.description);

    void update() {
      _attacks[index] = a.copyWith(
        name: nameCtrl.text,
        bonusAtk: int.tryParse(bonusCtrl.text) ?? 0,
        nbAttacks: int.tryParse(nbCtrl.text) ?? 1,
        dm: dmCtrl.text,
        additionalEffect: effectCtrl.text,
        description: descCtrl.text,
      );
    }

    nameCtrl.addListener(update);
    bonusCtrl.addListener(update);
    nbCtrl.addListener(update);
    dmCtrl.addListener(update);
    effectCtrl.addListener(update);
    descCtrl.addListener(update);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom (ex: Morsure, Épée longue)',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => setState(() => _attacks.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: bonusCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(labelText: 'Atk (+7)', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: nbCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Nb Att.', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: dmCtrl,
                  decoration: const InputDecoration(labelText: 'DM (1d6+3)', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 💡 AJOUT DES DEUX CHAMPS DANS L'INTERFACE DE SAISIE
          TextField(
            controller: effectCtrl,
            decoration: const InputDecoration(
              labelText: 'Effet secondaire (ex: Paralysie, Poison mortel 1d6)',
              isDense: true,
              prefixIcon: Icon(Icons.star_border, size: 16, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description / Portée / Conditions',
              isDense: true,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Capacities ───────────────────────────────────────────────────────
  Widget _buildCapacitiesTab(BuildContext context, ScrollController ctrl) {
    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          if (_capacities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Aucune capacité',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
          ..._capacities.asMap().entries.map((e) =>
              _capacityEditor(context, e.key, e.value)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _capacities.add(
                const TemplateCapacity(name: '', description: ''))),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une capacité'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }

  Widget _capacityEditor(
      BuildContext context, int index, TemplateCapacity c) {
    final nameCtrl = TextEditingController(text: c.name);
    final descCtrl = TextEditingController(text: c.description);
    final dmCtrl = TextEditingController(text: c.dm);
    String actionType = c.actionType;

    void update() {
      _capacities[index] = c.copyWith(
        name: nameCtrl.text,
        description: descCtrl.text,
        actionType: actionType,
        dm: dmCtrl.text,
      );
    }

    nameCtrl.addListener(update);
    descCtrl.addListener(update);
    dmCtrl.addListener(update);

    return StatefulBuilder(builder: (context, setLocal) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      setState(() => _capacities.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Action type chips
            Row(
              children: [
                Text('Type : ',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13)),
                ...['', 'A', 'M', 'L', '*'].map((type) {
                  final selected = actionType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setLocal(() => actionType = type);
                        update();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.purple.withValues(alpha: 0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? Colors.purple
                                : Colors.grey.shade700,
                          ),
                        ),
                        child: Text(
                          type.isEmpty ? '—' : type,
                          style: TextStyle(
                            color: selected
                                ? Colors.purple
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dmCtrl,
              decoration: const InputDecoration(
                labelText: 'DM (optionnel)',
                isDense: true,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _typeBtn(String label, IconData icon, bool ally) {
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
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
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

  Widget _dropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(labelOf(e)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Sync text controller values into attacks/capacities lists
    // (already done via listeners, but call update anyway)
    final provider = context.read<BestiaryProvider>();
    final template = CharacterTemplate(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      isAlly: _isAlly,
      baseInitiative: int.tryParse(_initCtrl.text) ?? 0,
      maxHp: int.tryParse(_hpCtrl.text) ?? 1,
      def: int.tryParse(_defCtrl.text) ?? 10,
      imageUrl: _imageUrl,
      nc: _ncCtrl.text.trim().isEmpty ? null : double.tryParse(_ncCtrl.text),
      creatureType: _creatureType,
      taille: _taille,
      archetype: _archetype,
      forVal: int.tryParse(_forCtrl.text) ?? 10,
      agiVal: int.tryParse(_agiCtrl.text) ?? 10,
      conVal: int.tryParse(_conCtrl.text) ?? 10,
      intVal: int.tryParse(_intCtrl.text) ?? 10,
      perVal: int.tryParse(_perCtrl.text) ?? 10,
      chaVal: int.tryParse(_chaCtrl.text) ?? 10,
      volVal: int.tryParse(_volCtrl.text) ?? 10,
      superiorStats: Set.from(_superiorStats),
      attacks: List.from(_attacks),
      capacities: List.from(_capacities),
    );
    if (_isEdit) {
      provider.updateTemplate(template);
    } else {
      provider.addTemplate(template);
    }
    Navigator.pop(context);
  }
}
