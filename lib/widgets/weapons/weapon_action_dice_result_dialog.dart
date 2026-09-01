import 'package:flutter/material.dart';

import '../../models/action_critical_profile.dart';
import '../../models/action_dice_result.dart';
import '../../models/weapon.dart';

import '../action_resolution/common/action_dialog_scaffold.dart';
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
    return ActionDialogScaffold(
      icon: critical
          ? Icons.local_fire_department_rounded
          : Icons.flash_on_rounded,
      title: weapon.name,
      subtitle: switch (criticalType) {
        ActionCriticalType.none => 'Resultado del daño',
        ActionCriticalType.normal => 'Golpe crítico',
        ActionCriticalType.empowered => 'Crítico potenciado',
      },
      secondaryLabel: 'Cerrar',
      onSecondary: () {
        Navigator.of(context).pop();
      },
      primaryLabel: onReroll == null ? 'Cerrar' : 'Volver a atacar',
      onPrimary: onReroll == null
          ? () {
              Navigator.of(context).pop();
            }
          : onReroll,
      child: ActionValueBreakdown(
        title: 'Desglose del daño',
        collapsedLabel: 'Daño total',
        totalLabel: 'DAÑO TOTAL',
        icon: Icons.flash_on_rounded,
        parts: result.parts,
        finalTotal: result.total,
        criticalType: criticalType,
        fallbackColor: Theme.of(context).colorScheme.error,
        initiallyExpanded: false,
      ),
    );
  }
}
