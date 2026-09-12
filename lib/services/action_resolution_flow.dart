import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/action_content.dart';
import '../models/action_definition.dart';
import '../models/action_source.dart';
import '../models/healing_bonus.dart';
import '../models/character_effect_triggered_external_outcome.dart';
import '../models/character_effect_trigger_external_result.dart';
import '../models/damage_bonus.dart';
import '../models/action_apply_result.dart';
import '../models/action_hit_behavior.dart';
import '../models/dice_pool.dart';
import '../models/formulas/character_formula.dart';
import '../models/passive_trigger_external_result.dart';
import '../models/character_effect.dart';
import '../models/passive_triggered_external_outcome.dart';
import '../models/action_trigger_context.dart';
import '../models/action_target_result.dart';
import '../models/action_attack_roll_mode.dart';
import '../models/ability.dart';
import '../models/action_attack_result.dart';
import '../models/action_chance_check.dart';
import '../models/action_dice_mode.dart';
import '../models/action_dice_result.dart';
import '../models/action_execution_result.dart';
import '../models/action_resolution_context.dart';
import '../models/action_resolution_plan.dart';
import '../models/action_resolution_result.dart';
import '../models/action_saving_throw.dart';
import '../models/action_target_attack_result.dart';
import '../models/character.dart';
import '../models/prepared_action_resolution.dart';
import '../models/action_dice_request.dart';
import '../models/weapon.dart';
import '../models/passive.dart';
import '../models/passive_roll_resolution.dart';
import '../models/item_definition.dart';

import '../widgets/abilities/attack_roll_sheet.dart';
import '../widgets/action_resolution/dice/dice_mode_sheet.dart';
import '../widgets/action_resolution/dice/physical_attack_roll_dialog.dart';
import '../widgets/action_resolution/dice/physical_dice_dialog.dart';
import '../widgets/action_resolution/targeting/target_selector_dialog.dart';
import '../widgets/action_resolution/targeting/attack_targets_dialog.dart';
import '../widgets/action_resolution/saves/saving_throws_dialog.dart';
import '../widgets/action_resolution/options/optional_choices_dialog.dart';
import '../widgets/action_resolution/requirements/external_requirements_dialog.dart';
import '../widgets/action_resolution/chance/chance_checks_dialog.dart';

import 'character_effect_trigger_engine.dart';
import 'formula_evaluator.dart';
import 'passive_trigger_engine.dart';
import 'action_dice_resolver.dart';
import 'passive_action_resolver.dart';
import 'action_resolver.dart';
import '../utils/formula_dice_helper.dart';

class ActionResolutionFlow {
  final Character character;

  const ActionResolutionFlow({required this.character});

  String get selfLabel {
    return character.name.isNotEmpty ? character.name : 'Tu personaje';
  }

  List<PassiveTriggeredExternalOutcome> collectDeathTriggers() {
    final outcomes = <PassiveTriggeredExternalOutcome>[];

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) continue;

