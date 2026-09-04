class InventoryItem {
  final String id;
  String characterId;
  String itemId;
  int quantity;
  bool equipped;
  String? equippedSlotId;
  String? customName;
  String? notes;

  InventoryItem({
    required this.id,
    this.characterId = '',
    required this.itemId,
    this.quantity = 1,
    this.equipped = false,
    this.equippedSlotId,
    this.customName,
    this.notes,
  });

  // Alias para la separación formal del catálogo
  String get itemDefinitionId => itemId;
  set itemDefinitionId(String value) => itemId = value;

  InventoryItem copyWith({
    String? id,
    String? characterId,
    String? itemId,
    int? quantity,
    bool? equipped,
    String? Function()? equippedSlotId,
    String? customName,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      equipped: equipped ?? this.equipped,
      equippedSlotId: equippedSlotId != null
          ? equippedSlotId()
          : this.equippedSlotId,
      customName: customName ?? this.customName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'characterId': characterId,
    'itemId': itemId,
    'quantity': quantity,
    'equipped': equipped,
    'equippedSlotId': equippedSlotId,
    'customName': customName,
    'notes': notes,
  };

  Map<String, dynamic> toJson() => toMap();

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    final equippedSlot = map['equippedSlotId'] as String?;
    final isEquipped =
        map['equipped'] as bool? ??
        (equippedSlot != null && equippedSlot.isNotEmpty);
    return InventoryItem(
      id: map['id'] as String? ?? '',
      characterId: map['characterId'] as String? ?? '',
      itemId: (map['itemId'] ?? map['itemDefinitionId']) as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      equipped: isEquipped,
      equippedSlotId: equippedSlot,
      customName: map['customName'] as String?,
      notes: map['notes'] as String?,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      InventoryItem.fromMap(json);
}
