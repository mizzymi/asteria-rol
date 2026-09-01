import 'package:flutter/material.dart';

import '../../../models/action_attack_result.dart';
import '../../../models/action_attack_roll_mode.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/numeric_dice_field.dart';

Future<ActionAttackRolls?> showPhysicalAttackRollDialog(
  BuildContext context, {
  required AttackRollMode mode,
}) async {
  int? firstRoll;
  int? secondRoll;

  String? firstError;
  String? secondError;

  final needsSecondRoll = mode != AttackRollMode.normal;

  return showDialog<ActionAttackRolls>(
    context: context,
    barrierDismissible: true,
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
            var valid = true;

            if (firstRoll == null || firstRoll! < 1 || firstRoll! > 20) {
              firstError = 'Entre 1 y 20';

              valid = false;
            } else {
              firstError = null;
            }

            if (needsSecondRoll) {
              if (secondRoll == null || secondRoll! < 1 || secondRoll! > 20) {
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

            Navigator.of(dialogContext).pop((
              firstRoll: firstRoll!,
              secondRoll: needsSecondRoll ? secondRoll : null,
            ));
          }

          return ActionDialogScaffold(
            icon: Icons.gps_fixed_rounded,

            title: 'Tirada de ataque',

            subtitle: explanation,

            primaryLabel: 'Continuar',

            onSecondary: () {
              Navigator.of(dialogContext).pop();
            },

            onPrimary: submit,

            child: needsSecondRoll
                ? Row(
                    children: [
                      Expanded(
                        child: NumericDiceField(
                          sides: 20,
                          value: firstRoll,
                          label: 'd20 #1',
                          errorText: firstError,
                          autofocus: true,
                          onChanged: (value) {
                            firstRoll = value;

                            if (value != null && value >= 1 && value <= 20) {
                              firstError = null;
                            }

                            setDialogState(() {});
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: NumericDiceField(
                          sides: 20,
                          value: secondRoll,
                          label: 'd20 #2',
                          errorText: secondError,
                          onChanged: (value) {
                            secondRoll = value;

                            if (value != null && value >= 1 && value <= 20) {
                              secondError = null;
                            }

                            setDialogState(() {});
                          },
                        ),
                      ),
                    ],
                  )
                : NumericDiceField(
                    sides: 20,
                    value: firstRoll,
                    errorText: firstError,
                    autofocus: true,
                    onChanged: (value) {
                      firstRoll = value;

                      if (value != null && value >= 1 && value <= 20) {
                        firstError = null;
                      }

                      setDialogState(() {});
                    },
                  ),
          );
        },
      );
    },
  );
}
