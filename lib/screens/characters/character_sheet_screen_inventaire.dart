part of 'character_sheet_screen.dart';

class _InventaireTab extends StatefulWidget {
  final int sheetId;
  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onSheetChanged;
  const _InventaireTab({
    required this.sheetId,
    required this.sheet,
    required this.onSheetChanged,
  });

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
    if (mounted)
      setState(() {
        _items = items;
        _loading = false;
      });
  }

  Future<void> _addItem() async {
    final item = await _db.insertInventoryItem(
      InventoryItem(
        characterSheetId: widget.sheetId,
        name: '',
        position: _items.length,
      ),
    );
    if (!mounted) return;
    setState(() => _items.add(item));
  }

  Future<void> _deleteItem(InventoryItem item) async {
    if (item.id == null) {
      setState(() => _items.remove(item));
      return;
    }
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
      builder:
          (ctx) => AlertDialog(
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
        _MonnaieWidget(sheet: s, onChanged: _saveMonnaie),
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
                child: Text(
                  'Objet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(
                width: 110,
                child: Center(
                  child: Text(
                    'Qté',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 40), // desc btn space
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              _items.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.onSurfaceMuted.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Inventaire vide',
                          style: TextStyle(color: AppColors.onSurfaceMuted),
                        ),
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
                    itemBuilder:
                        (_, i) => _ItemRow(
                          item: _items[i],
                          onDelete: () => _deleteItem(_items[i]),
                          onNameChanged:
                              (v) => _updateItem(_items[i].copyWith(name: v)),
                          onQtyChanged:
                              (v) =>
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
      sheet.monnaiePC +
      sheet.monnaiePA * 10 +
      sheet.monnaiePO * 100 +
      sheet.monnaiePP * 1000;

  /// Normalise vers les grosses pièces :
  /// PC→PA dès 10 PC, PA→PO dès 10 PA, PO→PP seulement à partir de 100 PO.
  static ({int pc, int pa, int po, int pp}) _normalize(
    int pc,
    int pa,
    int po,
    int pp,
  ) {
    if (pc >= 10) {
      pa += pc ~/ 10;
      pc = pc % 10;
    }
    if (pa >= 10) {
      po += pa ~/ 10;
      pa = pa % 10;
    }
    if (po >= 100) {
      pp += po ~/ 10;
      po = po % 10;
    }
    return (pc: pc, pa: pa, po: po, pp: pp);
  }

  void _edit(
    BuildContext context,
    String label,
    Color color,
    int current,
    Future<void> Function(int) onSave,
  ) async {
    final ctrl = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
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
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setS) {
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
                          onChanged: (v) {
                            if (v != null) setS(() => denom = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (amount > 0) ...[
                      Text(
                        'Coût : $costPC PC équivalents',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
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
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Fonds insuffisants',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final a = int.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (a <= 0) return;
                      final m =
                          {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
                      Navigator.pop(ctx, {'costPC': a * m});
                    },
                    child: const Text('Payer'),
                  ),
                ],
              );
            },
          ),
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
    newPC -= usePC;
    rem -= usePC;

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
    newPC = n.pc;
    newPA = n.pa;
    newPO = n.po;
    newPP = n.pp;

    await onChanged(
      sheet.copyWith(
        monnaiePC: newPC,
        monnaiePA: newPA,
        monnaiePO: newPO,
        monnaiePP: newPP,
      ),
    );

    if (context.mounted) {
      final parts = [
        if (newPP > 0) '$newPP PP',
        if (newPO > 0) '$newPO PO',
        if (newPA > 0) '$newPA PA',
        if (newPC > 0) '$newPC PC',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiement effectué — reste : ${parts.isEmpty ? "0 PC" : parts.join("  ")}',
          ),
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
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setS) {
              final mult = {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
              final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
              final gainPC = amount * mult;

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: Colors.green,
                    ),
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
                          onChanged: (v) {
                            if (v != null) setS(() => denom = v);
                          },
                        ),
                      ],
                    ),
                    if (amount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Gain : $gainPC PC équivalents',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: () {
                      final a = int.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (a <= 0) return;
                      final m =
                          {'PC': 1, 'PA': 10, 'PO': 100, 'PP': 1000}[denom]!;
                      Navigator.pop(ctx, {'gainPC': a * m});
                    },
                    child: const Text('Recevoir'),
                  ),
                ],
              );
            },
          ),
    );

    if (result == null) return;
    final gainPC = result['gainPC'] as int;

    // Ajouter en PC puis normaliser vers les grosses pièces
    int newPC = sheet.monnaiePC + gainPC;
    int newPA = sheet.monnaiePA;
    int newPO = sheet.monnaiePO;
    int newPP = sheet.monnaiePP;

    final n = _normalize(newPC, newPA, newPO, newPP);
    newPC = n.pc;
    newPA = n.pa;
    newPO = n.po;
    newPP = n.pp;

    await onChanged(
      sheet.copyWith(
        monnaiePC: newPC,
        monnaiePA: newPA,
        monnaiePO: newPO,
        monnaiePP: newPP,
      ),
    );

    if (context.mounted) {
      final parts = [
        if (newPP > 0) '$newPP PP',
        if (newPO > 0) '$newPO PO',
        if (newPA > 0) '$newPA PA',
        if (newPC > 0) '$newPC PC',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Argent reçu — bourse : ${parts.isEmpty ? "0 PC" : parts.join("  ")}',
          ),
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
              const Text(
                'Monnaie',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _gain(context),
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
                label: const Text(
                  'Gain',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                label: 'PC',
                sublabel: 'Cuivre',
                color: const Color(0xFFB87333),
                value: sheet.monnaiePC,
                onTap:
                    () => _edit(
                      context,
                      'Pièces de Cuivre (PC)',
                      const Color(0xFFB87333),
                      sheet.monnaiePC,
                      (v) => onChanged(sheet.copyWith(monnaiePC: v)),
                    ),
              ),
              const SizedBox(width: 8),
              _CoinTile(
                label: 'PA',
                sublabel: 'Argent',
                color: const Color(0xFF9E9E9E),
                value: sheet.monnaiePA,
                onTap:
                    () => _edit(
                      context,
                      'Pièces d\'Argent (PA)',
                      const Color(0xFF9E9E9E),
                      sheet.monnaiePA,
                      (v) => onChanged(sheet.copyWith(monnaiePA: v)),
                    ),
              ),
              const SizedBox(width: 8),
              _CoinTile(
                label: 'PO',
                sublabel: 'Or',
                color: const Color(0xFFFFD700),
                value: sheet.monnaiePO,
                onTap:
                    () => _edit(
                      context,
                      'Pièces d\'Or (PO)',
                      const Color(0xFFFFD700),
                      sheet.monnaiePO,
                      (v) => onChanged(sheet.copyWith(monnaiePO: v)),
                    ),
              ),
              const SizedBox(width: 8),
              _CoinTile(
                label: 'PP',
                sublabel: 'Platine',
                color: const Color(0xFF90CAF9),
                value: sheet.monnaiePP,
                onTap:
                    () => _edit(
                      context,
                      'Pièces de Platine (PP)',
                      const Color(0xFF90CAF9),
                      sheet.monnaiePP,
                      (v) => onChanged(sheet.copyWith(monnaiePP: v)),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '1 PP = 10 PO  •  1 PO = 10 PA  •  1 PA = 10 PC',
            style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted),
          ),
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
    required this.label,
    required this.sublabel,
    required this.color,
    required this.value,
    required this.onTap,
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
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
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
                  onTap:
                      widget.item.quantity > 0
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
            tooltip:
                hasDesc
                    ? 'Voir / modifier la description'
                    : 'Ajouter une description',
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
    'polyvalent': [2, 2, 2, 1, 1, 0, -1],
    'expert': [3, 2, 1, 1, 0, 0, -1],
    'specialiste': [4, 2, 1, 0, 0, -1, -1],
  };
  static const _presetLabels = {
    'polyvalent': 'Polyvalent  (+2, +2, +2, +1, +1, 0, -1)',
    'expert': 'Expert  (+3, +2, +1, +1, 0, 0, -1)',
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
  final Map<String, int?> _assignments = {for (final c in _caracs) c.$1: null};

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
        if (idx >= 0) {
          _assignments[abbr] = idx;
          used[idx] = true;
        }
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
      _preset.isNotEmpty && _assignments.values.every((v) => v != null);

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
      for (final k in _assignments.keys) {
        _assignments[k] = null;
      }
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
              ...(_presets.keys.map(
                (p) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _presetLabels[p]!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: p,
                  groupValue: _preset,
                  onChanged: (v) => _onPresetChanged(v!),
                ),
              )),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            isDense: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text(
                              '—',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: current,
                            items: [
                              if (current != null)
                                DropdownMenuItem(
                                  value: current,
                                  child: Text(
                                    _formatVal(vals[current]),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ...available
                                  .where((i) => i != current)
                                  .map(
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        _formatVal(vals[i]),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged:
                                (idx) =>
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
          onPressed:
              _allAssigned
                  ? () => Navigator.pop(context, _buildResult())
                  : null,
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

// ── Dice Log ──────────────────────────────────────────────────────────────────
