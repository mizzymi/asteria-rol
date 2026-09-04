import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/equipment_slot.dart';

class EquipmentSlotsConfigDialog extends StatefulWidget {
  final Character character;
  final VoidCallback onSaved;

  const EquipmentSlotsConfigDialog({
    super.key,
    required this.character,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Character character,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          EquipmentSlotsConfigDialog(character: character, onSaved: onSaved),
    );
  }

  @override
  State<EquipmentSlotsConfigDialog> createState() =>
      _EquipmentSlotsConfigDialogState();
}

class _EquipmentSlotsConfigDialogState
    extends State<EquipmentSlotsConfigDialog> {
  late Map<String, int> _capacities;

  @override
  void initState() {
    super.initState();

    if (widget.character.equipmentSlots.isEmpty) {
      widget.character.equipmentSlots = List.from(defaultEquipmentSlots);
    }

    _capacities = {
      for (final slot in widget.character.equipmentSlots)
        slot.id: slot.maxEquipped,
    };
  }

  void _modify(String slotId, int delta) {
    setState(() {
      final current = _capacities[slotId] ?? 1;
      _capacities[slotId] = (current + delta).clamp(0, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded),
          SizedBox(width: 10),
          Text('Ranuras de equipo'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.character.equipmentSlots.map((slot) {
            final count = _capacities[slot.id] ?? slot.maxEquipped;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          slot.id,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () => _modify(slot.id, -1),
                  ),
                  Container(
                    width: 38,
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _modify(slot.id, 1),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            for (final entry in _capacities.entries) {
              widget.character.updateSlotCapacity(entry.key, entry.value);
            }
            widget.onSaved();
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
