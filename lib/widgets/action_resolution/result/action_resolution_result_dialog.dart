import 'package:flutter/material.dart';

import '../../../models/action_apply_result.dart';
import '../../../models/action_cost.dart';
import '../../../models/skill.dart';
import '../../../models/action_execution_result.dart';
import '../../../models/action_target_result.dart';
import '../../../models/character.dart';
import '../../../models/action_critical_profile.dart';
import '../../../models/action_effect_result.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';

import 'action_damage_breakdown.dart';
import 'action_healing_breakdown.dart';
import 'action_effects_breakdown.dart';

Future<void> showActionResolutionResultDialog(
  BuildContext context, {
  required Character character,
  required ActionExecutionResult execution,
  Future<void> Function(ExternalTargetOutcome outcome)? onApplyExternalOutcome,
}) {
  final resolution = execution.resolution;
  final application = execution.application;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return ActionDialogScaffold(
        icon: resolution.critical
            ? Icons.local_fire_department_rounded
            : Icons.auto_awesome_rounded,

        title: resolution.ability.name,

        subtitle: switch (resolution.criticalType) {
          ActionCriticalType.none => 'Resultado',
          ActionCriticalType.normal => 'Golpe crítico',
          ActionCriticalType.empowered => 'Crítico potenciado',
        },

        primaryLabel: 'Cerrar',

        onPrimary: () {
          Navigator.pop(dialogContext);
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===============================================================
            // RESULTADOS POR OBJETIVO
            // ===============================================================
            for (final result in resolution.targetResults) ...[
              _TargetResultCard(
                character: character,
                targetResult: result,
                ability: resolution.ability.abilityType,
                criticalType: resolution.criticalType,
              ),

              const SizedBox(height: 10),
            ],

            // ===============================================================
            // RESUMEN GLOBAL
            // ===============================================================
            if (application.changedAnything) ...[
              const SizedBox(height: 8),

              Text(
                'Resumen',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              ActionSectionCard(
                icon: Icons.summarize_rounded,
                child: Column(
                  children: [
                    if (application.affectedTargetCount > 1)
                      _SummaryLine(
                        label: 'Objetivos afectados',
                        value: application.affectedTargetCount,
                        icon: Icons.groups_rounded,
                      ),

                    if (application.externalAffectedTargetCount > 0 &&
                        application.affectedTargetCount !=
                            application.externalAffectedTargetCount)
                      _SummaryLine(
                        label: 'Objetivos externos',
                        value: application.externalAffectedTargetCount,
                        icon: Icons.gps_fixed_rounded,
                      ),

                    if (application.selfDamageApplied > 0)
                      _SummaryLine(
                        label: 'Daño recibido',
                        value: application.selfDamageApplied,
                        icon: Icons.flash_on_rounded,
                      ),

                    if (application.selfHealingApplied > 0)
                      _SummaryLine(
                        label: 'Curación recibida',
                        value: application.selfHealingApplied,
                        icon: Icons.favorite_rounded,
                      ),

                    if (application.selfEffectsApplied > 0)
                      _SummaryLine(
                        label: 'Efectos recibidos',
                        value: application.selfEffectsApplied,
                        icon: Icons.auto_awesome_rounded,
                      ),

                    if (application.externalDamageDealt > 0)
                      _SummaryLine(
                        label: 'Daño realizado',
                        value: application.externalDamageDealt,
                        icon: Icons.flash_on_rounded,
                      ),

                    if (application.externalHealingDealt > 0)
                      _SummaryLine(
                        label: 'Curación realizada',
                        value: application.externalHealingDealt,
                        icon: Icons.favorite_rounded,
                      ),

                    if (application.externalEffectCount > 0)
                      _SummaryLine(
                        label: 'Efectos externos',
                        value: application.externalEffectCount,
                        icon: Icons.auto_awesome_rounded,
                      ),
                  ],
                ),
              ),
            ],

            if (application.externalTargetOutcomes.isNotEmpty) ...[
              const SizedBox(height: 18),

              Text(
                'Resultados externos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              for (final outcome in application.externalTargetOutcomes) ...[
                _ExternalTargetOutcomeCard(
                  outcome: outcome,
                  onApply: onApplyExternalOutcome == null
                      ? null
                      : () async {
                          await onApplyExternalOutcome(outcome);
                        },
                ),

                const SizedBox(height: 10),
              ],

              Text(
                onApplyExternalOutcome == null
                    ? 'Estos resultados deben aplicarse en el objetivo correspondiente.'
                    : 'Aplica cada resultado al personaje objetivo correspondiente.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (resolution.costs.isNotEmpty) ...[
              const SizedBox(height: 18),

              Text(
                'Costes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              ActionSectionCard(
                icon: Icons.payments_rounded,
                child: Column(
                  children: [
                    for (final cost in resolution.costs) _CostLine(cost: cost),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

// =============================================================================
// TARGET RESULT
// =============================================================================

class _TargetResultCard extends StatelessWidget {
  final Character character;

  final ActionTargetResult targetResult;

  final AbilityType ability;

  final ActionCriticalType criticalType;

  const _TargetResultCard({
    required this.character,
    required this.targetResult,
    required this.ability,
    required this.criticalType,
  });

  String get targetLabel {
    if (targetResult.target.isSelf) {
      return character.name.isNotEmpty ? character.name : 'Tu personaje';
    }

    return targetResult.target.label ?? 'Objetivo';
  }

  @override
  Widget build(BuildContext context) {
    final result = targetResult;

    final hasDamage = result.damage > 0;
    final hasHealing = result.healing > 0;
    final hasEffects = result.effects.isNotEmpty;

    final hasResolvedContent = hasDamage || hasHealing || hasEffects;

    return ActionSectionCard(
      title: targetLabel,

      icon: result.hasAttackResult && result.missed
          ? Icons.close_rounded
          : Icons.check_rounded,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===================================================================
          // ATAQUE
          // ===================================================================
          if (result.hasAttackResult) ...[
            _ResultLine(
              icon: result.hit ? Icons.check_rounded : Icons.close_rounded,
              text: result.hit ? 'El ataque impactó.' : 'El ataque no impactó.',
            ),

            if (hasResolvedContent) const SizedBox(height: 7),
          ],

          // ===================================================================
          // DAÑO
          // ===================================================================
          if (hasDamage) ...[
            ActionDamageBreakdown(
              targetResult: result,
              ability: ability,
              criticalType: criticalType,
            ),

            const SizedBox(height: 14),
          ],

          // ===================================================================
          // CURACIÓN
          // ===================================================================
          if (hasHealing) ...[
            ActionHealingBreakdown(
              targetResult: result,
              ability: ability,
              criticalType: criticalType,
            ),

            const SizedBox(height: 14),
          ],

          // ===================================================================
          // EFECTOS
          //
          // IMPORTANTE:
          // no dependen visualmente de result.hit.
          //
          // El resolver ya decidió qué efectos sobrevivieron a ataque,
          // salvación y condiciones.
          // ===================================================================
          if (hasEffects) ...[
            ActionEffectsBreakdown(
              targetResult: result,
              targetLabel: targetLabel,
            ),

            const SizedBox(height: 14),
          ],

          // ===================================================================
          // SIN RESULTADO
          // ===================================================================
          if (!result.hasAttackResult && !hasResolvedContent)
            const _ResultLine(
              icon: Icons.info_outline_rounded,
              text: 'La acción se resolvió sin resultado numérico.',
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// RESULT LINE
// =============================================================================

class _ResultLine extends StatelessWidget {
  final IconData icon;

  final String text;

  const _ResultLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUMMARY LINE
// =============================================================================

class _SummaryLine extends StatelessWidget {
  final String label;

  final int value;

  final IconData icon;

  const _SummaryLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  final ActionCost cost;

  const _CostLine({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline_rounded, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _costLabel(cost),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          Text(
            '-${cost.amount}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  String _costLabel(ActionCost cost) {
    final explicit = cost.label?.trim();

    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    switch (cost.type) {
      case ActionCostType.resource:
        return 'Recurso';

      case ActionCostType.passiveCharge:
        return 'Carga de pasiva';

      case ActionCostType.abilityUse:
        return 'Uso de habilidad';
    }
  }
}

class _ExternalTargetOutcomeCard extends StatelessWidget {
  final ExternalTargetOutcome outcome;

  final Future<void> Function()? onApply;

  const _ExternalTargetOutcomeCard({required this.outcome, this.onApply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionSectionCard(
      title: outcome.effectiveTargetLabel,
      icon: Icons.gps_fixed_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (outcome.dealtDamage)
            _ExternalOutcomeLine(
              icon: Icons.flash_on_rounded,
              label: 'Daño',
              value: outcome.damage,
            ),

          if (outcome.healed)
            _ExternalOutcomeLine(
              icon: Icons.favorite_rounded,
              label: 'Curación',
              value: outcome.healing,
            ),

          if (outcome.hasEffects) ...[
            if (outcome.dealtDamage || outcome.healed)
              const SizedBox(height: 10),

            Text(
              'Efectos',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            for (final effectResult in outcome.effects) ...[
              _ExternalOutcomeEffectLine(effectResult: effectResult),

              const SizedBox(height: 6),
            ],
          ],

          if (onApply != null) ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await onApply!();
                },
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: const Text('Aplicar al objetivo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExternalOutcomeLine extends StatelessWidget {
  final IconData icon;

  final String label;

  final int value;

  const _ExternalOutcomeLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ExternalOutcomeEffectLine extends StatelessWidget {
  final ActionEffectResult effectResult;

  const _ExternalOutcomeEffectLine({required this.effectResult});

  @override
  Widget build(BuildContext context) {
    final effect = effectResult.template;

    final name = effect.name.trim().isNotEmpty ? effect.name.trim() : 'Efecto';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 17),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
