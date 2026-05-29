class StatusEffect {
  final int? id;
  final int participantId;
  final String name;
  final String description;
  final int remainingTurns;

  const StatusEffect({
    this.id,
    required this.participantId,
    required this.name,
    required this.description,
    required this.remainingTurns,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'participant_id': participantId,
        'name': name,
        'description': description,
        'remaining_turns': remainingTurns,
      };

  factory StatusEffect.fromMap(Map<String, dynamic> m) => StatusEffect(
        id: m['id'] as int?,
        participantId: m['participant_id'] as int,
        name: m['name'] as String,
        description: m['description'] as String,
        remainingTurns: m['remaining_turns'] as int,
      );

  StatusEffect copyWith({
    int? id,
    int? participantId,
    String? name,
    String? description,
    int? remainingTurns,
  }) =>
      StatusEffect(
        id: id ?? this.id,
        participantId: participantId ?? this.participantId,
        name: name ?? this.name,
        description: description ?? this.description,
        remainingTurns: remainingTurns ?? this.remainingTurns,
      );
}
