import 'package:flutter/material.dart';

import '../../models/action_critical_profile.dart';
import '../../models/weapon.dart';
import '../../models/weapon_attack_resolution.dart';

import '../abilities/attack_roll_sheet.dart';

import '../action_resolution/common/action_attack_roll_result_card.dart';
import '../action_resolution/common/action_dialog_scaffold.dart';
import '../action_resolution/common/action_section_card.dart';

Future<void> showWeaponAttackResultDialog(
  BuildContext context, {
  required Weapon weapon,
  required WeaponAttackResolution result,
  required VoidCallback onReroll,
  required ValueChanged<ActionCriticalType> onRollDamage,
}) {
  final attackResult = result.attackResult;
  final criticalType = attackResult.criticalType;
  final criticalFail = result.criticalFail;

  final criticalLabel = switch (criticalType) {
    ActionCriticalType.none => null,
    ActionCriticalType.normal => 'Crítico',
    ActionCriticalType.empowered => 'Crítico potenciado',
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return ActionDialogScaffold(
        icon: attackResult.critical
            ? Icons.local_fire_department_rounded
            : criticalFail
            ? Icons.warning_amber_rounded
            : Icons.gps_fixed_rounded,
        title: weapon.name,
        subtitle: criticalFail
            ? 'Pifia'
            : attackResult.critical
            ? criticalLabel
            : 'Resultado del ataque',
        secondaryLabel: 'Volver a atacar',
        onSecondary: () {
          Navigator.of(dialogContext).pop();
          onReroll();
        },
        primaryLabel: criticalFail
            ? 'Cerrar'
            : attackResult.critical
            ? 'Daño crítico'
            : 'Tirar daño',
        onPrimary: () {
          Navigator.of(dialogContext).pop();

          if (!criticalFail) {
            onRollDamage(criticalType);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionAttackRollResultCard(
              attackResult: attackResult,
              criticalLabel: criticalLabel,
            ),
            if (result.secondRoll != null) ...[
              const SizedBox(height: 12),
              ActionSectionCard(
                icon: result.mode.icon,
                title: result.mode.label,
                child: Row(
                  children: [
                    Expanded(
                      child: _RollLine(
                        label: 'd20 #1',
                        value: result.firstRoll,
                        selected: result.firstRoll == result.naturalRoll,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RollLine(
                        label: 'd20 #2',
                        value: result.secondRoll!,
                        selected: result.secondRoll == result.naturalRoll,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (criticalFail) ...[
              const SizedBox(height: 12),
              const ActionSectionCard(
                icon: Icons.warning_amber_rounded,
                title: 'Pifia',
                child: Text(
                  'El resultado natural fue 1. No se puede tirar daño.',
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _RollLine extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;

  const _RollLine({
    required this.label,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: selected ? theme.colorScheme.primary : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
