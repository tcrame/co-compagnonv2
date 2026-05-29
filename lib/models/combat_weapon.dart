class CombatWeapon {
  final int? id;
  final int characterSheetId;
  final String name;
  /// 'contact' or 'distance'
  final String type;
  final int portee;
  final bool equipped;
  final String description;
  final int position;
  /// Free text damage expression e.g. "1d6", "2d8+3" (may be empty)
  final String dm;

  const CombatWeapon({
    this.id,
    required this.characterSheetId,
    this.name = '',
    this.type = 'contact',
    this.portee = 0,
    this.equipped = false,
    this.description = '',
    this.position = 0,
    this.dm = '',
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'character_sheet_id': characterSheetId,
    'name': name,
    'type': type,
    'portee': portee,
    'equipped': equipped ? 1 : 0,
    'description': description,
    'position': position,
    'dm': dm,
  };

  factory CombatWeapon.fromMap(Map<String, dynamic> m) => CombatWeapon(
    id: m['id'] as int?,
    characterSheetId: m['character_sheet_id'] as int,
    name: m['name'] as String? ?? '',
    type: m['type'] as String? ?? 'contact',
    portee: m['portee'] as int? ?? 0,
    equipped: (m['equipped'] as int? ?? 0) == 1,
    description: m['description'] as String? ?? '',
    position: m['position'] as int? ?? 0,
    dm: m['dm'] as String? ?? '',
  );

  CombatWeapon copyWith({
    int? id,
    int? characterSheetId,
    String? name,
    String? type,
    int? portee,
    bool? equipped,
    String? description,
    int? position,
    String? dm,
  }) => CombatWeapon(
    id: id ?? this.id,
    characterSheetId: characterSheetId ?? this.characterSheetId,
    name: name ?? this.name,
    type: type ?? this.type,
    portee: portee ?? this.portee,
    equipped: equipped ?? this.equipped,
    description: description ?? this.description,
    position: position ?? this.position,
    dm: dm ?? this.dm,
  );
}
