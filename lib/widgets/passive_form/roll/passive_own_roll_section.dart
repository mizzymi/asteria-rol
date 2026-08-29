import 'package:flutter/material.dart';

import '../../../models/dice_pool.dart';
import '../../../models/skill.dart';

import '../../forms/common/ability_multiplier_editor.dart';
import '../../forms/common/dice_pools_editor.dart';

class PassiveOwnRollSection extends StatelessWidget {
  final List<DicePool> dicePools;

  final Map<AbilityType, int> abilityMultipliers;

  final TextEditingController flatBonusController;

  final String preview;

  final VoidCallback onChanged;

  final ValueChanged<Map<AbilityType, int>> onMultipliersChanged;

  const PassiveOwnRollSection({
    super.key,
    required this.dicePools,
    required this.abilityMultipliers,
    required this.flatBonusController,
    required this.preview,
    required this.onChanged,
    required this.onMultipliersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.casino_rounded, size: 19)),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados de la tirada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        preview,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            DicePoolsEditor(
              pools: dicePools,

              onAdd: () {
                dicePools.add(DicePool(count: 1, sides: 6));

                onChanged();
              },

              onChanged: onChanged,
            ),

            const SizedBox(height: 14),

            AbilityMultiplierEditor(
              multipliers: abilityMultipliers,

              onChanged: onMultipliersChanged,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: flatBonusController,

              keyboardType: const TextInputType.numberWithOptions(signed: true),

              decoration: const InputDecoration(
                labelText: 'Bonus fijo de la tirada',
                hintText: '0',
                prefixIcon: Icon(Icons.exposure_plus_1_rounded),
              ),

              onChanged: (_) {
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
