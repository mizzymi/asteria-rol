import 'package:flutter/material.dart';

import '../../../models/action_resolution_context.dart';
import '../../../models/action_external_requirement.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';

class _AnswerState {
  final ActionExternalRequirement requirement;

  bool? value;

  bool inferred;

  _AnswerState({required this.requirement, this.value, this.inferred = false});
}

Future<Map<String, bool>?> showExternalRequirementsDialog(
  BuildContext context, {
  required String targetLabel,

  required List<ActionExternalRequirement> requirements,

  Map<String, bool> knownAnswers = const {},
}) {
  if (requirements.isEmpty) {
    return Future.value(const {});
  }

  final percentagePlanner = const ExternalPercentageQuestionPlanner();

  final percentageResolver = const ExternalPercentageAnswerResolver();

  final booleanRequirements = requirements
      .where(
        (requirement) =>
            requirement.type == ActionExternalRequirementType.boolean,
      )
      .toList(growable: false);

  final percentageRequirements = percentagePlanner.order(
    requirements
        .where((requirement) => requirement.isPercentageRequirement)
        .toList(growable: false),
  );

  final ordered = [...booleanRequirements, ...percentageRequirements];

  final states = <String, _AnswerState>{
    for (final requirement in ordered)
      requirement.normalizedVariableName: _AnswerState(
        requirement: requirement,
        value: knownAnswers[requirement.normalizedVariableName],
        inferred: knownAnswers.containsKey(requirement.normalizedVariableName),
      ),
  };

  void infer() {
    final answers = <String, bool>{};

    for (final state in states.values) {
      if (state.value != null) {
        answers[state.requirement.normalizedVariableName] = state.value!;
      }
    }

    final inferred = percentageResolver.resolve(
      requirements: percentageRequirements,
      answers: answers,
    );

    for (final entry in inferred.entries) {
      final state = states[entry.key];

      if (state == null) {
        continue;
      }

      if (state.value != null && !state.inferred) {
        continue;
      }

      state.value = entry.value != 0;

      state.inferred = true;
    }
  }

  infer();

  return showDialog<Map<String, bool>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return ActionDialogScaffold(
            icon: Icons.manage_search_rounded,

            title: 'Condiciones del objetivo',

            subtitle: targetLabel,

            primaryLabel: 'Continuar',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: () {
              if (states.values.any((state) => state.value == null)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Responde las condiciones pendientes.'),
                  ),
                );

                return;
              }

              Navigator.pop(
                dialogContext,
                Map<String, bool>.unmodifiable({
                  for (final state in states.values)
                    state.requirement.normalizedVariableName: state.value!,
                }),
              );
            },

            child: Column(
              children: [
                for (final state in states.values) ...[
                  ActionSectionCard(
                    title: state.requirement.label,

                    icon: state.inferred
                        ? Icons.auto_awesome_rounded
                        : Icons.help_outline_rounded,

                    subtitle: state.inferred
                        ? 'Calculado automáticamente'
                        : null,

                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.close_rounded),
                          label: Text('No'),
                        ),

                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.check_rounded),
                          label: Text('Sí'),
                        ),
                      ],

                      selected: state.value == null
                          ? const <bool>{}
                          : {state.value!},

                      onSelectionChanged: state.inferred
                          ? null
                          : (values) {
                              if (values.isEmpty) {
                                return;
                              }

                              setDialogState(() {
                                state.value = values.first;

                                state.inferred = false;

                                infer();
                              });
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
}
