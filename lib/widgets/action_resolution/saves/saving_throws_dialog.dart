import 'package:flutter/material.dart';

import '../../../models/action_saving_throw.dart';
import '../../../models/character.dart';
import '../../../services/action_saving_throw_resolver.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';
import '../common/numeric_dice_field.dart';

class _SavingInput {
  final ActionSavingThrowRequest request;

  final TextEditingController rollController;

  final TextEditingController modifierController;

  String? rollError;
  String? modifierError;

  _SavingInput({required this.request, required int initialModifier})
    : rollController = TextEditingController(),
      modifierController = TextEditingController(text: '$initialModifier');

  void dispose() {
    rollController.dispose();
    modifierController.dispose();
  }
}

Future<List<ActionSavingThrowResult>?> showPhysicalSavingThrowsDialog(
  BuildContext context, {
  required Character character,
  required List<ActionSavingThrowRequest> requests,
}) async {
  if (requests.isEmpty) {
    return const [];
  }

  final entries = requests.map((request) {
    final modifier = request.targetId == 'self'
        ? character.savingThrowBonus(request.ability)
        : 0;

    return _SavingInput(request: request, initialModifier: modifier);
  }).toList();

  final result = await showDialog<List<ActionSavingThrowResult>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            var valid = true;

            for (final entry in entries) {
              final roll = int.tryParse(entry.rollController.text.trim());

              final modifier = int.tryParse(
                entry.modifierController.text.trim(),
              );

              if (roll == null || roll < 1 || roll > 20) {
                entry.rollError = 'Entre 1 y 20';

                valid = false;
              } else {
                entry.rollError = null;
              }

              if (modifier == null) {
                entry.modifierError = 'Número inválido';

                valid = false;
              } else {
                entry.modifierError = null;
              }
            }

            if (!valid) {
              setDialogState(() {});
              return;
            }

            const resolver = ActionSavingThrowResolver();

            final results = entries
                .map(
                  (entry) => resolver.resolve(
                    request: entry.request,
                    naturalRoll: int.parse(entry.rollController.text.trim()),
                    modifier: int.parse(entry.modifierController.text.trim()),
                  ),
                )
                .toList(growable: false);

            Navigator.pop(
              dialogContext,
              List<ActionSavingThrowResult>.unmodifiable(results),
            );
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
                  _SavingThrowCard(character: character, entry: entry),

                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      );
    },
  );

  for (final entry in entries) {
    entry.dispose();
  }

  return result;
}

class _SavingThrowCard extends StatelessWidget {
  final Character character;

  final _SavingInput entry;

  const _SavingThrowCard({required this.character, required this.entry});

  @override
  Widget build(BuildContext context) {
    final request = entry.request;

    final targetLabel = request.targetId == 'self'
        ? (character.name.isNotEmpty ? character.name : 'Tu personaje')
        : _externalTargetLabel(request.targetId);

    return ActionSectionCard(
      title: targetLabel,

      subtitle:
          '${request.effectName} · '
          '${request.ability.name} · '
          'CD ${request.dc}',

      icon: Icons.security_rounded,

      child: Row(
        children: [
          Expanded(
            child: NumericDiceField(
              sides: 20,
              controller: entry.rollController,
              errorText: entry.rollError,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('+', style: TextStyle(fontWeight: FontWeight.w900)),
          ),

          Expanded(
            child: TextField(
              controller: entry.modifierController,

              enabled: request.targetId != 'self',

              keyboardType: const TextInputType.numberWithOptions(signed: true),

              textAlign: TextAlign.center,

              decoration: InputDecoration(
                labelText: 'Mod.',
                errorText: entry.modifierError,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, int>?> showExternalSavingModifiersDialog(
  BuildContext context, {
  required List<ActionSavingThrowRequest> requests,
}) async {
  final external = requests
      .where((request) => request.targetId != 'self')
      .toList(growable: false);

  if (external.isEmpty) {
    return const {};
  }

  final controllers = <String, TextEditingController>{
    for (final request in external)
      request.id: TextEditingController(text: '0'),
  };

  final errors = <String, String?>{};

  final result = await showDialog<Map<String, int>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return ActionDialogScaffold(
            icon: Icons.security_rounded,

            title: 'Salvaciones externas',

            subtitle: 'Introduce sus modificadores. Asteria tirará los d20.',

            primaryLabel: 'Tirar',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: () {
              var valid = true;

              final values = <String, int>{};

              for (final request in external) {
                final value = int.tryParse(
                  controllers[request.id]!.text.trim(),
                );

                if (value == null) {
                  errors[request.id] = 'Número inválido';

                  valid = false;
                } else {
                  errors[request.id] = null;

                  values[request.id] = value;
                }
              }

              if (!valid) {
                setDialogState(() {});
                return;
              }

              Navigator.pop(
                dialogContext,
                Map<String, int>.unmodifiable(values),
              );
            },

            child: Column(
              children: [
                for (final request in external) ...[
                  TextField(
                    controller: controllers[request.id],

                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),

                    decoration: InputDecoration(
                      labelText:
                          '${_externalTargetLabel(request.targetId)} · '
                          '${request.ability.name}',

                      helperText:
                          '${request.effectName} · '
                          'CD ${request.dc}',

                      errorText: errors[request.id],

                      prefixIcon: const Icon(Icons.security_rounded),
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

  for (final controller in controllers.values) {
    controller.dispose();
  }

  return result;
}

String _externalTargetLabel(String targetId) {
  final number = RegExp(r'\d+$').firstMatch(targetId)?.group(0);

  return number == null ? 'Objetivo' : 'Objetivo $number';
}
