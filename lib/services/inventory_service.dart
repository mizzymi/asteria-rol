import 'package:flutter/material.dart';

import '../models/action_execution_result.dart';
import '../models/character.dart';
import '../models/equipment_slot.dart';
import '../models/item.dart';
import 'action_resolution_flow.dart';

class InventoryService {
  const InventoryService();

  // ===========================================================================
  // AGREGAR / REMOVER ITEMS
  // ===========================================================================

  void addItem({
    required Character character,
    required ItemDefinition definition,
    int quantity = 1,
  }) {
    if (quantity <= 0) return;

    character.registerItemDefinition(definition);

    if (definition.stackable) {
      for (final invItem in character.inventoryItems) {
        if (invItem.itemId == definition.id && !invItem.equipped) {
          invItem.quantity += quantity;
          return;
        }
      }
    }

    character.inventoryItems.add(
      InventoryItem(
        id: 'inv_${DateTime.now().microsecondsSinceEpoch}_${character.inventoryItems.length}',
        itemId: definition.id,
        quantity: quantity,
        equipped: false,
        equippedSlotId: null,
      ),
    );
  }

  bool removeItem({
    required Character character,
    required String inventoryItemId,
    int quantity = 1,
  }) {
    final index = character.inventoryItems.indexWhere(
      (item) => item.id == inventoryItemId,
    );
    if (index < 0) return false;

    final item = character.inventoryItems[index];
    if (item.quantity <= quantity) {
      if (item.equipped) {
        character.unequipInventoryItem(item);
      }
      character.inventoryItems.removeAt(index);
    } else {
      item.quantity -= quantity;
    }

    return true;
  }

  // ===========================================================================
  // EQUIPAMIENTO
  // ===========================================================================

  void equipItemInSlot({
    required Character character,
    required InventoryItem item,
    required String slotId,
  }) {
    final definition = character.definitionForInventoryItem(item);
    if (definition == null || !definition.isEquippable) return;

    // 1. Buscar la definición del slot para conocer su maxEquipped
    final slotDef = character.equipmentSlots.firstWhere(
      (s) => s.id == slotId,
      orElse: () => EquipmentSlotDefinition(
        id: slotId,
        name: slotId,
        category: EquipmentSlotCategory.custom,
        maxEquipped: 1,
      ),
    );

    // 2. Objetos actualmente equipados en este mismo slot
    final equippedInSlot = character.inventoryItems
        .where(
          (i) => i.equipped && i.equippedSlotId == slotId && i.id != item.id,
        )
        .toList();

    // 3. Si ya llegó o superó su capacidad, desequipar el necesario
    while (equippedInSlot.length >= slotDef.maxEquipped &&
        equippedInSlot.isNotEmpty) {
      final toUnequip = equippedInSlot.removeAt(0);
      character.unequipInventoryItem(toUnequip);
    }

    // 4. Equipar el nuevo objeto
    character.equipInventoryItem(item, slotId: slotId);
  }

  void equipItem({
    required Character character,
    required InventoryItem item,
    EquipmentSlotDefinition? slot,
  }) {
    final definition = character.definitionForInventoryItem(item);
    if (definition == null || !definition.isEquippable) return;

    final targetSlotId =
        slot?.id ??
        (definition.equipmentSlotIds.isNotEmpty
            ? definition.equipmentSlotIds.first
            : definition.type.defaultEquipmentSlotId ?? 'main_hand');

    equipItemInSlot(character: character, item: item, slotId: targetSlotId);
  }

  void unequipItem({
    required Character character,
    required InventoryItem item,
  }) {
    character.unequipInventoryItem(item);
  }

  // ===========================================================================
  // CONSUMO ATÓMICO (ACTION ENGINE)
  // ===========================================================================

  Future<bool> useConsumable({
    required BuildContext context,
    required Character character,
    required InventoryItem inventoryItem,
  }) async {
    final definition = character.definitionForInventoryItem(inventoryItem);
    if (definition == null) return false;

    if (inventoryItem.quantity <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No te quedan unidades de ${definition.name}.'),
          ),
        );
      }
      return false;
    }

    final flow = ActionResolutionFlow(character: character);

    // Ejecuta el flujo nativo de consumible del Action Engine
    final ActionExecutionResult? result = await flow.resolveConsumable(
      context,
      item: definition,
    );

    // Atomicidad: si se cancela o falla el commit, no se resta nada
    if (result == null) {
      return false;
    }

    // Deducción atómica pos-commit
    removeItem(
      character: character,
      inventoryItemId: inventoryItem.id,
      quantity: 1,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Has usado ${definition.name}.')));
    }

    return true;
  }
}
