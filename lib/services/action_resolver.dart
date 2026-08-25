import '../models/skill.dart';
import '../models/action_optional_group.dart';
import '../models/action_cost.dart';
import '../models/action_dice_result.dart';
import '../models/ability.dart';
import '../models/ability_effect_part.dart';
import '../models/action_external_requirement.dart';
import '../models/action_resolution_context.dart';
import '../models/action_resolution_plan.dart';
import '../models/character.dart';
import '../models/action_dice_request.dart';
import '../models/action_attack_result.dart';
import '../models/action_critical_profile.dart';
import '../models/dice_pool.dart';
import '../models/action_chance_check.dart';
import '../models/action_resolution_result.dart';
import '../models/action_target_result.dart';
import '../models/prepared_action_resolution.dart';
import '../models/action_execution_result.dart';
import '../models/action_saving_throw.dart';
import '../models/action_effect_result.dart';
import '../models/passive.dart';

import 'action_result_applier.dart';
import 'action_chance_resolver.dart';
import 'action_cost_resolver.dart';
import 'action_dice_resolver.dart';

class ActionResolver {
  final Character character;

  const ActionResolver({required this.character});

  List<ActionSavingThrowRequest> collectSavingThrowRequests({
    required PreparedActionResolution prepared,
  }) {
    final requests = <ActionSavingThrowRequest>[];

    for (final target in prepared.context.targets) {
      final selected = selectedParts(
        plan: prepared.plan,
        context: prepared.context,
        target: target,
      );

      for (final effect in prepared.ability.effects) {
        if (!effect.usesSavingThrow) {
          continue;
        }

        final hasSelectedPart = effect.parts.any(selected.contains);

        final hasExtra =
            effect.dicePools.isNotEmpty ||
            effect.abilityModifierMultipliers.values.any(
              (value) => value != 0,
            ) ||
            effect.effectBonus != 0 ||
            effect.legacyAddAbilityModifier;

        if (!hasSelectedPart && !hasExtra) {
          continue;
        }

        requests.add(
          ActionSavingThrowRequest(
            id: '${target.id}:${effect.id}',
            targetId: target.id,
            effectId: effect.id,
            effectName: effect.name,
            ability: effect.savingThrowAbility,
            dc: character.abilityEffectSaveDc(prepared.ability, effect),
            successEffect: effect.saveSuccessEffect,
          ),
        );
      }
    }

    return List.unmodifiable(requests);
  }

  PreparedActionResolution prepareAbilityAction({
    required CharacterAbility ability,
    required ActionResolutionContext context,
    Iterable<int> criticalMinimumRollSources = const [],
    bool forcedCritical = false,
    bool empoweredCritical = false,
  }) {
    final plan = prepareAbility(ability: ability, context: context);

    final sources = criticalMinimumRollSources.isEmpty
        ? character.criticalMinimumRollSourcesForAbility(ability)
        : criticalMinimumRollSources;

    final criticalProfile = buildCriticalProfile(
      minimumRollSources: sources,
      forcedCritical: forcedCritical,
      empowered: empoweredCritical,
    );

    final costResolver = ActionCostResolver(character: character);

    final costs = <ActionCost>[
      ...costResolver.costsForAbility(ability.id),

      ...collectSelectedPartCosts(plan: plan, context: context),
    ];

    return PreparedActionResolution(
      ability: ability,
      context: context,
      plan: plan,
      criticalProfile: criticalProfile,
      costs: List.unmodifiable(costs),
    );
  }

  ActionCostValidationResult validatePreparedActionCosts(
    PreparedActionResolution prepared,
  ) {
    final resolver = ActionCostResolver(character: character);

    return resolver.validate(prepared.costs);
  }

  ActionAttackResult? resolvePreparedAttack({
    required PreparedActionResolution prepared,
    required int? naturalRoll,
    required int modifier,
  }) {
    if (!prepared.ability.requiresAttackRoll) {
      return null;
    }

    if (naturalRoll == null) {
      throw StateError('La habilidad requiere una tirada de ataque.');
    }

    return resolveAttackRoll(
      naturalRoll: naturalRoll,
      modifier: modifier,
      criticalProfile: prepared.criticalProfile,
    );
  }

  bool preparedActionIsCritical({
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
  }) {
    if (attackResult != null) {
      return attackResult.critical;
    }

    return prepared.criticalProfile.forcedCritical;
  }

  List<ActionChanceCheck> collectCriticalChanceChecks({
    required bool critical,
  }) {
    if (!critical) {
      return const [];
    }

    final checks = <ActionChanceCheck>[];

    for (final bonus in character.activeCriticalDamageBonuses()) {
      if (!bonus.canTrigger) {
        continue;
      }

      if (bonus.alwaysTriggers) {
        continue;
      }

      checks.add(
        ActionChanceCheck(
          id: 'critical_bonus:${bonus.id}',
          label: bonus.name.isNotEmpty ? bonus.name : 'Daño crítico adicional',
          chancePercent: bonus.chancePercent,
        ),
      );
    }

    return checks;
  }

