class InventoryItem {
  /// Identidad de ESTA entrada del inventario.
  ///
  /// No es la identidad del objeto.
  final String id;

  /// ItemDefinition real que posee el personaje.
  final String itemId;

  int quantity;

  bool equipped;

  /// Slot concreto donde está equipado.
  ///
  /// null = inventario.
  String? equippedSlotId;

  InventoryItem({
    required this.id,
    required this.itemId,
    this.quantity = 1,
    this.equipped = false,
    this.equippedSlotId,
  }) : assert(quantity >= 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'quantity': quantity,
      'equipped': equipped,
      'equippedSlotId': equippedSlotId,
    };
  }

  factory InventoryItem.fromMap(Map<dynamic, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      equipped: map['equipped'] == true,
      equippedSlotId: map['equippedSlotId']?.toString(),
    );
  }
}
