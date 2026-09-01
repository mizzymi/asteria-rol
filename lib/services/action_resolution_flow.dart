import 'package:flutter/material.dart';

import '../models/action_definition.dart';
import '../models/action_source.dart';
import '../models/weapon_attack_resolution.dart';
import '../models/healing_bonus.dart';
import '../models/character_effect_triggered_external_outcome.dart';
import '../models/character_effect_trigger_external_result.dart';
import '../models/damage_bonus.dart';
import '../models/action_apply_result.dart';
import '../models/action_hit_behavior.dart';
import '../models/dice_pool.dart';
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
import 'passive_trigger_engine.dart';
import 'action_dice_resolver.dart';
import 'passive_action_resolver.dart';
import 'weapon_action_resolver.dart';
import 'action_resolver.dart';
import 'action_cost_resolver.dart';

class ActionResolutionFlow {
  final Character character;

  const ActionResolutionFlow({required this.character});

  String get selfLabel {
    return character.name.isNotEmpty ? character.name : 'Tu personaje';
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
      // =========================================================================
      // SALVACIÓN
      // =========================================================================

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

        final answers = await showExternalSavingThrowResultsDialog(
          context,
          requests: [request],
        );

        if (answers == null || !context.mounted) {
          return null;
        }

        saved = answers[request.id] ?? false;

        // Salvación exitosa que anula todo.
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

      // =========================================================================
      // ACCIONES
      // =========================================================================

      var damage = 0;
      var healing = 0;

      final effects = <CharacterEffect>[];

      for (final action in outcome.actions) {
        switch (action.type) {
          // =====================================================================
          // DAÑO
          // =====================================================================

          case PassiveTriggerActionType.dealDamage:
            final amount = await _resolvePassiveTriggerActionAmount(
              context,
              resolver: resolver,
              passive: passive,
              target: target,
              actionContext: actionContext,
              action: action,
              diceMode: diceMode,
            );

            if (amount == null) {
              return null;
            }

            damage += amount;

            break;

          // =====================================================================
          // CURACIÓN
          // =====================================================================

          case PassiveTriggerActionType.heal:
            final amount = await _resolvePassiveTriggerActionAmount(
              context,
              resolver: resolver,
              passive: passive,
              target: target,
              actionContext: actionContext,
              action: action,
              diceMode: diceMode,
            );

            if (amount == null) {
              return null;
            }

            healing += amount;

            break;

          // =====================================================================
          // APLICAR EFECTO
          // =====================================================================

          case PassiveTriggerActionType.applyEffect:
            final effectId = action.effectId?.trim();

            if (effectId == null || effectId.isEmpty) {
              break;
            }

            // ===========================================================================
            // ENCONTRAR EFECTO VINCULADO
            // ===========================================================================

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

            // ===========================================================================
            // COPIA PARA EL RESULTADO EXTERNO
            // ===========================================================================

            final copy = CharacterEffect.fromMap(template.toMap());

            copy.resetDuration();

            effects.add(copy);

            break;

          // =====================================================================
          // NO TIENEN SENTIDO SOBRE OTRO CHARACTER EN ESTE PIPELINE
          // =====================================================================

          case PassiveTriggerActionType.addResource:
          case PassiveTriggerActionType.subtractResource:
          case PassiveTriggerActionType.setResource:
          case PassiveTriggerActionType.addCharge:
          case PassiveTriggerActionType.subtractCharge:
          case PassiveTriggerActionType.removeEffect:
          case PassiveTriggerActionType.incrementCounter:
          case PassiveTriggerActionType.setCounter:
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
          damage: damage,
          healing: healing,
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
  }) async {
    // ===========================================================================
    // FÓRMULA
    // ===========================================================================

    final modifier = resolver.passiveTriggerActionModifier(
      passive: passive,
      action: action,
      context: actionContext,
      target: target,
    );

    // ===========================================================================
    // SIN DADOS
    // ===========================================================================

    if (!action.hasDice) {
      return modifier;
    }

    // ===========================================================================
    // REQUEST
    // ===========================================================================

    final request = ActionDiceRequest(
      parts: [
        ActionDiceRequestPart(
          id: 'passive-trigger-action',

          effectId: 'passive-trigger',

          effectName: 'Trigger de ${passive.name}',

          effectType: action.type == PassiveTriggerActionType.heal
              ? AbilityEffectType.healing
              : AbilityEffectType.damage,

          dicePools: List<DicePool>.unmodifiable(action.dicePools),

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

      return result.parts.fold<int>(0, (sum, part) => sum + part.total);
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

    return result.parts.fold<int>(0, (sum, part) => sum + part.total);
  }

  Future<PassiveRollResolution?> resolvePassiveRoll(
    BuildContext context, {
    required CharacterPassive passive,
  }) async {
    final resolver = PassiveActionResolver(character: character);

    // ===========================================================================
    // MODO DE DADOS
    // ===========================================================================

    final diceMode = await showActionDiceModeSheet(context);

    if (diceMode == null || !context.mounted) {
      return null;
    }

    final request = resolver.buildRollRequest(passive);

    final calculationText = request.parts.isEmpty
        ? '0'
        : request.parts.first.calculationText;

    // ===========================================================================
    // RESOLVER
    // ===========================================================================

    switch (diceMode) {
      // -------------------------------------------------------------------------
      // DIGITAL
      // -------------------------------------------------------------------------

      case ActionDiceMode.digital:
        final diceResult = resolver.resolveDigitalRequest(request);

        return PassiveRollResolution(
          diceResult: diceResult,
          calculationText: calculationText,
        );

      // -------------------------------------------------------------------------
      // FÍSICO
      // -------------------------------------------------------------------------

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

  CharacterAbility _weaponActionAbility(Weapon weapon) {
    return CharacterAbility(
      id: 'weapon:${weapon.id}',
      name: weapon.name,
      abilityType: weapon.attackAbility,
      requiresAttackRoll: true,
      targetType: AbilityTargetType.external,
      targetResolutionMode: AbilityTargetResolutionMode.shared,
      effects: const [],
    );
  }

  Future<ActionExecutionResult?> resolveWeapon(
    BuildContext context, {
    required Weapon weapon,
  }) async {
    final weaponResolver = WeaponActionResolver(character: character);

    final actionResolver = ActionResolver(character: character);

    // ===========================================================================
    // 1. TARGET
    // ===========================================================================

    final targets = await showActionTargetSelector(
      context,
      targetType: AbilityTargetType.external,
      selfLabel: selfLabel,
    );

    if (targets == null || !context.mounted) {
      return null;
    }

    if (targets.isEmpty) {
      return null;
    }

    // ===========================================================================
    // IMPORTANTE
    //
    // WeaponActionResolver todavía evalúa fórmulas/condiciones contra
    // _targetForContext(), es decir, el primer target.
    //
    // Hasta completar 7B no permitimos resolución multi-target de armas.
    // ===========================================================================

    if (targets.length != 1) {
      _showError(
        context,
        'Los ataques de arma todavía requieren un único objetivo.',
      );

      return null;
    }

    final target = targets.first;

    final actionContext = ActionResolutionContext(
      character: character,
      targets: [target],
    );

    actionContext.populateKnownTargetVariables();

    // ===========================================================================
    // 2. REQUIREMENTS
    // ===========================================================================

    final requirements = weaponResolver
        .orderedPreResolutionExternalRequirementsForTarget(
          weapon: weapon,
          context: actionContext,
          target: target,
        );

    for (final requirement in requirements) {
      final answers = await showExternalRequirementsDialog(
        context,
        targetLabel: target.label ?? 'Objetivo',
        requirements: [requirement],
        knownAnswers: const {},
      );

      if (answers == null || !context.mounted) {
        return null;
      }

      final answer = answers[requirement.normalizedVariableName];

      if (answer == null) {
        continue;
      }

      actionResolver.applyExternalRequirementAnswer(
        context: actionContext,
        target: target,
        requirement: requirement,
        answer: answer,
      );
    }

    // ===========================================================================
    // 3. OPCIONALES
    // ===========================================================================

    final optionalGroups = weaponResolver.availableOptionalGroups(
      weapon: weapon,
      context: actionContext,
    );

    if (optionalGroups.isNotEmpty) {
      final entries = [
        for (final group in optionalGroups)
          OptionalChoiceEntry(
            group: group,
            target: null,
            validation: ActionCostResolver(
              character: character,
            ).validate(group.costs),
          ),
      ];

      final selections = await showOptionalChoicesDialog(
        context,
        entries: entries,
        selfLabel: selfLabel,
      );

      if (selections == null || !context.mounted) {
        return null;
      }

      for (final entry in entries) {
        actionContext.setOptionalGroupSelected(
          entry.group.id,
          selections[entry.key] ?? false,
        );
      }
    }

    // ===========================================================================
    // COSTES POTENCIALES
    //
    // Todavía no sabemos hit/miss.
    // Validamos que el personaje podría pagar todos los bonuses seleccionados.
    // ===========================================================================

    final potentialCosts = weaponResolver.collectPotentialDamageBonusCosts(
      context: actionContext,
    );

    final costResolver = ActionCostResolver(character: character);

    final costValidation = costResolver.validate(potentialCosts);

    if (!costValidation.valid) {
      _showError(
        context,
        costValidation.error ?? 'No puedes pagar los costes de este ataque.',
      );

      return null;
    }

    // ===========================================================================
    // 4. MODO DE DADOS
    // ===========================================================================

    final diceMode = await showActionDiceModeSheet(context);

    if (diceMode == null || !context.mounted) {
      return null;
    }

    // ===========================================================================
    // 5. VENTAJA / DESVENTAJA
    // ===========================================================================

    final attackMode = await showAttackRollModeSheet(context);

    if (attackMode == null || !context.mounted) {
      return null;
    }

    // ===========================================================================
    // 6. ATAQUE
    // ===========================================================================

    final WeaponAttackResolution weaponAttack;

    switch (diceMode) {
      case ActionDiceMode.digital:
        weaponAttack = weaponResolver.rollAttackDigital(
          weapon: weapon,
          mode: attackMode,
        );

        break;

      case ActionDiceMode.physical:
        final rolls = await showPhysicalAttackRollDialog(
          context,
          mode: attackMode,
        );

        if (rolls == null || !context.mounted) {
          return null;
        }

        weaponAttack = weaponResolver.resolveAttackPhysical(
          weapon: weapon,
          mode: attackMode,
          firstRoll: rolls.firstRoll,
          secondRoll: rolls.secondRoll,
        );

        break;
    }

    final attackResult = weaponAttack.attackResult;

    // ===========================================================================
    // 7. HIT / MISS DEL TARGET
    // ===========================================================================

    final attackResults = await showAttackTargetsDialog(
      context,
      targets: [target],
      attackResult: attackResult,
      selfLabel: selfLabel,
      ability: weapon.attackAbility,
    );

    if (attackResults == null || !context.mounted) {
      return null;
    }

    final targetAttackResult = attackResults[target.id];

    if (targetAttackResult == null) {
      return null;
    }

    final resolvedCosts = weaponResolver.collectResolvedDamageBonusCosts(
      context: actionContext,
      hit: targetAttackResult.hit,
    );

    final finalCostValidation = ActionCostResolver(
      character: character,
    ).validate(resolvedCosts);

    if (!finalCostValidation.valid) {
      _showError(
        context,
        finalCostValidation.error ??
            'Ya no puedes pagar los costes de este ataque.',
      );

      return null;
    }

    // ===========================================================================
    // 8. TIPO DE CRÍTICO
    // ===========================================================================

    final criticalType = attackResult.criticalType;

    // ===========================================================================
    // 9. CHANCE CHECKS DE CRÍTICO
    // ===========================================================================

    final chanceChecks = weaponResolver.collectCriticalChanceChecks(
      weapon: weapon,
      criticalType: criticalType,
      context: actionContext,
    );

    List<ActionChanceResult> chanceResults = const [];

    if (chanceChecks.isNotEmpty) {
      switch (diceMode) {
        case ActionDiceMode.digital:
          chanceResults = actionResolver.resolveChanceChecksDigital(
            checks: chanceChecks,
          );

          break;

        case ActionDiceMode.physical:
          final inputs = await showPhysicalChanceChecksDialog(
            context,
            checks: chanceChecks,
          );

          if (inputs == null || !context.mounted) {
            return null;
          }

          final rollsByCheckId = {
            for (final input in inputs) input.checkId: input.roll,
          };

          chanceResults = actionResolver.resolveChanceChecksPhysical(
            checks: chanceChecks,
            rollsByCheckId: rollsByCheckId,
          );

          break;
      }
    }

    final successfulChanceIds = actionResolver.successfulChanceCheckIds(
      chanceResults,
    );

    // ===========================================================================
    // 10. REQUEST DE DAÑO
    // ===========================================================================

    final request = weaponResolver.buildDamageRequest(
      weapon: weapon,
      criticalType: criticalType,
      context: actionContext,
      successfulChanceCheckIds: successfulChanceIds,
    );

    // ===========================================================================
    // 11. DADOS
    // ===========================================================================

    final ActionDiceResult diceResult;

    switch (diceMode) {
      case ActionDiceMode.digital:
        diceResult = weaponResolver.resolveDamageDigitalRequest(request);

        break;

      case ActionDiceMode.physical:
        final sections = <PhysicalDiceSection>[];

        if (request.parts.any((part) => part.requiresRoll)) {
          sections.add(
            PhysicalDiceSection(
              id: 'weapon:${weapon.id}',
              title: weapon.name,
              request: request,
            ),
          );
        }

        Map<String, List<ActionPhysicalDiceInput>> inputsBySection = const {};

        if (sections.isNotEmpty) {
          final inputs = await showPhysicalDiceDialog(
            context,
            sections: sections,
          );

          if (inputs == null || !context.mounted) {
            return null;
          }

          inputsBySection = inputs;
        }

        diceResult = weaponResolver.resolveDamagePhysicalRequest(
          request: request,
          inputs: inputsBySection['weapon:${weapon.id}'] ?? const [],
        );

        break;
    }

    // ===========================================================================
    // 12. HIT GATE
    //
    // El request puede contener componentes ignoreHit.
    // Por tanto NO podemos simplemente poner daño 0 si falla.
    // Filtramos cada parte según su propio hitBehavior.
    // ===========================================================================

    final syntheticAbility = _weaponActionAbility(weapon);

    final targetResult = actionResolver.buildTargetResult(
      ability: syntheticAbility,
      target: target,
      diceResult: diceResult,
      attackResult: targetAttackResult,
    );

    // ===========================================================================
    // 14. RESULTADO DEL ACTION ENGINE
    // ===========================================================================

    final source = ActionSource.weapon(weapon);

    final definition = ActionDefinition.fromWeapon(weapon);

    final resolution = actionResolver.buildDirectResolutionResult(
      source: source,

      ability: syntheticAbility,

      targetResolutionMode: AbilityTargetResolutionMode.shared,

      targetResults: [targetResult],

      attackResult: attackResult,

      criticalProfile: attackResult.criticalProfile,

      chanceResults: chanceResults,

      selectedOptionalGroupIds: actionContext.selectedOptionalGroupIds,

      selectedOptionalGroupIdsByTargetId:
          actionContext.selectedOptionalGroupIdsByTargetId,

      preResolutionExternalVariablesByTargetId: actionContext
          .snapshotTargetExternalVariables(),

      externalVariablesByTargetId: actionContext
          .snapshotTargetExternalVariables(),

      costs: resolvedCosts,
    );

    // ===========================================================================
    // 15. FINALIZACIÓN COMÚN
    //
    // No llamamos directamente commitResolution.
    //
    // Queremos:
    // - triggers externos
    // - consumo de usage limits
    // - merge de outcomes
    // - dispatch post-resolution
    //
    // exactamente igual que una habilidad.
    // ===========================================================================

    final prepared = actionResolver.prepareDirectAction(
      source: source,

      definition: definition,

      ability: syntheticAbility,

      context: actionContext,

      criticalProfile: attackResult.criticalProfile,

      costs: resolvedCosts,
    );

    return _finalizeResolution(
      context,
      resolver: actionResolver,
      prepared: prepared,
      resolution: resolution,
      diceMode: diceMode,
    );
  }

  // ===========================================================================
  // ENTRY POINT
  // ===========================================================================

  Future<ActionExecutionResult?> resolveAbility(
    BuildContext context, {
    required CharacterAbility ability,
  }) async {
    final resolver = ActionResolver(character: character);

    try {
      resolver.validatePassiveTriggerTargetScopes(ability: ability);
    } on StateError catch (error) {
      _showError(context, error.message.toString());

      return null;
    }

    // -------------------------------------------------------------------------
    // TARGETS
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // CONDICIONES EXTERNAS
    // -------------------------------------------------------------------------

    final requirementsCompleted = await _collectExternalRequirements(
      context,
      resolver: resolver,
      ability: ability,
      actionContext: actionContext,
    );

    if (!requirementsCompleted || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // PLAN
    // -------------------------------------------------------------------------

    final initialPlan = resolver.prepareAbilityPlan(
      ability: ability,
      context: actionContext,
    );

    // -------------------------------------------------------------------------
    // OPCIONALES
    // -------------------------------------------------------------------------

    final optionalCompleted = await _collectOptionalChoices(
      context,
      resolver: resolver,
      plan: initialPlan,
      actionContext: actionContext,
    );

    if (!optionalCompleted || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // PREPARED
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // COSTES
    //
    // Solo validamos.
    // El pago ocurre exclusivamente en commitResolution().
    // -------------------------------------------------------------------------

    final validation = resolver.validatePreparedActionCosts(prepared);

    if (!validation.valid) {
      _showError(
        context,
        validation.error ?? 'No puedes pagar los costes de esta acción.',
      );

      return null;
    }

    // -------------------------------------------------------------------------
    // MODO DE DADOS
    //
    // Solo preguntamos físico/digital si realmente hay algo que tirar.
    // -------------------------------------------------------------------------

    ActionDiceMode diceMode = ActionDiceMode.digital;

    final requiresDiceMode = resolver.preparedActionRequiresDiceMode(prepared);

    if (requiresDiceMode) {
      final selectedDiceMode = await showActionDiceModeSheet(context);

      if (selectedDiceMode == null || !context.mounted) {
        return null;
      }

      diceMode = selectedDiceMode;
    }

    // -------------------------------------------------------------------------
    // ATAQUE
    // -------------------------------------------------------------------------

    if (ability.requiresAttackRoll) {
      return _resolveAttack(
        context,
        resolver: resolver,
        prepared: prepared,
        diceMode: diceMode,
      );
    }

    // -------------------------------------------------------------------------
    // SIN ATAQUE
    // -------------------------------------------------------------------------

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

      // =========================================================================
      // TARGET NUEVO
      // =========================================================================

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

      // =========================================================================
      // TARGET EXISTENTE
      // =========================================================================

      final current = outcomes[index];

      outcomes[index] = ExternalTargetOutcome(
        targetId: current.targetId,

        targetLabel: current.targetLabel ?? triggered.targetLabel,

        damage: current.damage + triggered.damage,

        healing: current.healing + triggered.healing,

        effects: current.effects,

        passiveEffects: [...current.passiveEffects, ...triggered.effects],

        // Trigger procedente de PASIVA
        triggerResults: [...current.triggerResults, triggered],

        // Solo conservar los triggers procedentes de CharacterEffect
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

      // =========================================================================
      // TARGET NUEVO
      // =========================================================================

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

      // =========================================================================
      // TARGET EXISTENTE
      // =========================================================================

      final current = outcomes[index];

      outcomes[index] = ExternalTargetOutcome(
        targetId: current.targetId,

        targetLabel: current.targetLabel ?? triggered.targetLabel,

        damage: current.damage + triggered.damage,

        healing: current.healing + triggered.healing,

        effects: current.effects,

        passiveEffects: [...current.passiveEffects, ...triggered.effects],

        // Conservar triggers de PASIVAS
        triggerResults: current.triggerResults,

        // Añadir trigger procedente de EFFECT
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
    // ===========================================================================
    // REQUIREMENTS POST-RESOLUTION
    //
    // Todavía NO hemos:
    // - pagado costes
    // - aplicado resultado
    // - disparado triggers post
    //
    // Así cancelar aquí sigue cancelando TODA la acción.
    // ===========================================================================

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
        // =======================================================================
        // SIN LÍMITE
        // =======================================================================

        if (candidate.usageLimit == TriggerUsageLimit.unlimited) {
          triggeredOutcomes.add(candidate);

          continue;
        }

        // =======================================================================
        // LIMITADO
        //
        // oncePerTurn / oncePerRound solo puede reservarse una vez
        // dentro de esta resolución.
        // =======================================================================

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

    // ===========================================================================
    // TRIGGERS PROCEDENTES DE CHARACTER EFFECTS
    // ===========================================================================

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

    // ===========================================================================
    // REFRESCAR SNAPSHOT
    //
    // El resultado inicial se construyó antes de las respuestas post.
    // ===========================================================================

    final finalResolution = resolution.copyWith(
      externalVariablesByTargetId: prepared.context
          .snapshotTargetExternalVariables(),
    );

    // ===========================================================================
    // COMMIT REAL
    // ===========================================================================

    return _commitResolution(
      context: context,
      resolver: resolver,
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

      // =======================================================================
      // EFECTOS
      // =======================================================================

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
    // ===========================================================================
    // CONTEXTO / MODIFICADOR
    // ===========================================================================

    final formulaContext = actionContext.buildFormulaContext(target: target);

    final modifier = character.damageBonusModifier(
      bonus,
      formulaContext: formulaContext,
    );

    // ===========================================================================
    // REQUEST
    //
    // El mismo request se utiliza para físico y digital.
    // ===========================================================================

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

    // ===========================================================================
    // DIGITAL
    // ===========================================================================

    if (diceMode == ActionDiceMode.digital) {
      final result = const ActionDiceResolver().rollDigital(request);

      return result.parts.fold<int>(0, (sum, part) => sum + part.total);
    }

    // ===========================================================================
    // FÍSICO
    // ===========================================================================

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
    // ===========================================================================
    // CONTEXTO / MODIFICADOR
    // ===========================================================================

    final formulaContext = actionContext.buildFormulaContext(target: target);

    final modifier = character.healingBonusModifier(
      bonus,
      formulaContext: formulaContext,
    );

    // ===========================================================================
    // REQUEST
    // ===========================================================================

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

    // ===========================================================================
    // DIGITAL
    // ===========================================================================

    if (diceMode == ActionDiceMode.digital) {
      final result = const ActionDiceResolver().rollDigital(request);

      return result.parts.fold<int>(0, (sum, part) => sum + part.total);
    }

    // ===========================================================================
    // FÍSICO
    // ===========================================================================

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
    // ===========================================================================
    // POST-RESOLUTION
    //
    // Se procesa únicamente para targets externos que realmente
    // produjeron eventos post-resolution.
    // ===========================================================================

    for (final targetResult in resolution.externalTargetResults) {
      final events = resolver.postResolutionEventsForTarget(targetResult);

      if (events.isEmpty) {
        continue;
      }

      final target = targetResult.target;

      // =======================================================================
      // INVALIDAR ESTADO CURRENT
      //
      // Después de daño/curación ya no podemos reutilizar como "current"
      // la información recogida antes de resolver la acción.
      //
      // El snapshot BEFORE permanece intacto.
      // =======================================================================

      prepared.context.clearTargetCurrentHealthKnowledge(target);

      final requirements = resolver
          .orderedPostResolutionExternalRequirementsForTarget(
            ability: prepared.ability,
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

  // ===========================================================================
  // SIN ATAQUE
  // ===========================================================================

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

    if (resolution == null) {
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

  // ===========================================================================
  // ATAQUE
  // ===========================================================================

  Future<ActionExecutionResult?> _resolveAttack(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
  }) async {
    // -------------------------------------------------------------------------
    // VENTAJA / DESVENTAJA
    // -------------------------------------------------------------------------

    final attackMode = await showAttackRollModeSheet(context);

    if (attackMode == null || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // D20
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // HIT / MISS
    // -------------------------------------------------------------------------

    final attackResults = await showAttackTargetsDialog(
      context,
      targets: prepared.context.targets,
      attackResult: attackResult,
      selfLabel: selfLabel,
      ability: prepared.ability.abilityType,
    );

    if (attackResults == null || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // SALVACIONES
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // RESOLUCIÓN
    // -------------------------------------------------------------------------

    final resolution = await _resolvePrepared(
      context,
      resolver: resolver,
      prepared: prepared,
      attackResult: attackResult,
      attackResultsByTargetId: attackResults,
      savingThrowResults: saves,
      diceMode: diceMode,
    );

    if (resolution == null) {
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

  // ===========================================================================
  // D20 ATAQUE
  // ===========================================================================

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

  // ===========================================================================
  // RESOLUCIÓN PREPARADA
  // ===========================================================================

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

    // ===========================================================================
    // SCOPES
    //
    // El Resolver decide cuántas resoluciones existen.
    //
    // El Flow no necesita saber si son:
    // - shared
    // - independent
    // ===========================================================================

    final scopes = resolver.preparedResolutionScopes(prepared);

    // ===========================================================================
    // CHANCE CHECKS
    // ===========================================================================

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
        // -----------------------------------------------------------------------
        // DIGITAL
        // -----------------------------------------------------------------------

        case ActionDiceMode.digital:
          chanceResultsByScopeId[scope.id] = resolver
              .resolveChanceChecksDigital(checks: checks);

          break;

        // -----------------------------------------------------------------------
        // FÍSICO
        // -----------------------------------------------------------------------

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

    // ===========================================================================
    // REQUESTS
    // ===========================================================================

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

    // ===========================================================================
    // DADOS
    // ===========================================================================

    final diceResultsByScopeId = <String, ActionDiceResult>{};

    switch (diceMode) {
      // =========================================================================
      // DIGITAL
      // =========================================================================

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

      // =========================================================================
      // FÍSICO
      // =========================================================================

      case ActionDiceMode.physical:
        final sections = <PhysicalDiceSection>[];

        for (final scope in scopes) {
          final request = requestsByScopeId[scope.id];

          if (request == null) {
            continue;
          }

          // No pedimos dados cuyo valor ya sea automático.
          if (!request.parts.any((part) => part.requiresRoll)) {
            continue;
          }

          final target = scope.target;

          sections.add(
            PhysicalDiceSection(
              id: scope.id,
              title: target == null
                  ? prepared.ability.name
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

    // ===========================================================================
    // RESULTADO
    //
    // A partir de aquí el Flow ya no conoce la estrategia de resolución.
    // ===========================================================================

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

  // ===========================================================================
  // SALVACIONES
  // ===========================================================================

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
        // -----------------------------------------------------------------------
        // SELF FÍSICO
        // -----------------------------------------------------------------------

        case ActionDiceMode.physical:
          final inputs = await showPhysicalSavingThrowsDialog(
            context,
            requests: selfRequests,
          );

          if (inputs == null || !context.mounted) {
            // Cancelar aquí cancela TODA
            // la acción.
            return null;
          }

          results.addAll(
            resolver.resolvePhysicalSavingThrows(
              requests: selfRequests,
              inputs: inputs,
            ),
          );

          break;

        // -----------------------------------------------------------------------
        // SELF DIGITAL
        // -----------------------------------------------------------------------

        case ActionDiceMode.digital:
          results.addAll(
            resolver.resolveDigitalSavingThrows(requests: selfRequests),
          );

          break;
      }
    }

    // ===========================================================================
    // EXTERNOS
    //
    // No conocemos sus stats ni su tirada.
    // Solo preguntamos si superaron la salvación.
    // ===========================================================================

    if (externalRequests.isNotEmpty) {
      final externalAnswers = await showExternalSavingThrowResultsDialog(
        context,
        requests: externalRequests,
      );

      if (externalAnswers == null || !context.mounted) {
        // Cancelar aquí cancela TODA
        // la acción.
        return null;
      }

      results.addAll(
        resolver.resolveExternalSavingThrowResults(
          requests: externalRequests,
          resultsByRequestId: externalAnswers,
        ),
      );
    }

    final immutableResults = List<ActionSavingThrowResult>.unmodifiable(
      results,
    );

    return immutableResults;
  }

  // ===========================================================================
  // EXTERNAL REQUIREMENTS
  // ===========================================================================

  Future<bool> _collectExternalRequirements(
    BuildContext context, {
    required ActionResolver resolver,
    required CharacterAbility ability,
    required ActionResolutionContext actionContext,
  }) async {
    // ===========================================================================
    // REQUIREMENTS PRE-RESOLUTION POR TARGET
    //
    // El Resolver decide:
    // - qué requirements existen,
    // - cuáles ya conoce,
    // - cuáles puede inferir,
    // - cuáles realmente necesitan pregunta.
    //
    // El Flow únicamente muestra UI y registra la respuesta.
    // ===========================================================================

    for (final target in actionContext.targets) {
      final requirements = resolver
          .orderedPreResolutionExternalRequirementsForTarget(
            ability: ability,
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

  // ===========================================================================
  // OPCIONALES
  // ===========================================================================

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

  // ===========================================================================
  // COMMIT
  // ===========================================================================
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

  ActionExecutionResult? _commitResolution({
    required BuildContext context,
    required ActionResolver resolver,
    required ActionResolutionResult resolution,

    List<PassiveTriggerExternalResult> triggeredResults = const [],

    List<CharacterEffectTriggerExternalResult> effectTriggeredResults =
        const [],
  }) {
    try {
      var execution = resolver.commitResolution(resolution);

      // =========================================================================
      // CONSUMIR USOS DE TRIGGERS EXTERNOS
      //
      // Solo llegamos aquí después de un commit exitoso.
      // =========================================================================

      final triggerEngine = PassiveTriggerEngine(character: character);

      for (final result in triggeredResults) {
        triggerEngine.consumeExternalTriggerResult(result);
      }

      final effectTriggerEngine = CharacterEffectTriggerEngine(
        character: character,
      );

      for (final result in effectTriggeredResults) {
        effectTriggerEngine.consumeExternalTriggerResult(result);
      }

      // =========================================================================
      // FUSIONAR RESULTADOS
      // =========================================================================

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

      return execution;
    } on StateError catch (error) {
      _showError(context, error.message.toString());

      return null;
    }
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
