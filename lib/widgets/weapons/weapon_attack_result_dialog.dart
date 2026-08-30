import 'package:flutter/material.dart';

import '../../models/action_attack_roll_mode.dart';
import '../../models/action_critical_profile.dart';
import '../../models/weapon.dart';
import '../../models/weapon_attack_resolution.dart';

Future<void> showWeaponAttackResultDialog(
  BuildContext context, {
  required Weapon weapon,
  required WeaponAttackResolution result,
  required VoidCallback onReroll,
  required ValueChanged<ActionCriticalType> onRollDamage,
}) {
  final attackResult = result.attackResult;

  final criticalType = attackResult.criticalType;

  final critical = attackResult.critical;

  final criticalFail = result.criticalFail;

  final bonus = attackResult.modifier;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              critical
                  ? Icons.local_fire_department_rounded
                  : criticalFail
                  ? Icons.warning_rounded
                  : Icons.gps_fixed_rounded,
            ),

            const SizedBox(width: 10),

            Expanded(child: Text(weapon.name)),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.mode != AttackRollMode.normal)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      result.mode == AttackRollMode.advantage
                          ? 'Ventaja'
                          : 'Desventaja',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${result.firstRoll}  /  '
                      '${result.secondRoll}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

            Text('d20', style: Theme.of(context).textTheme.bodySmall),

            const SizedBox(height: 4),

            Text(
              '${result.naturalRoll}',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bonificador '),

                Text(
                  bonus >= 0 ? '+$bonus' : '$bonus',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Divider(),

            const SizedBox(height: 8),

            Text('TOTAL', style: Theme.of(context).textTheme.labelLarge),

            Text(
              '${result.total}',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
            ),

            if (critical) ...[
              const SizedBox(height: 8),

              Text(
                criticalType == ActionCriticalType.empowered
                    ? '🔥 CRÍTICO POTENCIADO'
                    : '💥 CRÍTICO',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],

            if (criticalFail) ...[
              const SizedBox(height: 8),

              const Text(
                '💀 PIFIA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ],
        ),

        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();

              onReroll();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Volver a atacar'),
          ),

          if (!criticalFail)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                onRollDamage(criticalType);
              },
              icon: Icon(
                critical
                    ? Icons.local_fire_department_rounded
                    : Icons.casino_rounded,
              ),
              label: Text(critical ? 'Daño crítico' : 'Tirar daño'),
            ),
        ],
      );
    },
  );
}