  ActionResolutionResult buildSharedResolutionResult({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionDiceResult diceResult,
    required ActionCriticalProfile criticalProfile,
    ActionAttackResult? attackResult,
    List<ActionChanceResult> chanceResults = const [],
    List<ActionCost> costs = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
  }) {
    final linkedEffects = _abilityLinkedEffectResults(plan.ability);

    final targetResults = context.targets
        .map(
          (target) => ActionTargetResult(
            target: target,
            diceResult: diceResult,

            savingThrows: savingThrowResults
                .where((result) => result.request.targetId == target.id)
                .toList(growable: false),

            effects: linkedEffects,
          ),
        )
        .toList(growable: false);

    return ActionResolutionResult(
      ability: plan.ability,
      targetResolutionMode: AbilityTargetResolutionMode.shared,
      targetResults: targetResults,
      attackResult: attackResult,
      criticalProfile: criticalProfile,
      chanceResults: List.unmodifiable(chanceResults),
      selectedOptionalGroupIds: context.selectedOptionalGroupIds,
      costs: List.unmodifiable(costs),
      externalVariablesByTargetId: context.snapshotTargetExternalVariables(),
    );
  }

  ActionResolutionResult buildIndependentResolutionResult({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required Map<String, ActionDiceResult> diceResultsByTargetId,
    required ActionCriticalProfile criticalProfile,
    ActionAttackResult? attackResult,
    List<ActionChanceResult> chanceResults = const [],
    List<ActionCost> costs = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
  }) {
    final linkedEffects = _abilityLinkedEffectResults(plan.ability);

    final targetResults = <ActionTargetResult>[];

    for (final target in context.targets) {
      final diceResult = diceResultsByTargetId[target.id];

      if (diceResult == null) {
        throw StateError('Falta el resultado para el objetivo ${target.id}.');
      }

      targetResults.add(
        ActionTargetResult(
          target: target,
          diceResult: diceResult,

          savingThrows: savingThrowResults
              .where((result) => result.request.targetId == target.id)
              .toList(growable: false),

          effects: linkedEffects,
        ),
      );
    }

    return ActionResolutionResult(
      ability: plan.ability,
      targetResolutionMode: AbilityTargetResolutionMode.independent,
      targetResults: targetResults,
      attackResult: attackResult,
      criticalProfile: criticalProfile,
      chanceResults: List.unmodifiable(chanceResults),
      selectedOptionalGroupIds: context.selectedOptionalGroupIds,
      costs: List.unmodifiable(costs),
      externalVariablesByTargetId: context.snapshotTargetExternalVariables(),
    );
  }

  ActionResolutionResult buildResolutionResult({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionCriticalProfile criticalProfile,
    ActionDiceResult? sharedDiceResult,
    Map<String, ActionDiceResult> independentDiceResults = const {},
    ActionAttackResult? attackResult,
    List<ActionChanceResult> chanceResults = const [],
    List<ActionCost> costs = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
  }) {
    switch (plan.ability.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        final diceResult = sharedDiceResult;

        if (diceResult == null) {
          throw StateError(
            'La resolución compartida necesita un ActionDiceResult.',
          );
        }

        return buildSharedResolutionResult(
          plan: plan,
          context: context,
          diceResult: diceResult,
          criticalProfile: criticalProfile,
          attackResult: attackResult,
          chanceResults: chanceResults,
          costs: costs,
          savingThrowResults: savingThrowResults,
        );

      case AbilityTargetResolutionMode.independent:
        return buildIndependentResolutionResult(
          plan: plan,
          context: context,
          diceResultsByTargetId: independentDiceResults,
          criticalProfile: criticalProfile,
          attackResult: attackResult,
          chanceResults: chanceResults,
          costs: costs,
          savingThrowResults: savingThrowResults,
        );
    }
  }

  void _appendCriticalExtraDice({
    required List<ActionDiceRequestPart> parts,
    required bool critical,
    required ActionResolutionContext context,
    ActionTarget? target,
    Set<String> successfulChanceCheckIds = const {},
  }) {
    if (!critical) {
      return;
    }

    final bonuses = character.activeCriticalDamageBonuses();

    for (final bonus in bonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      final chanceCheckId = 'critical_bonus:${bonus.id}';

      if (!bonus.alwaysTriggers &&
          !successfulChanceCheckIds.contains(chanceCheckId)) {
        continue;
      }

      final modifier = character.criticalDamageBonusModifier(
        bonus,
        formulaContext: context.buildFormulaContext(target: target),
      );

      parts.add(
        ActionDiceRequestPart(
          id: 'critical_extra:${bonus.id}',
          effectId: 'critical_extra',
          effectName: bonus.name.isNotEmpty
              ? bonus.name
              : 'Daño crítico adicional',

          effectType: AbilityEffectType.damage,

          dicePools: List<DicePool>.unmodifiable(bonus.dicePools),

          modifier: modifier,

          kind: ActionDicePartKind.criticalExtra,

          sourceType: ActionDiceSourceType.criticalBonus,
          sourceId: bonus.id,
          sourceName: bonus.name,

          damageType: bonus.damageType,
        ),
      );
    }
  }

  ActionCriticalProfile buildCriticalProfile({
    Iterable<int> minimumRollSources = const [],
    bool forcedCritical = false,
    bool empowered = false,
  }) {
    final effectiveMinimumRoll = ActionCriticalProfile.effectiveMinimumRoll(
      minimumRollSources,
    );

    return ActionCriticalProfile(
      minimumNaturalRoll: effectiveMinimumRoll,
      forcedCritical: forcedCritical,
      empowered: empowered,
    );
  }

