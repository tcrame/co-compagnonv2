class CombatArmor {
  final int? id;
  final int characterSheetId;
  final String name;
  /// 'principale' | 'casque' | 'gants' | 'bottes' | 'autre'
  final String type;
  /// 'tissus' | 'cuir souple' | 'cuir renforcé' | 'maille' | 'plaque' | 'autre'
  final String matiere;
  final int defBonus;
  final int encBase;
  /// Niveau de magie : réduit l'ENC de cette valeur
  final int niveauMagie;
  final bool equipped;
  final String description;

  const CombatArmor({
    this.id,
    required this.characterSheetId,
    this.name = '',
    this.type = 'principale',
    this.matiere = 'tissus',
    this.defBonus = 0,
    this.encBase = 0,
    this.niveauMagie = 0,
    this.equipped = false,
    this.description = '',
  });

  /// ENC effectif après réduction magique
  int get encEffectif => (encBase - niveauMagie).clamp(0, 99);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'character_sheet_id': characterSheetId,
    'name': name,
    'type': type,
    'matiere': matiere,
    'def_bonus': defBonus,
    'enc_base': encBase,
    'niveau_magie': niveauMagie,
    'equipped': equipped ? 1 : 0,
    'description': description,
  };

  factory CombatArmor.fromMap(Map<String, dynamic> m) => CombatArmor(
    id: m['id'] as int?,
    characterSheetId: m['character_sheet_id'] as int,
    name: m['name'] as String? ?? '',
    type: m['type'] as String? ?? 'principale',
    matiere: m['matiere'] as String? ?? 'tissus',
    defBonus: m['def_bonus'] as int? ?? 0,
    encBase: m['enc_base'] as int? ?? 0,
    niveauMagie: m['niveau_magie'] as int? ?? 0,
    equipped: (m['equipped'] as int? ?? 0) == 1,
    description: m['description'] as String? ?? '',
  );

  CombatArmor copyWith({
    int? id,
    int? characterSheetId,
    String? name,
    String? type,
    String? matiere,
    int? defBonus,
    int? encBase,
    int? niveauMagie,
    bool? equipped,
    String? description,
  }) => CombatArmor(
    id: id ?? this.id,
    characterSheetId: characterSheetId ?? this.characterSheetId,
    name: name ?? this.name,
    type: type ?? this.type,
    matiere: matiere ?? this.matiere,
    defBonus: defBonus ?? this.defBonus,
    encBase: encBase ?? this.encBase,
    niveauMagie: niveauMagie ?? this.niveauMagie,
    equipped: equipped ?? this.equipped,
    description: description ?? this.description,
  );
}

/// Valeurs suggérées par matière
const Map<String, ({int def, int enc})> kMatiereDefaults = {
  'tissus':         (def: 0, enc: 0),
  'cuir souple':    (def: 1, enc: 1),
  'cuir renforcé':  (def: 2, enc: 2),
  'maille':         (def: 3, enc: 4),
  'plaque':         (def: 4, enc: 6),
  'autre':          (def: 0, enc: 0),
};

const List<String> kArmorTypes = ['principale', 'casque', 'gants', 'bottes', 'autre'];
const List<String> kArmorMatieres = ['tissus', 'cuir souple', 'cuir renforcé', 'maille', 'plaque', 'autre'];
