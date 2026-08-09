import 'package:flutter/material.dart';

import '../../models/dice_roll.dart';
import '../../models/skill.dart';

import 'stats_colors.dart';

class RollResultDialog extends StatelessWidget {
  final String label;

  final AbilityType ability;

  final DiceRollResult roll;

  final int bonus;

  final VoidCallback onRepeat;

  const RollResultDialog({
    super.key,
    required this.label,
    required this.ability,
    required this.roll,
    required this.bonus,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = StatsColors.abilityColor(ability);

    final critical = roll.die == 20;

    final failure = roll.die == 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: StatsColors.softBackground(
                      context,
                      ability,
                      strength: 0.22,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(StatsColors.abilityIcon(ability), color: color),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: StatsColors.softBackground(
                  context,
                  ability,
                  strength: 0.20,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${roll.die}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),

                  const Text('d20'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              bonus >= 0
                  ? '${roll.die} + $bonus'
                  : '${roll.die} - ${bonus.abs()}',
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 6),

            Text(
              'TOTAL ${roll.total}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),

            if (critical || failure) ...[
              const SizedBox(height: 12),

              Text(
                critical ? '✨ 20 natural' : '💀 1 natural',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cerrar'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRepeat,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Repetir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