  ActionAttackResult resolveAttackRoll({
    required int naturalRoll,
    required int modifier,
    required ActionCriticalProfile criticalProfile,
  }) {
    if (naturalRoll < 1 || naturalRoll > 20) {
      throw ArgumentError.value(
        naturalRoll,
        'naturalRoll',
        'La tirada natural debe estar entre 1 y 20.',
      );
    }

    return ActionAttackResult(
      naturalRoll: naturalRoll,
      modifier: modifier,
      total: naturalRoll + modifier,
      criticalProfile: criticalProfile,
    );
  }

  ActionDiceRequest buildDiceRequest({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionCriticalProfile criticalProfile,
    ActionTarget? target,
    int? criticalNaturalRoll,
    Set<String> successfulChanceCheckIds = const {},
  }) {
    final selected = selectedParts(
      plan: plan,
      context: context,
      target: target,
    );

    final parts = <ActionDiceRequestPart>[];

    final critical =
        criticalProfile.forcedCritical ||
        (criticalNaturalRoll != null &&
            criticalProfile.isCriticalRoll(criticalNaturalRoll));

    final ActionCriticalType criticalType;

    if (!critical) {
      criticalType = ActionCriticalType.none;
    } else if (criticalNaturalRoll != null) {
      criticalType = criticalProfile.criticalTypeFor(criticalNaturalRoll);
    } else {
      criticalType = criticalProfile.empowered
          ? ActionCriticalType.empowered
          : ActionCriticalType.normal;
    }

    for (final effect in plan.ability.effects) {
      for (final part in effect.parts) {
        if (!selected.contains(part)) {
          continue;
        }

        final baseModifier = character.abilityEffectPartModifier(part);

        var dicePools = List<DicePool>.unmodifiable(part.dicePools);

        var modifier = baseModifier;

        var automaticValue = 0;

        final participatesInCritical =
            critical &&
            plan.ability.requiresAttackRoll &&
            effect.effectType == AbilityEffectType.damage &&
            !effect.usesSavingThrow &&
            part.participatesInCritical;

        if (participatesInCritical) {
          switch (criticalType) {
            case ActionCriticalType.none:
              break;

            case ActionCriticalType.normal:
              automaticValue += _maximumDiceValue(part.dicePools);

              modifier = baseModifier * 2;

              break;

            case ActionCriticalType.empowered:
              automaticValue +=
                  (_maximumDiceValue(part.dicePools) + baseModifier) * 2;

              dicePools = const [];

              modifier = 0;

              break;
          }
        }

        parts.add(
          ActionDiceRequestPart(
            id: '${effect.id}:${part.id}',
            effectId: effect.id,
            effectName: effect.name,
            effectType: effect.effectType,
            abilityPart: part,
            dicePools: dicePools,
            modifier: modifier,
            automaticValue: automaticValue,

            sourceType: ActionDiceSourceType.ability,
            sourceId: plan.ability.id,
            sourceName: plan.ability.name,

            damageType: part.typeName,
          ),
        );
      }

      final extraMultipliers = Map<AbilityType, int>.from(
        effect.abilityModifierMultipliers,
      );

      if (extraMultipliers.isEmpty && effect.legacyAddAbilityModifier) {
        extraMultipliers[plan.ability.abilityType] = 1;
      }

      final hasExtra =
          effect.dicePools.isNotEmpty ||
          extraMultipliers.values.any((value) => value != 0) ||
          effect.effectBonus != 0;

      if (hasExtra) {
        final baseModifier = character.abilityEffectModifier(
          plan.ability,
          effect,
        );

        var dicePools = List<DicePool>.unmodifiable(effect.dicePools);

        var modifier = baseModifier;
        var automaticValue = 0;

        final extraParticipatesInCritical =
            critical &&
            plan.ability.requiresAttackRoll &&
            effect.dealsDamage &&
            !effect.usesSavingThrow;

        if (extraParticipatesInCritical) {
          switch (criticalType) {
            case ActionCriticalType.none:
              break;

            case ActionCriticalType.normal:
              automaticValue += _maximumDiceValue(effect.dicePools);

              modifier = baseModifier * 2;

              break;

            case ActionCriticalType.empowered:
              automaticValue =
                  (_maximumDiceValue(effect.dicePools) + baseModifier) * 2;

              dicePools = const [];
              modifier = 0;

              break;
          }
        }

        parts.add(
          ActionDiceRequestPart(
            id: '${effect.id}:extra',
            effectId: effect.id,
            effectName: effect.name,
            effectType: effect.effectType,

            dicePools: dicePools,
            modifier: modifier,
            automaticValue: automaticValue,

            sourceType: ActionDiceSourceType.ability,
            sourceId: plan.ability.id,
            sourceName: plan.ability.name,

            damageType: effect.effectTypeName,
          ),
        );
      }
    }

    if (_abilityDealsDamage(plan.ability)) {
      _appendDamageBonuses(
        parts: parts,
        context: context,
        target: target,
        criticalType: criticalType,
      );
    }

    if (_abilityHeals(plan.ability)) {
      _appendHealingBonuses(parts: parts, context: context, target: target);
    }

    if (critical && _abilityDealsDamage(plan.ability)) {
      _appendCriticalExtraDice(
        parts: parts,
        critical: critical,
        context: context,
        target: target,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );
    }

    return ActionDiceRequest(parts: parts, criticalProfile: criticalProfile);
  }

