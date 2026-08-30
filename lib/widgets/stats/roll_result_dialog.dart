import 'package:flutter/material.dart';

import '../../models/action_critical_profile.dart';
import '../../models/skill.dart';

import 'stats_colors.dart';

class RollResultDialog extends StatelessWidget {
  final String label;

  final AbilityType ability;

  final int naturalRoll;

  final int total;

  final int bonus;

  final ActionCriticalProfile criticalProfile;

  final VoidCallback onRepeat;

  const RollResultDialog({
    super.key,
    required this.label,
    required this.ability,
    required this.naturalRoll,
    required this.total,
    required this.bonus,
    required this.criticalProfile,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = StatsColors.abilityColor(ability);

    final failure = naturalRoll == 1;

    final critical = !failure && criticalProfile.isCriticalRoll(naturalRoll);

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
                    '$naturalRoll',
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
                  ? '$naturalRoll + $bonus'
                  : '$naturalRoll - ${bonus.abs()}',
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 6),

            Text(
              'TOTAL $total',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),

            if (critical) ...[
              const SizedBox(height: 12),

              Text(
                criticalProfile.minimumNaturalRoll == 20
                    ? '✨ $naturalRoll natural · crítico'
                    : '✨ $naturalRoll natural · crítico '
                          '(${criticalProfile.minimumNaturalRoll}–20)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],

            if (failure) ...[
              const SizedBox(height: 12),

              const Text(
                '💀 1 natural',
                style: TextStyle(fontWeight: FontWeight.w800),
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
