import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/character_template.dart';
import '../../providers/bestiary_provider.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/participant_avatar.dart';

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
        onPressed: () => _showTemplateSheet(context, null),
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
            subtitle: Text(
              'Init: ${t.baseInitiative}  •  PV: ${t.maxHp}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: Colors.grey.shade500, size: 20),
              onPressed: () => _showTemplateSheet(context, t),
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
}

class TemplateFormSheet extends StatefulWidget {
  final CharacterTemplate? existing;
  const TemplateFormSheet({super.key, this.existing});

  @override
  State<TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _initCtrl;
  late final TextEditingController _hpCtrl;
  late bool _isAlly;
  String? _imageUrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _initCtrl =
        TextEditingController(text: t != null ? '${t.baseInitiative}' : '');
    _hpCtrl = TextEditingController(text: t != null ? '${t.maxHp}' : '');
    _isAlly = t?.isAlly ?? true;
    _imageUrl = t?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _initCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final color = _isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? 'Modifier le personnage' : 'Nouveau personnage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                      labelText: 'Initiative de base',
                      prefixIcon: Icon(Icons.bolt),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
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
                      if (int.tryParse(v) == null || int.parse(v) <= 0) {
                        return '> 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Image picker
            ImagePickerField(
              initialUrl: _imageUrl,
              participantName:
                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text : (_isAlly ? 'A' : 'E'),
              isAlly: _isAlly,
              onChanged: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: Icon(_isEdit ? Icons.save : Icons.add,
                    color: Colors.white),
                label: Text(_isEdit ? 'Enregistrer' : 'Ajouter au bestiaire'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<BestiaryProvider>();
    final template = CharacterTemplate(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      isAlly: _isAlly,
      baseInitiative: int.parse(_initCtrl.text),
      maxHp: int.parse(_hpCtrl.text),
      imageUrl: _imageUrl,
    );
    if (_isEdit) {
      provider.updateTemplate(template);
    } else {
      provider.addTemplate(template);
    }
    Navigator.pop(context);
  }
}