  bool _abilityDealsDamage(CharacterAbility ability) {
    return ability.effects.any(
      (effect) => effect.effectType == AbilityEffectType.damage,
    );
  }

  bool _abilityHeals(CharacterAbility ability) {
    return ability.effects.any(
      (effect) => effect.effectType == AbilityEffectType.healing,
    );
  }

  void _appendDamageBonuses({
    required List<ActionDiceRequestPart> parts,
    required ActionResolutionContext context,
    required ActionCriticalType criticalType,
    ActionTarget? target,
  }) {
    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;

      if (!bonus.hasDamage) {
        continue;
      }

      final baseModifier = character.damageBonusModifier(
        bonus,
        passive: active.passive,
        formulaContext: context.buildFormulaContext(
          passive: active.passive,
          target: target,
        ),
      );

      var dicePools = List<DicePool>.unmodifiable(bonus.dicePools);

      var modifier = baseModifier;
      var automaticValue = 0;

      switch (criticalType) {
        case ActionCriticalType.none:
          break;

        case ActionCriticalType.normal:
          automaticValue += _maximumDiceValue(bonus.dicePools);

          modifier = baseModifier * 2;

          break;

        case ActionCriticalType.empowered:
          automaticValue =
              (_maximumDiceValue(bonus.dicePools) + baseModifier) * 2;

          dicePools = const [];
          modifier = 0;

          break;
      }

      final passive = active.passive;

      parts.add(
        ActionDiceRequestPart(
          id: 'damage_bonus:${passive?.id ?? 'effect'}:${bonus.id}',
          effectId: 'damage_bonus',
          effectName: bonus.name.isNotEmpty ? bonus.name : 'Daño adicional',
          effectType: AbilityEffectType.damage,

          dicePools: dicePools,
          modifier: modifier,
          automaticValue: automaticValue,

          sourceType: passive != null
              ? ActionDiceSourceType.passive
              : ActionDiceSourceType.effect,

          sourceId: passive?.id ?? bonus.id,
          sourceName: passive?.name ?? bonus.name,

          damageType: bonus.damageType,
        ),
      );
    }
  }

  void _appendHealingBonuses({
    required List<ActionDiceRequestPart> parts,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    for (final bonus in character.activeHealingBonuses) {
      if (!bonus.hasHealing) {
        continue;
      }

      final modifier = character.healingBonusModifier(
        bonus,
        formulaContext: context.buildFormulaContext(target: target),
      );

      parts.add(
        ActionDiceRequestPart(
          id: 'healing_bonus:${bonus.id}',
          effectId: 'healing_bonus',
          effectName: bonus.name.isNotEmpty ? bonus.name : 'Curación adicional',
          effectType: AbilityEffectType.healing,

          dicePools: List<DicePool>.unmodifiable(bonus.dicePools),

          modifier: modifier,

          sourceType: ActionDiceSourceType.effect,
          sourceId: bonus.id,
          sourceName: bonus.name,
        ),
      );
    }
  }

  List<ActionExternalRequirement> collectExternalRequirements({
    required CharacterAbility ability,
  }) {
    final requirements = <ActionExternalRequirement>[];

    // =========================================================================
    // 1. REQUIREMENTS DE LA PROPIA HABILIDAD
    // =========================================================================

    for (final effect in ability.effects) {
      for (final part in effect.parts) {
        requirements.addAll(part.externalRequirements);
      }
    }

    // =========================================================================
    // 2. REQUIREMENTS DE PASIVAS QUE PUEDEN REACCIONAR
    // =========================================================================

    final possibleEvents = _possiblePassiveEventsForAbility(ability);

    for (final passive in character.passives) {
      if (!passive.enabled) {
        continue;
      }

      for (final trigger in passive.triggers) {
        if (!possibleEvents.contains(trigger.event)) {
          continue;
        }

        // ---------------------------------------------------------------------
        // CONDICIÓN
        // ---------------------------------------------------------------------

        if (trigger.hasCondition) {
          requirements.addAll(
            _externalRequirementsFromExpression(trigger.condition!.expression),
          );
        }

        // ---------------------------------------------------------------------
        // VALOR
        //
        // También es importante.
        //
        // Ejemplo:
        //
        // Evento: damageDealt
        // Acción: causar daño
        // Valor:
        // target_health_percent < 50 ? ...
        //
        // El valor también necesita conocer al objetivo.
        // ---------------------------------------------------------------------

        final valueFormula = trigger.valueFormula;

        if (valueFormula != null && valueFormula.expression.trim().isNotEmpty) {
          requirements.addAll(
            _externalRequirementsFromExpression(valueFormula.expression),
          );
        }
      }
    }

    return ActionExternalRequirementSet(requirements).requirements;
  }

  Set<PassiveTriggerEvent> _possiblePassiveEventsForAbility(
    CharacterAbility ability,
  ) {
    final events = <PassiveTriggerEvent>{};

    // =========================================================================
    // DAÑO
    // =========================================================================

    if (_abilityDealsDamage(ability)) {
      events.add(PassiveTriggerEvent.damageDealt);

      // Una habilidad con ataque puede acabar
      // produciendo criticalHit.
      if (ability.requiresAttackRoll) {
        events.add(PassiveTriggerEvent.criticalHit);
      }
    }

    // =========================================================================
    // CURACIÓN
    // =========================================================================

    if (_abilityHeals(ability)) {
      events.add(PassiveTriggerEvent.healingDealt);
    }

    return events;
  }

  List<ActionExternalRequirement> _externalRequirementsFromExpression(
    String expression,
  ) {
    final requirements = <ActionExternalRequirement>[];

    final normalized = expression.trim();

    if (normalized.isEmpty) {
      return const [];
    }

    // =========================================================================
    // BOOLEANOS DE TARGET
    // =========================================================================

    void addBooleanIfUsed({
      required String variableName,
      required String label,
    }) {
      if (!_expressionContainsVariable(normalized, variableName)) {
        return;
      }

      requirements.add(
        ActionExternalRequirement.boolean(
          variableName: variableName,
          label: label,
        ),
      );
    }

    addBooleanIfUsed(
      variableName: 'target_wounded',
      label: '¿El objetivo está herido?',
    );

    addBooleanIfUsed(
      variableName: 'target_full_health',
      label: '¿El objetivo está a vida completa?',
    );

    addBooleanIfUsed(
      variableName: 'target_below_half',
      label: '¿El objetivo está por debajo del 50% de vida?',
    );

    addBooleanIfUsed(
      variableName: 'target_at_or_below_half',
      label: '¿El objetivo está al 50% de vida o por debajo?',
    );

    addBooleanIfUsed(
      variableName: 'target_above_half',
      label: '¿El objetivo está por encima del 50% de vida?',
    );

    addBooleanIfUsed(
      variableName: 'target_at_or_above_half',
      label: '¿El objetivo está al 50% de vida o por encima?',
    );

    // Estos normalmente los sabemos sin preguntar,
    // pero siguen siendo requirements válidos.
    addBooleanIfUsed(
      variableName: 'target_is_self',
      label: '¿El objetivo es tu personaje?',
    );

    addBooleanIfUsed(
      variableName: 'target_is_external',
      label: '¿El objetivo es externo?',
    );

    // =========================================================================
    // PORCENTAJE DE VIDA
    //
    // Soportamos:
    //
    // target_health_percent < 50
    // target_health_percent <= 50
    // target_health_percent > 50
    // target_health_percent >= 50
    //
    // También target_health_percent_before.
    // =========================================================================

    requirements.addAll(
      _extractHealthPercentageRequirements(
        normalized,
        variableName: 'target_health_percent',
      ),
    );

    requirements.addAll(
      _extractHealthPercentageRequirements(
        normalized,
        variableName: 'target_health_percent_before',
      ),
    );

    requirements.addAll(
      _extractNormalizedHealthRequirements(
        normalized,
      ),
    );

    return ActionExternalRequirementSet(requirements).requirements;
  }

  bool _expressionContainsVariable(String expression, String variableName) {
    final pattern = RegExp(
      r'(^|[^A-Za-z0-9_])' + RegExp.escape(variableName) + r'([^A-Za-z0-9_]|$)',
    );

    return pattern.hasMatch(expression);
  }

  List<ActionExternalRequirement>
  _extractNormalizedHealthRequirements(
      String expression,
      ) {
    final result = <ActionExternalRequirement>[];

    final pattern = RegExp(
      r'\btarget_health_percent_(lt|lte|gt|gte)_'
      r'(\d+(?:\.\d+)?)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(expression)) {
      final operatorName =
      match.group(1)?.toLowerCase();

      final threshold =
      double.tryParse(match.group(2) ?? '');

      if (operatorName == null ||
          threshold == null) {
        continue;
      }

      final safeThreshold =
      threshold.clamp(0.0, 100.0).toDouble();

      final thresholdText =
      safeThreshold ==
          safeThreshold.roundToDouble()
          ? safeThreshold.toInt().toString()
          : safeThreshold.toString();

      switch (operatorName) {
        case 'lt':
          result.add(
            ActionExternalRequirement.percentageBelow(
              variableName:
              'target_health_percent',
              threshold: safeThreshold,
              label:
              '¿El objetivo está por debajo del '
                  '$thresholdText% de vida?',
            ),
          );
          break;

        case 'lte':
          result.add(
            ActionExternalRequirement.percentageAtOrBelow(
              variableName:
              'target_health_percent',
              threshold: safeThreshold,
              label:
              '¿El objetivo está al '
                  '$thresholdText% de vida o por debajo?',
            ),
          );
          break;

        case 'gt':
          result.add(
            ActionExternalRequirement.percentageAbove(
              variableName:
              'target_health_percent',
              threshold: safeThreshold,
              label:
              '¿El objetivo está por encima del '
                  '$thresholdText% de vida?',
            ),
          );
          break;

        case 'gte':
          result.add(
            ActionExternalRequirement.percentageAtOrAbove(
              variableName:
              'target_health_percent',
              threshold: safeThreshold,
              label:
              '¿El objetivo está al '
                  '$thresholdText% de vida o por encima?',
            ),
          );
          break;
      }
    }

    return result;
  }

  List<ActionExternalRequirement> _extractHealthPercentageRequirements(
    String expression, {
    required String variableName,
  }) {
    final result = <ActionExternalRequirement>[];

    final pattern = RegExp(
      '${RegExp.escape(variableName)}'
      r'\s*(<=|>=|<|>)\s*'
      r'(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(expression)) {
      final operator = match.group(1);

      final rawThreshold = match.group(2);

      if (operator == null || rawThreshold == null) {
        continue;
      }

      final threshold = double.tryParse(rawThreshold);

      if (threshold == null) {
        continue;
      }

      final safeThreshold = threshold.clamp(0.0, 100.0).toDouble();

      final thresholdText = safeThreshold == safeThreshold.roundToDouble()
          ? safeThreshold.toInt().toString()
          : safeThreshold.toString();

      switch (operator) {
        case '<':
          result.add(
            ActionExternalRequirement.percentageBelow(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '¿El objetivo está por debajo del '
                  '$thresholdText% de vida?',
            ),
          );

          break;

        case '<=':
          result.add(
            ActionExternalRequirement.percentageAtOrBelow(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '¿El objetivo está al '
                  '$thresholdText% de vida o por debajo?',
            ),
          );

          break;

        case '>':
          result.add(
            ActionExternalRequirement.percentageAbove(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '¿El objetivo está por encima del '
                  '$thresholdText% de vida?',
            ),
          );

          break;

        case '>=':
          result.add(
            ActionExternalRequirement.percentageAtOrAbove(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '¿El objetivo está al '
                  '$thresholdText% de vida o por encima?',
            ),
          );

          break;
      }
    }

    return result;
  }

  ActionResolutionPlan prepareAbility({
    required CharacterAbility ability,
    required ActionResolutionContext context,
  }) {
    final automaticParts = <AbilityEffectPart>[];
    final optionalParts = <AbilityEffectPart>[];

    for (final effect in ability.effects) {
      for (final part in effect.parts) {
        final available = context.isAbilityEffectPartAvailable(part);

        if (!available) {
          continue;
        }

        if (part.optional) {
          optionalParts.add(part);
        } else {
          automaticParts.add(part);
        }
      }
    }

    final costResolver = ActionCostResolver(character: character);

    return ActionResolutionPlan(
      ability: ability,
      automaticParts: automaticParts,
      optionalParts: optionalParts,
      externalRequirements: collectExternalRequirements(ability: ability),
      costs: costResolver.costsForAbility(ability.id),
    );
  }

  List<AbilityEffectPart> selectedParts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    final result = <AbilityEffectPart>[];

    for (final effect in plan.ability.effects) {
      for (final part in effect.parts) {
        final shouldUse = context.shouldUseAbilityEffectPart(
          part,
          target: target,
        );

        if (shouldUse) {
          result.add(part);
        }
      }
    }

    return result;
  }

  int _maximumDiceValue(Iterable<DicePool> pools) {
    return pools.fold<int>(0, (total, pool) => total + pool.maximum);
  }

  List<ActionChanceResult> resolveCriticalChancesDigital({
    required PreparedActionResolution prepared,
    required bool critical,
  }) {
    if (!critical) {
      return const [];
    }

    final checks = collectCriticalChanceChecks(critical: true);

    if (checks.isEmpty) {
      return const [];
    }

    final resolver = ActionChanceResolver();

    return checks.map(resolver.rollDigital).toList(growable: false);
  }

  Set<String> successfulChanceCheckIds(Iterable<ActionChanceResult> results) {
    return results
        .where((result) => result.success)
        .map((result) => result.check.id)
        .toSet();
  }

  ActionResolutionResult resolvePreparedAbilityDigital({
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
    List<ActionSavingThrowResult> savingThrowResults = const [],
    List<ActionChanceResult>? preResolvedChanceResults,
  }) {
    final costValidation = validatePreparedActionCosts(prepared);

    if (!costValidation.valid) {
      throw StateError(
        costValidation.error ?? 'No se pueden pagar los costes de la acción.',
      );
    }

    validateSavingThrowResults(prepared: prepared, results: savingThrowResults);

    final critical = preparedActionIsCritical(
      prepared: prepared,
      attackResult: attackResult,
    );

    final chanceResults =
        preResolvedChanceResults ??
        resolveCriticalChancesDigital(prepared: prepared, critical: critical);

    final successfulChanceIds = successfulChanceCheckIds(chanceResults);

    switch (prepared.ability.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        if (prepared.context.targets.length > 1 &&
            hasTargetSpecificConditions(prepared.ability)) {
          throw StateError(
            'Una resolución compartida con condiciones '
            'específicas por objetivo necesita respuestas '
            'compatibles entre todos los objetivos.',
          );
        }

        final diceRequest = buildDiceRequest(
          plan: prepared.plan,
          context: prepared.context,
          criticalProfile: prepared.criticalProfile,
          criticalNaturalRoll: attackResult?.naturalRoll,
          successfulChanceCheckIds: successfulChanceIds,
        );

        final diceResolver = const ActionDiceResolver();

        final diceResult = diceResolver.rollDigital(diceRequest);

        return buildResolutionResult(
          plan: prepared.plan,
          context: prepared.context,
          criticalProfile: prepared.criticalProfile,
          sharedDiceResult: diceResult,
          attackResult: attackResult,
          chanceResults: chanceResults,
          costs: prepared.costs,
          savingThrowResults: savingThrowResults,
        );

      case AbilityTargetResolutionMode.independent:
        final independentResults = resolveIndependentDiceDigital(
          prepared: prepared,
          criticalProfile: prepared.criticalProfile,
          attackResult: attackResult,
          successfulChanceCheckIds: successfulChanceIds,
        );

        return buildResolutionResult(
          plan: prepared.plan,
          context: prepared.context,
          criticalProfile: prepared.criticalProfile,
          independentDiceResults: independentResults,
          attackResult: attackResult,
          chanceResults: chanceResults,
          costs: prepared.costs,
          savingThrowResults: savingThrowResults,
        );
    }
  }

  ActionExecutionResult commitResolution(
    ActionResolutionResult result, {
    bool payCosts = true,
  }) {
    if (payCosts) {
      final costResolver = ActionCostResolver(character: character);

      final validation = costResolver.validate(result.costs);

      if (!validation.valid) {
        throw StateError(
          validation.error ?? 'Los costes de la acción ya no pueden pagarse.',
        );
      }

      final payment = costResolver.pay(result.costs);

      if (!payment.valid) {
        throw StateError(payment.error ?? 'No se han podido pagar los costes.');
      }
    }

    final applier = ActionResultApplier(character: character);

    final application = applier.apply(result);

    return ActionExecutionResult(resolution: result, application: application);
  }

  void validateSavingThrowResults({
    required PreparedActionResolution prepared,
    required List<ActionSavingThrowResult> results,
  }) {
    final requiredRequests = collectSavingThrowRequests(prepared: prepared);

    for (final request in requiredRequests) {
      final exists = results.any((result) => result.request.id == request.id);

      if (!exists) {
        throw StateError(
          'Falta resolver la salvación '
          '${request.effectName} para ${request.targetId}.',
        );
      }
    }
  }

  List<ActionEffectResult> _abilityLinkedEffectResults(
    CharacterAbility ability,
  ) {
    return ability.linkedEffects
        .map((effect) => ActionEffectResult(template: effect))
        .toList(growable: false);
  }

  Map<String, ActionDiceResult> resolveIndependentDiceDigital({
    required PreparedActionResolution prepared,
    required ActionCriticalProfile criticalProfile,
    ActionAttackResult? attackResult,
    Set<String> successfulChanceCheckIds = const {},
  }) {
    final results = <String, ActionDiceResult>{};

    final diceResolver = const ActionDiceResolver();

    for (final target in prepared.context.targets) {
      final diceRequest = buildDiceRequest(
        plan: prepared.plan,
        context: prepared.context,
        criticalProfile: criticalProfile,
        target: target,
        criticalNaturalRoll: attackResult?.naturalRoll,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );

      results[target.id] = diceResolver.rollDigital(diceRequest);
    }

    return Map<String, ActionDiceResult>.unmodifiable(results);
  }

  bool hasTargetSpecificConditions(CharacterAbility ability) {
    return ability.effects.any(
      (effect) =>
          effect.parts.any((part) => part.externalRequirements.isNotEmpty),
    );
  }

  List<AbilityEffectPart> availableOptionalParts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    final result = <AbilityEffectPart>[];

    for (final effect in plan.ability.effects) {
      for (final part in effect.parts) {
        if (!part.optional) {
          continue;
        }

        final available = context.isAbilityEffectPartAvailable(
          part,
          target: target,
        );

        if (!available) {
          continue;
        }

        result.add(part);
      }
    }

    return result;
  }

  ActionResolutionPlan prepareAbilityPlan({
    required CharacterAbility ability,
    required ActionResolutionContext context,
  }) {
    return prepareAbility(ability: ability, context: context);
  }

  List<ActionCost> collectSelectedPartCosts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
  }) {
    final costs = <ActionCost>[];

    switch (plan.ability.targetResolutionMode) {
      // =======================================================================
      // SHARED
      // =======================================================================

      case AbilityTargetResolutionMode.shared:
        final selected = selectedParts(plan: plan, context: context);

        for (final part in selected) {
          costs.addAll(part.costs);
        }

        break;

      // =======================================================================
      // INDEPENDENT
      // =======================================================================

      case AbilityTargetResolutionMode.independent:
        for (final target in context.targets) {
          final selected = selectedParts(
            plan: plan,
            context: context,
            target: target,
          );

          for (final part in selected) {
            costs.addAll(part.costs);
          }
        }

        break;
    }

    return costs;
  }

  ActionCostValidationResult validateOptionalSelection({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required AbilityEffectPart candidate,
    ActionTarget? target,
  }) {
    final currentCosts = <ActionCost>[
      ...ActionCostResolver(
        character: character,
      ).costsForAbility(plan.ability.id),
    ];

    if (plan.ability.targetResolutionMode ==
        AbilityTargetResolutionMode.shared) {
      final selected = selectedParts(plan: plan, context: context);

      for (final part in selected) {
        currentCosts.addAll(part.costs);
      }
    } else {
      for (final currentTarget in context.targets) {
        final selected = selectedParts(
          plan: plan,
          context: context,
          target: currentTarget,
        );

        for (final part in selected) {
          currentCosts.addAll(part.costs);
        }
      }
    }

    currentCosts.addAll(candidate.costs);

    final resolver = ActionCostResolver(character: character);

    return resolver.validate(currentCosts);
  }

  List<ActionOptionalGroup> availableOptionalGroups({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    final grouped = <String, List<AbilityEffectPart>>{};

    for (final effect in plan.ability.effects) {
      for (final part in effect.parts) {
        if (!part.optional) {
          continue;
        }

        final available = context.isAbilityEffectPartAvailable(
          part,
          target: target,
        );

        if (!available) {
          continue;
        }

        final groupId = part.effectiveOptionalGroupId;

        grouped.putIfAbsent(groupId, () => <AbilityEffectPart>[]);

        grouped[groupId]!.add(part);
      }
    }

    final costResolver = ActionCostResolver(character: character);

    final result = <ActionOptionalGroup>[];

    for (final entry in grouped.entries) {
      final parts = entry.value;

      if (parts.isEmpty) {
        continue;
      }

      final costs = <ActionCost>[];

      for (final part in parts) {
        costs.addAll(part.costs);
      }

      result.add(
        ActionOptionalGroup(
          id: entry.key,
          label: parts.first.effectiveOptionalLabel,
          parts: List.unmodifiable(parts),
          costs: List.unmodifiable(costResolver.combineCosts(costs)),
        ),
      );
    }

    return List.unmodifiable(result);
  }

  ActionCostValidationResult validateOptionalGroupSelection({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionOptionalGroup group,
    ActionTarget? target,
  }) {
    final costResolver = ActionCostResolver(character: character);

    final costs = <ActionCost>[
      ...costResolver.costsForAbility(plan.ability.id),
    ];

    // =========================================================================
    // COSTES YA SELECCIONADOS
    // =========================================================================

    switch (plan.ability.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        final selected = selectedParts(plan: plan, context: context);

        for (final part in selected) {
          costs.addAll(part.costs);
        }

        break;

      case AbilityTargetResolutionMode.independent:
        for (final currentTarget in context.targets) {
          final selected = selectedParts(
            plan: plan,
            context: context,
            target: currentTarget,
          );

          for (final part in selected) {
            costs.addAll(part.costs);
          }
        }

        break;
    }

    // =========================================================================
    // NUEVO GRUPO QUE QUEREMOS ACTIVAR
    // =========================================================================

    costs.addAll(group.costs);

    return costResolver.validate(costs);
  }

  ActionCriticalProfile buildCriticalProfileForAbility(
    CharacterAbility ability, {
    bool forcedCritical = false,
    bool empowered = false,
  }) {
    return buildCriticalProfile(
      minimumRollSources: character.criticalMinimumRollSourcesForAbility(
        ability,
      ),
      forcedCritical: forcedCritical,
      empowered: empowered,
    );
  }

  ActionCostValidationResult payPreparedActionCosts(
    PreparedActionResolution prepared,
  ) {
    final resolver = ActionCostResolver(character: character);

    return resolver.pay(prepared.costs);
  }

  ActionDiceRequest buildPreparedDiceRequest({
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
    Set<String> successfulChanceCheckIds = const {},
    ActionTarget? target,
  }) {
    return buildDiceRequest(
      plan: prepared.plan,
      context: prepared.context,
      criticalProfile: prepared.criticalProfile,
      target: target,
      criticalNaturalRoll: attackResult?.naturalRoll,
      successfulChanceCheckIds: successfulChanceCheckIds,
    );
  }

  ActionResolutionResult buildPreparedSharedResolution({
    required PreparedActionResolution prepared,
    required ActionDiceResult diceResult,
    ActionAttackResult? attackResult,
    List<ActionChanceResult> chanceResults = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
  }) {
    if (prepared.ability.targetResolutionMode !=
        AbilityTargetResolutionMode.shared) {
      throw StateError('Esta operación solo admite resolución compartida.');
    }

    return buildResolutionResult(
      plan: prepared.plan,
      context: prepared.context,
      criticalProfile: prepared.criticalProfile,
      sharedDiceResult: diceResult,
      attackResult: attackResult,
      chanceResults: chanceResults,
      savingThrowResults: savingThrowResults,
      costs: prepared.costs,
    );
  }

  ActionResolutionResult buildPreparedIndependentResolution({
    required PreparedActionResolution prepared,
    required Map<String, ActionDiceResult> diceResultsByTargetId,
    ActionAttackResult? attackResult,
    List<ActionChanceResult> chanceResults = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
  }) {
    if (prepared.ability.targetResolutionMode !=
        AbilityTargetResolutionMode.independent) {
      throw StateError('Esta operación requiere resolución independiente.');
    }

    return buildResolutionResult(
      plan: prepared.plan,
      context: prepared.context,
      criticalProfile: prepared.criticalProfile,
      independentDiceResults: diceResultsByTargetId,
      attackResult: attackResult,
      chanceResults: chanceResults,
      savingThrowResults: savingThrowResults,
      costs: prepared.costs,
    );
  }
}
