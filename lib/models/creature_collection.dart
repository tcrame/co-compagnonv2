import '../models/character_template.dart';

class CreatureCollection {
  final int? id;
  final String name;
  final String syncUuid;
  final DateTime createdAt;

  // Compte ou liste des monstres inclus (optionnel, pratique pour l'UI)
  final List<CharacterTemplate> templates;

  const CreatureCollection({
    this.id,
    required this.name,
    required this.syncUuid,
    required this.createdAt,
    this.templates = const [],
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'sync_uuid': syncUuid,
    'created_at': createdAt.toIso8601String(),
  };

  factory CreatureCollection.fromMap(Map<String, dynamic> map, {List<CharacterTemplate> templates = const []}) {
    return CreatureCollection(
      id: map['id'] as int?,
      name: map['name'] as String,
      syncUuid: map['sync_uuid'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      templates: templates,
    );
  }

  CreatureCollection copyWith({
    int? id,
    String? name,
    String? syncUuid,
    DateTime? createdAt,
    List<CharacterTemplate>? templates,
  }) =>
      CreatureCollection(
        id: id ?? this.id,
        name: name ?? this.name,
        syncUuid: syncUuid ?? this.syncUuid,
        createdAt: createdAt ?? this.createdAt,
        templates: templates ?? this.templates,
      );
}