import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/weapon.dart';
import '../../models/weapon_damage_result.dart';

class WeaponDamageResultDialog extends StatelessWidget {
  final Character character;
  final Weapon weapon;
  final WeaponDamageResult result;

  final VoidCallback onReroll;

  const WeaponDamageResultDialog({
    super.key,
    required this.character,
    required this.weapon,
    required this.result,
    required this.onReroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.critical
                ? Icons.local_fire_department_rounded
                : Icons.casino_rounded,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              result.critical ? '${weapon.name} · CRÍTICO' : weapon.name,
            ),
          ),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...result.parts.map((part) {
              final damage = part.damage;
              final roll = part.roll;

              final modifier = character.weaponDamageModifier(weapon, damage);

              final shownModifier = result.critical ? modifier * 2 : modifier;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      damage.name.isNotEmpty ? damage.name : damage.damageType,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (damage.damageType.isNotEmpty)
                      Text(
                        damage.damageType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                    const SizedBox(height: 10),

                    Text(
                      _rollText(roll, shownModifier),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${roll.total}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(),

            const SizedBox(height: 8),

            Center(
              child: Column(
                children: [
                  Text(
                    'Daño total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${result.total}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton.icon(
          onPressed: onReroll,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Volver a tirar'),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  String _rollText(dynamic roll, int modifier) {
    final parts = <String>[];

    for (final group in roll.groups) {
      parts.add(group.rolls.join(' + '));
    }

    String result = parts.join(' + ');

    if (modifier > 0) {
      result += ' + $modifier';
    }

    if (modifier < 0) {
      result += ' - ${modifier.abs()}';
    }

    return result;
  }
}
