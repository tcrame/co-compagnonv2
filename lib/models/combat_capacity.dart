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
  /// True if this capacity was auto-added from a voie (cannot be manually deleted)
  final bool isFromVoie;
  /// The voie catalogue ID (e.g. "magicien_voie-de-la-magie-destructrice") — empty for manual entries
  final String voieCatalogueId;

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
    this.isFromVoie = false,
    this.voieCatalogueId = '',
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
    'is_from_voie': isFromVoie ? 1 : 0,
    'voie_catalogue_id': voieCatalogueId,
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
    isFromVoie: (m['is_from_voie'] as int? ?? 0) == 1,
    voieCatalogueId: m['voie_catalogue_id'] as String? ?? '',
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
    bool? isFromVoie,
    String? voieCatalogueId,
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
    isFromVoie: isFromVoie ?? this.isFromVoie,
    voieCatalogueId: voieCatalogueId ?? this.voieCatalogueId,
  );
}
