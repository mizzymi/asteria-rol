import 'package:flutter/material.dart';

import '../../../models/action_chance_check.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';
import '../common/numeric_dice_field.dart';

Future<List<ActionPhysicalChanceInput>?> showPhysicalChanceChecksDialog(
  BuildContext context, {
  required List<ActionChanceCheck> checks,
}) async {
  if (checks.isEmpty) {
    return const [];
  }

  final rolls = <String, int?>{
    for (final check in checks)
      check.id: null,
  };

  final errors = <String, String?>{};

  final result = await showDialog<List<ActionPhysicalChanceInput>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return ActionDialogScaffold(
            icon: Icons.percent_rounded,

            title: 'Tiradas de probabilidad',

            subtitle: 'Introduce todos los d100.',

            primaryLabel: 'Continuar',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: () {
              var valid = true;

              for (final check in checks) {
                final roll = rolls[check.id];

                if (roll == null || roll < 1 || roll > 100) {
                  errors[check.id] = 'Entre 1 y 100';

                  valid = false;
                } else {
                  errors[check.id] = null;
                }
              }

              if (!valid) {
                setDialogState(() {});
                return;
              }

              final inputs = checks
                  .map(
                    (check) => ActionPhysicalChanceInput(
                      checkId: check.id,
                      roll: rolls[check.id]!,
                    ),
                  )
                  .toList(growable: false);

              Navigator.of(
                dialogContext,
              ).pop(List<ActionPhysicalChanceInput>.unmodifiable(inputs));
            },

            child: Column(
              children: [
                for (final check in checks) ...[
                  ActionSectionCard(
                    title: check.label,

                    subtitle: '${check.normalizedChance}% de probabilidad',

                    icon: Icons.percent_rounded,

                    child: NumericDiceField(
                      sides: 100,
                      value: rolls[check.id],
                      errorText: errors[check.id],
                      onChanged: (value) {
                        rolls[check.id] = value;
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      );
    },
  );

  return result;
}
