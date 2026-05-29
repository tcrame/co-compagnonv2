class CombatCapacity {
  final int? id;
  final int characterSheetId;
  final String name;
  final bool isMagique;
  final String voie;
  final int rang;
  final int portee;
  final bool activated;
  final String description;
  final int position;
  /// Free text damage expression e.g. "1d6", "2d8+3" (may be empty)
  final String dm;

  const CombatCapacity({
    this.id,
    required this.characterSheetId,
    this.name = '',
    this.isMagique = false,
    this.voie = '',
    this.rang = 1,
    this.portee = 0,
    this.activated = false,
    this.description = '',
    this.position = 0,
    this.dm = '',
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'character_sheet_id': characterSheetId,
    'name': name,
    'is_magique': isMagique ? 1 : 0,
    'voie': voie,
    'rang': rang,
    'portee': portee,
    'activated': activated ? 1 : 0,
    'description': description,
    'position': position,
    'dm': dm,
  };

  factory CombatCapacity.fromMap(Map<String, dynamic> m) => CombatCapacity(
    id: m['id'] as int?,
    characterSheetId: m['character_sheet_id'] as int,
    name: m['name'] as String? ?? '',
    isMagique: (m['is_magique'] as int? ?? 0) == 1,
    voie: m['voie'] as String? ?? '',
    rang: m['rang'] as int? ?? 1,
    portee: m['portee'] as int? ?? 0,
    activated: (m['activated'] as int? ?? 0) == 1,
    description: m['description'] as String? ?? '',
    position: m['position'] as int? ?? 0,
    dm: m['dm'] as String? ?? '',
  );

  CombatCapacity copyWith({
    int? id,
    int? characterSheetId,
    String? name,
    bool? isMagique,
    String? voie,
    int? rang,
    int? portee,
    bool? activated,
    String? description,
    int? position,
    String? dm,
  }) => CombatCapacity(
    id: id ?? this.id,
    characterSheetId: characterSheetId ?? this.characterSheetId,
    name: name ?? this.name,
    isMagique: isMagique ?? this.isMagique,
    voie: voie ?? this.voie,
    rang: rang ?? this.rang,
    portee: portee ?? this.portee,
    activated: activated ?? this.activated,
    description: description ?? this.description,
    position: position ?? this.position,
    dm: dm ?? this.dm,
  );
}
