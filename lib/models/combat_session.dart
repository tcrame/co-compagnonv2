class CombatSession {
  final int? id;
  final String name;
  final String shareCode; // 💡 AJOUT : Code de partage unique alphanumérique
  final DateTime createdAt;

  CombatSession({
    this.id,
    required this.name,
    required this.shareCode, // 💡 Requis dans le constructeur
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'share_code': shareCode, // 💡 AJOUT : Persistance dans la base locale
    'created_at': createdAt.toIso8601String(),
  };

  factory CombatSession.fromMap(Map<String, dynamic> map) => CombatSession(
    id: map['id'] as int?, // Sécurisé au cas où l'id est nul à l'extraction
    name: map['name'] as String,
    shareCode: map['share_code'] as String? ?? '', // 💡 AJOUT : Récupération avec fallback de secours
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  CombatSession copyWith({int? id, String? name, String? shareCode, DateTime? createdAt}) =>
      CombatSession(
        id: id ?? this.id,
        name: name ?? this.name,
        shareCode: shareCode ?? this.shareCode, // 💡 Pris en compte dans le copyWith
        createdAt: createdAt ?? this.createdAt,
      );
}
