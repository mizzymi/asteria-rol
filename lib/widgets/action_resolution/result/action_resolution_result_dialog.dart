import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/passive_trigger_external_result.dart';
import '../../../models/external_action_transfer.dart';
import '../../../models/character_effect.dart';
import '../../../models/damage_bonus.dart';
import '../../../models/healing_bonus.dart';
import '../../../models/critical_damage_bonus.dart';
import '../../../models/skill.dart';
import '../../../models/action_apply_result.dart';
import '../../../models/action_cost.dart';
import '../../../models/action_execution_result.dart';
import '../../../models/character.dart';
import '../../../models/action_effect_result.dart';
import '../../../models/action_result_view_data.dart';
import '../../../models/action_result_target_view_data.dart';
import '../../../models/action_result_dice_part_view_data.dart';
import '../../../models/action_hit_behavior.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';

import '../../../services/external_action_transfer_sender_service.dart';

Future<void> showActionResolutionResultDialog(
  BuildContext context, {
  required Character character,
  required ActionExecutionResult execution,
}) {
  final viewData = ActionResultViewData.fromExecution(
    execution,
    selfLabel: character.name,
  );

  final application = viewData.application;

  final externalTransfers = <String, ExternalActionTransfer>{};

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return ActionDialogScaffold(
        icon: viewData.isCritical
            ? Icons.local_fire_department_rounded
            : Icons.auto_awesome_rounded,

        title: viewData.actionName,

        subtitle: viewData.empoweredCritical
            ? 'Crítico potenciado: ${viewData.criticalProfile.empoweredFormula}'
            : viewData.normalCritical
            ? 'Golpe crítico'
            : 'Resultado',

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
            for (final target in viewData.targets) ...[
              _TargetResultCard(target: target),

              const SizedBox(height: 10),
            ],

            // ===========================================================================
            // RESULTADO RESUELTO
            // ===========================================================================
            if (viewData.hitTargetCount > 0 ||
                viewData.missedTargetCount > 0 ||
                viewData.hasDamage ||
                viewData.hasHealing ||
                viewData.hasEffects) ...[
              const SizedBox(height: 8),

              Text(
                'Resultado resuelto',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              ActionSectionCard(
                icon: Icons.summarize_rounded,
                child: Column(
                  children: [
                    if (viewData.hitTargetCount > 0)
                      _SummaryLine(
                        label: 'Impactos',
                        value: viewData.hitTargetCount,
                        icon: Icons.check_circle_outline_rounded,
                      ),

                    if (viewData.missedTargetCount > 0)
                      _SummaryLine(
                        label: 'Fallos',
                        value: viewData.missedTargetCount,
                        icon: Icons.cancel_outlined,
                      ),

                    if (viewData.totalResolvedDamage > 0)
                      _SummaryLine(
                        label: 'Daño total',
                        value: viewData.totalResolvedDamage,
                        icon: Icons.flash_on_rounded,
                      ),

                    if (viewData.totalResolvedHealing > 0)
                      _SummaryLine(
                        label: 'Curación total',
                        value: viewData.totalResolvedHealing,
                        icon: Icons.favorite_rounded,
                      ),

                    if (viewData.totalResolvedEffects > 0)
                      _SummaryLine(
                        label: 'Efectos',
                        value: viewData.totalResolvedEffects,
                        icon: Icons.auto_awesome_rounded,
                      ),
                  ],
                ),
              ),
            ],

            // ===========================================================================
            // APLICACIÓN
            // ===========================================================================
            if (application.selfDamageApplied > 0 ||
                application.selfHealingApplied > 0 ||
                application.selfEffectsApplied > 0 ||
                application.pendingExternalDamage > 0 ||
                application.pendingExternalHealing > 0 ||
                application.externalEffectCount > 0) ...[
              const SizedBox(height: 18),

              Text(
                'Aplicación',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              ActionSectionCard(
                icon: Icons.playlist_add_check_rounded,
                child: Column(
                  children: [
                    // =====================================================================
                    // SELF
                    // =====================================================================
                    if (application.selfDamageApplied > 0)
                      _SummaryLine(
                        label: 'Daño aplicado',
                        value: application.selfDamageApplied,
                        icon: Icons.flash_on_rounded,
                      ),

                    if (application.selfHealingApplied > 0)
                      _SummaryLine(
                        label: 'Curación aplicada',
                        value: application.selfHealingApplied,
                        icon: Icons.favorite_rounded,
                      ),

                    if (application.selfEffectsApplied > 0)
                      _SummaryLine(
                        label: 'Efectos aplicados a self',
                        value: application.selfEffectsApplied,
                        icon: Icons.auto_awesome_rounded,
                      ),

                    if (application.externalEffectCount > 0)
                      _SummaryLine(
                        label: 'Efectos externos pendientes',
                        value: application.externalEffectCount,
                        icon: Icons.auto_awesome_rounded,
                      ),

                    // =====================================================================
                    // EXTERNOS
                    // =====================================================================
                    if (application.pendingExternalDamage > 0)
                      _SummaryLine(
                        label: 'Daño externo pendiente',
                        value: application.pendingExternalDamage,
                        icon: Icons.gps_fixed_rounded,
                      ),

                    if (application.pendingExternalHealing > 0)
                      _SummaryLine(
                        label: 'Curación externa pendiente',
                        value: application.pendingExternalHealing,
                        icon: Icons.gps_fixed_rounded,
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

                  onCopy: () async {
                    // =======================================================================
                    // REUTILIZAR TRANSFER SI YA LO CREAMOS
                    // =======================================================================

                    var transfer = externalTransfers[outcome.targetId];

                    if (transfer == null) {
                      transfer =
                          await const ExternalActionTransferSenderService()
                              .createPending(
                                resolution: execution.resolution,
                                outcome: outcome,
                              );

                      externalTransfers[outcome.targetId] = transfer;
                    }

                    // =======================================================================
                    // COPIAR JSON
                    // =======================================================================

                    await Clipboard.setData(
                      ClipboardData(text: transfer.toJson()),
                    );

                    if (!dialogContext.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Resultado para '
                          '${outcome.effectiveTargetLabel} '
                          'copiado.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],

            if (viewData.hasCosts) ...[
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
                    for (final cost in viewData.costs) _CostLine(cost: cost),
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

class _TargetResultCard extends StatefulWidget {
  final ActionResultTargetViewData target;

  const _TargetResultCard({required this.target});

  @override
  State<_TargetResultCard> createState() => _TargetResultCardState();
}

class _TargetResultCardState extends State<_TargetResultCard> {
  bool _showBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final target = widget.target;

    return ActionSectionCard(
      title: target.targetLabel,

      icon: target.hasAttackResult
          ? target.landedHit
                ? Icons.check_rounded
                : Icons.close_rounded
          : Icons.auto_awesome_rounded,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===============================================================
          // ATAQUE
          // ===============================================================
          if (target.hasAttackResult) ...[
            _ResultLine(
              icon: target.landedHit
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              text: target.landedHit
                  ? 'El ataque impactó.'
                  : 'El ataque no impactó.',
            ),

            const SizedBox(height: 8),
          ],

          // ===============================================================
          // TOTAL RESUELTO
          //
          // Siempre visible.
          // ===============================================================
          _TargetResolvedTotals(target: target),

          // ===============================================================
          // SALVACIONES
          // ===============================================================
          if (target.savingThrowViews.isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              'Salvaciones',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 7),

            for (final save in target.savingThrowViews) ...[
              _ResultLine(
                icon: save.saved ? Icons.shield_rounded : Icons.shield_outlined,
                text:
                    '${save.effectName} · ${save.resultLabel} · CD ${save.dc}',
              ),

              Padding(
                padding: const EdgeInsets.only(left: 27, bottom: 4),
                child: Text(
                  save.outcomeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              if (save.hasRollDetails)
                Padding(
                  padding: const EdgeInsets.only(left: 27, bottom: 7),
                  child: Text(
                    '${save.naturalRoll} + ${save.modifier} = ${save.total}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],

          // ===============================================================
          // EFECTOS
          // ===============================================================
          if (target.hasEffects) ...[
            const SizedBox(height: 14),

            Text(
              'Efectos resueltos',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 7),

            for (final effectResult in target.effects) ...[
              _EffectDetails(effect: effectResult.template),

              const SizedBox(height: 10),
            ],
          ],

          // ===============================================================
          // TOGGLE DESGLOSE
          // ===============================================================
          if (target.hasDiceBreakdown) ...[
            const SizedBox(height: 14),

            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _showBreakdown = !_showBreakdown;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      _showBreakdown
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Desglose',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    Text(
                      _showBreakdown ? 'Ocultar' : 'Ver',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showBreakdown) ...[
              const SizedBox(height: 4),

              for (final part in target.diceParts) _DicePartLine(part: part),
            ],
          ],

          if (!target.hasAttackResult && !target.hasResolvedContent)
            const _ResultLine(
              icon: Icons.info_outline_rounded,
              text: 'La acción se resolvió sin resultado.',
            ),
        ],
      ),
    );
  }
}

class _TargetResolvedTotals extends StatelessWidget {
  final ActionResultTargetViewData target;

  const _TargetResolvedTotals({required this.target});

  @override
  Widget build(BuildContext context) {
    final hasDamage = target.hasDamage;
    final hasHealing = target.hasHealing;

    if (!hasDamage && !hasHealing) {
      return _ResolvedValue(
        icon: Icons.horizontal_rule_rounded,
        label: 'Total',
        value: 0,
      );
    }

    return Column(
      children: [
        if (hasDamage)
          _ResolvedValue(
            icon: Icons.flash_on_rounded,
            label: 'Daño total',
            value: target.damage,
          ),

        if (hasDamage && hasHealing) const SizedBox(height: 8),

        if (hasHealing)
          _ResolvedValue(
            icon: Icons.favorite_rounded,
            label: 'Curación total',
            value: target.healing,
          ),
      ],
    );
  }
}

class _ResolvedValue extends StatelessWidget {
  final IconData icon;

  final String label;

  final int value;

  const _ResolvedValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),

        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _DicePartLine extends StatelessWidget {
  final ActionResultDicePartViewData part;

  const _DicePartLine({required this.part});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            part.criticalExtra
                ? Icons.local_fire_department_rounded
                : Icons.casino_rounded,
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.primaryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 2),

                Text(
                  part.effectiveSourceLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  part.kindLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (part.hasCalculationText) ...[
                  const SizedBox(height: 3),

                  Text(
                    part.calculationText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                if (part.hasRollDetails) ...[
                  const SizedBox(height: 3),

                  for (final group in part.rollGroups)
                    if (group.hasRolls)
                      Text(
                        '${group.notation}: [${group.rollsText}]',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                ],

                if (part.hasDamageType) ...[
                  const SizedBox(height: 2),

                  Text(
                    part.damageType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '${part.total}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
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

  final Future<void> Function()? onCopy;

  const _ExternalTargetOutcomeCard({required this.outcome, this.onCopy});

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

          // =========================================================================
          // TRIGGERS / PASIVAS
          // =========================================================================
          if (outcome.triggerResults.isNotEmpty) ...[
            if (outcome.dealtDamage || outcome.healed)
              const SizedBox(height: 12),

            Text(
              'Triggers',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            for (final trigger in outcome.triggerResults) ...[
              _PassiveTriggerResultLine(result: trigger),

              const SizedBox(height: 6),
            ],
          ],

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

            // =========================================================================
            // EFECTOS NORMALES DE LA HABILIDAD
            // =========================================================================
            for (final effectResult in outcome.effects) ...[
              _ExternalOutcomeEffectLine(effectResult: effectResult),

              const SizedBox(height: 6),
            ],

            // =========================================================================
            // EFECTOS PROCEDENTES DE TRIGGERS / PASIVAS
            // =========================================================================
            for (final effect in outcome.passiveEffects) ...[
              _EffectDetails(effect: effect),

              const SizedBox(height: 6),
            ],
          ],

          if (onCopy != null) ...[
            const SizedBox(height: 14),

            const _ExternalPendingNotice(),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await onCopy!();
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar resultado'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PassiveTriggerResultLine extends StatelessWidget {
  final PassiveTriggerExternalResult result;

  const _PassiveTriggerResultLine({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final details = <String>[];

    // =========================================================================
    // SALVACIÓN
    // =========================================================================

    if (result.saved) {
      details.add('Salvación superada');
    }

    // =========================================================================
    // DAÑO
    // =========================================================================

    if (result.damage > 0) {
      details.add('+${result.damage} daño');
    }

    // =========================================================================
    // CURACIÓN
    // =========================================================================

    if (result.healing > 0) {
      details.add('+${result.healing} curación');
    }

    // =========================================================================
    // EFECTOS
    // =========================================================================

    for (final effect in result.effects) {
      final name = effect.name.trim();

      details.add(name.isEmpty ? 'Efecto' : name);
    }

    final passiveName = result.passiveName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.saved ? Icons.shield_rounded : Icons.bolt_rounded,
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passiveName.isEmpty ? 'Pasiva' : passiveName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),

                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    details.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalPendingNotice extends StatelessWidget {
  const _ExternalPendingNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Pendiente de aplicar en la '
              'Asteria del objetivo.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
    return _EffectDetails(effect: effectResult.template);
  }
}

// =============================================================================
// EFFECT HELPERS
// =============================================================================

bool _hasGeneralBonuses(CharacterEffect effect) {
  return effect.armorClassBonus != 0 ||
      effect.initiativeBonus != 0 ||
      effect.speedBonus != 0 ||
      effect.maxHealthBonus != 0 ||
      effect.attackBonus != 0;
}

String _signed(int value) {
  if (value > 0) {
    return '+$value';
  }

  return '$value';
}

String _abilityLabel(AbilityType ability) {
  switch (ability) {
    case AbilityType.strength:
      return 'FUE';

    case AbilityType.dexterity:
      return 'DES';

    case AbilityType.constitution:
      return 'CON';

    case AbilityType.intelligence:
      return 'INT';

    case AbilityType.wisdom:
      return 'SAB';

    case AbilityType.charisma:
      return 'CAR';
  }
}

String _abilityMultipliersText(Map<AbilityType, int> multipliers) {
  final pieces = <String>[];

  for (final entry in multipliers.entries) {
    final multiplier = entry.value;

    if (multiplier == 0) {
      continue;
    }

    final label = _abilityLabel(entry.key);

    if (multiplier == 1) {
      pieces.add(label);
    } else {
      pieces.add('$multiplier × $label');
    }
  }

  return pieces.join(' + ');
}

String _skillLabel(DndSkill skill) {
  final raw = skill.name;

  if (raw.isEmpty) {
    return 'Habilidad';
  }

  return '${raw[0].toUpperCase()}${raw.substring(1)}';
}

class _EffectDetails extends StatelessWidget {
  final CharacterEffect effect;

  const _EffectDetails({required this.effect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = effect.name.trim().isNotEmpty ? effect.name.trim() : 'Efecto';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================================
          // CABECERA
          // ===================================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 19),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${effect.type.label} · ${effect.durationText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ===================================================================
          // DESCRIPCIÓN
          // ===================================================================
          if (effect.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),

            Text(effect.description.trim(), style: theme.textTheme.bodySmall),
          ],

          // ===================================================================
          // DURACIÓN PERSONALIZADA / NOTA
          // ===================================================================
          if (effect.durationNote.trim().isNotEmpty &&
              effect.durationType != CharacterEffectDurationType.custom) ...[
            const SizedBox(height: 8),

            _EffectTextDetail(
              label: 'Duración',
              value: effect.durationNote.trim(),
            ),
          ],

          // ===================================================================
          // ESTADO
          // ===================================================================
          const SizedBox(height: 10),

          _EffectSubTitle(text: 'Estado'),

          _EffectValueLine(label: 'Tipo', value: effect.type.label),

          _EffectValueLine(label: 'Duración', value: effect.durationText),

          if (effect.hasDuration)
            _EffectValueLine(
              label: 'Duración máxima',
              value: '${effect.maxDuration}',
            ),

          // ===================================================================
          // BONOS GENERALES
          // ===================================================================
          if (_hasGeneralBonuses(effect)) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Bonificaciones'),

            if (effect.armorClassBonus != 0)
              _EffectValueLine(
                label: 'CA',
                value: _signed(effect.armorClassBonus),
              ),

            if (effect.initiativeBonus != 0)
              _EffectValueLine(
                label: 'Iniciativa',
                value: _signed(effect.initiativeBonus),
              ),

            if (effect.speedBonus != 0)
              _EffectValueLine(
                label: 'Velocidad',
                value: _signed(effect.speedBonus),
              ),

            if (effect.maxHealthBonus != 0)
              _EffectValueLine(
                label: 'Vida máxima',
                value: _signed(effect.maxHealthBonus),
              ),

            if (effect.attackBonus != 0)
              _EffectValueLine(
                label: 'Ataque',
                value: _signed(effect.attackBonus),
              ),
          ],

          // ===================================================================
          // ATRIBUTOS
          // ===================================================================
          if (effect.abilityModifierBonuses.values.any(
            (value) => value != 0,
          )) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Atributos'),

            for (final entry in effect.abilityModifierBonuses.entries)
              if (entry.value != 0)
                _EffectValueLine(
                  label: _abilityLabel(entry.key),
                  value: _signed(entry.value),
                ),
          ],

          // ===================================================================
          // HABILIDADES
          // ===================================================================
          if (effect.skillBonuses.values.any((value) => value != 0)) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Habilidades'),

            for (final entry in effect.skillBonuses.entries)
              if (entry.value != 0)
                _EffectValueLine(
                  label: _skillLabel(entry.key),
                  value: _signed(entry.value),
                ),
          ],

          // ===================================================================
          // SALVACIONES
          // ===================================================================
          if (effect.savingThrowBonuses.values.any((value) => value != 0)) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Salvaciones'),

            for (final entry in effect.savingThrowBonuses.entries)
              if (entry.value != 0)
                _EffectValueLine(
                  label: _abilityLabel(entry.key),
                  value: _signed(entry.value),
                ),
          ],

          // ===================================================================
          // CRÍTICO
          // ===================================================================
          if (effect.criticalMinimumNaturalRoll < 20 ||
              effect.empoweredCritical) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Crítico'),

            if (effect.criticalMinimumNaturalRoll < 20)
              _EffectValueLine(
                label: 'Crítico natural',
                value: '${effect.criticalMinimumNaturalRoll}+',
              ),

            if (effect.empoweredCritical)
              const _EffectValueLine(label: 'Crítico potenciado', value: 'Sí'),
          ],

          // ===================================================================
          // DAÑO ADICIONAL
          // ===================================================================
          if (effect.damageBonuses.any((bonus) => bonus.hasDamage)) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Daño adicional'),

            for (final bonus in effect.damageBonuses)
              if (bonus.hasDamage) _DamageBonusDetails(bonus: bonus),
          ],

          // ===================================================================
          // DAÑO CRÍTICO ADICIONAL
          // ===================================================================
          if (effect.criticalDamageBonuses.any(
            (bonus) => bonus.canTrigger,
          )) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Daño crítico adicional'),

            for (final bonus in effect.criticalDamageBonuses)
              if (bonus.canTrigger) _CriticalDamageBonusDetails(bonus: bonus),
          ],

          // ===================================================================
          // CURACIÓN
          // ===================================================================
          if (effect.healingBonuses.any((bonus) => bonus.hasHealing)) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Curación adicional'),

            for (final bonus in effect.healingBonuses)
              if (bonus.hasHealing) _HealingBonusDetails(bonus: bonus),
          ],

          // ===================================================================
          // NOTAS
          // ===================================================================
          if (effect.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),

            _EffectSubTitle(text: 'Notas'),

            Text(
              effect.notes.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DamageBonusDetails extends StatelessWidget {
  final DamageBonus bonus;

  const _DamageBonusDetails({required this.bonus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = bonus.name.trim();

    return _EffectNestedBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

          if (bonus.diceNotation.isNotEmpty)
            _EffectValueLine(label: 'Dados', value: bonus.diceNotation),

          if (bonus.abilityModifierMultipliers.values.any(
            (value) => value != 0,
          ))
            _EffectValueLine(
              label: 'Atributo',
              value: _abilityMultipliersText(bonus.abilityModifierMultipliers),
            ),

          if (bonus.flatBonus != 0)
            _EffectValueLine(
              label: 'Bonus fijo',
              value: _signed(bonus.flatBonus),
            ),

          if (bonus.damageType.trim().isNotEmpty)
            _EffectValueLine(label: 'Tipo', value: bonus.damageType.trim()),

          if (bonus.hasFormula)
            _EffectTextDetail(
              label: 'Fórmula',
              value: bonus.formula!.expression,
            ),

          if (bonus.hasCondition)
            _EffectTextDetail(
              label: 'Condición',
              value: bonus.condition!.expression,
            ),

          if (bonus.optional)
            _EffectValueLine(
              label: 'Opcional',
              value: bonus.effectiveOptionalLabel,
            ),

          _EffectValueLine(
            label: 'Requiere impacto',
            value: switch (bonus.hitBehavior) {
              ActionHitBehavior.requireHit => 'Sí',
              ActionHitBehavior.ignoreHit => 'No',
            },
          ),

          _EffectValueLine(
            label: 'Participa en crítico',
            value: bonus.participatesInCritical ? 'Sí' : 'No',
          ),
        ],
      ),
    );
  }
}

class _CriticalDamageBonusDetails extends StatelessWidget {
  final CriticalDamageBonus bonus;

  const _CriticalDamageBonusDetails({required this.bonus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = bonus.name.trim();

    return _EffectNestedBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

          if (bonus.diceNotation.isNotEmpty)
            _EffectValueLine(label: 'Dados', value: bonus.diceNotation),

          if (bonus.abilityModifierMultipliers.values.any(
            (value) => value != 0,
          ))
            _EffectValueLine(
              label: 'Atributo',
              value: _abilityMultipliersText(bonus.abilityModifierMultipliers),
            ),

          if (bonus.flatBonus != 0)
            _EffectValueLine(
              label: 'Bonus fijo',
              value: _signed(bonus.flatBonus),
            ),

          if (bonus.damageType.trim().isNotEmpty)
            _EffectValueLine(label: 'Tipo', value: bonus.damageType.trim()),

          _EffectValueLine(
            label: 'Probabilidad',
            value: '${bonus.chancePercent}%',
          ),

          if (bonus.hasFormula)
            _EffectTextDetail(
              label: 'Fórmula',
              value: bonus.formula!.expression,
            ),

          if (bonus.hasCondition)
            _EffectTextDetail(
              label: 'Condición',
              value: bonus.condition!.expression,
            ),

          if (bonus.optional)
            _EffectValueLine(
              label: 'Opcional',
              value: bonus.effectiveOptionalLabel,
            ),

          if (bonus.description.trim().isNotEmpty)
            _EffectTextDetail(
              label: 'Descripción',
              value: bonus.description.trim(),
            ),
        ],
      ),
    );
  }
}

class _HealingBonusDetails extends StatelessWidget {
  final HealingBonus bonus;

  const _HealingBonusDetails({required this.bonus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = bonus.name.trim();

    return _EffectNestedBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

          if (bonus.diceNotation.isNotEmpty)
            _EffectValueLine(label: 'Dados', value: bonus.diceNotation),

          if (bonus.abilityModifierMultipliers.values.any(
            (value) => value != 0,
          ))
            _EffectValueLine(
              label: 'Atributo',
              value: _abilityMultipliersText(bonus.abilityModifierMultipliers),
            ),

          if (bonus.flatBonus != 0)
            _EffectValueLine(
              label: 'Bonus fijo',
              value: _signed(bonus.flatBonus),
            ),

          if (bonus.hasFormula)
            _EffectTextDetail(
              label: 'Fórmula',
              value: bonus.formula!.expression,
            ),
        ],
      ),
    );
  }
}

class _EffectNestedBlock extends StatelessWidget {
  final Widget child;

  const _EffectNestedBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: child,
    );
  }
}

class _EffectSubTitle extends StatelessWidget {
  final String text;

  const _EffectSubTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EffectValueLine extends StatelessWidget {
  final String label;
  final String value;

  const _EffectValueLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),

          const SizedBox(width: 10),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectTextDetail extends StatelessWidget {
  final String label;
  final String value;

  const _EffectTextDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),

            TextSpan(text: value),
          ],
        ),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
