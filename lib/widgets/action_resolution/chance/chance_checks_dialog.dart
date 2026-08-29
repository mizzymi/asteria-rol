import 'package:flutter/material.dart';

import '../../../models/action_chance_check.dart';
import '../../../services/action_chance_resolver.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';
import '../common/numeric_dice_field.dart';

Future<List<ActionChanceResult>?> showPhysicalChanceChecksDialog(
  BuildContext context, {
  required List<ActionChanceCheck> checks,
}) async {
  if (checks.isEmpty) {
    return const [];
  }

  final controllers = <String, TextEditingController>{
    for (final check in checks) check.id: TextEditingController(),
  };

  final errors = <String, String?>{};

  final result = await showDialog<List<ActionChanceResult>>(
    context: context,
    barrierDismissible: false,
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

              final rolls = <String, int>{};

              for (final check in checks) {
                final roll = int.tryParse(controllers[check.id]!.text.trim());

                if (roll == null || roll < 1 || roll > 100) {
                  errors[check.id] = 'Entre 1 y 100';

                  valid = false;
                } else {
                  errors[check.id] = null;

                  rolls[check.id] = roll;
                }
              }

              if (!valid) {
                setDialogState(() {});
                return;
              }

              final resolver = ActionChanceResolver();

              final results = checks
                  .map(
                    (check) => resolver.resolvePhysical(
                      check: check,
                      roll: rolls[check.id]!,
                    ),
                  )
                  .toList(growable: false);

              Navigator.pop(
                dialogContext,
                List<ActionChanceResult>.unmodifiable(results),
              );
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

                      controller: controllers[check.id]!,

                      errorText: errors[check.id],
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

  for (final controller in controllers.values) {
    controller.dispose();
  }

  return result;
}
