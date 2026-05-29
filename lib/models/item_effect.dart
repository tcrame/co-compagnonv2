class ItemEffect {
  final int? id;
  /// 'weapon' | 'armor' | 'capacity'
  final String itemType;
  final int itemId;
  final String statKey;
  final int modifierValue;

  const ItemEffect({
    this.id,
    required this.itemType,
    required this.itemId,
    required this.statKey,
    required this.modifierValue,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'item_type': itemType,
    'item_id': itemId,
    'stat_key': statKey,
    'modifier_value': modifierValue,
  };

  factory ItemEffect.fromMap(Map<String, dynamic> m) => ItemEffect(
    id: m['id'] as int?,
    itemType: m['item_type'] as String,
    itemId: m['item_id'] as int,
    statKey: m['stat_key'] as String,
    modifierValue: m['modifier_value'] as int,
  );

  ItemEffect copyWith({
    int? id,
    String? itemType,
    int? itemId,
    String? statKey,
    int? modifierValue,
  }) => ItemEffect(
    id: id ?? this.id,
    itemType: itemType ?? this.itemType,
    itemId: itemId ?? this.itemId,
    statKey: statKey ?? this.statKey,
    modifierValue: modifierValue ?? this.modifierValue,
  );
}

/// Keys disponibles pour les effets
const List<({String key, String label})> kEffectStatKeys = [
  (key: 'agi',          label: 'Agilité (AGI)'),
  (key: 'con',          label: 'Constitution (CON)'),
  (key: 'for',          label: 'Force (FOR)'),
  (key: 'per',          label: 'Perception (PER)'),
  (key: 'cha',          label: 'Charisme (CHA)'),
  (key: 'int',          label: 'Intelligence (INT)'),
  (key: 'vol',          label: 'Volonté (VOL)'),
  (key: 'def',          label: 'Défense (DEF)'),
  (key: 'rd',           label: 'Réduction Dégâts (RD)'),
  (key: 'init',         label: 'Initiative (INIT)'),
  (key: 'att_contact',  label: 'Attaque Contact'),
  (key: 'att_distance', label: 'Attaque Distance'),
  (key: 'att_magique',  label: 'Attaque Magique'),
  (key: 'pv',           label: 'Points de Vie (PV max)'),
  (key: 'pm',           label: 'Points de Mana (PM max)'),
  (key: 'pc',           label: 'Points de Chance (PC max)'),
  (key: 'dr',           label: 'Dés de Récupération (DR max)'),
];
