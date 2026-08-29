import 'package:flutter/material.dart';

import '../../../models/skill.dart';

class AbilityMultiplierEditor extends StatelessWidget {
  final Map<AbilityType, int> multipliers;

  final ValueChanged<Map<AbilityType, int>> onChanged;

  const AbilityMultiplierEditor({
    super.key,
    required this.multipliers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Modificadores',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            IconButton.filledTonal(
              tooltip: 'Añadir atributo',
              onPressed: () {
                for (final ability in AbilityType.values) {
                  if (multipliers.containsKey(ability)) {
                    continue;
                  }

                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated[ability] = 1;

                  onChanged(updated);

                  return;
                }
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        for (final entry in multipliers.entries)
          Row(
            children: [
              Expanded(child: Text(entry.key.label)),

              IconButton(
                onPressed: entry.value > 1
                    ? () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated[entry.key] = entry.value - 1;

                        onChanged(updated);
                      }
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),

              Text(
                '×${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),

              IconButton(
                onPressed: () {
                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated[entry.key] = entry.value + 1;

                  onChanged(updated);
                },
                icon: const Icon(Icons.add_rounded),
              ),

              IconButton(
                onPressed: () {
                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated.remove(entry.key);

                  onChanged(updated);
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
      ],
    );
  }
}
