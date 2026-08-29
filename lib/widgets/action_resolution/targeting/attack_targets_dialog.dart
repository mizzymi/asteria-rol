import 'package:flutter/material.dart';

import '../../../models/action_attack_result.dart';
import '../../../models/action_resolution_context.dart';
import '../../../models/action_target_attack_result.dart';
import '../../../models/skill.dart';

import '../../../theme/ability_colors.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';

Future<Map<String, ActionTargetAttackResult>?> showAttackTargetsDialog(
  BuildContext context, {
  required List<ActionTarget> targets,
  required ActionAttackResult attackResult,
  required String selfLabel,
  AbilityType? ability,
}) {
  final hits = <String, bool>{for (final target in targets) target.id: true};

  return showDialog<Map<String, ActionTargetAttackResult>>(
    context: context,
    barrierDismissible: false,
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
                  for (final target in targets)
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
                _AttackRollResultCard(
                  attackResult: attackResult,
                  ability: ability,
                ),

                const SizedBox(height: 18),

                // ===========================================================
                // OBJETIVOS
                // ===========================================================
                for (final target in targets) ...[
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

// =============================================================================
// RESULTADO VISUAL DEL ATAQUE
// =============================================================================

class _AttackRollResultCard extends StatelessWidget {
  final ActionAttackResult attackResult;

  final AbilityType? ability;

  const _AttackRollResultCard({
    required this.attackResult,
    required this.ability,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accentColor = ability == null
        ? theme.colorScheme.primary
        : AbilityColors.of(ability!);

    final backgroundColor = ability == null
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
        : AbilityColors.soft(ability!, alpha: 0.10);

    final borderColor = ability == null
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : AbilityColors.border(ability!, alpha: 0.32);

    final modifier = attackResult.modifier;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          // ---------------------------------------------------------------
          // ATRIBUTO
          // ---------------------------------------------------------------
          if (ability != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                ability!.shortLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            const SizedBox(height: 18),
          ],

          // ---------------------------------------------------------------
          // 17 + 7
          // ---------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AttackMathValue(
                value: '${attackResult.naturalRoll}',
                label: 'd20',
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 1, 16, 0),
                child: Text(
                  modifier >= 0 ? '+' : '−',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              _AttackMathValue(value: '${modifier.abs()}', label: 'Mod.'),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------------------
          // TOTAL
          // ---------------------------------------------------------------
          Text(
            '${attackResult.total}',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            attackResult.critical ? 'CRÍTICO' : 'RESULTADO TOTAL',
            style: theme.textTheme.labelLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),

          if (attackResult.critical) ...[
            const SizedBox(height: 8),

            Icon(
              Icons.local_fire_department_rounded,
              color: accentColor,
              size: 25,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// VALOR DE LA OPERACIÓN
// =============================================================================

class _AttackMathValue extends StatelessWidget {
  final String value;

  final String label;

  const _AttackMathValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
