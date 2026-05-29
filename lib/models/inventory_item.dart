class InventoryItem {
  final int? id;
  final int characterSheetId;
  final String name;
  final int quantity;
  final String description;
  final int position;

  const InventoryItem({
    this.id,
    required this.characterSheetId,
    this.name = '',
    this.quantity = 1,
    this.description = '',
    this.position = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'character_sheet_id': characterSheetId,
    'name': name,
    'quantity': quantity,
    'description': description,
    'position': position,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> m) => InventoryItem(
    id: m['id'] as int?,
    characterSheetId: m['character_sheet_id'] as int,
    name: m['name'] as String? ?? '',
    quantity: m['quantity'] as int? ?? 1,
    description: m['description'] as String? ?? '',
    position: m['position'] as int? ?? 0,
  );

  InventoryItem copyWith({
    int? id,
    int? characterSheetId,
    String? name,
    int? quantity,
    String? description,
    int? position,
  }) => InventoryItem(
    id: id ?? this.id,
    characterSheetId: characterSheetId ?? this.characterSheetId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    description: description ?? this.description,
    position: position ?? this.position,
  );
}
