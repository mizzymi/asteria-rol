import 'package:flutter/material.dart';

import '../../../models/action_saving_throw.dart';
import '../../../models/saving_throw_roll_mode.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';
import '../common/numeric_dice_field.dart';

class _SavingInput {
  final ActionSavingThrowRequest request;

  int? naturalRoll;
  int? secondNaturalRoll;

  String? rollError;
  String? secondRollError;

  _SavingInput({required this.request});
}

Future<List<ActionPhysicalSavingThrowInput>?> showPhysicalSavingThrowsDialog(
  BuildContext context, {
  required List<ActionSavingThrowRequest> requests,
}) async {
  if (requests.isEmpty) {
    return const [];
  }

  final entries = requests
      .map((request) => _SavingInput(request: request))
      .toList();

  final result = await showDialog<List<ActionPhysicalSavingThrowInput>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            var valid = true;

            for (final entry in entries) {
              final roll = entry.naturalRoll;

              if (roll == null || roll < 1 || roll > 20) {
                entry.rollError = 'Entre 1 y 20';
                valid = false;
              } else {
                entry.rollError = null;
              }

              if (entry.request.rollMode != SavingThrowRollMode.normal) {
                final secondRoll = entry.secondNaturalRoll;
                if (secondRoll == null || secondRoll < 1 || secondRoll > 20) {
                  entry.secondRollError = 'Entre 1 y 20';
                  valid = false;
                } else {
                  entry.secondRollError = null;
                }
              } else {
                entry.secondRollError = null;
              }
            }

            if (!valid) {
              setDialogState(() {});
              return;
            }

            final inputs = entries
                .map(
                  (entry) => ActionPhysicalSavingThrowInput(
                    requestId: entry.request.id,
                    naturalRoll: entry.naturalRoll!,
                    secondNaturalRoll:
                        entry.request.rollMode == SavingThrowRollMode.normal
                        ? null
                        : entry.secondNaturalRoll,
                  ),
                )
                .toList(growable: false);

            Navigator.of(
              dialogContext,
            ).pop(List<ActionPhysicalSavingThrowInput>.unmodifiable(inputs));
          }

          return ActionDialogScaffold(
            icon: Icons.security_rounded,

            title: 'Salvaciones',

            subtitle: 'Introduce tus tiradas físicas.',

            primaryLabel: 'Resolver',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: submit,

            child: Column(
              children: [
                for (final entry in entries) ...[
                  _SavingThrowCard(entry: entry),

                  const SizedBox(height: 12),
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

class _SavingThrowCard extends StatelessWidget {
  final _SavingInput entry;

  const _SavingThrowCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final request = entry.request;

    return ActionSectionCard(
      title: 'Tu personaje',

      subtitle:
          '${request.effectName} · '
          '${request.ability.name} · '
          'CD ${request.dc} · ${request.rollMode.label}',

      icon: Icons.security_rounded,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.rollMode != SavingThrowRollMode.normal) ...[
            Text(
              request.rollMode == SavingThrowRollMode.advantage
                  ? 'Tira 2d20 y se usará el mayor.'
                  : 'Tira 2d20 y se usará el menor.',
            ),
            const SizedBox(height: 10),
          ],
          NumericDiceField(
            sides: 20,
            value: entry.naturalRoll,
            errorText: entry.rollError,
            onChanged: (value) {
              entry.naturalRoll = value;
            },
          ),
          if (request.rollMode != SavingThrowRollMode.normal) ...[
            const SizedBox(height: 10),
            NumericDiceField(
              sides: 20,
              value: entry.secondNaturalRoll,
              errorText: entry.secondRollError,
              onChanged: (value) {
                entry.secondNaturalRoll = value;
              },
            ),
          ],
        ],
      ),
    );
  }
}

Future<Map<String, bool>?> showExternalSavingThrowResultsDialog(
  BuildContext context, {
  required List<ActionSavingThrowRequest> requests,
}) async {
  final external = requests
      .where((request) => request.targetId != 'self')
      .toList(growable: false);

  if (external.isEmpty) {
    return const {};
  }

  final answers = <String, bool?>{
    for (final request in external) request.id: null,
  };

  return showDialog<Map<String, bool>>(
    context: context,

    // Ahora sí puedes cancelar también
    // tocando fuera del diálogo.
    barrierDismissible: true,

    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final completed = answers.values.every((value) => value != null);

          return ActionDialogScaffold(
            icon: Icons.security_rounded,

            title: 'Salvaciones externas',

            subtitle: 'Indica únicamente si cada objetivo supera su salvación.',

            primaryLabel: 'Continuar',

            // CANCELAR TODA LA ACCIÓN
            onSecondary: () {
              Navigator.of(dialogContext).pop(null);
            },

            onPrimary: completed
                ? () {
                    Navigator.of(dialogContext).pop(
                      Map<String, bool>.unmodifiable({
                        for (final entry in answers.entries)
                          entry.key: entry.value!,
                      }),
                    );
                  }
                : null,

            child: Column(
              children: [
                for (final request in external) ...[
                  ActionSectionCard(
                    title: _externalTargetLabel(request.targetId),

                    subtitle:
                        '${request.effectName} · '
                        '${request.ability.name} · '
                        'CD ${request.dc}',

                    icon: Icons.security_rounded,

                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                answers[request.id] = false;
                              });
                            },
                            icon: Icon(
                              answers[request.id] == false
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            label: const Text('No se salva'),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              setDialogState(() {
                                answers[request.id] = true;
                              });
                            },
                            icon: Icon(
                              answers[request.id] == true
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                            ),
                            label: const Text('Se salva'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

String _externalTargetLabel(String targetId) {
  final number = RegExp(r'\d+$').firstMatch(targetId)?.group(0);

  return number == null ? 'Objetivo' : 'Objetivo $number';
}
