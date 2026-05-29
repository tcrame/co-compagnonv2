class CharacterTemplate {
  final int? id;
  final String name;
  final bool isAlly;
  final int baseInitiative;
  final int maxHp;
  final String? imageUrl;

  const CharacterTemplate({
    this.id,
    required this.name,
    required this.isAlly,
    required this.baseInitiative,
    required this.maxHp,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'is_ally': isAlly ? 1 : 0,
        'base_initiative': baseInitiative,
        'max_hp': maxHp,
        'image_url': imageUrl,
      };

  factory CharacterTemplate.fromMap(Map<String, dynamic> map) =>
      CharacterTemplate(
        id: map['id'] as int,
        name: map['name'] as String,
        isAlly: (map['is_ally'] as int) == 1,
        baseInitiative: map['base_initiative'] as int,
        maxHp: map['max_hp'] as int,
        imageUrl: map['image_url'] as String?,
      );

  CharacterTemplate copyWith({
    int? id,
    String? name,
    bool? isAlly,
    int? baseInitiative,
    int? maxHp,
    String? imageUrl,
    bool clearImageUrl = false,
  }) =>
      CharacterTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        isAlly: isAlly ?? this.isAlly,
        baseInitiative: baseInitiative ?? this.baseInitiative,
        maxHp: maxHp ?? this.maxHp,
        imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      );
}
