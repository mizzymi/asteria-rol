import 'package:flutter/material.dart';

import '../../../models/action_attack_result.dart';
import '../../../models/action_resolution_context.dart';
import '../../../models/action_target_attack_result.dart';
import '../../../models/skill.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';
import '../common/action_attack_roll_result_card.dart';

Future<Map<String, ActionTargetAttackResult>?> showAttackTargetsDialog(
  BuildContext context, {
  required List<ActionTarget> targets,
  required ActionAttackResult attackResult,
  required String selfLabel,
  AbilityType? ability,
}) {
  final attackTargets = targets
      .where((target) => target.participatesInAttackRoll)
      .toList(growable: false);

  final hits = <String, bool>{
    for (final target in attackTargets) target.id: true,
  };

  return showDialog<Map<String, ActionTargetAttackResult>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return ActionDialogScaffold(
            icon: attackResult.critical
                ? Icons.local_fire_department_rounded
                : Icons.gps_fixed_rounded,

            title: attackResult.critical
                ? 'Golpe crítico'
                : 'Resultado del ataque',

            subtitle: 'Indica qué objetivos han sido impactados.',

            primaryLabel: 'Continuar',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: () {
              Navigator.pop(
                dialogContext,
                Map<String, ActionTargetAttackResult>.unmodifiable({
                  for (final target in attackTargets)
                    target.id: (hits[target.id] ?? true)
                        ? const ActionTargetAttackResult.hit()
                        : const ActionTargetAttackResult.miss(),
                }),
              );
            },

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===========================================================
                // RESULTADO DEL ATAQUE
                // ===========================================================
                ActionAttackRollResultCard(
                  attackResult: attackResult,
                  ability: ability,
                ),

                const SizedBox(height: 18),

                // ===========================================================
                // OBJETIVOS
                // ===========================================================
                for (final target in attackTargets) ...[
                  ActionSectionCard(
                    title: target.isSelf
                        ? selfLabel
                        : target.label ?? 'Objetivo',

                    icon: target.isSelf
                        ? Icons.person_rounded
                        : Icons.gps_fixed_rounded,

                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.close_rounded),
                            label: Text('Falla'),
                          ),

                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.check_rounded),
                            label: Text('Impacta'),
                          ),
                        ],

                        selected: {hits[target.id] ?? true},

                        onSelectionChanged: (values) {
                          if (values.isEmpty) {
                            return;
                          }

                          setDialogState(() {
                            hits[target.id] = values.first;
                          });
                        },
                      ),
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
