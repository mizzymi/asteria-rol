import 'package:flutter/material.dart';

import '../../../models/action_attack_roll_mode.dart';
import '../common/action_dialog_scaffold.dart';
import '../common/numeric_dice_field.dart';

typedef PhysicalAttackRolls = ({int firstRoll, int? secondRoll});

Future<PhysicalAttackRolls?> showPhysicalAttackRollDialog(
  BuildContext context, {
  required AttackRollMode mode,
}) async {
  final firstController = TextEditingController();
  final secondController = TextEditingController();

  String? firstError;
  String? secondError;

  final needsSecondRoll = mode != AttackRollMode.normal;

  final result = await showDialog<PhysicalAttackRolls>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final explanation = switch (mode) {
            AttackRollMode.normal => 'Introduce el resultado de tu d20.',

            AttackRollMode.advantage =>
              'Introduce ambos d20. Se utilizará el mayor.',

            AttackRollMode.disadvantage =>
              'Introduce ambos d20. Se utilizará el menor.',
          };

          void submit() {
            final first = int.tryParse(firstController.text.trim());

            final second = needsSecondRoll
                ? int.tryParse(secondController.text.trim())
                : null;

            var valid = true;

            if (first == null || first < 1 || first > 20) {
              firstError = 'Entre 1 y 20';
              valid = false;
            } else {
              firstError = null;
            }

            if (needsSecondRoll) {
              if (second == null || second < 1 || second > 20) {
                secondError = 'Entre 1 y 20';
                valid = false;
              } else {
                secondError = null;
              }
            }

            if (!valid) {
              setDialogState(() {});
              return;
            }

            Navigator.pop(dialogContext, (
              firstRoll: first!,
              secondRoll: second,
            ));
          }

          return ActionDialogScaffold(
            icon: Icons.gps_fixed_rounded,

            title: 'Tirada de ataque',

            subtitle: explanation,

            primaryLabel: 'Continuar',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: submit,

            child: needsSecondRoll
                ? Row(
                    children: [
                      Expanded(
                        child: NumericDiceField(
                          sides: 20,
                          controller: firstController,
                          label: 'd20 #1',
                          errorText: firstError,
                          autofocus: true,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: NumericDiceField(
                          sides: 20,
                          controller: secondController,
                          label: 'd20 #2',
                          errorText: secondError,
                        ),
                      ),
                    ],
                  )
                : NumericDiceField(
                    sides: 20,
                    controller: firstController,
                    errorText: firstError,
                    autofocus: true,
                  ),
          );
        },
      );
    },
  );

  firstController.dispose();
  secondController.dispose();

  return result;
}
