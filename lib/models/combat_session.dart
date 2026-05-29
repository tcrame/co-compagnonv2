class CombatSession {
  final int? id;
  final String name;
  final DateTime createdAt;

  CombatSession({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory CombatSession.fromMap(Map<String, dynamic> map) => CombatSession(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  CombatSession copyWith({int? id, String? name, DateTime? createdAt}) =>
      CombatSession(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
}
