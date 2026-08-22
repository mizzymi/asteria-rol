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
            // =================================================================
            // DAÑO BASE DEL ARMA
            // =================================================================
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

                    if (damage.damageType.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        damage.damageType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    Text(
                      _rollText(roll, shownModifier),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${part.total}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // =================================================================
            // BONUS DE DAÑO DE PASIVAS / EFECTOS
            // =================================================================
            if (result.bonusDamageParts.isNotEmpty) ...[
              const SizedBox(height: 4),

              Text(
                'Daño adicional',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              ...result.bonusDamageParts.map((part) {
                final bonus = part.bonus;

                return ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: const Icon(Icons.bolt_rounded),

                  title: Text(
                    bonus.name.trim().isNotEmpty ? bonus.name : 'Bonus de daño',
                  ),

                  subtitle: Text(
                    _bonusFormula(bonus.diceNotation, bonus.flatBonus),
                  ),

                  trailing: Text(
                    '+${part.total}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                );
              }),
            ],

            // =================================================================
            // BONUS DE CRÍTICO DE PASIVAS / EFECTOS
            // =================================================================
            if (result.critical && result.criticalBonusParts.isNotEmpty) ...[
              const Divider(),

              Text(
                'Daño extra de crítico',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              ...result.criticalBonusParts.map((part) {
                final bonus = part.bonus;

                return ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: Icon(
                    part.triggered
                        ? Icons.local_fire_department_rounded
                        : Icons.casino_outlined,
                  ),

                  title: Text(
                    bonus.name.trim().isNotEmpty ? bonus.name : 'Bonus crítico',
                  ),

                  subtitle: Text(
                    part.triggered
                        ? _bonusFormula(bonus.diceNotation, bonus.flatBonus)
                        : 'No activado · ${part.chanceRoll}/${bonus.chancePercent}',
                  ),

                  trailing: Text(
                    part.triggered ? '+${part.total}' : '0',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: part.triggered
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),
            ],

            const Divider(),

            const SizedBox(height: 8),

            // =================================================================
            // RESUMEN
            // =================================================================
            _TotalRow(label: 'Daño del arma', value: result.weaponDamageTotal),

            if (result.bonusDamageTotal != 0)
              _TotalRow(
                label: 'Daño adicional',
                value: result.bonusDamageTotal,
              ),

            if (result.critical && result.criticalBonusTotal != 0)
              _TotalRow(
                label: 'Daño crítico extra',
                value: result.criticalBonusTotal,
              ),

            const SizedBox(height: 12),

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
          icon: const Icon(Icons.gps_fixed_rounded),
          label: const Text('Volver a atacar'),
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

    var text = parts.join(' + ');

    if (modifier > 0) {
      text += ' + $modifier';
    }

    if (modifier < 0) {
      text += ' - ${modifier.abs()}';
    }

    return text;
  }

  String _bonusFormula(String diceNotation, int flatBonus) {
    final parts = <String>[];

    if (diceNotation.trim().isNotEmpty) {
      parts.add(diceNotation.trim());
    }

    if (flatBonus != 0) {
      parts.add(flatBonus > 0 ? '+$flatBonus' : '$flatBonus');
    }

    if (parts.isEmpty) {
      return 'Daño adicional';
    }

    return parts.join(' + ').replaceAll('+ -', '- ');
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final int value;

  const _TotalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),

          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