      for (final trigger in passive.triggers) {
        if (trigger.event != PassiveTriggerEvent.characterDied) continue;
        if (trigger.actions.isEmpty) continue;

        outcomes.add(
          PassiveTriggeredExternalOutcome(
            passiveId: passive.id,
            passiveName: passive.name,
            triggerId: trigger.id,
            targetId: 'self',
            targetLabel: character.name,
            savingThrow: trigger.savingThrow,
            usageLimit: trigger.usageLimit,
            actions: trigger.actions
                .map((action) => PassiveTriggerAction.fromMap(action.toMap()))
                .toList(),
          ),
        );
      }
    }
    return outcomes;
  }

  Future<List<PassiveTriggerExternalResult>?>
  _resolvePassiveTriggeredExternalOutcomes(
    BuildContext context, {
    required ActionResolver resolver,
    required ActionResolutionContext actionContext,
    required List<PassiveTriggeredExternalOutcome> outcomes,
    required ActionDiceMode diceMode,
    required String resolutionId,
  }) async {
    final results = <PassiveTriggerExternalResult>[];

    for (var outcomeIndex = 0; outcomeIndex < outcomes.length; outcomeIndex++) {
      final outcome = outcomes[outcomeIndex];
      CharacterPassive? passive;

      final externalResultId =
          '$resolutionId:passive:'
          '${outcome.passiveId}:'
          '${outcome.triggerId}:'
          '${outcome.targetId}:'
          '$outcomeIndex';

      for (final candidate in character.enabledPassives) {
        if (candidate.id == outcome.passiveId) {
          passive = candidate;
          break;
        }
      }

      if (passive == null) {
        continue;
      }

      ActionTarget? target;

      for (final candidate in actionContext.targets) {
        if (candidate.id == outcome.targetId) {
          target = candidate;
          break;
        }
      }

      if (target == null) {
        continue;
      }

      var saved = false;

      final save = outcome.savingThrow;

      if (save != null && save.dc > 0) {
        final request = ActionSavingThrowRequest(
          id:
              'passive-trigger:'
              '${outcome.passiveId}:'
              '${outcome.triggerId}:'
              '${outcome.targetId}',
          targetId: outcome.targetId,
          effectId: 'passive-trigger:${outcome.triggerId}',
          effectName: outcome.passiveName,
          ability: save.ability,
          dc: save.dc,
          successEffect: SaveSuccessEffect.none,
        );

        if (!context.mounted) {
          return null;
        }

        final answers = await showExternalSavingThrowResultsDialog(
          context,
          requests: [request],
        );

        if (answers == null || !context.mounted) {
          return null;
        }

        saved = answers[request.id] ?? false;

        if (saved && save.behavior == TriggerSaveBehavior.negate) {
          results.add(
            PassiveTriggerExternalResult(
              passiveId: outcome.passiveId,
              passiveName: outcome.passiveName,
              triggerId: outcome.triggerId,
              targetId: outcome.targetId,
              targetLabel: outcome.targetLabel,
              saved: true,
              resolutionId: externalResultId,
            ),
          );

          continue;
        }
      }

      var damage = 0;
      var healing = 0;
      var mitigation = 0;

      final effects = <CharacterEffect>[];
      final breakdown = <String>[];

      for (final action in outcome.actions) {
        switch (action.type) {
          case PassiveTriggerActionType.dealDamage:
            final amount = await _resolvePassiveTriggerActionAmount(
              context,
              resolver: resolver,
              passive: passive,
              target: target,
              actionContext: actionContext,
              action: action,
              diceMode: diceMode,
              breakdown: breakdown,
              label: 'Daño causado',
            );

            if (amount == null) {
              return null;
            }

            damage += amount;
            break;

          case PassiveTriggerActionType.heal:
            final amount = await _resolvePassiveTriggerActionAmount(
              context,
              resolver: resolver,
              passive: passive,
              target: target,
              actionContext: actionContext,
              action: action,
              diceMode: diceMode,
              breakdown: breakdown,
              label: 'Curación',
            );

            if (amount == null) {
              return null;
            }

            healing += amount;
            break;

          case PassiveTriggerActionType.mitigateDamage:
            final amount = await _resolvePassiveTriggerActionAmount(
              context,
              resolver: resolver,
              passive: passive,
              target: target,
              actionContext: actionContext,
              action: action,
              diceMode: diceMode,
              breakdown: breakdown,
              label: 'Mitigación',
            );

            if (amount == null) {
              return null;
            }

            mitigation += amount;
            break;

          case PassiveTriggerActionType.applyEffect:
            final effectId = action.effectId?.trim();

            if (effectId == null || effectId.isEmpty) {
              break;
            }

            CharacterEffect? template;

            for (final candidate in passive.linkedEffects) {
              if (candidate.id == effectId) {
                template = candidate;
                break;
              }
            }

            if (template == null) {
              break;
            }

            final copy = CharacterEffect.fromMap(template.toMap());
            copy.resetDuration();
            effects.add(copy);
            breakdown.add('Efecto aplicado: ${copy.name}');
            break;

          case PassiveTriggerActionType.addResource:
            {
              final resourceId = action.resourceId;
              if (resourceId != null && resourceId.isNotEmpty) {
                final amount = resolver.passiveTriggerActionModifier(
                  passive: passive,
                  action: action,
                  context: actionContext,
                  target: target,
                );
                if (amount != 0) {
                  character.addResourceValue(
                    resourceId,
                    amount,
                    dispatchTriggers: true,
                  );
                  breakdown.add('Recurso $resourceId: +$amount');
                }
              }
            }
            break;

          case PassiveTriggerActionType.subtractResource:
            {
              final resourceId = action.resourceId;
              if (resourceId != null && resourceId.isNotEmpty) {
                final amount = resolver.passiveTriggerActionModifier(
                  passive: passive,
                  action: action,
                  context: actionContext,
                  target: target,
                );
                if (amount > 0) {
                  character.subtractResourceValue(
                    resourceId,
                    amount,
                    dispatchTriggers: true,
                  );
                  breakdown.add('Recurso $resourceId: -$amount');
                }
              }
            }
            break;

          case PassiveTriggerActionType.setResource:
            {
              final resourceId = action.resourceId;
              if (resourceId != null && resourceId.isNotEmpty) {
                final value = resolver.passiveTriggerActionModifier(
                  passive: passive,
                  action: action,
                  context: actionContext,
                  target: target,
                );
                character.setResourceValue(
                  resourceId,
                  value,
                  dispatchTriggers: true,
                );
                breakdown.add('Recurso $resourceId: = $value');
              }
            }
            break;

          case PassiveTriggerActionType.addCharge:
            {
              final amount = await _resolvePassiveTriggerActionAmount(
                context,
                resolver: resolver,
                passive: passive,
                target: target,
                actionContext: actionContext,
                action: action,
                diceMode: diceMode,
                breakdown: breakdown,
                label: 'Cargas añadidas',
              );
              if (amount != null && amount != 0) {
                final targetPassiveId =
                    action.targetId?.trim().isNotEmpty == true
                    ? action.targetId!
                    : passive.id;
                character.addPassiveCharges(
                  targetPassiveId,
                  amount.round(),
                  dispatchTriggers: true,
                );
              }
            }
            break;

          case PassiveTriggerActionType.subtractCharge:
            {
              final amount = await _resolvePassiveTriggerActionAmount(
                context,
                resolver: resolver,
                passive: passive,
                target: target,
                actionContext: actionContext,
                action: action,
                diceMode: diceMode,
                breakdown: breakdown,
                label: 'Cargas gastadas',
              );
              if (amount != null && amount > 0) {
                final targetPassiveId =
                    action.targetId?.trim().isNotEmpty == true
                    ? action.targetId!
                    : passive.id;
                character.subtractPassiveCharges(
                  targetPassiveId,
                  amount.round(),
                  dispatchTriggers: true,
                );
              }
            }
            break;

          case PassiveTriggerActionType.incrementCounter:
            {
              final counterId = action.counterId;
              if (counterId != null && counterId.isNotEmpty) {
                final amount = resolver.passiveTriggerActionModifier(
                  passive: passive,
                  action: action,
                  context: actionContext,
                  target: target,
                );
                if (amount != 0) {
                  character.incrementCounter(
                    counterId,
                    amount,
                    dispatchTriggers: true,
                  );
                  breakdown.add('Contador $counterId: ${amount > 0 ? '+' : ''}$amount');
                }
              }
            }
            break;

          case PassiveTriggerActionType.setCounter:
            {
              final counterId = action.counterId;
              if (counterId != null && counterId.isNotEmpty) {
                final value = resolver.passiveTriggerActionModifier(
                  passive: passive,
                  action: action,
                  context: actionContext,
                  target: target,
                );
                character.setCounter(counterId, value, dispatchTriggers: true);
                breakdown.add('Contador $counterId: = $value');
              }
            }
            break;

          case PassiveTriggerActionType.removeEffect:
            {
              final effectId = action.effectId?.trim();
              if (effectId != null && effectId.isNotEmpty) {
                character.removeEffect(
                  effectId,
                  refreshTriggers: false,
                  dispatchHealthTriggers: false,
                );
                breakdown.add('Efecto eliminado: $effectId');
              }
            }
            break;
        }
      }

      results.add(
        PassiveTriggerExternalResult(
          passiveId: outcome.passiveId,
          passiveName: outcome.passiveName,
          triggerId: outcome.triggerId,
          targetId: outcome.targetId,
          targetLabel: outcome.targetLabel,
          saved: saved,
          damage: math.max(0, damage),
          healing: healing,
          mitigation: math.max(0, mitigation),
          breakdown: List<String>.unmodifiable(breakdown),
          effects: List<CharacterEffect>.unmodifiable(effects),
          resolutionId: externalResultId,
        ),
      );
    }

    return List<PassiveTriggerExternalResult>.unmodifiable(results);
  }

  Future<int?> _resolvePassiveTriggerActionAmount(
    BuildContext context, {
    required ActionResolver resolver,
    required CharacterPassive passive,
    required ActionTarget target,
    required ActionResolutionContext actionContext,
    required PassiveTriggerAction action,
    required ActionDiceMode diceMode,
    required List<String> breakdown,
    required String label,
  }) async {
    final formulaExpression = action.valueFormula?.expression ?? '';
    final formulaContext = actionContext.buildFormulaContext(
      passive: passive,
      target: target,
    );
    final extraction = FormulaDiceExtraction.extract(
      formulaExpression,
      context: formulaContext,
    );

    var modifier = 0;
    if (extraction.cleanedExpression.trim().isNotEmpty) {
      final evaluated = const FormulaEvaluator().evaluate(
        CharacterFormula(expression: extraction.cleanedExpression),
        context: formulaContext,
      );
      if (evaluated.valid) {
        modifier = evaluated.value.round();
      }
    }

    final allDicePools = <DicePool>[
      ...action.dicePools,
      ...extraction.dicePools,
    ];

    if (allDicePools.isEmpty) {
      final formula = formulaExpression.trim();
      breakdown.add(
        formula.isEmpty
            ? '$label: $modifier'
            : '$label: $formula = $modifier',
      );
      return modifier;
    }

    final request = ActionDiceRequest(
      parts: [
        ActionDiceRequestPart(
          id: 'passive-trigger-action',
          effectId: 'passive-trigger',
          effectName: 'Trigger de ${passive.name}',
          effectType: action.type == PassiveTriggerActionType.heal
              ? AbilityEffectType.healing
              : AbilityEffectType.damage,
          dicePools: List<DicePool>.unmodifiable(allDicePools),
          modifier: modifier,
          hitBehavior: ActionHitBehavior.ignoreHit,
          sourceType: ActionDiceSourceType.passive,
          sourceId: passive.id,
          sourceName: passive.name,
          damageType: action.damageType,
        ),
      ],
    );

    if (diceMode == ActionDiceMode.digital) {
      final result = const ActionDiceResolver().rollDigital(request);
      final total = result.parts.fold<int>(0, (sum, part) => sum + part.total);
      breakdown.add(
        _passiveDiceBreakdown(label, formulaExpression, result, total),
      );
      return total;
    }

    final inputs = await showPhysicalDiceDialog(
      context,
      sections: [
        PhysicalDiceSection(
          id: 'passive-trigger',
          title: passive.name,
          request: request,
        ),
      ],
    );

    if (inputs == null || !context.mounted) {
      return null;
    }

    final physical = inputs['passive-trigger'];
    if (physical == null) {
      return null;
    }

    final result = const ActionDiceResolver().resolvePhysical(
      request: request,
      inputs: physical,
    );

    final total = result.parts.fold<int>(0, (sum, part) => sum + part.total);
    breakdown.add(
        _passiveDiceBreakdown(label, formulaExpression, result, total),
      );
    return total;
  }

  String _passiveDiceBreakdown(
    String label,
    String formulaExpression,
    ActionDiceResult result,
    int total,
  ) {
    final pieces = <String>[];

    for (final part in result.parts) {
      for (final group in part.result.groups) {
        pieces.add(
          '${group.pool.notation} [${group.rolls.join(', ')}] = ${group.total}',
        );
      }

      final modifier = part.result.modifier;
      if (modifier != 0) {
        pieces.add('${modifier > 0 ? '+' : ''}$modifier');
      }

      if (part.automaticValue != 0) {
        final automatic = part.automaticValue;
        pieces.add('${automatic > 0 ? '+' : ''}$automatic automático');
      }
    }

    final detail = pieces.isEmpty ? '$total' : pieces.join(' · ');
    final formula = formulaExpression.trim();
    final formulaPrefix = formula.isEmpty ? '' : '$formula → ';
    return '$label: $formulaPrefix$detail → $total';
  }

  Future<PassiveRollResolution?> resolvePassiveRoll(
    BuildContext context, {
    required CharacterPassive passive,
  }) async {
    final resolver = PassiveActionResolver(character: character);

    final diceMode = await showActionDiceModeSheet(context);

    if (diceMode == null || !context.mounted) {
      return null;
    }

    final request = resolver.buildRollRequest(passive);
    final calculationText = request.parts.isEmpty
        ? '0'
        : request.parts.first.calculationText;

    switch (diceMode) {
      case ActionDiceMode.digital:
        final diceResult = resolver.resolveDigitalRequest(request);
        return PassiveRollResolution(
          diceResult: diceResult,
          calculationText: calculationText,
        );

      case ActionDiceMode.physical:
        final inputsBySection = await showPhysicalDiceDialog(
          context,
          sections: [
            PhysicalDiceSection(
              id: 'passive:${passive.id}',
              title: passive.name,
              request: request,
            ),
          ],
        );

        if (inputsBySection == null || !context.mounted) {
          return null;
        }

        final inputs = inputsBySection['passive:${passive.id}'];
        if (inputs == null) {
          return null;
        }

        final diceResult = resolver.resolvePhysicalRequest(
          request,
          inputs: inputs,
        );

        return PassiveRollResolution(
          diceResult: diceResult,
          calculationText: calculationText,
        );
    }
  }

  Future<ActionExecutionResult?> resolveWeapon(
    BuildContext context, {
    required Weapon weapon,
  }) async {
    final resolver = ActionResolver(character: character);

    final source = ActionSource.weapon(weapon);
    final definition = ActionDefinition.fromWeapon(weapon);
    final content = ActionContent.fromWeapon(weapon);

    try {
      resolver.validatePassiveTriggerTargetScopes(
        definition: definition,
        content: content,
      );
    } on StateError catch (error) {
      _showError(context, error.message.toString());
      return null;
    }

    final targets = await showActionTargetSelector(
      context,
      targetType: definition.targetType,
      selfLabel: selfLabel,
    );

    if (targets == null || !context.mounted) {
      return null;
    }

    if (targets.isEmpty) {
      return null;
    }

    if (targets.length != 1) {
      _showError(context, 'Los ataques de arma requieren un único objetivo.');
      return null;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: targets,
    );

    actionContext.populateKnownTargetVariables();

    final requirementsCompleted = await _collectExternalRequirements(
      context,
      resolver: resolver,
      source: source,
      definition: definition,
      content: content,
      actionContext: actionContext,
    );

    if (!requirementsCompleted || !context.mounted) {
      return null;
    }

    final criticalProfile = resolver.buildCriticalProfileForWeapon(weapon);

    final initialPrepared = resolver.prepareDirectAction(
      source: source,
      definition: definition,
      content: content,
      context: actionContext,
      criticalProfile: criticalProfile,
    );

    final optionalCompleted = await _collectOptionalChoices(
      context,
      resolver: resolver,
      plan: initialPrepared.plan,
      actionContext: actionContext,
    );

    if (!optionalCompleted || !context.mounted) {
      return null;
    }

    final prepared = resolver.prepareDirectAction(
      source: source,
      definition: definition,
      content: content,
      context: actionContext,
      criticalProfile: criticalProfile,
    );

    try {
      resolver.validatePreparedTargetResolution(prepared);
    } on StateError catch (error) {
      _showError(context, error.message.toString());
      return null;
    }

    final validation = resolver.validatePreparedActionCosts(prepared);

    if (!validation.valid) {
      _showError(
        context,
        validation.error ?? 'No puedes pagar los costes de este ataque.',
      );
      return null;
    }

    // Permitir elegir siempre si se tira en digital o en físico
    final selectedDiceMode = await showActionDiceModeSheet(context);

    if (selectedDiceMode == null || !context.mounted) {
      return null;
    }

    final ActionDiceMode diceMode = selectedDiceMode;

    if (prepared.definition.requiresAttackRoll) {
      return _resolveAttack(
        context,
        resolver: resolver,
        prepared: prepared,
        diceMode: diceMode,
      );
    }

    return _resolveWithoutAttack(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
    );
  }

  Future<ActionExecutionResult?> resolveConsumable(
    BuildContext context, {
    required ItemDefinition item,
  }) async {
    final consumable = item.consumable;

    if (consumable == null) {
      _showError(context, 'Este objeto no es un consumible.');
      return null;
    }

    if (consumable.effects.isEmpty) {
      _showError(context, 'Este consumible no tiene efectos configurados.');
      return null;
    }

    final resolver = ActionResolver(character: character);

    final source = ActionSource.item(item);
    final definition = ActionDefinition.fromConsumableItem(item);
    final content = ActionContent.fromConsumableItem(item);

    try {
      resolver.validatePassiveTriggerTargetScopes(
        definition: definition,
        content: content,
      );
    } on StateError catch (error) {
      _showError(context, error.message.toString());
      return null;
    }

    final targets = await showActionTargetSelector(
      context,
      targetType: definition.targetType,
      selfLabel: selfLabel,
    );

    if (targets == null || !context.mounted) {
      return null;
    }

    if (targets.isEmpty) {
      return null;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: targets,
    );

    actionContext.populateKnownTargetVariables();

    final requirementsCompleted = await _collectExternalRequirements(
      context,
      resolver: resolver,
      source: source,
      definition: definition,
      content: content,
      actionContext: actionContext,
    );

    if (!requirementsCompleted || !context.mounted) {
      return null;
    }

    final criticalProfile = resolver.buildCriticalProfile();

    final initialPrepared = resolver.prepareDirectAction(
      source: source,
      definition: definition,
      content: content,
      context: actionContext,
      criticalProfile: criticalProfile,
    );

    final optionalCompleted = await _collectOptionalChoices(
      context,
      resolver: resolver,
      plan: initialPrepared.plan,
      actionContext: actionContext,
    );

    if (!optionalCompleted || !context.mounted) {
      return null;
    }

    final prepared = resolver.prepareDirectAction(
      source: source,
      definition: definition,
      content: content,
      context: actionContext,
      criticalProfile: criticalProfile,
    );

    try {
      resolver.validatePreparedTargetResolution(prepared);
    } on StateError catch (error) {
      _showError(context, error.message.toString());
      return null;
    }

    final validation = resolver.validatePreparedActionCosts(prepared);

    if (!validation.valid) {
      _showError(
        context,
        validation.error ?? 'No puedes pagar los costes de este consumible.',
      );
      return null;
    }

    // Permitir elegir siempre si se tira en digital o en físico
    final selectedDiceMode = await showActionDiceModeSheet(context);

    if (selectedDiceMode == null || !context.mounted) {
      return null;
    }

    final ActionDiceMode diceMode = selectedDiceMode;

    if (prepared.definition.requiresAttackRoll) {
      return _resolveAttack(
        context,
        resolver: resolver,
        prepared: prepared,
        diceMode: diceMode,
      );
    }

    return _resolveWithoutAttack(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
    );
  }

  Future<ActionExecutionResult?> resolveAbility(
    BuildContext context, {
    required CharacterAbility ability,
  }) async {
    final resolver = ActionResolver(character: character);
    final source = ActionSource.ability(ability);
    final definition = ActionDefinition.fromAbility(ability);
    final content = ActionContent.fromAbility(ability);

    try {
      resolver.validatePassiveTriggerTargetScopes(
        definition: definition,
        content: content,
      );
    } on StateError catch (error) {
      _showError(context, error.message.toString());
      return null;
    }

    final targets = await showActionTargetSelector(
      context,
      targetType: ability.targetType,
      selfLabel: selfLabel,
    );

    if (targets == null || !context.mounted) {
      return null;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: targets,
    );

    actionContext.populateKnownTargetVariables();

    final requirementsCompleted = await _collectExternalRequirements(
      context,
      resolver: resolver,
      source: source,
      definition: definition,
      content: content,
      actionContext: actionContext,
    );

    if (!requirementsCompleted || !context.mounted) {
      return null;
    }

    final initialPlan = resolver.prepareAbilityPlan(
      ability: ability,
      context: actionContext,
    );

    final optionalCompleted = await _collectOptionalChoices(
      context,
      resolver: resolver,
      plan: initialPlan,
      actionContext: actionContext,
    );

    if (!optionalCompleted || !context.mounted) {
      return null;
    }

    final prepared = resolver.prepareAbilityAction(
      ability: ability,
      context: actionContext,
    );

    try {
      resolver.validatePreparedTargetResolution(prepared);
    } on StateError catch (error) {
      _showError(context, error.message.toString());
      return null;
    }

    final validation = resolver.validatePreparedActionCosts(prepared);

    if (!validation.valid) {
      _showError(
        context,
        validation.error ?? 'No puedes pagar los costes de esta acción.',
      );
      return null;
    }

    // Permitir elegir siempre si se tira en digital o en físico
    final selectedDiceMode = await showActionDiceModeSheet(context);

    if (selectedDiceMode == null || !context.mounted) {
      return null;
    }

    final ActionDiceMode diceMode = selectedDiceMode;

    if (prepared.definition.requiresAttackRoll) {
      return _resolveAttack(
        context,
        resolver: resolver,
        prepared: prepared,
        diceMode: diceMode,
      );
    }

    return _resolveWithoutAttack(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
    );
  }

  ActionExecutionResult _mergePassiveTriggeredResults({
    required ActionExecutionResult execution,
    required List<PassiveTriggerExternalResult> triggeredResults,
  }) {
    if (triggeredResults.isEmpty) {
      return execution;
    }

    final application = execution.application;

    final outcomes = List<ExternalTargetOutcome>.from(
      application.externalTargetOutcomes,
    );

    for (final triggered in triggeredResults) {
      if (!triggered.changedAnything) {
        continue;
      }

      final index = outcomes.indexWhere(
        (outcome) => outcome.targetId == triggered.targetId,
      );

      if (index < 0) {
        outcomes.add(
          ExternalTargetOutcome(
            targetId: triggered.targetId,
            targetLabel: triggered.targetLabel,
            damage: triggered.damage,
            healing: triggered.healing,
            passiveEffects: List<CharacterEffect>.unmodifiable(
              triggered.effects,
            ),
            triggerResults: [triggered],
            effectTriggerResults: const [],
          ),
        );
        continue;
      }

      final current = outcomes[index];

      outcomes[index] = ExternalTargetOutcome(
        targetId: current.targetId,
        targetLabel: current.targetLabel ?? triggered.targetLabel,
        damage: current.damage + triggered.damage,
        healing: current.healing + triggered.healing,
        effects: current.effects,
        passiveEffects: [...current.passiveEffects, ...triggered.effects],
        triggerResults: [...current.triggerResults, triggered],
        effectTriggerResults: current.effectTriggerResults,
      );
    }

    final mergedApplication = ActionApplyResult(
      selfDamageApplied: application.selfDamageApplied,
      selfHealingApplied: application.selfHealingApplied,
      selfEffectsApplied: application.selfEffectsApplied,
      criticalDispatched: application.criticalDispatched,
      externalTargetOutcomes: List<ExternalTargetOutcome>.unmodifiable(
        outcomes,
      ),
    );

    return ActionExecutionResult(
      resolution: execution.resolution,
      application: mergedApplication,
    );
  }

  ActionExecutionResult _mergeEffectTriggeredResults({
    required ActionExecutionResult execution,
    required List<CharacterEffectTriggerExternalResult> triggeredResults,
  }) {
    if (triggeredResults.isEmpty) {
      return execution;
    }

    final application = execution.application;

    final outcomes = List<ExternalTargetOutcome>.from(
      application.externalTargetOutcomes,
    );

    for (final triggered in triggeredResults) {
      if (!triggered.changedAnything) {
        continue;
      }

      final index = outcomes.indexWhere(
        (outcome) => outcome.targetId == triggered.targetId,
      );

      if (index < 0) {
        outcomes.add(
          ExternalTargetOutcome(
            targetId: triggered.targetId,
            targetLabel: triggered.targetLabel,
            damage: triggered.damage,
            healing: triggered.healing,
            passiveEffects: List<CharacterEffect>.unmodifiable(
              triggered.effects,
            ),
            triggerResults: const [],
            effectTriggerResults: [triggered],
          ),
        );
        continue;
      }

      final current = outcomes[index];

      outcomes[index] = ExternalTargetOutcome(
        targetId: current.targetId,
        targetLabel: current.targetLabel ?? triggered.targetLabel,
        damage: current.damage + triggered.damage,
        healing: current.healing + triggered.healing,
        effects: current.effects,
        passiveEffects: [...current.passiveEffects, ...triggered.effects],
        triggerResults: current.triggerResults,
        effectTriggerResults: [...current.effectTriggerResults, triggered],
      );
    }

    final mergedApplication = ActionApplyResult(
      selfDamageApplied: application.selfDamageApplied,
      selfHealingApplied: application.selfHealingApplied,
      selfEffectsApplied: application.selfEffectsApplied,
      criticalDispatched: application.criticalDispatched,
      externalTargetOutcomes: List<ExternalTargetOutcome>.unmodifiable(
        outcomes,
      ),
    );

    return ActionExecutionResult(
      resolution: execution.resolution,
      application: mergedApplication,
    );
  }

  Future<ActionExecutionResult?> _finalizeResolution(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionResolutionResult resolution,
    required ActionDiceMode diceMode,
  }) async {
    final postCompleted = await _collectPostResolutionExternalRequirements(
      context,
      resolver: resolver,
      prepared: prepared,
      resolution: resolution,
    );

    if (!postCompleted || !context.mounted) {
      return null;
    }

    final triggeredOutcomes = <PassiveTriggeredExternalOutcome>[];
    final effectTriggeredOutcomes = <CharacterEffectTriggeredExternalOutcome>[];
    final reservedLimitedTriggers = <String>{};
    final reservedLimitedEffectTriggers = <String>{};

    final critical =
        resolution.attackResult?.critical ??
        resolution.criticalProfile.forcedCritical;

    for (final targetResult in resolution.externalTargetResults) {
      final candidates = resolver.collectTriggeredExternalOutcomesForTarget(
        targetResult: targetResult,
        context: prepared.context,
        critical: critical,
      );

      final effectCandidates = resolver
          .collectEffectTriggeredExternalOutcomesForTarget(
            targetResult: targetResult,
            context: prepared.context,
            critical: critical,
          );

      for (final candidate in effectCandidates) {
        if (candidate.usageLimit == TriggerUsageLimit.unlimited) {
          effectTriggeredOutcomes.add(candidate);
          continue;
        }

        final key = candidate.usageKey;
        if (reservedLimitedEffectTriggers.contains(key)) {
          continue;
        }

        reservedLimitedEffectTriggers.add(key);
        effectTriggeredOutcomes.add(candidate);
      }

      for (final candidate in candidates) {
        if (candidate.usageLimit == TriggerUsageLimit.unlimited) {
          triggeredOutcomes.add(candidate);
          continue;
        }

        final key = candidate.usageKey;
        if (reservedLimitedTriggers.contains(key)) {
          continue;
        }

        reservedLimitedTriggers.add(key);
        triggeredOutcomes.add(candidate);
      }
    }

    final resolutionId = 'action-${DateTime.now().microsecondsSinceEpoch}';

    final triggeredResults = await _resolvePassiveTriggeredExternalOutcomes(
      context,
      resolver: resolver,
      actionContext: prepared.context,
      outcomes: triggeredOutcomes,
      diceMode: diceMode,
      resolutionId: resolutionId,
    );

    if (triggeredResults == null || !context.mounted) {
      return null;
    }

    final effectTriggeredResults =
        await _resolveEffectTriggeredExternalOutcomes(
          context,
          resolver: resolver,
          actionContext: prepared.context,
          outcomes: effectTriggeredOutcomes,
          diceMode: diceMode,
          resolutionId: resolutionId,
        );

    if (effectTriggeredResults == null || !context.mounted) {
      return null;
    }

    final finalResolution = resolution.copyWith(
      externalVariablesByTargetId: prepared.context
          .snapshotTargetExternalVariables(),
    );

    if (!context.mounted) {
      return null;
    }

    return _commitResolution(
      context: context,
      resolver: resolver,
      prepared: prepared,
      resolution: finalResolution,
      triggeredResults: triggeredResults,
      effectTriggeredResults: effectTriggeredResults,
    );
  }

  Future<List<CharacterEffectTriggerExternalResult>?>
  _resolveEffectTriggeredExternalOutcomes(
    BuildContext context, {
    required ActionResolver resolver,
    required ActionResolutionContext actionContext,
    required List<CharacterEffectTriggeredExternalOutcome> outcomes,
    required ActionDiceMode diceMode,
    required String resolutionId,
  }) async {
    final results = <CharacterEffectTriggerExternalResult>[];

    for (var outcomeIndex = 0; outcomeIndex < outcomes.length; outcomeIndex++) {
      final outcome = outcomes[outcomeIndex];

      final externalResultId =
          '$resolutionId:effect:'
          '${outcome.sourceEffectId}:'
          '${outcome.triggerId}:'
          '${outcome.targetId}:'
          '$outcomeIndex';

      ActionTarget? target;

      for (final candidate in actionContext.targets) {
        if (candidate.id == outcome.targetId) {
          target = candidate;
          break;
        }
      }

      if (target == null) {
        continue;
      }

      var damage = 0;
      var healing = 0;

      // =======================================================================
      // DAÑO
      // =======================================================================

      for (final bonus in outcome.damageBonuses) {
        if (!context.mounted) {
          return null;
        }

        final amount = await _resolveEffectTriggerDamage(
          context,
          bonus: bonus,
          sourceEffectId: outcome.sourceEffectId,
          sourceEffectName: outcome.sourceEffectName,
          target: target,
          actionContext: actionContext,
          diceMode: diceMode,
        );

        if (amount == null) {
          return null;
        }

        damage += amount;
      }

      // =======================================================================
      // CURACIÓN
      // =======================================================================

      for (final bonus in outcome.healingBonuses) {
        if (!context.mounted) {
          return null;
        }

        final amount = await _resolveEffectTriggerHealing(
          context,
          bonus: bonus,
          sourceEffectId: outcome.sourceEffectId,
          sourceEffectName: outcome.sourceEffectName,
          target: target,
          actionContext: actionContext,
          diceMode: diceMode,
        );

        if (amount == null) {
          return null;
        }

        healing += amount;
      }

      final effects = outcome.linkedEffects
          .map((effect) => CharacterEffect.fromMap(effect.toMap()))
          .toList();

      for (final effect in effects) {
        effect.resetDuration();
      }

      results.add(
        CharacterEffectTriggerExternalResult(
          sourceEffectId: outcome.sourceEffectId,
          sourceEffectName: outcome.sourceEffectName,
          triggerId: outcome.triggerId,
          targetId: outcome.targetId,
          targetLabel: outcome.targetLabel,
          damage: damage,
          healing: healing,
          effects: List<CharacterEffect>.unmodifiable(effects),
          resolutionId: externalResultId,
        ),
      );
    }

    return List<CharacterEffectTriggerExternalResult>.unmodifiable(results);
  }

  Future<int?> _resolveEffectTriggerDamage(
    BuildContext context, {
    required DamageBonus bonus,
    required String sourceEffectId,
    required String sourceEffectName,
    required ActionTarget target,
    required ActionResolutionContext actionContext,
    required ActionDiceMode diceMode,
  }) async {
    final formulaContext = actionContext.buildFormulaContext(target: target);

    final modifier = character.damageBonusModifier(
      bonus,
      formulaContext: formulaContext,
    );

    final partId =
        'effect-trigger-damage:'
        '$sourceEffectId:'
        '${bonus.id}:'
        '${target.id}';

    final request = ActionDiceRequest(
      parts: [
        ActionDiceRequestPart(
          id: partId,
          effectId: 'effect-trigger:$sourceEffectId',
          effectName: bonus.name.trim().isNotEmpty
              ? bonus.name.trim()
              : sourceEffectName,
          effectType: AbilityEffectType.damage,
          dicePools: List<DicePool>.unmodifiable(bonus.dicePools),
          modifier: modifier,
          hitBehavior: ActionHitBehavior.ignoreHit,
          sourceType: ActionDiceSourceType.effect,
          sourceId: sourceEffectId,
          sourceName: sourceEffectName,
          damageType: bonus.damageType,
        ),
      ],
    );

    if (diceMode == ActionDiceMode.digital) {
      final result = const ActionDiceResolver().rollDigital(request);
      return result.parts.fold<int>(0, (sum, part) => sum + part.total);
    }

    final sectionId =
        'effect-trigger-damage-section:'
        '$sourceEffectId:'
        '${bonus.id}:'
        '${target.id}';

    final inputsBySection = await showPhysicalDiceDialog(
      context,
      sections: [
        PhysicalDiceSection(
          id: sectionId,
          title: sourceEffectName.trim().isNotEmpty
              ? sourceEffectName.trim()
              : 'Trigger de efecto',
          request: request,
        ),
      ],
    );

    if (inputsBySection == null || !context.mounted) {
      return null;
    }

    final inputs = inputsBySection[sectionId];
    if (inputs == null) {
      return null;
    }

    final result = const ActionDiceResolver().resolvePhysical(
      request: request,
      inputs: inputs,
    );

    return result.parts.fold<int>(0, (sum, part) => sum + part.total);
  }

  Future<int?> _resolveEffectTriggerHealing(
    BuildContext context, {
    required HealingBonus bonus,
    required String sourceEffectId,
    required String sourceEffectName,
    required ActionTarget target,
    required ActionResolutionContext actionContext,
    required ActionDiceMode diceMode,
  }) async {
    final formulaContext = actionContext.buildFormulaContext(target: target);

    final modifier = character.healingBonusModifier(
      bonus,
      formulaContext: formulaContext,
    );

    final partId =
        'effect-trigger-healing:'
        '$sourceEffectId:'
        '${bonus.id}:'
        '${target.id}';

    final request = ActionDiceRequest(
      parts: [
        ActionDiceRequestPart(
          id: partId,
          effectId: 'effect-trigger:$sourceEffectId',
          effectName: bonus.name.trim().isNotEmpty
              ? bonus.name.trim()
              : sourceEffectName,
          effectType: AbilityEffectType.healing,
          dicePools: List<DicePool>.unmodifiable(bonus.dicePools),
          modifier: modifier,
          hitBehavior: ActionHitBehavior.ignoreHit,
          sourceType: ActionDiceSourceType.effect,
          sourceId: sourceEffectId,
          sourceName: sourceEffectName,
        ),
      ],
    );

    if (diceMode == ActionDiceMode.digital) {
      final result = const ActionDiceResolver().rollDigital(request);
      return result.parts.fold<int>(0, (sum, part) => sum + part.total);
    }

    final sectionId =
        'effect-trigger-healing-section:'
        '$sourceEffectId:'
        '${bonus.id}:'
        '${target.id}';

    final inputsBySection = await showPhysicalDiceDialog(
      context,
      sections: [
        PhysicalDiceSection(
          id: sectionId,
          title: sourceEffectName.trim().isNotEmpty
              ? sourceEffectName.trim()
              : 'Trigger de efecto',
          request: request,
        ),
      ],
    );

    if (inputsBySection == null || !context.mounted) {
      return null;
    }

    final inputs = inputsBySection[sectionId];
    if (inputs == null) {
      return null;
    }

    final result = const ActionDiceResolver().resolvePhysical(
      request: request,
      inputs: inputs,
    );

    return result.parts.fold<int>(0, (sum, part) => sum + part.total);
  }

  Future<bool> _collectPostResolutionExternalRequirements(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionResolutionResult resolution,
  }) async {
    final critical =
        resolution.attackResult?.critical ??
        resolution.criticalProfile.forcedCritical;

    for (final targetResult in resolution.externalTargetResults) {
      final events = resolver.postResolutionEventsForTarget(
        targetResult,
        critical: critical,
      );

      if (events.isEmpty) {
        continue;
      }

      final target = targetResult.target;
      prepared.context.clearTargetCurrentHealthKnowledge(target);

      final requirements = resolver
          .orderedPostResolutionExternalRequirementsForTarget(
            context: prepared.context,
            target: target,
            events: events,
          );

      if (requirements.isEmpty) {
        continue;
      }

      for (final requirement in requirements) {
        final answers = await showExternalRequirementsDialog(
          context,
          targetLabel: target.label ?? 'Objetivo',
          requirements: [requirement],
          knownAnswers: const {},
        );

        if (answers == null || !context.mounted) {
          return false;
        }

        final answer = answers[requirement.normalizedVariableName];
        if (answer == null) {
          continue;
        }

        resolver.applyExternalRequirementAnswer(
          context: prepared.context,
          target: target,
          requirement: requirement,
          answer: answer,
        );
      }
    }

    return true;
  }

  Future<ActionExecutionResult?> _resolveWithoutAttack(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
  }) async {
    final saves = await _collectSavingThrows(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
    );

    if (saves == null || !context.mounted) {
      return null;
    }

    final resolution = await _resolvePrepared(
      context,
      resolver: resolver,
      prepared: prepared,
      savingThrowResults: saves,
      diceMode: diceMode,
    );

    if (resolution == null || !context.mounted) {
      return null;
    }

    return _finalizeResolution(
      context,
      resolver: resolver,
      prepared: prepared,
      resolution: resolution,
      diceMode: diceMode,
    );
  }

  Future<ActionExecutionResult?> _resolveAttack(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
  }) async {
    final attackMode = await showAttackRollModeSheet(context);

    if (attackMode == null || !context.mounted) {
      return null;
    }

    final rolls = await _resolveAttackRolls(
      context,
      resolver: resolver,
      mode: attackMode,
      diceMode: diceMode,
    );

    if (rolls == null || !context.mounted) {
      return null;
    }

    final attackResult = resolver.resolvePreparedAttackRoll(
      prepared: prepared,
      mode: attackMode,
      firstRoll: rolls.firstRoll,
      secondRoll: rolls.secondRoll,
    );

    final attackResults = await showAttackTargetsDialog(
      context,
      targets: prepared.context.targets,
      attackResult: attackResult,
      selfLabel: selfLabel,
      ability: prepared.definition.abilityType,
    );

    if (attackResults == null || !context.mounted) {
      return null;
    }

    final saves = await _collectSavingThrows(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
      attackResults: attackResults,
    );

    if (saves == null || !context.mounted) {
      return null;
    }

    final resolution = await _resolvePrepared(
      context,
      resolver: resolver,
      prepared: prepared,
      attackResult: attackResult,
      attackResultsByTargetId: attackResults,
      savingThrowResults: saves,
      diceMode: diceMode,
    );

    if (resolution == null || !context.mounted) {
      return null;
    }

    return _finalizeResolution(
      context,
      resolver: resolver,
      prepared: prepared,
      resolution: resolution,
      diceMode: diceMode,
    );
  }

  Future<ActionAttackRolls?> _resolveAttackRolls(
    BuildContext context, {
    required ActionResolver resolver,
    required AttackRollMode mode,
    required ActionDiceMode diceMode,
  }) async {
    switch (diceMode) {
      case ActionDiceMode.physical:
        return showPhysicalAttackRollDialog(context, mode: mode);

      case ActionDiceMode.digital:
        return resolver.resolvePreparedAttackRollsDigital(mode: mode);
    }
  }

  Future<ActionResolutionResult?> _resolvePrepared(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required List<ActionSavingThrowResult> savingThrowResults,
    required ActionDiceMode diceMode,
    ActionAttackResult? attackResult,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) async {
    final critical = resolver.preparedActionIsCritical(
      prepared: prepared,
      attackResult: attackResult,
    );

    final scopes = resolver.preparedResolutionScopes(prepared);

    final chanceResultsByScopeId = <String, List<ActionChanceResult>>{};

    for (final scope in scopes) {
      final checks = resolver.collectPreparedCriticalChanceChecksForScope(
        prepared: prepared,
        critical: critical,
        scope: scope,
        attackResultsByTargetId: attackResultsByTargetId,
      );

      if (checks.isEmpty) {
        chanceResultsByScopeId[scope.id] = const [];
        continue;
      }

      switch (diceMode) {
        case ActionDiceMode.digital:
          chanceResultsByScopeId[scope.id] = resolver
              .resolveChanceChecksDigital(checks: checks);
          break;

        case ActionDiceMode.physical:
          final inputs = await showPhysicalChanceChecksDialog(
            context,
            checks: checks,
          );

          if (inputs == null || !context.mounted) {
            return null;
          }

          final rollsByCheckId = {
            for (final input in inputs) input.checkId: input.roll,
          };

          chanceResultsByScopeId[scope.id] = resolver
              .resolveChanceChecksPhysical(
                checks: checks,
                rollsByCheckId: rollsByCheckId,
              );
          break;
      }
    }

    final requestsByScopeId = <String, ActionDiceRequest>{};

    for (final scope in scopes) {
      final chanceResults =
          chanceResultsByScopeId[scope.id] ?? const <ActionChanceResult>[];

      final successfulChanceIds = resolver.successfulChanceCheckIds(
        chanceResults,
      );

      requestsByScopeId[scope.id] = resolver.buildPreparedDiceRequestForScope(
        prepared: prepared,
        scope: scope,
        attackResult: attackResult,
        attackResultsByTargetId: attackResultsByTargetId,
        successfulChanceCheckIds: successfulChanceIds,
      );
    }

    final diceResultsByScopeId = <String, ActionDiceResult>{};

    switch (diceMode) {
      case ActionDiceMode.digital:
        for (final scope in scopes) {
          final request = requestsByScopeId[scope.id];
          if (request == null) {
            continue;
          }

          diceResultsByScopeId[scope.id] = resolver.resolvePreparedDiceDigital(
            request: request,
          );
        }
        break;

      case ActionDiceMode.physical:
        final sections = <PhysicalDiceSection>[];

        for (final scope in scopes) {
          final request = requestsByScopeId[scope.id];
          if (request == null) {
            continue;
          }

          if (!request.parts.any((part) => part.requiresRoll)) {
            continue;
          }

          final target = scope.target;

          sections.add(
            PhysicalDiceSection(
              id: scope.id,
              title: target == null
                  ? prepared.definition.name
                  : target.isSelf
                  ? selfLabel
                  : target.label ?? 'Objetivo',
              request: request,
            ),
          );
        }

        Map<String, List<ActionPhysicalDiceInput>> physicalInputsByScopeId =
            const {};

        if (sections.isNotEmpty) {
          final physicalInputs = await showPhysicalDiceDialog(
            context,
            sections: sections,
          );

          if (physicalInputs == null || !context.mounted) {
            return null;
          }

          physicalInputsByScopeId = physicalInputs;
        }

        for (final scope in scopes) {
          final request = requestsByScopeId[scope.id];
          if (request == null) {
            continue;
          }

          final inputs =
              physicalInputsByScopeId[scope.id] ??
              const <ActionPhysicalDiceInput>[];

          diceResultsByScopeId[scope.id] = resolver.resolvePreparedDicePhysical(
            request: request,
            inputs: inputs,
          );
        }
        break;
    }

    return resolver.buildPreparedResolutionFromScopes(
      prepared: prepared,
      diceResultsByScopeId: Map<String, ActionDiceResult>.unmodifiable(
        diceResultsByScopeId,
      ),
      attackResult: attackResult,
      attackResultsByTargetId: attackResultsByTargetId,
      chanceResultsByScopeId:
          Map<String, List<ActionChanceResult>>.unmodifiable(
            chanceResultsByScopeId,
          ),
      savingThrowResults: savingThrowResults,
    );
  }

  Future<List<ActionSavingThrowResult>?> _collectSavingThrows(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
    Map<String, ActionTargetAttackResult> attackResults = const {},
  }) async {
    final requests = resolver.collectSavingThrowRequests(
      prepared: prepared,
      attackResultsByTargetId: attackResults,
    );

    if (requests.isEmpty) {
      return const [];
    }

    final selfRequests = requests
        .where((request) => request.targetId == 'self')
        .toList(growable: false);

    final externalRequests = requests
        .where((request) => request.targetId != 'self')
        .toList(growable: false);

    final results = <ActionSavingThrowResult>[];

    // ===========================================================================
    // SELF
    // ===========================================================================

    if (selfRequests.isNotEmpty) {
      switch (diceMode) {
        case ActionDiceMode.physical:
          final inputs = await showPhysicalSavingThrowsDialog(
            context,
            requests: selfRequests,
          );

          if (inputs == null || !context.mounted) {
            return null;
          }

          results.addAll(
            resolver.resolvePhysicalSavingThrows(
              requests: selfRequests,
              inputs: inputs,
            ),
          );
          break;

        case ActionDiceMode.digital:
          results.addAll(
            resolver.resolveDigitalSavingThrows(requests: selfRequests),
          );
          break;
      }
    }

    if (!context.mounted) {
      return null;
    }

    // ===========================================================================
    // EXTERNOS
    // ===========================================================================

    if (externalRequests.isNotEmpty) {
      final externalAnswers = await showExternalSavingThrowResultsDialog(
        context,
        requests: externalRequests,
      );

      if (externalAnswers == null || !context.mounted) {
        return null;
      }

      results.addAll(
        resolver.resolveExternalSavingThrowResults(
          requests: externalRequests,
          resultsByRequestId: externalAnswers,
        ),
      );
    }

    return List<ActionSavingThrowResult>.unmodifiable(results);
  }

  Future<bool> _collectExternalRequirements(
    BuildContext context, {
    required ActionResolver resolver,
    required ActionSource source,
    required ActionDefinition definition,
    required ActionContent content,
    required ActionResolutionContext actionContext,
  }) async {
    for (final target in actionContext.targets) {
      final requirements = resolver
          .orderedPreResolutionExternalRequirementsForTarget(
            source: source,
            definition: definition,
            content: content,
            context: actionContext,
            target: target,
          );

      if (requirements.isEmpty) {
        continue;
      }

      for (final requirement in requirements) {
        final answers = await showExternalRequirementsDialog(
          context,
          targetLabel: target.isSelf ? selfLabel : target.label ?? 'Objetivo',
          requirements: [requirement],
          knownAnswers: const {},
        );

        if (answers == null || !context.mounted) {
          return false;
        }

        final answer = answers[requirement.normalizedVariableName];
        if (answer == null) {
          continue;
        }

        resolver.applyExternalRequirementAnswer(
          context: actionContext,
          target: target,
          requirement: requirement,
          answer: answer,
        );
      }
    }

    return true;
  }

  void _appendOptionalEntries({
    required List<OptionalChoiceEntry> entries,
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
    ActionTarget? target,
  }) {
    final groups = resolver.availableOptionalGroups(
      plan: plan,
      context: actionContext,
      target: target,
    );

    for (final group in groups) {
      entries.add(
        OptionalChoiceEntry(
          group: group,
          target: target,
          validation: resolver.validateOptionalGroupSelection(
            plan: plan,
            context: actionContext,
            group: group,
            target: target,
          ),
        ),
      );
    }
  }

  Future<bool> _collectOptionalChoices(
    BuildContext context, {
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
  }) async {
    final entries = <OptionalChoiceEntry>[];

    final scopes = resolver.resolutionScopes(
      plan: plan,
      context: actionContext,
    );

    for (final scope in scopes) {
      _appendOptionalEntries(
        entries: entries,
        resolver: resolver,
        plan: plan,
        actionContext: actionContext,
        target: scope.target,
      );
    }

    if (entries.isEmpty) {
      return true;
    }

    final selections = await showOptionalChoicesDialog(
      context,
      entries: entries,
      selfLabel: selfLabel,
    );

    if (selections == null || !context.mounted) {
      return false;
    }

    for (final entry in entries) {
      final selected = selections[entry.key] ?? false;
      final target = entry.target;

      if (target == null) {
        actionContext.setOptionalGroupSelected(entry.group.id, selected);
        continue;
      }

      actionContext.setOptionalGroupSelectedForTarget(
        target.id,
        entry.group.id,
        selected,
      );
    }

    return true;
  }

  void _dispatchTargetTriggers({
    required ActionResolver resolver,
    required ActionTargetResult targetResult,
    required bool critical,
  }) {
    final events = resolver.postResolutionEventsForTarget(
      targetResult,
      critical: critical,
    );

    if (events.isEmpty) {
      return;
    }

    final target = targetResult.target;
    final variables = <String, double>{
      'damage': targetResult.damage.toDouble(),
      'healing': targetResult.healing.toDouble(),
    };

    for (final event in events) {
      character.dispatchPassiveTrigger(
        event,
        eventVariables: variables,
        actionContext: ActionTriggerContext(
          targetId: target.id,
          targetLabel: target.label,
        ),
      );
    }
  }

  void _dispatchPostResolutionTriggers({
    required ActionResolver resolver,
    required ActionResolutionResult resolution,
  }) {
    final critical =
        resolution.attackResult?.critical ??
        resolution.criticalProfile.forcedCritical;

    for (final targetResult in resolution.externalTargetResults) {
      _dispatchTargetTriggers(
        resolver: resolver,
        targetResult: targetResult,
        critical: critical,
      );
    }
  }

  List<PassiveTriggeredExternalOutcome> collectTriggersForEvent(
    PassiveTriggerEvent event,
  ) {
    final outcomes = <PassiveTriggeredExternalOutcome>[];

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) continue;

      for (final trigger in passive.triggers) {
        if (trigger.event != event) continue;
        if (trigger.actions.isEmpty) continue;

        outcomes.add(
          PassiveTriggeredExternalOutcome(
            passiveId: passive.id,
            passiveName: passive.name,
            triggerId: trigger.id,
            targetId: 'self',
            targetLabel: character.name,
            savingThrow: trigger.savingThrow,
            usageLimit: trigger.usageLimit,
            actions: trigger.actions
                .map((action) => PassiveTriggerAction.fromMap(action.toMap()))
                .toList(),
          ),
        );
      }
    }
    return outcomes;
  }

  bool _passiveActionHasRollableDice(PassiveTriggerAction action) {
    if (action.hasDice) {
      return true;
    }

    final expression = action.valueFormula?.expression.trim() ?? '';
    if (expression.isEmpty) {
      return false;
    }

    // `PassiveTriggerAction.hasDice` only sees explicit DicePool entries.
    // Formulas such as "1d8 + con_mod" also need the physical/digital choice.
    return RegExp(
      r'(?:^|[^a-zA-Z0-9_])(?:[a-zA-Z_]\w*|\d+)?\s*\*?\s*\d*\s*d\s*\d+',
      caseSensitive: false,
    ).hasMatch(expression);
  }

  bool _passiveOutcomesHaveRollableDice(
    Iterable<PassiveTriggeredExternalOutcome> outcomes,
  ) {
    return outcomes.any(
      (outcome) => outcome.actions.any(_passiveActionHasRollableDice),
    );
  }

  Future<ActionDiceMode?> _choosePassiveDiceModeIfNeeded(
    BuildContext context,
    Iterable<PassiveTriggeredExternalOutcome> outcomes,
  ) async {
    if (!_passiveOutcomesHaveRollableDice(outcomes)) {
      return ActionDiceMode.digital;
    }

    if (!context.mounted) {
      return null;
    }

    return showActionDiceModeSheet(context);
  }

  Future<Set<String>?> _selectHealthPassiveTriggers(
    BuildContext context, {
    required bool isDamage,
    required bool lethalDamage,
    required List<PassiveTriggeredExternalOutcome> regularOutcomes,
    required List<PassiveTriggeredExternalOutcome> deathOutcomes,
  }) {
    final visibleOutcomes = <PassiveTriggeredExternalOutcome>[
      ...regularOutcomes,
      if (lethalDamage) ...deathOutcomes,
    ];

    // Todos empiezan marcados para conservar el comportamiento anterior, pero
    // el usuario puede decidir trigger por trigger cuáles quiere ejecutar.
    final selectedKeys = visibleOutcomes.map((o) => o.usageKey).toSet();

    return showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                lethalDamage
                    ? '¡Has caído en combate!'
                    : isDamage
                    ? 'Daño recibido y pasivas'
                    : 'Curación recibida y pasivas',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lethalDamage
                          ? 'Elige qué triggers quieres aplicar para este daño y la caída:'
                          : 'Elige qué triggers quieres aplicar:',
                    ),
                    const SizedBox(height: 10),
                    ...visibleOutcomes.map((o) {
                      final isDeathTrigger =
                          lethalDamage && deathOutcomes.contains(o);
                      final selected = selectedKeys.contains(o.usageKey);

                      return CheckboxListTile(
                        value: selected,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: Icon(
                          isDeathTrigger
                              ? Icons.warning_amber_rounded
                              : Icons.auto_awesome_rounded,
                        ),
                        title: Text(o.passiveName),
                        subtitle: Text(
                          '${isDeathTrigger ? 'Al morir' : isDamage ? 'Al recibir daño' : 'Al recibir curación'} · ${o.actions.length} acción(es)',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedKeys.add(o.usageKey);
                            } else {
                              selectedKeys.remove(o.usageKey);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, <String>{}),
                  child: const Text('Ignorar todas'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    Set<String>.from(selectedKeys),
                  ),
                  child: const Text('Aplicar seleccionadas'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _showPassiveTriggerResultsDialog(
    BuildContext context,
    List<PassiveTriggerExternalResult> results, {
    String title = 'Resultados de pasivas',
    List<String> summary = const [],
  }) async {
    if (results.isEmpty || !context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;

        Widget resultChip({
          required IconData icon,
          required String label,
          required Color background,
          required Color foreground,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.summarize_rounded,
                                size: 19,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Resumen',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          for (final line in summary)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(line),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  for (var i = 0; i < results.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  results[i].passiveName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (!results[i].changedAnything)
                                  Text(
                                    'Sin cambios.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (results[i].mitigation > 0)
                                        resultChip(
                                          icon: Icons.shield_rounded,
                                          label:
                                              'Mitigado ${results[i].mitigation}',
                                          background: colors.tertiaryContainer,
                                          foreground: colors.onTertiaryContainer,
                                        ),
                                      if (results[i].healing > 0)
                                        resultChip(
                                          icon: Icons.favorite_rounded,
                                          label:
                                              '+${results[i].healing} PV',
                                          background: colors.primaryContainer,
                                          foreground: colors.onPrimaryContainer,
                                        ),
                                      if (results[i].damage > 0)
                                        resultChip(
                                          icon: Icons.flash_on_rounded,
                                          label:
                                              '${results[i].damage} de daño',
                                          background: colors.errorContainer,
                                          foreground: colors.onErrorContainer,
                                        ),
                                      if (results[i].effects.isNotEmpty)
                                        resultChip(
                                          icon: Icons.auto_fix_high_rounded,
                                          label:
                                              '${results[i].effects.length} efecto${results[i].effects.length == 1 ? '' : 's'}',
                                          background:
                                              colors.secondaryContainer,
                                          foreground:
                                              colors.onSecondaryContainer,
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (results[i].breakdown.isNotEmpty) ...[
                            Divider(
                              height: 1,
                              color: colors.outlineVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            Theme(
                              data: theme.copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                leading: Icon(
                                  Icons.receipt_long_rounded,
                                  color: colors.onSurfaceVariant,
                                ),
                                title: const Text('Ver desglose'),
                                subtitle: Text(
                                  '${results[i].breakdown.length} detalle${results[i].breakdown.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHighest
                                          .withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (final line
                                            in results[i].breakdown)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 7,
                                                      ),
                                                  child: Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: colors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 9),
                                                Expanded(child: Text(line)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _consumePassiveResults(List<PassiveTriggerExternalResult> results) {
    final triggerEngine = PassiveTriggerEngine(character: character);
    for (final result in results) {
      triggerEngine.consumeExternalTriggerResult(result);
    }
  }

  Future<void> _applyDeathPassiveOutcomes(
    BuildContext context, {
    required ActionResolver resolver,
    required List<PassiveTriggeredExternalOutcome> deathTriggers,
    ActionDiceMode? diceMode,
  }) async {
    if (deathTriggers.isEmpty || !context.mounted) {
      return;
    }

    final resolvedDiceMode =
        diceMode ??
        await _choosePassiveDiceModeIfNeeded(context, deathTriggers);

    if (resolvedDiceMode == null || !context.mounted) {
      return;
    }

    final deathResolutionId =
        'death-${DateTime.now().microsecondsSinceEpoch}';
    final deathResults = await _resolvePassiveTriggeredExternalOutcomes(
      context,
      resolver: resolver,
      actionContext: ActionResolutionContext(
        character: character,
        targets: [ActionTarget(id: 'self', kind: ActionTargetKind.self)],
      ),
      outcomes: deathTriggers,
      diceMode: resolvedDiceMode,
      resolutionId: deathResolutionId,
    );

    if (deathResults == null) {
      return;
    }

    _consumePassiveResults(deathResults);

    for (final res in deathResults) {
      if (res.damage > 0) {
        character.takeDamage(res.damage, dispatchTriggers: false);
      }
      if (res.healing > 0) {
        character.heal(res.healing, dispatchTriggers: false);
      }
      for (final effect in res.effects) {
        character.applyReceivedEffect(
          effect,
          refreshTriggers: false,
          dispatchHealthTriggers: false,
        );
      }
    }

    character.refreshPassiveTriggers();

    if (context.mounted) {
      await _showPassiveTriggerResultsDialog(
        context,
        deathResults,
        title: 'Resultados de pasivas de muerte',
      );
    }
  }

  Future<bool> resolveHealthChange(
    BuildContext context, {
    required int baseAmount,
    required bool isDamage,
  }) async {
    final resolver = ActionResolver(character: character);
    final healthBefore = character.currentHealth;
    final event = isDamage
        ? PassiveTriggerEvent.damageReceived
        : PassiveTriggerEvent.healingReceived;

    final outcomes = collectTriggersForEvent(event);
    final deathTriggers = isDamage ? collectDeathTriggers() : const <PassiveTriggeredExternalOutcome>[];

    // Para daño manual podemos saber de antemano si el golpe base dejaría al
    // personaje a 0. En ese caso el diálogo de daño y el de muerte se unifican.
    final projectedLethal =
        isDamage && character.currentHealth - baseAmount <= 0;

    final confirmationOutcomes = <PassiveTriggeredExternalOutcome>[
      ...outcomes,
      if (projectedLethal) ...deathTriggers,
    ];

    var selectedOutcomes = List<PassiveTriggeredExternalOutcome>.from(
      confirmationOutcomes,
    );

    if (confirmationOutcomes.isNotEmpty) {
      if (!context.mounted) return false;

      final selectedKeys = await _selectHealthPassiveTriggers(
        context,
        isDamage: isDamage,
        lethalDamage: projectedLethal,
        regularOutcomes: outcomes,
        deathOutcomes: deathTriggers,
      );

      if (selectedKeys == null || !context.mounted) {
        return false;
      }

      selectedOutcomes = confirmationOutcomes
          .where((outcome) => selectedKeys.contains(outcome.usageKey))
          .toList();
    }

    final selectedRegularOutcomes = outcomes
        .where(
          (outcome) => selectedOutcomes.any(
            (selected) => selected.usageKey == outcome.usageKey,
          ),
        )
        .toList();

    final selectedDeathOutcomes = deathTriggers
        .where(
          (outcome) => selectedOutcomes.any(
            (selected) => selected.usageKey == outcome.usageKey,
          ),
        )
        .toList();

    ActionDiceMode? diceMode;
    if (selectedOutcomes.isNotEmpty) {
      diceMode = await _choosePassiveDiceModeIfNeeded(
        context,
        selectedOutcomes,
      );
      if (diceMode == null || !context.mounted) {
        return false;
      }
    } else {
      diceMode = ActionDiceMode.digital;
    }

    final resolutionId = 'health-${DateTime.now().microsecondsSinceEpoch}';
    List<PassiveTriggerExternalResult> triggerResults = const [];

    if (selectedRegularOutcomes.isNotEmpty) {
      final actionContext = ActionResolutionContext(
        character: character,
        targets: [ActionTarget(id: 'self', kind: ActionTargetKind.self)],
        externalVariables: {
          isDamage ? 'damage' : 'healing': baseAmount.toDouble(),
        },
      );

      final resolvedResults = await _resolvePassiveTriggeredExternalOutcomes(
        context,
        resolver: resolver,
        actionContext: actionContext,
        outcomes: selectedRegularOutcomes,
        diceMode: diceMode,
        resolutionId: resolutionId,
      );

      if (resolvedResults == null || !context.mounted) {
        return false;
      }

      triggerResults = resolvedResults;

      _consumePassiveResults(triggerResults);
    }

    int totalMitigation = 0;
    int extraHealing = 0;
    int extraDamage = 0;

    for (final res in triggerResults) {
      // Un trigger puede tener cualquier combinación de acciones. No debemos
      // descartar una curación solo porque el evento original sea daño, ni un
      // daño solo porque el evento original sea curación.
      if (isDamage) {
        totalMitigation += res.mitigation;
      }
      extraDamage += res.damage;
      extraHealing += res.healing;

      for (final effect in res.effects) {
        character.applyReceivedEffect(
          effect,
          refreshTriggers: false,
          dispatchHealthTriggers: false,
        );
      }
    }

    int appliedDamage = 0;
    int appliedHealing = 0;

    if (isDamage) {
      // La mitigación modifica únicamente el golpe que originó el evento.
      final int finalDamage = math.max(
        0,
        baseAmount - totalMitigation + extraDamage,
      );
      appliedDamage = finalDamage;
      if (finalDamage > 0) {
        character.takeDamage(finalDamage, dispatchTriggers: false);
      }

      // Las curaciones generadas por los triggers se aplican DESPUÉS del golpe.
      // Así una pasiva que cura al recibir daño no se desperdicia por estar el
      // personaje a vida máxima antes de recibir el impacto.
      if (extraHealing > 0) {
        final beforeTriggerHealing = character.currentHealth;
        character.heal(extraHealing, dispatchTriggers: false);
        appliedHealing += character.currentHealth - beforeTriggerHealing;
      }
    } else {
      final int finalHealing = baseAmount + extraHealing;
      if (finalHealing > 0) {
        final beforeHealing = character.currentHealth;
        character.heal(finalHealing, dispatchTriggers: false);
        appliedHealing += character.currentHealth - beforeHealing;
      }

      // También respetamos posibles acciones de daño disparadas por un trigger
      // de healingReceived.
      if (extraDamage > 0) {
        character.takeDamage(extraDamage, dispatchTriggers: false);
        appliedDamage += extraDamage;
      }
    }

    character.refreshPassiveTriggers();

    if (triggerResults.isNotEmpty && context.mounted) {
      final healthAfter = character.currentHealth;
      final summary = <String>[
        'PV: $healthBefore → $healthAfter',
        if (isDamage) 'Daño inicial: $baseAmount',
        if (!isDamage) 'Curación inicial: +$baseAmount',
        if (totalMitigation > 0) 'Mitigación total: -$totalMitigation',
        if (extraDamage > 0) 'Daño de pasivas: +$extraDamage',
        if (extraHealing > 0) 'Curación de pasivas: +$extraHealing',
        if (isDamage) 'Daño final aplicado: $appliedDamage',
        if (appliedHealing > 0) 'Curación real aplicada: +$appliedHealing',
      ];

      await _showPassiveTriggerResultsDialog(
        context,
        triggerResults,
        summary: summary,
      );
    }

    if (isDamage && character.currentHealth <= 0 && deathTriggers.isNotEmpty) {
      if (!context.mounted) return true;

      if (projectedLethal) {
        // Las pasivas de muerte ya estaban incluidas en la única confirmación.
        await _applyDeathPassiveOutcomes(
          context,
          resolver: resolver,
          deathTriggers: selectedDeathOutcomes,
          diceMode: diceMode,
        );
      } else {
        // Caso raro: el daño base no era letal, pero una pasiva añadió daño y
        // terminó provocando la caída. Aquí sí hace falta confirmar la muerte.
        await handleCharacterDeath(context, resolver: resolver);
      }
    }

    return true;
  }

  // Gestión de muerte para flujos donde la caída se descubre después de haber
  // resuelto una acción. La elección de dados ocurre DESPUÉS de pulsar aplicar.
  Future<void> handleCharacterDeath(
    BuildContext context, {
    required ActionResolver resolver,
  }) async {
    final deathTriggers = collectDeathTriggers();
    if (deathTriggers.isEmpty || !context.mounted) return;

    final selectedKeys = deathTriggers.map((o) => o.usageKey).toSet();

    final chosenKeys = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('¡Has caído en combate!'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elige qué triggers disponibles al morir quieres aplicar:',
                    ),
                    const SizedBox(height: 10),
                    ...deathTriggers.map((o) {
                      final selected = selectedKeys.contains(o.usageKey);
                      return CheckboxListTile(
                        value: selected,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                        title: Text(o.passiveName),
                        subtitle: Text(
                          'Al morir · ${o.actions.length} acción(es)',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedKeys.add(o.usageKey);
                            } else {
                              selectedKeys.remove(o.usageKey);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, <String>{}),
                  child: const Text('Ignorar todas'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    Set<String>.from(selectedKeys),
                  ),
                  child: const Text('Aplicar seleccionadas'),
                ),
              ],
            );
          },
        );
      },
    );

    if (chosenKeys == null || !context.mounted) return;

    final selectedDeathTriggers = deathTriggers
        .where((outcome) => chosenKeys.contains(outcome.usageKey))
        .toList();

    if (selectedDeathTriggers.isEmpty) return;

    await _applyDeathPassiveOutcomes(
      context,
      resolver: resolver,
      deathTriggers: selectedDeathTriggers,
    );
  }

  Future<ActionExecutionResult?> _commitResolution({
    required BuildContext context,
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionResolutionResult resolution,
    List<PassiveTriggerExternalResult> triggeredResults = const [],
    List<CharacterEffectTriggerExternalResult> effectTriggeredResults =
        const [],
  }) async {
    try {
      var execution = resolver.commitResolution(resolution);

      final triggerEngine = PassiveTriggerEngine(character: character);

      for (final result in triggeredResults) {
        triggerEngine.consumeExternalTriggerResult(result);
      }

      final effectTriggeredEngine = CharacterEffectTriggerEngine(
        character: character,
      );

      for (final result in effectTriggeredResults) {
        effectTriggeredEngine.consumeExternalTriggerResult(result);
      }

      execution = _mergePassiveTriggeredResults(
        execution: execution,
        triggeredResults: triggeredResults,
      );

      execution = _mergeEffectTriggeredResults(
        execution: execution,
        triggeredResults: effectTriggeredResults,
      );

      _dispatchPostResolutionTriggers(
        resolver: resolver,
        resolution: execution.resolution,
      );

      // =======================================================================
      // FLUJO INTERACTIVO DE MUERTE EN ACCIONES DIRECTAS
      // =======================================================================
      if (character.currentHealth <= 0) {
        final deathTriggers = collectDeathTriggers();
        if (deathTriggers.isNotEmpty) {
          if (!context.mounted) {
            return execution;
          }

          await handleCharacterDeath(
            context,
            resolver: resolver,
          );
        }
      }

      return execution;
    } on StateError catch (error) {
      if (!context.mounted) {
        return null;
      }

      _showError(context, error.message.toString());
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
