import 'package:flutter/material.dart';

import '../../models/action_critical_profile.dart';
import '../../models/action_dice_result.dart';
import '../../models/weapon.dart';

import '../action_resolution/result/action_value_breakdown.dart';

class WeaponActionDiceResultDialog extends StatelessWidget {
  final Weapon weapon;

  final ActionDiceResult result;

  final ActionCriticalType criticalType;

  final VoidCallback? onReroll;

  const WeaponActionDiceResultDialog({
    super.key,
    required this.weapon,
    required this.result,
    required this.criticalType,
    this.onReroll,
  });

  bool get critical {
    return criticalType != ActionCriticalType.none;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            critical
                ? Icons.local_fire_department_rounded
                : Icons.casino_rounded,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(switch (criticalType) {
              ActionCriticalType.none => weapon.name,

              ActionCriticalType.normal => '${weapon.name} · CRÍTICO',

              ActionCriticalType.empowered =>
                '${weapon.name} · CRÍTICO POTENCIADO',
            }),
          ),
        ],
      ),

      content: SingleChildScrollView(
        child: ActionValueBreakdown(
          title: 'Daño',
          collapsedLabel: 'Ver desglose',
          totalLabel: 'Daño total',
          icon: Icons.flash_on_rounded,
          parts: result.parts,
          finalTotal: result.total,
          criticalType: criticalType,
          initiallyExpanded: true,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cerrar'),
        ),

        if (onReroll != null)
          FilledButton.icon(
            onPressed: onReroll,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Volver a atacar'),
          ),
      ],
    );
  }
}
