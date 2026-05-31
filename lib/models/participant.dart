class Participant {
  final int? id;
  final int sessionId;
  final String name;
  final bool isAlly;
  final int baseInitiative;
  final int maxHp;
  final int currentHp;
  final int def;
  final String? imageUrl;
  final int? templateId;
  final int? characterSheetId;

  // Computed during combat — not persisted
  final int? rolledInitiative;

  const Participant({
    this.id,
    required this.sessionId,
    required this.name,
    required this.isAlly,
    required this.baseInitiative,
    required this.maxHp,
    required this.currentHp,
    this.def = 10,
    this.imageUrl,
    this.templateId,
    this.characterSheetId,
    this.rolledInitiative,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'name': name,
        'is_ally': isAlly ? 1 : 0,
        'base_initiative': baseInitiative,
        'max_hp': maxHp,
        'current_hp': currentHp,
        'def': def,
        'image_url': imageUrl,
        'template_id': templateId,
        'character_sheet_id': characterSheetId,
      };

  factory Participant.fromMap(Map<String, dynamic> map) => Participant(
        id: map['id'] as int,
        sessionId: map['session_id'] as int,
        name: map['name'] as String,
        isAlly: (map['is_ally'] as int) == 1,
        baseInitiative: map['base_initiative'] as int,
        maxHp: map['max_hp'] as int,
        currentHp: map['current_hp'] as int,
        def: (map['def'] as int?) ?? 10,
        imageUrl: map['image_url'] as String?,
        templateId: map['template_id'] as int?,
        characterSheetId: map['character_sheet_id'] as int?,
      );

  Participant copyWith({
    int? id,
    int? sessionId,
    String? name,
    bool? isAlly,
    int? baseInitiative,
    int? maxHp,
    int? currentHp,
    int? def,
    String? imageUrl,
    int? templateId,
    int? characterSheetId,
    int? rolledInitiative,
    bool clearImageUrl = false,
  }) =>
      Participant(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        name: name ?? this.name,
        isAlly: isAlly ?? this.isAlly,
        baseInitiative: baseInitiative ?? this.baseInitiative,
        maxHp: maxHp ?? this.maxHp,
        currentHp: currentHp ?? this.currentHp,
        def: def ?? this.def,
        imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
        templateId: templateId ?? this.templateId,
        characterSheetId: characterSheetId ?? this.characterSheetId,
        rolledInitiative: rolledInitiative ?? this.rolledInitiative,
      );

  bool get isAlive => currentHp > 0;
  int get hpPercent => maxHp > 0 ? (currentHp / maxHp * 100).round() : 0;
}
