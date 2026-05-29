class Participant {
  final int? id;
  final int sessionId;
  final String name;
  final bool isAlly;
  final int baseInitiative;
  final int maxHp;
  final int currentHp;
  final String? imageUrl;

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
    this.imageUrl,
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
        'image_url': imageUrl,
      };

  factory Participant.fromMap(Map<String, dynamic> map) => Participant(
        id: map['id'] as int,
        sessionId: map['session_id'] as int,
        name: map['name'] as String,
        isAlly: (map['is_ally'] as int) == 1,
        baseInitiative: map['base_initiative'] as int,
        maxHp: map['max_hp'] as int,
        currentHp: map['current_hp'] as int,
        imageUrl: map['image_url'] as String?,
      );

  Participant copyWith({
    int? id,
    int? sessionId,
    String? name,
    bool? isAlly,
    int? baseInitiative,
    int? maxHp,
    int? currentHp,
    String? imageUrl,
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
        imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
        rolledInitiative: rolledInitiative ?? this.rolledInitiative,
      );

  bool get isAlive => currentHp > 0;
  int get hpPercent => maxHp > 0 ? (currentHp / maxHp * 100).round() : 0;
}
