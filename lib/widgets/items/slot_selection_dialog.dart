import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/item.dart';

class SlotSelectionDialog extends StatelessWidget {
  final Character character;
  final ItemDefinition definition;
  final InventoryItem item;

  const SlotSelectionDialog({
    super.key,
    required this.character,
    required this.definition,
    required this.item,
  });

  static Future<String?> show(
    BuildContext context, {
    required Character character,
    required ItemDefinition definition,
    required InventoryItem item,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SlotSelectionDialog(
        character: character,
        definition: definition,
        item: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validSlotIds = definition.equipmentSlotIds.isNotEmpty
        ? definition.equipmentSlotIds
        : [definition.type.defaultEquipmentSlotId];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar ranura',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '¿Dónde deseas equipar "${definition.name}"?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...validSlotIds.map((slotId) {
              // Buscar si ya hay algo equipado en este slot
              InventoryItem? currentlyEquipped;
              for (final inv in character.inventoryItems) {
                if (inv.equipped && inv.equippedSlotId == slotId) {
                  currentlyEquipped = inv;
                  break;
                }
              }

              final currentDef = currentlyEquipped != null
                  ? character.definitionForInventoryItem(currentlyEquipped)
                  : null;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                leading: const Icon(Icons.checkroom_rounded),
                title: Text(
                  slotId!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: currentDef != null
                    ? Text('Ocupado por: ${currentDef.name}')
                    : const Text(
                        'Vacío',
                        style: TextStyle(color: Colors.green),
                      ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, slotId),
              );
            }),
          ],
        ),
      ),
    );
  }
}
