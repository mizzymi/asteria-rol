import 'package:flutter/material.dart';

import '../../../models/dice_pool.dart';
import '../../../models/passive_charge_dice_scaling.dart';

import '../../forms/common/dice_pools_editor.dart';

class PassiveChargeScalingEditor extends StatelessWidget {
  final PassiveChargeDiceScaling scaling;

  final bool ownerUsesCharges;

  final ValueChanged<PassiveChargeDiceScaling> onChanged;

  const PassiveChargeScalingEditor({
    super.key,
    required this.scaling,
    required this.ownerUsesCharges,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!ownerUsesCharges) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Esta pasiva no utiliza cargas. '
                'Activa las cargas en la sección de la pasiva '
                'para poder escalar este bonus.',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,

          value: scaling.enabled,

          title: const Text('Escalar según cargas'),

          subtitle: const Text(
            'Añade dados por cada carga actual de la pasiva.',
          ),

          onChanged: (enabled) {
            onChanged(
              PassiveChargeDiceScaling(
                enabled: enabled,

                dicePoolsPerCharge: scaling.dicePoolsPerCharge,

                maxCharges: scaling.maxCharges,

                minimumCharges: scaling.minimumCharges,
              ),
            );
          },
        ),

        if (scaling.enabled) ...[
          const SizedBox(height: 12),

          Text(
            'Dados por carga',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          DicePoolsEditor(
            pools: scaling.dicePoolsPerCharge,

            onAdd: () {
              final pools = <DicePool>[
                ...scaling.dicePoolsPerCharge,
                DicePool(count: 1, sides: 4),
              ];

              onChanged(
                PassiveChargeDiceScaling(
                  enabled: true,
                  dicePoolsPerCharge: pools,
                  maxCharges: scaling.maxCharges,
                  minimumCharges: scaling.minimumCharges,
                ),
              );
            },

            onChanged: () {
              // DicePoolsEditor ya ha mutado la lista.
              // Creamos una nueva configuración para
              // mantener el modelo consistente.
              onChanged(
                PassiveChargeDiceScaling(
                  enabled: true,

                  dicePoolsPerCharge: List<DicePool>.from(
                    scaling.dicePoolsPerCharge,
                  ),

                  maxCharges: scaling.maxCharges,

                  minimumCharges: scaling.minimumCharges,
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '${scaling.minimumCharges}',

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'Cargas mínimas',
                    helperText: 'Necesarias para aportar dados.',
                  ),

                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? 1;

                    onChanged(
                      PassiveChargeDiceScaling(
                        enabled: true,

                        dicePoolsPerCharge: scaling.dicePoolsPerCharge,

                        minimumCharges: parsed < 1 ? 1 : parsed,

                        maxCharges: scaling.maxCharges,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  initialValue: '${scaling.maxCharges}',

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'Máximo considerado',
                    helperText: '0 = sin límite.',
                  ),

                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? 0;

                    onChanged(
                      PassiveChargeDiceScaling(
                        enabled: true,

                        dicePoolsPerCharge: scaling.dicePoolsPerCharge,

                        minimumCharges: scaling.minimumCharges,

                        maxCharges: parsed < 0 ? 0 : parsed,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
