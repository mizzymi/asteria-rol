import '../models/weapon.dart';
import '../models/character_effect.dart';
import '../models/passive_triggered_external_outcome.dart';
import '../models/healing_bonus.dart';
import '../models/action_attack_roll_mode.dart';
import '../models/damage_bonus.dart';
import '../models/action_linked_effect.dart';
import '../models/action_target_attack_result.dart';
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
import '../models/saving_throw_roll_mode.dart';
import '../models/action_effect_result.dart';
import '../models/passive.dart';
import '../models/action_hit_behavior.dart';
import '../models/critical_damage_bonus.dart';
import '../models/character_effect_triggered_external_outcome.dart';
import '../models/action_source.dart';
import '../models/action_definition.dart';
import '../models/action_content.dart';

import 'action_stat_resolver.dart';
import 'character_effect_trigger_engine.dart';
import 'action_result_applier.dart';
import 'action_external_requirement_parser.dart';
import 'action_saving_throw_resolver.dart';
import 'action_critical_dice_transformer.dart';
import 'formula_evaluator.dart';
import 'action_chance_resolver.dart';
import 'action_cost_resolver.dart';
import 'action_dice_resolver.dart';
import 'passive_trigger_engine.dart';

typedef ActionResolutionScope = ({String id, ActionTarget? target});

class ActionResolver {
  final Character character;

  const ActionResolver({required this.character});

  List<ActionExternalRequirement> _externalRequirementsFromExpression(
    String expression,
  ) {
    return const ActionExternalRequirementParser().fromExpression(expression);
  }

  bool preparedActionRequiresDiceMode(PreparedActionResolution prepared) {
    // ===========================================================================
    // ATAQUE
    //
    // Si la habilidad requiere ataque, siempre necesitamos un d20.
    // ===========================================================================

    if (prepared.definition.requiresAttackRoll) {
      return true;
    }

    // ===========================================================================
    // SALVACIONES
    //
    // Si existe al menos una salvación, habrá que resolver d20.
    // ===========================================================================

    final savingThrows = collectSavingThrowRequests(prepared: prepared);

    final hasSelfSavingThrow = savingThrows.any(
      (request) => request.targetId == 'self',
    );

    if (hasSelfSavingThrow) {
      return true;
    }

    // ===========================================================================
    // DADOS DEL REQUEST
    // ===========================================================================

    final request = buildPreparedDiceRequest(
      prepared: prepared,
      successfulChanceCheckIds: const {},
    );

    if (request.parts.any((part) => part.requiresRoll)) {
      return true;
    }

    // ===========================================================================
    // SIN ATAQUE NO PUEDE HABER CRÍTICO NATURAL
    //
    // Por tanto no debemos forzar selección físico/digital
    // solo porque el personaje tenga bonos críticos configurados.
    //
    // Los críticos forzados sí pueden activar chance checks críticos.
    // ===========================================================================

    if (prepared.criticalProfile.forcedCritical) {
      final criticalChecks = collectCriticalChanceChecks(
        plan: prepared.plan,
        critical: true,
        context: prepared.context,
      );

      if (criticalChecks.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  ActionDiceResult resolvePreparedDiceDigital({
    required ActionDiceRequest request,
  }) {
    return const ActionDiceResolver().rollDigital(request);
  }

  ActionDiceResult resolvePreparedDicePhysical({
    required ActionDiceRequest request,
    required List<ActionPhysicalDiceInput> inputs,
  }) {
    return const ActionDiceResolver().resolvePhysical(
      request: request,
      inputs: inputs,
    );
  }

  ({int firstRoll, int? secondRoll}) rollPreparedAttackDigital({
    required AttackRollMode mode,
  }) {
    const diceResolver = ActionDiceResolver();

    final firstRoll = diceResolver.rollDigitalD20();

    int? secondRoll;

    switch (mode) {
      case AttackRollMode.normal:
        break;

      case AttackRollMode.advantage:
      case AttackRollMode.disadvantage:
        secondRoll = diceResolver.rollDigitalD20();
        break;
    }

    return (firstRoll: firstRoll, secondRoll: secondRoll);
  }

  bool _damageBonusSurvivesForTarget({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required DamageBonus bonus,
    CharacterPassive? passive,
    required ActionTarget target,
    ActionTargetAttackResult? attackResult,
  }) {
    // ===========================================================================
    // CONTENIDO
    // ===========================================================================

    if (!bonus.hasDamage) {
      return false;
    }

    // ===========================================================================
    // CONDICIÓN
    // ===========================================================================

    if (!_damageBonusConditionMet(
      bonus: bonus,
      context: context,
      passive: passive,
      target: target,
    )) {
      return false;
    }

    // ===========================================================================
    // OPCIONAL
    // ===========================================================================

    if (!_damageBonusOptionalSelected(
      plan: plan,
      bonus: bonus,
      context: context,
      target: target,
    )) {
      return false;
    }

    // ===========================================================================
    // HIT / MISS
    // ===========================================================================

    if (!_passesHitGate(
      requiresAttackRoll: plan.definition.requiresAttackRoll,
      behavior: bonus.hitBehavior,
      attackResult: attackResult,
      targetParticipatesInAttackRoll: target.participatesInAttackRoll,
    )) {
      return false;
    }

    return true;
  }

  List<ActionCost> collectSelectedBonusCosts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
  }) {
    final costs = <ActionCost>[];

    // ===========================================================================
    // DAMAGE BONUS
    //
    // Aquí todavía no existe resultado de ataque.
    //
    // `_passesHitGate(... attackResult: null)` no bloquea prematuramente,
    // así que estos son costes POTENCIALES.
    // ===========================================================================

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (bonus.costs.isEmpty) {
        continue;
      }

      switch (plan.definition.targetResolutionMode) {
        // =======================================================================
        // SHARED
        //
        // Basta con que el bonus sea viable para un target.
        // Se cobra potencialmente una sola vez.
        // =======================================================================

        case AbilityTargetResolutionMode.shared:
          var applies = false;

          for (final target in context.targets) {
            if (_damageBonusSurvivesForTarget(
              plan: plan,
              context: context,
              bonus: bonus,
              passive: passive,
              target: target,
              attackResult: null,
            )) {
              applies = true;
              break;
            }
          }

          if (applies) {
            costs.addAll(bonus.costs);
          }

          break;

        // =======================================================================
        // INDEPENDENT
        //
        // Cada target puede generar su coste.
        // =======================================================================

        case AbilityTargetResolutionMode.independent:
          for (final target in context.targets) {
            if (!_damageBonusSurvivesForTarget(
              plan: plan,
              context: context,
              bonus: bonus,
              passive: passive,
              target: target,
              attackResult: null,
            )) {
              continue;
            }

            costs.addAll(bonus.costs);
          }

          break;
      }
    }

    // ===========================================================================
    // HEALING BONUS
    //
    // Actualmente HealingBonus:
    // - no es opcional,
    // - no tiene hitBehavior,
    // - no tiene condition.
    //
    // Su coste es global por acción, no por target.
    // ===========================================================================

    if (plan.content.heals) {
      for (final active in character.activeHealingBonuses) {
        final bonus = active.bonus;

        if (!bonus.hasHealing || bonus.costs.isEmpty) {
          continue;
        }

        costs.addAll(bonus.costs);
      }
    }

    return List<ActionCost>.unmodifiable(
      ActionCostResolver(character: character).combineCosts(costs),
    );
  }

  bool _damageBonusConditionMet({
    required DamageBonus bonus,
    required ActionResolutionContext context,
    CharacterPassive? passive,
    ActionTarget? target,
  }) {
    if (!bonus.hasCondition) {
      return true;
    }

    final result = const FormulaEvaluator().evaluate(
      bonus.condition!,
      context: context.buildFormulaContext(passive: passive, target: target),
    );

    return result.valid && result.value != 0;
  }

  bool _damageBonusOptionalSelected({
    required ActionResolutionPlan plan,
    required DamageBonus bonus,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    if (!bonus.optional) {
      return true;
    }

    return _isOptionalGroupSelectedForTargetResolution(
      plan: plan,
      context: context,
      groupId: bonus.effectiveOptionalGroupId,
      target: target,
    );
  }

  // ===========================================================================
  // GATING · HIT / MISS
  // ===========================================================================

  ActionDiceResult resolveDiceResultForTarget({
    required ActionDefinition definition,
    required ActionTarget target,
    required ActionDiceResult diceResult,
    ActionTargetAttackResult? attackResult,
  }) {
    final survivingParts = diceResult.parts
        .where((part) {
          return _passesHitGate(
            requiresAttackRoll: definition.requiresAttackRoll,
            behavior: part.request.hitBehavior,
            attackResult: attackResult,
            targetParticipatesInAttackRoll: target.participatesInAttackRoll,
          );
        })
        .toList(growable: false);

    return ActionDiceResult(
      parts: List<ActionDicePartResult>.unmodifiable(survivingParts),
    );
  }

  ActionTargetResult buildTargetResult({
    required ActionDefinition definition,
    required ActionTarget target,
    required ActionDiceResult diceResult,
    ActionTargetAttackResult? attackResult,
    List<ActionSavingThrowResult> savingThrows = const [],
    List<ActionEffectResult> effects = const [],
    bool auxiliary = false,
  }) {
    final resolvedDiceResult = resolveDiceResultForTarget(
      definition: definition,
      target: target,
      diceResult: diceResult,
      attackResult: attackResult,
    );

    final resolvedDamage = resolvedDiceResult.parts
        .where((part) => part.request.effectType == AbilityEffectType.damage)
        .fold<int>(0, (sum, part) => sum + part.total);

    final resolvedHealing = resolvedDiceResult.parts
        .where((part) => part.request.effectType == AbilityEffectType.healing)
        .fold<int>(0, (sum, part) => sum + part.total);

    final resolvedMitigation = resolvedDiceResult.parts
        .where(
          (part) => part.request.effectType == AbilityEffectType.mitigation,
        )
        .fold<int>(0, (sum, part) => sum + part.total);

    return ActionTargetResult(
      target: target,
      diceResult: resolvedDiceResult,
      attackResult: attackResult,
      savingThrows: List.unmodifiable(savingThrows),
      effects: List.unmodifiable(effects),
      resolvedDamage: resolvedDamage,
      resolvedHealing: resolvedHealing,
      resolvedMitigation: resolvedMitigation,
      auxiliary: auxiliary,
    );
  }

  ActionResolutionResult buildResolutionResult({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionCriticalProfile criticalProfile,

    ActionDiceResult? sharedDiceResult,

    Map<String, ActionDiceResult>? independentDiceResults,

    ActionAttackResult? attackResult,

    List<ActionChanceResult> chanceResults = const [],

    Map<String, List<ActionChanceResult>> chanceResultsByTargetId = const {},

    List<ActionCost> costs = const [],

    List<ActionSavingThrowResult> savingThrowResults = const [],

    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    switch (plan.definition.targetResolutionMode) {
      // =========================================================================
      // SHARED
      // =========================================================================

      case AbilityTargetResolutionMode.shared:
        final diceResult = sharedDiceResult;

        if (diceResult == null) {
          throw StateError(
            'Falta el resultado de dados '
            'de la resolución compartida.',
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

          attackResultsByTargetId: attackResultsByTargetId,
        );

      // =========================================================================
      // INDEPENDENT
      // =========================================================================

      case AbilityTargetResolutionMode.independent:
        final diceResults = independentDiceResults;

        if (diceResults == null) {
          throw StateError(
            'Faltan los resultados de dados '
            'de la resolución independiente.',
          );
        }

        return buildIndependentResolutionResult(
          plan: plan,
          context: context,

          diceResultsByTargetId: diceResults,

          criticalProfile: criticalProfile,

          attackResult: attackResult,

          costs: costs,

          savingThrowResults: savingThrowResults,

          attackResultsByTargetId: attackResultsByTargetId,

          chanceResultsByTargetId: chanceResultsByTargetId,
        );
    }
  }

  PreparedActionResolution prepareDirectAction({
    required ActionSource source,
    required ActionDefinition definition,
    required ActionResolutionContext context,
    required ActionCriticalProfile criticalProfile,
    ActionContent content = const ActionContent.empty(),
    List<ActionCost> costs = const [],
  }) {
    final costResolver = ActionCostResolver(character: character);

    // =========================================================================
    // COSTES BASE
    // =========================================================================

    final normalizedBaseCosts = costResolver.combineCosts(costs);

    final plan = ActionResolutionPlan(
      source: source,
      definition: definition,
      content: content,
      automaticParts: const [],
      optionalParts: const [],
      externalRequirements: collectPreResolutionExternalRequirements(
        source: source,
        definition: definition,
        content: content,
      ),
      costs: List<ActionCost>.unmodifiable(normalizedBaseCosts),
    );

    // =========================================================================
    // COSTES POTENCIALES
    //
    // Aquí todavía no conocemos hit/miss.
    // Sirven para validar que la selección actual podría pagarse.
    //
    // El coste definitivo se calcula posteriormente mediante
    // collectResolvedActionCosts().
    // =========================================================================

    final potentialCosts = costResolver.combineCosts([
      ...normalizedBaseCosts,
      ...collectSelectedBonusCosts(plan: plan, context: context),
    ]);

    return PreparedActionResolution(
      source: source,
      definition: definition,
      context: context,
      plan: plan,
      criticalProfile: criticalProfile,
      costs: List<ActionCost>.unmodifiable(potentialCosts),
    );
  }

  ActionResolutionResult buildDirectResolutionResult({
    required ActionSource source,

    required AbilityTargetResolutionMode targetResolutionMode,

    required List<ActionTargetResult> targetResults,

    ActionAttackResult? attackResult,

    required ActionCriticalProfile criticalProfile,

    List<ActionChanceResult> chanceResults = const [],

    Set<String> selectedOptionalGroupIds = const {},

    Map<String, Set<String>> selectedOptionalGroupIdsByTargetId = const {},

    Map<String, Map<String, double>> preResolutionExternalVariablesByTargetId =
        const {},

    Map<String, Map<String, double>> externalVariablesByTargetId = const {},

    List<ActionCost> costs = const [],
  }) {
    return ActionResolutionResult(
      source: source,

      targetResolutionMode: targetResolutionMode,

      targetResults: List<ActionTargetResult>.unmodifiable(targetResults),

      attackResult: attackResult,

      criticalProfile: criticalProfile,

      chanceResults: List<ActionChanceResult>.unmodifiable(chanceResults),

      selectedOptionalGroupIds: Set<String>.unmodifiable(
        selectedOptionalGroupIds,
      ),

      selectedOptionalGroupIdsByTargetId: {
        for (final entry in selectedOptionalGroupIdsByTargetId.entries)
          entry.key: Set<String>.unmodifiable(entry.value),
      },

      preResolutionExternalVariablesByTargetId: {
        for (final entry in preResolutionExternalVariablesByTargetId.entries)
          entry.key: Map<String, double>.unmodifiable(entry.value),
      },

      externalVariablesByTargetId: {
        for (final entry in externalVariablesByTargetId.entries)
          entry.key: Map<String, double>.unmodifiable(entry.value),
      },

      costs: List<ActionCost>.unmodifiable(costs),
    );
  }

  /// Decide si un componente sobrevive al resultado del ataque.
  ///
  /// IMPORTANTE:
  /// - Si la habilidad no utiliza ataque, el hit/miss no bloquea nada.
  /// - `ignoreHit` siempre sobrevive.
  /// - `requireHit` solamente se bloquea cuando sabemos que hubo miss.
  /// - Si todavía no existe [attackResult], estamos en una fase previa
  ///   a la resolución del ataque y no bloqueamos el componente.
  ///
  /// Esto permite reutilizar la misma lógica durante:
  /// - planificación,
  /// - opcionales,
  /// - construcción final de dados,
  /// - saves,
  /// - linked effects.
  bool _passesHitGate({
    required bool requiresAttackRoll,
    required ActionHitBehavior behavior,
    ActionTargetAttackResult? attackResult,
    bool targetParticipatesInAttackRoll = true,
  }) {
    if (!requiresAttackRoll) {
      return true;
    }

    if (!targetParticipatesInAttackRoll) {
      return true;
    }

    switch (behavior) {
      case ActionHitBehavior.ignoreHit:
        return true;

      case ActionHitBehavior.requireHit:
        if (attackResult == null) {
          return true;
        }

        return attackResult.hit;
    }
  }

  bool _passesLinkedEffectHitGate({
    required ActionDefinition definition,
    required ActionLinkedEffect linkedEffect,
    ActionTarget? target,
    ActionTargetAttackResult? targetAttackResult,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
    bool auxiliarySelf = false,
  }) {
    if (!definition.requiresAttackRoll) {
      return true;
    }

    final behavior = linkedEffect.effectiveHitBehavior;

    if (behavior == ActionHitBehavior.ignoreHit) {
      return true;
    }

    if (!auxiliarySelf) {
      return _passesHitGate(
        requiresAttackRoll: definition.requiresAttackRoll,
        behavior: behavior,
        attackResult: targetAttackResult,
        targetParticipatesInAttackRoll:
            target?.participatesInAttackRoll ?? true,
      );
    }

    if (attackResultsByTargetId.isEmpty) {
      return true;
    }

    return attackResultsByTargetId.values.any((result) => result.hit);
  }

  ActionDiceResult _filterDiceResultForTarget({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionTarget target,
    required ActionDiceResult diceResult,
    ActionTargetAttackResult? attackResult,
  }) {
    final parts = diceResult.parts
        .where((partResult) {
          final request = partResult.request;

          if (!_passesHitGate(
            requiresAttackRoll: plan.definition.requiresAttackRoll,
            behavior: request.hitBehavior,
            attackResult: attackResult,
            targetParticipatesInAttackRoll: target.participatesInAttackRoll,
          )) {
            return false;
          }

          final abilityPart = request.abilityPart;

          if (abilityPart != null &&
              !_shouldUseAbilityEffectPartForTarget(
                plan: plan,
                context: context,
                part: abilityPart,
                target: target,
              )) {
            return false;
          }

          return true;
        })
        .toList(growable: false);

    return ActionDiceResult(
      parts: List<ActionDicePartResult>.unmodifiable(parts),
    );
  }

  bool _linkedEffectTargetsTarget({
    required ActionLinkedEffect linkedEffect,
    required ActionTarget target,
  }) {
    switch (linkedEffect.target) {
      case ActionLinkedEffectTarget.actionTarget:
        return true;

      case ActionLinkedEffectTarget.self:
        return target.isSelf;

      case ActionLinkedEffectTarget.externalTargets:
        return target.isExternal;
    }
  }

  AbilityEffect? _linkedEffectSourceEffect({
    required ActionContent content,
    required ActionLinkedEffect linkedEffect,
  }) {
    final explicitId = linkedEffect.normalizedSourceEffectId;

    if (explicitId != null) {
      for (final effect in content.effects) {
        if (effect.id == explicitId) {
          return effect;
        }
      }

      return null;
    }

    final savingEffects = content.effects
        .where((effect) => effect.usesSavingThrow)
        .toList(growable: false);

    if (savingEffects.length == 1) {
      return savingEffects.first;
    }

    return null;
  }

  bool _effectNeedsSavingThrowForTarget({
    required PreparedActionResolution prepared,
    required AbilityEffect effect,
    required ActionTarget target,
    required List<AbilityEffectPart> selectedParts,
    ActionTargetAttackResult? attackResult,
  }) {
    if (!effect.usesSavingThrow) {
      return false;
    }

    // ===========================================================================
    // 1. PARTES MODERNAS QUE SIGUEN VIVAS
    // ===========================================================================

    final hasSelectedPart = effect.parts.any(selectedParts.contains);

    if (hasSelectedPart) {
      return true;
    }

    // ===========================================================================
    // 2. EXTRA / LEGACY DEL EFFECT
    //
    // Históricamente el contenido numérico de una habilidad con ataque
    // dependía del impacto.
    //
    // Mientras este bloque legacy no tenga su propio hitBehavior,
    // conservamos ese comportamiento.
    // ===========================================================================

    final hasExtra =
        effect.dicePools.isNotEmpty ||
        effect.abilityModifierMultipliers.values.any((value) => value != 0) ||
        effect.effectBonus != 0 ||
        effect.legacyAddAbilityModifier;

    if (hasExtra &&
        _passesHitGate(
          requiresAttackRoll: prepared.definition.requiresAttackRoll,
          behavior: ActionHitBehavior.requireHit,
          attackResult: attackResult,
          targetParticipatesInAttackRoll: target.participatesInAttackRoll,
        )) {
      return true;
    }

    // ===========================================================================
    // 3. LINKED EFFECTS CONTROLADOS POR ESTE SAVE
    // ===========================================================================

    for (final linkedEffect in prepared.plan.content.linkedEffects) {
      if (linkedEffect.saveBehavior == ActionLinkedEffectSaveBehavior.ignore) {
        continue;
      }

      if (!_linkedEffectTargetsTarget(
        linkedEffect: linkedEffect,
        target: target,
      )) {
        continue;
      }

      final sourceEffect = _linkedEffectSourceEffect(
        content: prepared.plan.content,
        linkedEffect: linkedEffect,
      );

      if (sourceEffect == null ||
          sourceEffect.id != effect.id ||
          !sourceEffect.usesSavingThrow) {
        continue;
      }

      if (!_passesLinkedEffectHitGate(
        definition: prepared.definition,
        linkedEffect: linkedEffect,
        target: target,
        targetAttackResult: attackResult,
      )) {
        continue;
      }

      return true;
    }

    return false;
  }

  List<ActionSavingThrowResult> resolveExternalSavingThrowResults({
    required List<ActionSavingThrowRequest> requests,
    required Map<String, bool> resultsByRequestId,
  }) {
    final results = <ActionSavingThrowResult>[];

    for (final request in requests) {
      if (request.targetId == 'self') {
        continue;
      }

      final saved = resultsByRequestId[request.id];

      if (saved == null) {
        throw StateError(
          'Falta indicar el resultado de '
          '${request.effectName} para '
          '${request.targetId}.',
        );
      }

      results.add(
        ActionSavingThrowResult.external(request: request, saved: saved),
      );
    }

    return List<ActionSavingThrowResult>.unmodifiable(results);
  }

  List<ActionEffectResult> _buildLinkedEffectResultsForTarget({
    required ActionDefinition definition,
    required ActionContent content,
    required ActionTarget target,
    required ActionTargetAttackResult? attackResult,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    if (content.linkedEffects.isEmpty) {
      return const [];
    }

    final results = <ActionEffectResult>[];

    for (final linkedEffect in content.linkedEffects) {
      switch (linkedEffect.target) {
        case ActionLinkedEffectTarget.actionTarget:
          break;
        case ActionLinkedEffectTarget.self:
          if (!target.isSelf) {
            continue;
          }
          break;
        case ActionLinkedEffectTarget.externalTargets:
          if (!target.isExternal) {
            continue;
          }
          break;
      }

      if (!_passesLinkedEffectHitGate(
        definition: definition,
        linkedEffect: linkedEffect,
        target: target,
        targetAttackResult: attackResult,
      )) {
        continue;
      }

      if (!_passesLinkedEffectSaveGate(
        content: content,
        linkedEffect: linkedEffect,
        target: target,
        savingThrowResults: savingThrowResults,
      )) {
        continue;
      }

      results.add(ActionEffectResult(linkedEffect: linkedEffect));
    }

    return List<ActionEffectResult>.unmodifiable(results);
  }

  bool _passesLinkedEffectSaveGate({
    required ActionContent content,
    required ActionLinkedEffect linkedEffect,
    required List<ActionSavingThrowResult> savingThrowResults,
    ActionTarget? target,
    bool auxiliarySelf = false,
  }) {
    if (linkedEffect.saveBehavior == ActionLinkedEffectSaveBehavior.ignore) {
      return true;
    }

    if (auxiliarySelf) {
      return true;
    }

    if (target == null) {
      return true;
    }

    final sourceEffect = _linkedEffectSourceEffect(
      content: content,
      linkedEffect: linkedEffect,
    );

    if (sourceEffect == null || !sourceEffect.usesSavingThrow) {
      return true;
    }

    ActionSavingThrowResult? save;

    for (final candidate in savingThrowResults) {
      if (candidate.request.targetId != target.id) {
        continue;
      }
      if (candidate.request.effectId != sourceEffect.id) {
        continue;
      }
      save = candidate;
      break;
    }

    if (save == null || !save.saved) {
      return true;
    }

    switch (linkedEffect.saveBehavior) {
      case ActionLinkedEffectSaveBehavior.ignore:
        return true;
      case ActionLinkedEffectSaveBehavior.preventOnSuccess:
        return false;
      case ActionLinkedEffectSaveBehavior.followSource:
        switch (save.request.successEffect) {
          case SaveSuccessEffect.full:
          case SaveSuccessEffect.half:
            return true;
          case SaveSuccessEffect.none:
            return false;
        }
    }
  }

  List<ActionEffectResult> _buildAuxiliarySelfLinkedEffects({
    required ActionDefinition definition,
    required ActionContent content,
    required ActionResolutionContext context,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    if (context.targets.any((target) => target.isSelf)) {
      return const [];
    }

    final results = <ActionEffectResult>[];

    for (final linkedEffect in content.linkedEffects) {
      if (linkedEffect.target != ActionLinkedEffectTarget.self) {
        continue;
      }

      if (!_passesLinkedEffectHitGate(
        definition: definition,
        linkedEffect: linkedEffect,
        attackResultsByTargetId: attackResultsByTargetId,
        auxiliarySelf: true,
      )) {
        continue;
      }

      if (!_passesLinkedEffectSaveGate(
        content: content,
        linkedEffect: linkedEffect,
        savingThrowResults: savingThrowResults,
        auxiliarySelf: true,
      )) {
        continue;
      }

      results.add(ActionEffectResult(linkedEffect: linkedEffect));
    }

    return List<ActionEffectResult>.unmodifiable(results);
  }

  ActionTargetResult? _buildAuxiliarySelfTargetResult({
    required ActionDefinition definition,
    required ActionContent content,
    required ActionResolutionContext context,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    final effects = _buildAuxiliarySelfLinkedEffects(
      definition: definition,
      content: content,
      context: context,
      attackResultsByTargetId: attackResultsByTargetId,
      savingThrowResults: savingThrowResults,
    );

    if (effects.isEmpty) {
      return null;
    }

    return ActionTargetResult(
      target: const ActionTarget.self(participatesInAttackRoll: false),
      diceResult: const ActionDiceResult(parts: []),
      attackResult: null,
      savingThrows: const [],
      effects: effects,
      auxiliary: true,
    );
  }

  List<ActionSavingThrowRequest> collectSavingThrowRequests({
    required PreparedActionResolution prepared,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    final requests = <ActionSavingThrowRequest>[];

    for (final target in prepared.context.targets) {
      final targetAttackResult = attackResultsByTargetId[target.id];

      final selected = selectedParts(
        plan: prepared.plan,
        context: prepared.context,
        target: target,
        attackResult: targetAttackResult,
      );

      for (final effect in prepared.plan.content.effects) {
        if (!_abilityEffectEnabledForContext(effect, prepared.context)) {
          continue;
        }

        if (!_effectNeedsSavingThrowForTarget(
          prepared: prepared,
          effect: effect,
          target: target,
          selectedParts: selected,
          attackResult: targetAttackResult,
        )) {
          continue;
        }

        requests.add(
          ActionSavingThrowRequest(
            id: '${target.id}:${effect.id}',
            targetId: target.id,
            effectId: effect.id,
            effectName: effect.name,
            ability: effect.savingThrowAbility,
            dc: statResolver.effectSaveDc(plan: prepared.plan, effect: effect),
            successEffect: effect.saveSuccessEffect,
            rollMode: target.isSelf
                ? character.savingThrowRollMode(effect.savingThrowAbility)
                : SavingThrowRollMode.normal,
          ),
        );
      }
    }

    return List<ActionSavingThrowRequest>.unmodifiable(requests);
  }

  PreparedActionResolution prepareAbilityAction({
    required CharacterAbility ability,
    required ActionResolutionContext context,
    Iterable<int> criticalMinimumRollSources = const [],
    bool forcedCritical = false,
    bool? empoweredCritical,
  }) {
    final plan = prepareAbility(ability: ability, context: context);

    final sources = criticalMinimumRollSources.isEmpty
        ? character.criticalMinimumRollSourcesForAbility(ability)
        : criticalMinimumRollSources;

    final effectiveEmpoweredCritical =
        empoweredCritical ?? character.empoweredCriticalForAbility(ability);

    final criticalProfile = buildCriticalProfile(
      minimumRollSources: sources,
      forcedCritical: forcedCritical,
      empowered: effectiveEmpoweredCritical,
      empoweredMultiplier: character.empoweredCriticalMultiplierForAbility(
        ability,
      ),
      empoweredFormula: character.empoweredCriticalFormulaForAbility(ability),
      currentTurn: character.combatTurnSequence <= 0
          ? 1
          : character.combatTurnSequence,
      resources: character.empoweredCriticalResourceValues,
      resourceMaximums: character.empoweredCriticalResourceMaximumValues,
      counters: character.empoweredCriticalCounterValues,
      charges: character.empoweredCriticalChargesForAbility(ability),
      maxCharges: character.empoweredCriticalMaxChargesForAbility(ability),
    );

    final costs = <ActionCost>[
      // =========================================================================
      // COSTES BASE
      // =========================================================================
      ...plan.costs,

      // =========================================================================
      // PARTES SELECCIONADAS
      // =========================================================================
      ...collectSelectedPartCosts(plan: plan, context: context),

      // =========================================================================
      // BONUSES ACTIVOS / SELECCIONADOS
      // =========================================================================
      ...collectSelectedBonusCosts(plan: plan, context: context),
    ];

    final normalizedCosts = ActionCostResolver(
      character: character,
    ).combineCosts(costs);

    return PreparedActionResolution(
      source: ActionSource.ability(ability),
      definition: ActionDefinition.fromAbility(ability),
      context: context,
      plan: plan,
      criticalProfile: criticalProfile,
      costs: List<ActionCost>.unmodifiable(normalizedCosts),
    );
  }

  ActionCostValidationResult validatePreparedActionCosts(
    PreparedActionResolution prepared,
  ) {
    final resolver = ActionCostResolver(character: character);

    return resolver.validate(prepared.costs);
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

  bool _isOptionalGroupSelectedForTargetResolution({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required String groupId,
    ActionTarget? target,
  }) {
    switch (plan.definition.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        return context.isOptionalGroupSelected(groupId);

      case AbilityTargetResolutionMode.independent:
        if (target == null) {
          return false;
        }

        return context.isOptionalGroupSelectedForTarget(target.id, groupId);
    }
  }

  List<ActionChanceCheck> collectCriticalChanceChecks({
    required ActionResolutionPlan plan,
    required bool critical,
    required ActionResolutionContext context,
    ActionTarget? target,
    Iterable<CriticalDamageBonus>? bonuses,
  }) {
    if (!critical) {
      return const [];
    }

    final checks = <ActionChanceCheck>[];

    final activeBonuses = bonuses ?? _activeCriticalDamageBonusesForPlan(plan);

    for (final bonus in activeBonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      if (bonus.hasCondition) {
        final result = const FormulaEvaluator().evaluate(
          bonus.condition!,
          context: context.buildFormulaContext(target: target),
        );

        if (!result.valid || result.value == 0) {
          continue;
        }
      }

      if (bonus.optional) {
        final selected = _isOptionalGroupSelectedForTargetResolution(
          plan: plan,
          context: context,
          groupId: bonus.effectiveOptionalGroupId,
          target: target,
        );

        if (!selected) {
          continue;
        }
      }

      if (bonus.alwaysTriggers) {
        continue;
      }

      checks.add(
        ActionChanceCheck(
          id: 'critical_bonus:${bonus.id}',
          label: bonus.effectiveOptionalLabel,
          chancePercent: bonus.chancePercent,
        ),
      );
    }

    return checks;
  }

  int _resolveTargetTotalForEffectType({
    required ActionTarget target,
    required ActionDiceResult diceResult,
    required AbilityEffectType effectType,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    final relevantParts = diceResult.parts.where(
      (part) => part.request.effectType == effectType,
    );

    // Las resistencias solo pueden resolverse automáticamente para el propio
    // personaje, porque conocemos sus pasivas. Se aplican por componente de
    // daño para respetar el tipo (fuego, frío, cortante, etc.).
    if (effectType == AbilityEffectType.damage && target.isSelf) {
      var resistedTotal = 0;

      for (final part in relevantParts) {
        var partTotal = part.total;
        final request = part.request;

        if (request.sourceType == ActionDiceSourceType.ability &&
            request.effectId.isNotEmpty) {
          ActionSavingThrowResult? save;
          for (final candidate in savingThrowResults) {
            if (candidate.request.targetId == target.id &&
                candidate.request.effectId == request.effectId) {
              save = candidate;
              break;
            }
          }

          if (save != null && save.saved) {
            switch (save.request.successEffect) {
              case SaveSuccessEffect.full:
                break;
              case SaveSuccessEffect.half:
                partTotal ~/= 2;
                break;
              case SaveSuccessEffect.none:
                partTotal = 0;
                break;
            }
          }
        }

        resistedTotal += character.applyDamageResistance(
          partTotal,
          request.damageType,
        );
      }

      return resistedTotal;
    }

    final groupedAbilityEffects = <String, int>{};

    var independentBonuses = 0;

    // ===========================================================================
    // AGRUPAR
    // ===========================================================================

    for (final part in relevantParts) {
      final request = part.request;

      // -------------------------------------------------------------------------
      // COMPONENTES DE UN ABILITY EFFECT
      //
      // Estos pueden estar controlados por el save de ese effect.
      // -------------------------------------------------------------------------

      if (request.sourceType == ActionDiceSourceType.ability &&
          request.effectId.isNotEmpty) {
        groupedAbilityEffects[request.effectId] =
            (groupedAbilityEffects[request.effectId] ?? 0) + part.total;

        continue;
      }

      // -------------------------------------------------------------------------
      // BONOS INDEPENDIENTES
      //
      // Pasivas, efectos, critical extra...
      //
      // No heredan automáticamente la salvación del AbilityEffect.
      // -------------------------------------------------------------------------

      independentBonuses += part.total;
    }

    var total = independentBonuses;

    // ===========================================================================
    // APLICAR SAVES
    // ===========================================================================

    for (final entry in groupedAbilityEffects.entries) {
      var effectTotal = entry.value;

      ActionSavingThrowResult? save;

      for (final candidate in savingThrowResults) {
        if (candidate.request.targetId != target.id) {
          continue;
        }

        if (candidate.request.effectId != entry.key) {
          continue;
        }

        save = candidate;
        break;
      }

      if (save != null && save.saved) {
        switch (save.request.successEffect) {
          case SaveSuccessEffect.full:
            break;

          case SaveSuccessEffect.half:
            effectTotal ~/= 2;
            break;

          case SaveSuccessEffect.none:
            effectTotal = 0;
            break;
        }
      }

      total += effectTotal;
    }

    return total;
  }

  ({int damage, int healing, int mitigation}) _resolveTargetFinalValues({
    required ActionTarget target,
    required ActionDiceResult diceResult,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    return (
      damage: _resolveTargetTotalForEffectType(
        target: target,
        diceResult: diceResult,
        effectType: AbilityEffectType.damage,
        savingThrowResults: savingThrowResults,
      ),
      healing: _resolveTargetTotalForEffectType(
        target: target,
        diceResult: diceResult,
        effectType: AbilityEffectType.healing,
        savingThrowResults: savingThrowResults,
      ),
      mitigation: _resolveTargetTotalForEffectType(
        target: target,
        diceResult: diceResult,
        effectType: AbilityEffectType.mitigation,
        savingThrowResults: savingThrowResults,
      ),
    );
  }

  List<ActionExternalRequirement>
  orderedPreResolutionExternalRequirementsForTarget({
    required ActionSource source,
    required ActionDefinition definition,
    required ActionContent content,
    required ActionResolutionContext context,
    required ActionTarget target,
  }) {
    final requirements = orderedPreResolutionExternalRequirements(
      source: source,
      definition: definition,
      content: content,
    );

    if (requirements.isEmpty) {
      return const [];
    }

    final result = <ActionExternalRequirement>[];

    for (final requirement in requirements) {
      final resolved = tryResolveKnownExternalRequirement(
        context: context,
        target: target,
        requirement: requirement,
      );

      if (resolved) {
        continue;
      }

      result.add(requirement);
    }

    return List<ActionExternalRequirement>.unmodifiable(result);
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
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    final targetResults = <ActionTargetResult>[];

    for (final target in context.targets) {
      final targetAttackResult = attackResultsByTargetId[target.id];

      final targetDiceResult = _filterDiceResultForTarget(
        plan: plan,
        context: context,
        diceResult: diceResult,
        attackResult: targetAttackResult,
        target: target,
      );

      final targetSavingThrows = savingThrowResults
          .where((result) => result.request.targetId == target.id)
          .toList(growable: false);

      final finalValues = _resolveTargetFinalValues(
        target: target,
        diceResult: targetDiceResult,
        savingThrowResults: targetSavingThrows,
      );

      targetResults.add(
        ActionTargetResult(
          target: target,

          diceResult: targetDiceResult,

          attackResult: targetAttackResult,

          savingThrows: targetSavingThrows,

          effects: _buildLinkedEffectResultsForTarget(
            definition: plan.definition,
            content: plan.content,
            target: target,
            savingThrowResults: targetSavingThrows,
            attackResult: targetAttackResult,
          ),

          resolvedDamage: finalValues.damage,

          resolvedHealing: finalValues.healing,

          resolvedMitigation: finalValues.mitigation,
        ),
      );
    }

    // ===========================================================================
    // TARGETS AUXILIARES
    // ===========================================================================

    final auxiliarySelf = _buildAuxiliarySelfTargetResult(
      definition: plan.definition,
      content: plan.content,
      context: context,
      attackResultsByTargetId: attackResultsByTargetId,
      savingThrowResults: savingThrowResults,
    );

    if (auxiliarySelf != null) {
      targetResults.add(auxiliarySelf);
    }

    return ActionResolutionResult(
      source: plan.source,
      targetResolutionMode: AbilityTargetResolutionMode.shared,
      targetResults: targetResults,
      attackResult: attackResult,
      chanceResults: List<ActionChanceResult>.unmodifiable(chanceResults),
      chanceResultsByTargetId: const {},
      criticalProfile: criticalProfile,

      selectedOptionalGroupIds: context.selectedOptionalGroupIds,

      selectedOptionalGroupIdsByTargetId:
          context.selectedOptionalGroupIdsByTargetId,

      costs: List.unmodifiable(costs),

      preResolutionExternalVariablesByTargetId: context
          .snapshotTargetExternalVariables(),

      externalVariablesByTargetId: context.snapshotTargetExternalVariables(),
    );
  }

  ActionResolutionResult buildIndependentResolutionResult({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required Map<String, ActionDiceResult> diceResultsByTargetId,
    required ActionCriticalProfile criticalProfile,
    ActionAttackResult? attackResult,
    List<ActionCost> costs = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
    Map<String, List<ActionChanceResult>> chanceResultsByTargetId = const {},
  }) {
    final targetResults = <ActionTargetResult>[];

    for (final target in context.targets) {
      final rawDiceResult = diceResultsByTargetId[target.id];

      if (rawDiceResult == null) {
        throw StateError('Falta el resultado para el objetivo ${target.id}.');
      }

      final targetAttackResult = attackResultsByTargetId[target.id];

      final diceResult = _filterDiceResultForTarget(
        plan: plan,
        context: context,
        diceResult: rawDiceResult,
        attackResult: targetAttackResult,
        target: target,
      );

      final targetSavingThrows = savingThrowResults
          .where((result) => result.request.targetId == target.id)
          .toList(growable: false);

      final finalValues = _resolveTargetFinalValues(
        target: target,
        diceResult: diceResult,
        savingThrowResults: targetSavingThrows,
      );

      targetResults.add(
        ActionTargetResult(
          target: target,

          diceResult: diceResult,

          attackResult: targetAttackResult,

          savingThrows: targetSavingThrows,

          effects: _buildLinkedEffectResultsForTarget(
            definition: plan.definition,
            content: plan.content,
            target: target,
            savingThrowResults: targetSavingThrows,
            attackResult: targetAttackResult,
          ),

          resolvedDamage: finalValues.damage,

          resolvedHealing: finalValues.healing,

          resolvedMitigation: finalValues.mitigation,
        ),
      );
    }

    // ===========================================================================
    // TARGET SELF AUXILIAR
    // ===========================================================================

    final auxiliarySelf = _buildAuxiliarySelfTargetResult(
      definition: plan.definition,
      content: plan.content,
      context: context,
      attackResultsByTargetId: attackResultsByTargetId,
      savingThrowResults: savingThrowResults,
    );

    if (auxiliarySelf != null) {
      targetResults.add(auxiliarySelf);
    }

    return ActionResolutionResult(
      source: plan.source,

      targetResolutionMode: AbilityTargetResolutionMode.independent,

      targetResults: targetResults,

      attackResult: attackResult,

      criticalProfile: criticalProfile,

      chanceResults: const [],

      chanceResultsByTargetId:
          Map<String, List<ActionChanceResult>>.unmodifiable({
            for (final entry in chanceResultsByTargetId.entries)
              entry.key: List<ActionChanceResult>.unmodifiable(entry.value),
          }),

      selectedOptionalGroupIds: context.selectedOptionalGroupIds,

      selectedOptionalGroupIdsByTargetId:
          context.selectedOptionalGroupIdsByTargetId,

      costs: List.unmodifiable(costs),

      preResolutionExternalVariablesByTargetId: context
          .snapshotTargetExternalVariables(),

      externalVariablesByTargetId: context.snapshotTargetExternalVariables(),
    );
  }

  bool _hasUnsupportedSharedTargetSpecificSources(ActionResolutionPlan plan) {
    if (!plan.content.dealsDamage) {
      return false;
    }

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final condition = bonus.condition;
      if (condition != null &&
          _externalRequirementsFromExpression(
            condition.expression,
          ).isNotEmpty) {
        return true;
      }

      final formula = bonus.formula;
      if (formula != null &&
          _externalRequirementsFromExpression(formula.expression).isNotEmpty) {
        return true;
      }
    }

    if (plan.definition.requiresAttackRoll) {
      for (final bonus in _activeCriticalDamageBonusesForPlan(plan)) {
        final condition = bonus.condition;
        if (condition != null &&
            _externalRequirementsFromExpression(
              condition.expression,
            ).isNotEmpty) {
          return true;
        }

        final formula = bonus.formula;
        if (formula != null &&
            _externalRequirementsFromExpression(
              formula.expression,
            ).isNotEmpty) {
          return true;
        }
      }
    }

    if (plan.content.heals) {
      for (final bonus in character.activeHealingBonuses) {
        final formula = bonus.bonus.formula;
        if (formula != null &&
            _externalRequirementsFromExpression(
              formula.expression,
            ).isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  bool passiveTriggerConditionMet({
    required CharacterPassive passive,
    required PassiveTrigger trigger,
    required ActionResolutionContext context,
    required ActionTarget target,
  }) {
    final condition = trigger.condition;

    if (condition == null || condition.expression.trim().isEmpty) {
      return true;
    }

    final result = const FormulaEvaluator().evaluate(
      condition,
      context: context.buildFormulaContext(passive: passive, target: target),
    );

    return result.valid && result.value != 0;
  }

  int passiveTriggerActionModifier({
    required CharacterPassive passive,
    required PassiveTriggerAction action,
    required ActionResolutionContext context,
    required ActionTarget target,
  }) {
    final formula = action.valueFormula;

    if (formula == null || formula.expression.trim().isEmpty) {
      return 0;
    }

    final result = const FormulaEvaluator().evaluate(
      formula,
      context: context.buildFormulaContext(passive: passive, target: target),
    );

    if (!result.valid) {
      return 0;
    }

    return result.value.round();
  }

  bool _passiveTriggerUsesTargetExternalState(PassiveTrigger trigger) {
    // ===========================================================================
    // CONDICIÓN GENERAL DEL TRIGGER
    // ===========================================================================

    if (trigger.hasCondition) {
      final requirements = _externalRequirementsFromExpression(
        trigger.condition!.expression,
      );

      if (requirements.isNotEmpty) {
        return true;
      }
    }

    // ===========================================================================
    // FÓRMULAS DE TODAS LAS ACCIONES
    // ===========================================================================

    for (final action in trigger.actions) {
      final formula = action.valueFormula;

      if (formula == null || formula.expression.trim().isEmpty) {
        continue;
      }

      final requirements = _externalRequirementsFromExpression(
        formula.expression,
      );

      if (requirements.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  // ===========================================================================
  // CRITICAL EXTRA
  //
  // Estos componentes se activan A CAUSA de un crítico,
  // pero NO participan de nuevo en la transformación crítica.
  //
  // Por tanto:
  // - crítico normal    -> se tiran normalmente
  // - crítico potenciado -> se tiran normalmente
  //
  // Esto evita aplicar "crítico sobre crítico".
  // ===========================================================================
  void appendCriticalExtraDice({
    required ActionResolutionPlan plan,
    required List<ActionDiceRequestPart> parts,
    required bool critical,
    required ActionResolutionContext context,
    ActionTarget? target,
    Set<String> successfulChanceCheckIds = const {},
    Iterable<CriticalDamageBonus>? bonuses,
  }) {
    if (!critical) {
      return;
    }

    final activeBonuses = bonuses ?? _activeCriticalDamageBonusesForPlan(plan);

    for (final bonus in activeBonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      if (bonus.hasCondition) {
        final result = const FormulaEvaluator().evaluate(
          bonus.condition!,
          context: context.buildFormulaContext(target: target),
        );

        if (!result.valid || result.value == 0) {
          continue;
        }
      }

      if (bonus.optional) {
        final selected = _isOptionalGroupSelectedForTargetResolution(
          plan: plan,
          context: context,
          groupId: bonus.effectiveOptionalGroupId,
          target: target,
        );

        if (!selected) {
          continue;
        }
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

      final modifierLabel = _criticalDamageBonusModifierLabel(bonus);

      parts.add(
        ActionDiceRequestPart(
          id: 'critical_extra:${bonus.id}',
          hitBehavior: ActionHitBehavior.requireHit,
          effectId: 'critical_extra',

          effectName: bonus.name.isNotEmpty
              ? bonus.name
              : 'Daño crítico adicional',

          effectType: AbilityEffectType.damage,

          dicePools: List<DicePool>.unmodifiable(bonus.dicePools),

          baseModifier: modifier,
          modifier: modifier,
          modifierLabel: modifierLabel,

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
    int empoweredMultiplier = 2,
    String empoweredFormula = '',
    int currentTurn = 1,
    Map<String, double> resources = const {},
    Map<String, double> resourceMaximums = const {},
    Map<String, double> counters = const {},
    int charges = 0,
    int maxCharges = 0,
  }) {
    final effectiveMinimumRoll = ActionCriticalProfile.effectiveMinimumRoll(
      minimumRollSources,
    );

    return ActionCriticalProfile(
      minimumNaturalRoll: effectiveMinimumRoll,
      forcedCritical: forcedCritical,
      empowered: empowered,
      empoweredMultiplier: empoweredMultiplier.clamp(2, 10).toInt(),
      empoweredFormula: empoweredFormula.trim().isEmpty
          ? '(MAX + MOD) * ${empoweredMultiplier.clamp(2, 10)}'
          : empoweredFormula.trim(),
      currentTurn: currentTurn <= 0 ? 1 : currentTurn,
      resources: Map<String, double>.unmodifiable(resources),
      resourceMaximums: Map<String, double>.unmodifiable(resourceMaximums),
      counters: Map<String, double>.unmodifiable(counters),
      charges: charges,
      maxCharges: maxCharges,
    );
  }

  void validatePreparedTargetResolution(PreparedActionResolution prepared) {
    if (prepared.definition.targetResolutionMode !=
        AbilityTargetResolutionMode.shared) {
      return;
    }

    if (prepared.context.targets.length <= 1) {
      return;
    }

    // ===========================================================================
    // CONDITIONS DE AbilityEffectPart
    //
    // YA soportadas:
    //
    // - request shared = superset
    // - una única tirada
    // - filtrado posterior por target
    // ===========================================================================

    if (!_hasUnsupportedSharedTargetSpecificSources(prepared.plan)) {
      return;
    }

    // ===========================================================================
    // BONUSES TARGET-SPECIFIC
    //
    // Todavía pueden producir un request matemáticamente distinto por target.
    // Eso requiere independent.
    // ===========================================================================

    throw StateError(
      'Esta acción tiene componentes adicionales cuyo valor o condición '
      'depende del objetivo. Con varios objetivos requiere resolución '
      'independiente.',
    );
  }

  int preparedAttackModifier(PreparedActionResolution prepared) {
    return statResolver.attackModifier(prepared.plan);
  }

  ActionAttackResult resolvePreparedAttackRoll({
    required PreparedActionResolution prepared,
    required AttackRollMode mode,
    required int firstRoll,
    int? secondRoll,
  }) {
    final naturalRoll = selectNaturalAttackRoll(
      mode: mode,
      firstRoll: firstRoll,
      secondRoll: secondRoll,
    );

    return resolveAttackRoll(
      naturalRoll: naturalRoll,
      modifier: preparedAttackModifier(prepared),
      criticalProfile: prepared.criticalProfile,
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
    ActionTargetAttackResult? targetAttackResult,
    int? criticalNaturalRoll,
    Set<String> successfulChanceCheckIds = const {},
  }) {
    final List<AbilityEffectPart> selected;

    if (target != null) {
      // Resolución concreta de un target.
      selected = selectedParts(
        plan: plan,
        context: context,
        target: target,
        attackResult: targetAttackResult,
      );
    } else if (plan.definition.targetResolutionMode ==
            AbilityTargetResolutionMode.shared &&
        context.targets.length > 1) {
      // =======================================================================
      // SHARED + MULTI-TARGET
      //
      // La tirada compartida debe contener el superset de partes que puedan
      // aplicar a al menos un objetivo.
      //
      // La condición concreta de cada target se filtrará posteriormente
      // al construir su ActionTargetResult.
      // =======================================================================

      selected = <AbilityEffectPart>[
        for (final effect in plan.content.effects)
          if (_abilityEffectEnabledForContext(effect, context))
            for (final part in effect.parts)
              if (_partCanApplyToAnyTarget(
                plan: plan,
                context: context,
                part: part,
              ))
                part,
      ];
    } else {
      selected = selectedParts(
        plan: plan,
        context: context,
        attackResult: targetAttackResult,
      );
    }

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

    // ===========================================================================
    // DAMAGE COMPONENTS
    // ===========================================================================

    for (final damage in plan.content.damageComponents) {
      final abilityModifier = character.calculateAbilityMultipliers(
        damage.abilityModifierMultipliers,
      );

      final baseModifier = damage.flatBonus + abilityModifier;

      final effectiveCriticalType = damage.participatesInCritical
          ? criticalType
          : ActionCriticalType.none;

      final transformed = ActionCriticalDiceTransformer.transform(
        dicePools: damage.dicePools,

        baseModifier: baseModifier,

        criticalType: effectiveCriticalType,
        empoweredMultiplier: criticalProfile.empoweredMultiplier,
        empoweredFormula: criticalProfile.empoweredFormula,
        currentTurn: criticalProfile.currentTurn,
      );

      parts.add(
        ActionDiceRequestPart(
          id: 'damage:${plan.source.id}:${damage.id}',

          effectId: damage.id,

          effectName: damage.name.isNotEmpty ? damage.name : 'Daño',

          effectType: AbilityEffectType.damage,

          dicePools: transformed.dicePools,

          baseModifier: baseModifier,

          modifier: transformed.modifier,

          modifierLabel: _abilityModifierMultipliersLabel(
            damage.abilityModifierMultipliers,
          ),

          automaticValue: transformed.automaticValue,

          automaticValueLabel: transformed.automaticValue != 0
              ? _criticalAutomaticValueLabel(effectiveCriticalType)
              : '',
          empoweredCriticalFormula: transformed.empoweredFormula,
          empoweredCriticalTurn: transformed.empoweredTurn,
          empoweredCriticalMaximum: transformed.empoweredMaximum,
          empoweredCriticalResources: criticalProfile.resources,
          empoweredCriticalResourceMaximums: criticalProfile.resourceMaximums,
          empoweredCriticalCounters: criticalProfile.counters,
          empoweredCriticalCharges: criticalProfile.charges,
          empoweredCriticalMaxCharges: criticalProfile.maxCharges,

          sourceType: plan.source.isWeapon
              ? ActionDiceSourceType.weapon
              : ActionDiceSourceType.effect,

          sourceId: plan.source.id,

          sourceName: plan.source.name,

          damageType: damage.damageType,

          hitBehavior: damage.hitBehavior,
        ),
      );

      // =========================================================================
      // DADOS EXCLUSIVOS DE CRÍTICO
      // =========================================================================

      if (critical && damage.criticalDicePools.isNotEmpty) {
        parts.add(
          ActionDiceRequestPart(
            id:
                'damage_critical:'
                '${plan.source.id}:'
                '${damage.id}',

            effectId: damage.id,

            effectName: damage.name.isNotEmpty
                ? '${damage.name} · crítico'
                : 'Daño crítico',

            effectType: AbilityEffectType.damage,

            dicePools: List<DicePool>.unmodifiable(damage.criticalDicePools),

            baseModifier: 0,

            modifier: 0,

            kind: ActionDicePartKind.criticalExtra,

            sourceType: ActionDiceSourceType.criticalBonus,

            sourceId: damage.id,

            sourceName: damage.name,

            damageType: damage.damageType,

            hitBehavior: damage.hitBehavior,
          ),
        );
      }
    }

    for (final effect in plan.content.effects) {
      if (!_abilityEffectEnabledForContext(effect, context)) {
        continue;
      }

      for (final part in effect.parts) {
        if (!selected.contains(part)) {
          continue;
        }

        final baseModifier = character.abilityEffectPartModifier(part);

        final participatesInCritical =
            critical &&
            plan.definition.requiresAttackRoll &&
            effect.effectType == AbilityEffectType.damage &&
            !effect.usesSavingThrow &&
            part.participatesInCritical;

        final effectiveCriticalType = participatesInCritical
            ? criticalType
            : ActionCriticalType.none;

        final transformed = ActionCriticalDiceTransformer.transform(
          dicePools: part.dicePools,
          baseModifier: baseModifier,
          criticalType: effectiveCriticalType,
          empoweredMultiplier: criticalProfile.empoweredMultiplier,
          empoweredFormula: criticalProfile.empoweredFormula,
          currentTurn: criticalProfile.currentTurn,
        );

        parts.add(
          ActionDiceRequestPart(
            id: '${effect.id}:${part.id}',
            effectId: effect.id,
            effectName: effect.name,
            effectType: effect.effectType,
            abilityPart: part,
            dicePools: transformed.dicePools,
            baseModifier: baseModifier,
            modifier: transformed.modifier,
            modifierLabel: _abilityTypeShortLabel(plan.definition.abilityType),
            automaticValue: transformed.automaticValue,
            automaticValueLabel: transformed.automaticValue != 0
                ? _criticalAutomaticValueLabel(effectiveCriticalType)
                : '',
            empoweredCriticalFormula: transformed.empoweredFormula,
            empoweredCriticalTurn: transformed.empoweredTurn,
            empoweredCriticalMaximum: transformed.empoweredMaximum,
            empoweredCriticalResources: criticalProfile.resources,
            empoweredCriticalResourceMaximums: criticalProfile.resourceMaximums,
            empoweredCriticalCounters: criticalProfile.counters,
            empoweredCriticalCharges: criticalProfile.charges,
            empoweredCriticalMaxCharges: criticalProfile.maxCharges,
            hitBehavior: part.hitBehavior,

            sourceType: ActionDiceSourceType.ability,
            sourceId: plan.definition.id,
            sourceName: plan.definition.name,

            damageType: part.typeName,
          ),
        );
      }

      final extraMultipliers = Map<AbilityType, int>.from(
        effect.abilityModifierMultipliers,
      );

      if (extraMultipliers.isEmpty && effect.legacyAddAbilityModifier) {
        extraMultipliers[plan.definition.abilityType] = 1;
      }

      final modifierLabel = _abilityModifierMultipliersLabel(extraMultipliers);

      final hasExtra =
          effect.dicePools.isNotEmpty ||
          extraMultipliers.values.any((value) => value != 0) ||
          effect.effectBonus != 0;

      if (hasExtra) {
        final baseModifier = statResolver.effectModifier(
          plan: plan,
          effect: effect,
        );

        final participatesInCritical =
            critical &&
            plan.definition.requiresAttackRoll &&
            effect.dealsDamage &&
            !effect.usesSavingThrow &&
            effect.extraParticipatesInCritical;

        final effectiveCriticalType = participatesInCritical
            ? criticalType
            : ActionCriticalType.none;

        final transformed = ActionCriticalDiceTransformer.transform(
          dicePools: effect.dicePools,
          baseModifier: baseModifier,
          criticalType: effectiveCriticalType,
          empoweredMultiplier: criticalProfile.empoweredMultiplier,
          empoweredFormula: criticalProfile.empoweredFormula,
          currentTurn: criticalProfile.currentTurn,
        );

        parts.add(
          ActionDiceRequestPart(
            id: '${effect.id}:extra',
            hitBehavior: ActionHitBehavior.requireHit,
            effectId: effect.id,
            effectName: effect.name,
            effectType: effect.effectType,

            dicePools: transformed.dicePools,

            baseModifier: baseModifier,
            modifier: transformed.modifier,
            modifierLabel: modifierLabel,

            automaticValue: transformed.automaticValue,

            automaticValueLabel: transformed.automaticValue != 0
                ? _criticalAutomaticValueLabel(effectiveCriticalType)
                : '',
            empoweredCriticalFormula: transformed.empoweredFormula,
            empoweredCriticalTurn: transformed.empoweredTurn,
            empoweredCriticalMaximum: transformed.empoweredMaximum,
            empoweredCriticalResources: criticalProfile.resources,
            empoweredCriticalResourceMaximums: criticalProfile.resourceMaximums,
            empoweredCriticalCounters: criticalProfile.counters,
            empoweredCriticalCharges: criticalProfile.charges,
            empoweredCriticalMaxCharges: criticalProfile.maxCharges,

            sourceType: ActionDiceSourceType.ability,
            sourceId: plan.definition.id,
            sourceName: plan.definition.name,

            damageType: effect.effectTypeName,
          ),
        );
      }
    }

    if (plan.content.dealsDamage) {
      _appendDamageBonuses(
        parts: parts,
        context: context,
        target: target,
        criticalType: criticalType,
        criticalProfile: criticalProfile,
        plan: plan,
      );
    }

    if (plan.content.heals) {
      _appendHealingBonuses(parts: parts, context: context, target: target);
    }

    if (critical && plan.content.dealsDamage) {
      appendCriticalExtraDice(
        plan: plan,
        parts: parts,
        critical: critical,
        context: context,
        target: target,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );
    }

    return ActionDiceRequest(parts: parts, criticalProfile: criticalProfile);
  }

  String _abilityTypeShortLabel(AbilityType ability) {
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

  String _abilityModifierMultipliersLabel(Map<AbilityType, int> multipliers) {
    final pieces = <String>[];

    for (final entry in multipliers.entries) {
      final multiplier = entry.value;

      if (multiplier == 0) {
        continue;
      }

      final abilityLabel = _abilityTypeShortLabel(entry.key);

      if (multiplier == 1) {
        pieces.add(abilityLabel);
      } else {
        pieces.add('$abilityLabel ×$multiplier');
      }
    }

    return pieces.join(' + ');
  }

  String _damageBonusModifierLabel(DamageBonus bonus) {
    return _modifierSourceLabel(
      abilityModifierMultipliers: bonus.abilityModifierMultipliers,
      flatBonus: bonus.flatBonus,
      hasFormula: bonus.hasFormula,
    );
  }

  String _healingBonusModifierLabel(HealingBonus bonus) {
    return _modifierSourceLabel(
      abilityModifierMultipliers: bonus.abilityModifierMultipliers,
      flatBonus: bonus.flatBonus,
      hasFormula: bonus.hasFormula,
    );
  }

  String _criticalDamageBonusModifierLabel(CriticalDamageBonus bonus) {
    return _modifierSourceLabel(
      abilityModifierMultipliers: bonus.abilityModifierMultipliers,
      flatBonus: bonus.flatBonus,
      hasFormula: bonus.hasFormula,
    );
  }

  List<ActionSavingThrowResult> resolvePhysicalSavingThrows({
    required List<ActionSavingThrowRequest> requests,
    required List<ActionPhysicalSavingThrowInput> inputs,
  }) {
    if (requests.isEmpty) {
      return const [];
    }

    final inputsByRequestId = {
      for (final input in inputs) input.requestId: input,
    };

    const saveResolver = ActionSavingThrowResolver();

    final results = <ActionSavingThrowResult>[];

    for (final request in requests) {
      if (request.targetId != 'self') {
        throw StateError(
          'Las salvaciones físicas directas '
          'solo pueden resolverse para el propio personaje.',
        );
      }

      final input = inputsByRequestId[request.id];

      if (input == null) {
        throw StateError(
          'Falta la salvación física '
          'para ${request.effectName}.',
        );
      }

      final modifier = character.savingThrowBonus(request.ability);

      results.add(
        saveResolver.resolve(
          request: request,
          naturalRoll: input.naturalRoll,
          secondNaturalRoll: input.secondNaturalRoll,
          modifier: modifier,
        ),
      );
    }

    return List<ActionSavingThrowResult>.unmodifiable(results);
  }

  ActionAttackRolls resolvePreparedAttackRollsDigital({
    required AttackRollMode mode,
  }) {
    const diceResolver = ActionDiceResolver();

    final firstRoll = diceResolver.rollDigitalD20();

    final secondRoll = mode == AttackRollMode.normal
        ? null
        : diceResolver.rollDigitalD20();

    return (firstRoll: firstRoll, secondRoll: secondRoll);
  }

  List<ActionSavingThrowResult> resolveDigitalSavingThrows({
    required List<ActionSavingThrowRequest> requests,
  }) {
    if (requests.isEmpty) {
      return const [];
    }

    const saveResolver = ActionSavingThrowResolver();

    final results = <ActionSavingThrowResult>[];

    for (final request in requests) {
      if (request.targetId != 'self') {
        throw StateError(
          'Las salvaciones digitales directas '
          'solo pueden resolverse para el propio personaje.',
        );
      }

      final modifier = character.savingThrowBonus(request.ability);

      results.add(
        saveResolver.rollDigital(request: request, modifier: modifier),
      );
    }

    return List<ActionSavingThrowResult>.unmodifiable(results);
  }

  List<ActionChanceResult> resolveChanceChecksDigital({
    required List<ActionChanceCheck> checks,
  }) {
    if (checks.isEmpty) {
      return const [];
    }

    final resolver = ActionChanceResolver();

    return List<ActionChanceResult>.unmodifiable(
      checks.map(resolver.rollDigital),
    );
  }

  List<ActionChanceResult> resolveChanceChecksPhysical({
    required List<ActionChanceCheck> checks,
    required Map<String, int> rollsByCheckId,
  }) {
    if (checks.isEmpty) {
      return const [];
    }

    final resolver = ActionChanceResolver();

    final results = <ActionChanceResult>[];

    for (final check in checks) {
      final roll = rollsByCheckId[check.id];

      if (roll == null) {
        throw StateError('Falta la tirada física para ${check.id}.');
      }

      results.add(resolver.resolvePhysical(check: check, roll: roll));
    }

    return List<ActionChanceResult>.unmodifiable(results);
  }

  ActionStatResolver get statResolver {
    return ActionStatResolver(character: character);
  }

  // `hitBehavior` y `participatesInCritical` son independientes.
  //
  // - hitBehavior decide si esta parte sobrevive para un target.
  // - participatesInCritical decide cómo se transforma cuando
  //   la tirada de ataque global fue crítica.
  //
  // Por tanto, un bonus `ignoreHit + participatesInCritical` puede
  // conservar su transformación crítica incluso para un target
  // donde el ataque concreto haya fallado.
  void _appendDamageBonuses({
    required ActionResolutionPlan plan,
    required List<ActionDiceRequestPart> parts,
    required ActionResolutionContext context,
    required ActionCriticalType criticalType,
    required ActionCriticalProfile criticalProfile,
    ActionTarget? target,
  }) {
    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (!bonus.hasDamage) {
        continue;
      }

      if (!_damageBonusConditionMet(
        bonus: bonus,
        context: context,
        passive: passive,
        target: target,
      )) {
        continue;
      }

      if (!_damageBonusOptionalSelected(
        plan: plan,
        bonus: bonus,
        context: context,
        target: target,
      )) {
        continue;
      }

      final baseModifier = character.damageBonusModifier(
        bonus,
        passive: passive,
        formulaContext: context.buildFormulaContext(
          passive: passive,
          target: target,
        ),
      );

      final modifierLabel = _damageBonusModifierLabel(bonus);

      // =======================================================================
      // DADOS BASE + ESCALADO POR CARGAS
      // =======================================================================

      final effectiveDicePools = <DicePool>[...bonus.dicePools];

      if (passive != null && bonus.chargeScaling.hasScaling) {
        effectiveDicePools.addAll(
          bonus.chargeScaling.scaledDicePools(passive.currentCharges),
        );
      }

      final effectiveCriticalType = bonus.participatesInCritical
          ? criticalType
          : ActionCriticalType.none;

      final transformed = ActionCriticalDiceTransformer.transform(
        dicePools: effectiveDicePools,
        baseModifier: baseModifier,
        criticalType: effectiveCriticalType,
        empoweredMultiplier: criticalProfile.empoweredMultiplier,
        empoweredFormula: criticalProfile.empoweredFormula,
        currentTurn: criticalProfile.currentTurn,
      );

      parts.add(
        ActionDiceRequestPart(
          id:
              'damage_bonus:'
              '${passive?.id ?? 'effect'}:'
              '${bonus.id}',

          hitBehavior: bonus.hitBehavior,

          effectId: 'damage_bonus',

          effectName: bonus.name.isNotEmpty ? bonus.name : 'Daño adicional',

          effectType: AbilityEffectType.damage,

          dicePools: transformed.dicePools,

          baseModifier: baseModifier,

          modifier: transformed.modifier,

          modifierLabel: modifierLabel,

          automaticValue: transformed.automaticValue,

          automaticValueLabel: transformed.automaticValue != 0
              ? _criticalAutomaticValueLabel(effectiveCriticalType)
              : '',
          empoweredCriticalFormula: transformed.empoweredFormula,
          empoweredCriticalTurn: transformed.empoweredTurn,
          empoweredCriticalMaximum: transformed.empoweredMaximum,
          empoweredCriticalResources: criticalProfile.resources,
          empoweredCriticalResourceMaximums: criticalProfile.resourceMaximums,
          empoweredCriticalCounters: criticalProfile.counters,
          empoweredCriticalCharges: criticalProfile.charges,
          empoweredCriticalMaxCharges: criticalProfile.maxCharges,

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
    for (final active in character.activeHealingBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (!bonus.hasHealing) {
        continue;
      }

      final modifier = character.healingBonusModifier(
        bonus,
        formulaContext: context.buildFormulaContext(
          passive: passive,
          target: target,
        ),
      );

      final modifierLabel = _healingBonusModifierLabel(bonus);

      final effectiveDicePools = <DicePool>[...bonus.dicePools];

      if (passive != null && bonus.chargeScaling.hasScaling) {
        effectiveDicePools.addAll(
          bonus.chargeScaling.scaledDicePools(passive.currentCharges),
        );
      }

      parts.add(
        ActionDiceRequestPart(
          id:
              'healing_bonus:'
              '${passive?.id ?? 'effect'}:'
              '${bonus.id}',

          hitBehavior: ActionHitBehavior.ignoreHit,

          effectId: 'healing_bonus',

          effectName: bonus.name.isNotEmpty ? bonus.name : 'Curación adicional',

          effectType: AbilityEffectType.healing,

          dicePools: List<DicePool>.unmodifiable(effectiveDicePools),

          baseModifier: modifier,

          modifier: modifier,

          modifierLabel: modifierLabel,

          sourceType: passive != null
              ? ActionDiceSourceType.passive
              : ActionDiceSourceType.effect,

          sourceId: passive?.id ?? bonus.id,

          sourceName: passive?.name ?? bonus.name,
        ),
      );
    }
  }

  String _criticalAutomaticValueLabel(ActionCriticalType type) {
    switch (type) {
      case ActionCriticalType.none:
        return '';

      case ActionCriticalType.normal:
        return 'Crítico';

      case ActionCriticalType.empowered:
        return 'Crítico potenciado';
    }
  }

  // ===========================================================================
  // EXTERNAL REQUIREMENTS
  // ===========================================================================

  List<ActionExternalRequirement> orderedExternalRequirements({
    required ActionSource source,
    required ActionDefinition definition,
    required ActionContent content,
  }) {
    return orderedPreResolutionExternalRequirements(
      source: source,
      definition: definition,
      content: content,
    );
  }

  List<ActionExternalRequirement> orderedPreResolutionExternalRequirements({
    required ActionSource source,
    required ActionDefinition definition,
    required ActionContent content,
  }) {
    return _orderExternalRequirements(
      collectPreResolutionExternalRequirements(
        source: source,
        definition: definition,
        content: content,
      ),
    );
  }

  List<ActionExternalRequirement> orderedPostResolutionExternalRequirements({
    required Set<PassiveTriggerEvent> events,
  }) {
    return _orderExternalRequirements(
      collectPostResolutionExternalRequirements(events: events),
    );
  }

  List<ActionExternalRequirement>
  orderedPostResolutionExternalRequirementsForTarget({
    required ActionResolutionContext context,
    required ActionTarget target,
    required Set<PassiveTriggerEvent> events,
  }) {
    final requirements = orderedPostResolutionExternalRequirements(
      events: events,
    );

    if (requirements.isEmpty) {
      return const [];
    }

    final result = <ActionExternalRequirement>[];

    for (final requirement in requirements) {
      final resolved = tryResolveKnownExternalRequirement(
        context: context,
        target: target,
        requirement: requirement,
      );

      if (resolved) {
        continue;
      }

      result.add(requirement);
    }

    return List<ActionExternalRequirement>.unmodifiable(result);
  }

  String _healthPercentageVariableForRequirement(
    ActionExternalRequirement requirement,
  ) {
    final name = requirement.normalizedVariableName;

    if (name.startsWith('target_health_percent_before_')) {
      return 'target_health_percent_before';
    }

    return 'target_health_percent';
  }

  bool tryResolveKnownExternalRequirement({
    required ActionResolutionContext context,
    required ActionTarget target,
    required ActionExternalRequirement requirement,
  }) {
    // ===========================================================================
    // BOOLEAN YA CONOCIDO
    // ===========================================================================

    if (!requirement.isPercentageRequirement) {
      final knownAnswer = context.evaluateKnownTargetBoolean(
        target,
        requirement.normalizedVariableName,
      );

      if (knownAnswer == null) {
        return false;
      }

      applyExternalRequirementAnswer(
        context: context,
        target: target,
        requirement: requirement,
        answer: knownAnswer,
      );

      return true;
    }

    // ===========================================================================
    // PORCENTAJE
    // ===========================================================================

    final threshold = requirement.threshold;

    final operator = requirement.percentageOperator;

    if (threshold == null || operator == null) {
      return false;
    }

    final healthVariable = _healthPercentageVariableForRequirement(requirement);

    final knownAnswer = context.evaluateKnownTargetHealthThreshold(
      target,
      variableName: healthVariable,
      operator: operator,
      threshold: threshold,
    );

    if (knownAnswer == null) {
      return false;
    }

    applyExternalRequirementAnswer(
      context: context,
      target: target,
      requirement: requirement,
      answer: knownAnswer,
    );

    return true;
  }

  void applyExternalRequirementAnswer({
    required ActionResolutionContext context,
    required ActionTarget target,
    required ActionExternalRequirement requirement,
    required bool answer,
  }) {
    context.applyTargetExternalRequirementAnswer(
      target.id,
      requirement,
      answer,
    );

    if (!requirement.isPercentageRequirement) {
      return;
    }

    final threshold = requirement.threshold;

    final operator = requirement.percentageOperator;

    if (threshold == null || operator == null) {
      return;
    }

    final healthVariable = _healthPercentageVariableForRequirement(requirement);

    context.registerTargetHealthThresholdAnswer(
      target,
      variableName: healthVariable,
      operator: operator,
      threshold: threshold,
      answer: answer,
    );
  }

  List<PassiveTriggeredExternalOutcome> collectTriggersForEvent(
    PassiveTriggerEvent event,
  ) {
    final outcomes = <PassiveTriggeredExternalOutcome>[];

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) {
        continue;
      }

      for (final trigger in passive.triggers) {
        if (trigger.event != event) {
          continue;
        }

        if (trigger.actions.isEmpty) {
          continue;
        }

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

    return List<PassiveTriggeredExternalOutcome>.unmodifiable(outcomes);
  }

  List<CharacterEffectTriggeredExternalOutcome>
  collectEffectTriggeredExternalOutcomesForTarget({
    required ActionTargetResult targetResult,
    required ActionResolutionContext context,
    bool critical = false,
  }) {
    final triggerEngine = CharacterEffectTriggerEngine(character: character);

    final events = postResolutionEventsForTarget(
      targetResult,
      critical: critical,
    );

    if (events.isEmpty) {
      return const [];
    }

    final outcomes = <CharacterEffectTriggeredExternalOutcome>[];

    // ===========================================================================
    // EFECTOS ACTIVOS
    // ===========================================================================

    for (final sourceEffect in character.enabledEffects) {
      for (final trigger in sourceEffect.triggers) {
        // =========================================================================
        // EVENTO
        // =========================================================================

        if (!events.contains(trigger.event)) {
          continue;
        }

        // =========================================================================
        // TARGET
        // =========================================================================

        if (!trigger.targetsActionTarget) {
          continue;
        }

        // =========================================================================
        // SIN CONSECUENCIAS
        // =========================================================================

        if (!trigger.hasMechanicalEffects) {
          continue;
        }

        // =========================================================================
        // LÍMITE DE USO
        // =========================================================================

        if (!triggerEngine.canUseTrigger(sourceEffect, trigger)) {
          continue;
        }

        // =========================================================================
        // CONDICIÓN
        // =========================================================================

        if (!_effectTriggerConditionMet(
          trigger: trigger,
          context: context,
          target: targetResult.target,
        )) {
          continue;
        }

        // =========================================================================
        // RESULTADO PENDIENTE
        // =========================================================================

        outcomes.add(
          CharacterEffectTriggeredExternalOutcome(
            sourceEffectId: sourceEffect.id,

            sourceEffectName: sourceEffect.name,

            triggerId: trigger.id,

            targetId: targetResult.target.id,

            targetLabel: targetResult.target.label,

            usageLimit: trigger.usageLimit,

            damageBonuses: trigger.damageBonuses
                .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
                .toList(),

            healingBonuses: trigger.healingBonuses
                .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
                .toList(),

            mitigationBonuses: trigger.mitigationBonuses
                .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
                .toList(),

            linkedEffects: trigger.linkedEffects
                .map((effect) => CharacterEffect.fromMap(effect.toMap()))
                .toList(),
          ),
        );
      }
    }

    return List<CharacterEffectTriggeredExternalOutcome>.unmodifiable(outcomes);
  }

  bool _effectTriggerConditionMet({
    required CharacterEffectTrigger trigger,
    required ActionResolutionContext context,
    required ActionTarget target,
  }) {
    final condition = trigger.condition;

    if (condition == null || condition.expression.trim().isEmpty) {
      return true;
    }

    final result = const FormulaEvaluator().evaluate(
      condition,
      context: context.buildFormulaContext(target: target),
    );

    if (!result.valid) {
      return false;
    }

    return result.value != 0;
  }

  List<PassiveTriggeredExternalOutcome>
  collectTriggeredExternalOutcomesForTarget({
    required ActionTargetResult targetResult,
    required ActionResolutionContext context,
    bool critical = false,
  }) {
    final triggerEngine = PassiveTriggerEngine(character: character);

    final events = postResolutionEventsForTarget(
      targetResult,
      critical: critical,
    );

    if (events.isEmpty) {
      return const [];
    }

    final outcomes = <PassiveTriggeredExternalOutcome>[];

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) {
        continue;
      }

      for (final trigger in passive.triggers) {
        if (!events.contains(trigger.event)) {
          continue;
        }

        if (!trigger.targetsActionTarget) {
          continue;
        }

        if (trigger.actions.isEmpty) {
          continue;
        }

        if (!triggerEngine.canUseTrigger(passive, trigger)) {
          continue;
        }

        if (!passiveTriggerConditionMet(
          passive: passive,
          trigger: trigger,
          context: context,
          target: targetResult.target,
        )) {
          continue;
        }

        outcomes.add(
          PassiveTriggeredExternalOutcome(
            passiveId: passive.id,
            passiveName: passive.name,
            triggerId: trigger.id,

            targetId: targetResult.target.id,

            targetLabel: targetResult.target.label,

            savingThrow: trigger.savingThrow,

            usageLimit: trigger.usageLimit,

            actions: trigger.actions
                .map((action) => PassiveTriggerAction.fromMap(action.toMap()))
                .toList(),
          ),
        );
      }
    }

    return List<PassiveTriggeredExternalOutcome>.unmodifiable(outcomes);
  }

  Set<PassiveTriggerEvent> postResolutionEventsForTarget(
    ActionTargetResult targetResult, {
    bool critical = false,
  }) {
    final events = <PassiveTriggerEvent>{};

    final attackResult = targetResult.attackResult;

    if (attackResult != null) {
      if (attackResult.hit) {
        events.add(PassiveTriggerEvent.attackHit);

        if (critical) {
          events.add(PassiveTriggerEvent.criticalHit);
        }
      } else {
        events.add(PassiveTriggerEvent.attackMiss);
      }
    }

    if (targetResult.damage > 0) {
      events.add(PassiveTriggerEvent.damageDealt);
    }

    if (targetResult.healing > 0) {
      events.add(PassiveTriggerEvent.healingDealt);
    }

    return Set<PassiveTriggerEvent>.unmodifiable(events);
  }

  List<ActionExternalRequirement> collectPostResolutionExternalRequirements({
    required Set<PassiveTriggerEvent> events,
  }) {
    final requirements = <ActionExternalRequirement>[];

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) {
        continue;
      }

      for (final trigger in passive.triggers) {
        if (!events.contains(trigger.event)) {
          continue;
        }

        if (!_passiveEventUsesPreResolutionTargetState(trigger.event)) {
          continue;
        }

        if (trigger.event == PassiveTriggerEvent.criticalHit &&
            _passiveTriggerUsesTargetExternalState(trigger)) {
          continue;
        }

        // =======================================================================
        // CONDICIÓN DEL TRIGGER
        // =======================================================================

        if (trigger.hasCondition) {
          requirements.addAll(
            _externalRequirementsFromExpression(trigger.condition!.expression),
          );
        }

        // =======================================================================
        // FÓRMULAS DE SUS ACCIONES
        // =======================================================================

        for (final action in trigger.actions) {
          final valueFormula = action.valueFormula;

          if (valueFormula == null || valueFormula.expression.trim().isEmpty) {
            continue;
          }

          requirements.addAll(
            _externalRequirementsFromExpression(valueFormula.expression),
          );
        }
      }
    }

    return ActionExternalRequirementSet(requirements).requirements;
  }

  List<ActionExternalRequirement> collectPreResolutionExternalRequirements({
    required ActionSource source,
    required ActionDefinition definition,
    required ActionContent content,
  }) {
    final requirements = <ActionExternalRequirement>[];

    // =========================================================================
    // 1. REQUIREMENTS DEL CONTENIDO DE LA ACCIÓN
    // =========================================================================

    for (final effect in content.effects) {
      for (final part in effect.parts) {
        requirements.addAll(part.externalRequirements);
      }
    }

    // =========================================================================
    // 2. BONUS DE DAÑO / CRÍTICO
    // =========================================================================

    if (content.dealsDamage) {
      for (final active in character.activeDamageBonuses) {
        final bonus = active.bonus;

        if (bonus.hasCondition) {
          requirements.addAll(
            _externalRequirementsFromExpression(bonus.condition!.expression),
          );
        }

        if (bonus.hasFormula) {
          requirements.addAll(
            _externalRequirementsFromExpression(bonus.formula!.expression),
          );
        }
      }

      final criticalBonuses = _activeCriticalDamageBonusesForPlan(
        ActionResolutionPlan(
          source: source,
          definition: definition,
          content: content,
        ),
      );

      if (definition.requiresAttackRoll) {
        for (final bonus in criticalBonuses) {
          if (!bonus.canTrigger) {
            continue;
          }

          if (bonus.hasCondition) {
            requirements.addAll(
              _externalRequirementsFromExpression(bonus.condition!.expression),
            );
          }

          if (bonus.hasFormula) {
            requirements.addAll(
              _externalRequirementsFromExpression(bonus.formula!.expression),
            );
          }
        }
      }
    }

    // =========================================================================
    // 3. PASIVAS QUE PUEDEN REACCIONAR
    // =========================================================================

    final possibleEvents = _possiblePassiveEventsForAction(
      definition: definition,
      content: content,
    );

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) {
        continue;
      }

      for (final trigger in passive.triggers) {
        if (!possibleEvents.contains(trigger.event)) {
          continue;
        }

        if (!_passiveEventUsesPreResolutionTargetState(trigger.event)) {
          continue;
        }

        if (trigger.event == PassiveTriggerEvent.criticalHit &&
            _passiveTriggerUsesTargetExternalState(trigger)) {
          continue;
        }

        if (trigger.hasCondition) {
          requirements.addAll(
            _externalRequirementsFromExpression(trigger.condition!.expression),
          );
        }

        for (final action in trigger.actions) {
          final formula = action.valueFormula;

          if (formula == null || formula.expression.trim().isEmpty) {
            continue;
          }

          requirements.addAll(
            _externalRequirementsFromExpression(formula.expression),
          );
        }
      }
    }

    return ActionExternalRequirementSet(requirements).requirements;
  }

  void validatePassiveTriggerTargetScopes({
    required ActionDefinition definition,
    required ActionContent content,
  }) {
    final possibleEvents = _possiblePassiveEventsForAction(
      definition: definition,
      content: content,
    );

    if (!possibleEvents.contains(PassiveTriggerEvent.criticalHit)) {
      return;
    }

    for (final passive in character.enabledPassives) {
      if (!passive.enabled) {
        continue;
      }

      for (final trigger in passive.triggers) {
        if (trigger.event != PassiveTriggerEvent.criticalHit) {
          continue;
        }

        if (!_passiveTriggerUsesTargetExternalState(trigger)) {
          continue;
        }

        throw StateError(
          'El trigger crítico "${passive.name}" '
          'es global y no puede depender de variables '
          'de un objetivo concreto.',
        );
      }
    }
  }

  Set<PassiveTriggerEvent> _possiblePassiveEventsForAction({
    required ActionDefinition definition,
    required ActionContent content,
  }) {
    final events = <PassiveTriggerEvent>{};

    if (definition.requiresAttackRoll) {
      events.add(PassiveTriggerEvent.attackHit);
      events.add(PassiveTriggerEvent.attackMiss);
    }

    if (content.dealsDamage) {
      events.add(PassiveTriggerEvent.damageDealt);

      if (definition.requiresAttackRoll) {
        events.add(PassiveTriggerEvent.criticalHit);
      }
    }

    if (content.heals) {
      events.add(PassiveTriggerEvent.healingDealt);
    }

    return Set<PassiveTriggerEvent>.unmodifiable(events);
  }

  bool _shouldUseAbilityEffectPartForTarget({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required AbilityEffectPart part,
    required ActionTarget target,
  }) {
    // ===========================================================================
    // 1. CONDICIÓN
    //
    // La condición SIEMPRE se evalúa contra el target concreto.
    // ===========================================================================

    if (!context.isAbilityEffectPartAvailable(part, target: target)) {
      return false;
    }

    // ===========================================================================
    // 2. NO OPCIONAL
    // ===========================================================================

    if (!part.optional) {
      return true;
    }

    final groupId = part.effectiveOptionalGroupId;

    // ===========================================================================
    // 3. SELECCIÓN OPCIONAL
    //
    // SHARED:
    // una única selección global para toda la acción.
    //
    // INDEPENDENT:
    // cada target tiene su propia selección.
    // ===========================================================================

    switch (plan.definition.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        return context.isOptionalGroupSelected(groupId);

      case AbilityTargetResolutionMode.independent:
        return context.isOptionalGroupSelectedForTarget(target.id, groupId);
    }
  }

  bool _passiveEventUsesPreResolutionTargetState(PassiveTriggerEvent event) {
    switch (event) {
      case PassiveTriggerEvent.attackHit:
      case PassiveTriggerEvent.attackMiss:
      case PassiveTriggerEvent.criticalHit:
        return true;

      case PassiveTriggerEvent.damageDealt:
      case PassiveTriggerEvent.healingDealt:
      case PassiveTriggerEvent.healthChanged:
      case PassiveTriggerEvent.resourceChanged:
      case PassiveTriggerEvent.chargeChanged:
      case PassiveTriggerEvent.counterChanged:
      case PassiveTriggerEvent.damageReceived:
      case PassiveTriggerEvent.healingReceived:
      case PassiveTriggerEvent.effectApplied:
      case PassiveTriggerEvent.effectReceived:
      case PassiveTriggerEvent.characterDied:
      case PassiveTriggerEvent.enemyKilled:
      case PassiveTriggerEvent.turnStarted:
      case PassiveTriggerEvent.turnEnded:
      case PassiveTriggerEvent.roundStarted:
      case PassiveTriggerEvent.roundEnded:
      case PassiveTriggerEvent.manual:
      case PassiveTriggerEvent.custom:
        return false;
    }
  }

  List<ActionExternalRequirement> _orderExternalRequirements(
    List<ActionExternalRequirement> requirements,
  ) {
    if (requirements.isEmpty) {
      return const [];
    }

    const percentagePlanner = ExternalPercentageQuestionPlanner();

    final percentageRequirements = percentagePlanner.order(
      requirements
          .where((requirement) => requirement.isPercentageRequirement)
          .toList(growable: false),
    );

    final nonPercentageRequirements = requirements
        .where((requirement) => !requirement.isPercentageRequirement)
        .toList(growable: false);

    return List<ActionExternalRequirement>.unmodifiable([
      ...percentageRequirements,
      ...nonPercentageRequirements,
    ]);
  }

  ActionResolutionPlan prepareAbility({
    required CharacterAbility ability,
    required ActionResolutionContext context,
  }) {
    final automaticParts = <AbilityEffectPart>[];
    final optionalParts = <AbilityEffectPart>[];

    for (final effect in ability.effects) {
      for (final part in effect.parts) {
        // =======================================================================
        // PLAN = SUPERSET ESTRUCTURAL
        //
        // No resolvemos aquí condiciones dependientes del target.
        //
        // La selección real ocurre posteriormente mediante:
        //
        // selectedParts(
        //   context: ...,
        //   target: ...,
        // )
        //
        // Esto permite que shared e independent utilicen exactamente
        // la misma definición estructural de la habilidad.
        // =======================================================================

        if (part.optional) {
          optionalParts.add(part);
        } else {
          automaticParts.add(part);
        }
      }
    }

    final costResolver = ActionCostResolver(character: character);

    final definition = ActionDefinition.fromAbility(ability);

    final content = ActionContent.fromAbility(ability);

    final source = ActionSource.ability(ability);

    return ActionResolutionPlan(
      source: source,
      definition: definition,
      content: content,
      automaticParts: automaticParts,
      optionalParts: optionalParts,
      externalRequirements: collectPreResolutionExternalRequirements(
        source: source,
        definition: definition,
        content: content,
      ),
      costs: costResolver.costsForAbility(ability.id),
    );
  }

  bool _abilityEffectEnabledForContext(
    AbilityEffect effect,
    ActionResolutionContext context,
  ) {
    if (!effect.onlyWhenDamageFullyMitigated) {
      return true;
    }

    return context.externalFlag('damage_fully_mitigated') == true;
  }

  List<AbilityEffectPart> selectedParts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    ActionTarget? target,
    ActionTargetAttackResult? attackResult,
  }) {
    final result = <AbilityEffectPart>[];

    for (final effect in plan.content.effects) {
      if (!_abilityEffectEnabledForContext(effect, context)) {
        continue;
      }

      for (final part in effect.parts) {
        // =======================================================================
        // 1. CONDICIÓN + OPCIONALIDAD
        // =======================================================================

        final bool shouldUse;

        if (target != null) {
          shouldUse = _shouldUseAbilityEffectPartForTarget(
            plan: plan,
            context: context,
            part: part,
            target: target,
          );
        } else {
          shouldUse = context.shouldUseAbilityEffectPart(part);
        }

        if (!shouldUse) {
          continue;
        }

        // =======================================================================
        // 2. HIT / MISS
        // =======================================================================

        if (!_passesHitGate(
          requiresAttackRoll: plan.definition.requiresAttackRoll,
          behavior: part.hitBehavior,
          attackResult: attackResult,
          targetParticipatesInAttackRoll:
              target?.participatesInAttackRoll ?? true,
        )) {
          continue;
        }

        result.add(part);
      }
    }

    return List<AbilityEffectPart>.unmodifiable(result);
  }

  bool _partCanApplyToAnyTarget({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required AbilityEffectPart part,
  }) {
    if (context.targets.isEmpty) {
      return false;
    }

    for (final target in context.targets) {
      if (_shouldUseAbilityEffectPartForTarget(
        plan: plan,
        context: context,
        part: part,
        target: target,
      )) {
        return true;
      }
    }

    return false;
  }

  List<ActionChanceResult> resolveCriticalChancesDigital({
    required PreparedActionResolution prepared,
    required bool critical,
  }) {
    final checks = collectCriticalChanceChecks(
      plan: prepared.plan,
      critical: critical,
      context: prepared.context,
    );

    if (checks.isEmpty) {
      return const [];
    }

    final resolver = ActionChanceResolver();

    return List<ActionChanceResult>.unmodifiable(
      checks.map(resolver.rollDigital),
    );
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
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
    Map<String, List<ActionChanceResult>>? preResolvedChanceResultsByTargetId,
  }) {
    validateSavingThrowResults(
      prepared: prepared,
      results: savingThrowResults,
      attackResultsByTargetId: attackResultsByTargetId,
    );

    final critical = preparedActionIsCritical(
      prepared: prepared,
      attackResult: attackResult,
    );

    switch (prepared.definition.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        final chanceResults =
            preResolvedChanceResults ??
            resolveCriticalChancesDigital(
              prepared: prepared,
              critical: critical,
            );

        final successfulChanceIds = successfulChanceCheckIds(chanceResults);

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
          costs: collectResolvedActionCosts(
            plan: prepared.plan,
            context: prepared.context,
            attackResultsByTargetId: attackResultsByTargetId,
          ),
          savingThrowResults: savingThrowResults,
          attackResultsByTargetId: attackResultsByTargetId,
        );

      case AbilityTargetResolutionMode.independent:
        final chanceResultsByTarget =
            preResolvedChanceResultsByTargetId ??
            const <String, List<ActionChanceResult>>{};

        final successfulChanceIdsByTargetId = <String, Set<String>>{
          for (final entry in chanceResultsByTarget.entries)
            entry.key: successfulChanceCheckIds(entry.value),
        };

        final independentResults = resolveIndependentDiceDigital(
          prepared: prepared,
          criticalProfile: prepared.criticalProfile,
          attackResult: attackResult,
          attackResultsByTargetId: attackResultsByTargetId,
          successfulChanceCheckIdsByTargetId: successfulChanceIdsByTargetId,
        );

        return buildResolutionResult(
          plan: prepared.plan,
          context: prepared.context,
          criticalProfile: prepared.criticalProfile,
          independentDiceResults: independentResults,
          attackResult: attackResult,
          chanceResultsByTargetId: chanceResultsByTarget,
          costs: collectResolvedActionCosts(
            plan: prepared.plan,
            context: prepared.context,
            attackResultsByTargetId: attackResultsByTargetId,
          ),
          savingThrowResults: savingThrowResults,
          attackResultsByTargetId: attackResultsByTargetId,
        );
    }
  }

  ActionExecutionResult commitResolution(ActionResolutionResult result) {
    // ===========================================================================
    // 1. VALIDAR LA APLICACIÓN ANTES DE PAGAR
    //
    // Esto evita consumir recursos, cargas o usos de habilidad si el resultado
    // contiene algo que no puede aplicarse correctamente.
    // ===========================================================================

    final applier = ActionResultApplier(character: character);

    applier.validate(result);

    // ===========================================================================
    // 2. PAGAR COSTES
    // ===========================================================================

    final costResolver = ActionCostResolver(character: character);

    final payment = costResolver.pay(result.costs);

    if (!payment.valid) {
      throw StateError(
        payment.error ?? 'No se han podido pagar los costes de la acción.',
      );
    }

    // ===========================================================================
    // 3. APLICAR RESULTADO
    //
    // apply() vuelve a validar defensivamente.
    // ===========================================================================

    final application = applier.apply(result);

    // ===========================================================================
    // 4. RESULTADO FINAL
    // ===========================================================================

    return ActionExecutionResult(resolution: result, application: application);
  }

  void validateSavingThrowResults({
    required PreparedActionResolution prepared,
    required List<ActionSavingThrowResult> results,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    final requiredRequests = collectSavingThrowRequests(
      prepared: prepared,
      attackResultsByTargetId: attackResultsByTargetId,
    );

    for (final request in requiredRequests) {
      final exists = results.any((result) => result.request.id == request.id);

      if (!exists) {
        throw StateError(
          'Falta resolver la salvación '
          '${request.effectName} para '
          '${request.targetId}.',
        );
      }
    }
  }

  Map<String, ActionDiceResult> resolveIndependentDiceDigital({
    required PreparedActionResolution prepared,
    required ActionCriticalProfile criticalProfile,
    ActionAttackResult? attackResult,
    Map<String, Set<String>> successfulChanceCheckIdsByTargetId = const {},
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    final results = <String, ActionDiceResult>{};

    final diceResolver = const ActionDiceResolver();

    for (final target in prepared.context.targets) {
      final targetAttackResult = attackResultsByTargetId[target.id];

      final successfulChanceCheckIds =
          successfulChanceCheckIdsByTargetId[target.id] ?? const <String>{};

      final diceRequest = buildDiceRequest(
        plan: prepared.plan,
        context: prepared.context,
        criticalProfile: criticalProfile,
        target: target,
        targetAttackResult: targetAttackResult,
        criticalNaturalRoll: attackResult?.naturalRoll,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );

      results[target.id] = diceResolver.rollDigital(diceRequest);
    }

    return Map<String, ActionDiceResult>.unmodifiable(results);
  }

  bool hasTargetSpecificConditions(CharacterAbility ability) {
    final source = ActionSource.ability(ability);

    final definition = ActionDefinition.fromAbility(ability);

    final content = ActionContent.fromAbility(ability);

    final plan = ActionResolutionPlan(
      source: source,
      definition: definition,
      content: content,
    );

    // ===========================================================================
    // PARTES DE LA HABILIDAD
    // ===========================================================================

    final abilityHasTargetConditions = ability.effects.any(
      (effect) =>
          effect.parts.any((part) => part.externalRequirements.isNotEmpty),
    );

    if (abilityHasTargetConditions) {
      return true;
    }

    if (!content.dealsDamage) {
      return false;
    }

    // ===========================================================================
    // DAMAGE BONUSES GLOBALES
    // ===========================================================================

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;

      final condition = bonus.condition;

      if (condition != null &&
          _externalRequirementsFromExpression(
            condition.expression,
          ).isNotEmpty) {
        return true;
      }

      final formula = bonus.formula;

      if (formula != null &&
          _externalRequirementsFromExpression(formula.expression).isNotEmpty) {
        return true;
      }
    }

    // ===========================================================================
    // CRITICAL DAMAGE BONUSES
    // ===========================================================================

    if (definition.requiresAttackRoll) {
      for (final bonus in _activeCriticalDamageBonusesForPlan(plan)) {
        final condition = bonus.condition;

        if (condition != null &&
            _externalRequirementsFromExpression(
              condition.expression,
            ).isNotEmpty) {
          return true;
        }

        final formula = bonus.formula;

        if (formula != null &&
            _externalRequirementsFromExpression(
              formula.expression,
            ).isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  List<AbilityEffectPart> availableOptionalParts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    final result = <AbilityEffectPart>[];

    for (final effect in plan.content.effects) {
      if (!_abilityEffectEnabledForContext(effect, context)) {
        continue;
      }

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

    switch (plan.definition.targetResolutionMode) {
      // =========================================================================
      // SHARED
      //
      // Una misma AbilityEffectPart solo puede generar su coste una vez,
      // aunque aplique a varios targets.
      //
      // IMPORTANTE:
      // No deduplicamos por optionalGroupId.
      //
      // Un grupo opcional puede contener varias partes y cada parte puede tener
      // costes propios. El grupo controla la selección, no sustituye los costes
      // individuales de sus componentes.
      // =========================================================================

      case AbilityTargetResolutionMode.shared:
        final addedPartIds = <String>{};

        for (final target in context.targets) {
          final selected = selectedParts(
            plan: plan,
            context: context,
            target: target,
          );

          for (final part in selected) {
            if (!addedPartIds.add(part.id)) {
              continue;
            }

            costs.addAll(part.costs);
          }
        }

        break;

      // =========================================================================
      // INDEPENDENT
      //
      // Cada target representa una resolución independiente.
      //
      // Por tanto la misma parte puede generar coste varias veces si fue
      // seleccionada para varios targets.
      // =========================================================================

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

    return List<ActionCost>.unmodifiable(
      ActionCostResolver(character: character).combineCosts(costs),
    );
  }

  int selectNaturalAttackRoll({
    required AttackRollMode mode,
    required int firstRoll,
    int? secondRoll,
  }) {
    switch (mode) {
      case AttackRollMode.normal:
        return firstRoll;

      case AttackRollMode.advantage:
        if (secondRoll == null) {
          return firstRoll;
        }

        return firstRoll > secondRoll ? firstRoll : secondRoll;

      case AttackRollMode.disadvantage:
        if (secondRoll == null) {
          return firstRoll;
        }

        return firstRoll < secondRoll ? firstRoll : secondRoll;
    }
  }

  ActionCostValidationResult validateOptionalSelection({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required AbilityEffectPart candidate,
    ActionTarget? target,
  }) {
    final costResolver = ActionCostResolver(character: character);

    final currentCosts = <ActionCost>[...plan.costs];

    // ===========================================================================
    // COSTES YA SELECCIONADOS
    // ===========================================================================

    switch (plan.definition.targetResolutionMode) {
      // =========================================================================
      // SHARED
      //
      // Una parte compartida se cuenta una sola vez aunque aplique
      // a varios objetivos.
      // =========================================================================

      case AbilityTargetResolutionMode.shared:
        final addedPartIds = <String>{};

        for (final currentTarget in context.targets) {
          final selected = selectedParts(
            plan: plan,
            context: context,
            target: currentTarget,
          );

          for (final part in selected) {
            if (!addedPartIds.add(part.id)) {
              continue;
            }

            currentCosts.addAll(part.costs);
          }
        }

        break;

      // =========================================================================
      // INDEPENDENT
      //
      // Cada target tiene su propia resolución y por tanto sus propios costes.
      // =========================================================================

      case AbilityTargetResolutionMode.independent:
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

        break;
    }

    // ===========================================================================
    // CANDIDATO
    //
    // No añadimos otra vez su coste si su grupo opcional ya está seleccionado
    // en el scope correspondiente.
    // ===========================================================================

    final groupId = candidate.effectiveOptionalGroupId;

    final bool alreadySelected;

    switch (plan.definition.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        alreadySelected = context.isOptionalGroupSelected(groupId);

        break;

      case AbilityTargetResolutionMode.independent:
        alreadySelected =
            target != null &&
            context.isOptionalGroupSelectedForTarget(target.id, groupId);

        break;
    }

    if (!alreadySelected) {
      currentCosts.addAll(candidate.costs);
    }

    return costResolver.validate(costResolver.combineCosts(currentCosts));
  }

  bool _optionalAbilityPartAvailable({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required AbilityEffectPart part,
    ActionTarget? target,
  }) {
    if (target != null) {
      return context.isAbilityEffectPartAvailable(part, target: target);
    }

    if (plan.definition.targetResolutionMode ==
            AbilityTargetResolutionMode.shared &&
        context.targets.length > 1) {
      return context.targets.any(
        (currentTarget) =>
            context.isAbilityEffectPartAvailable(part, target: currentTarget),
      );
    }

    return context.isAbilityEffectPartAvailable(part, target: null);
  }

  bool _optionalDamageBonusAvailable({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required DamageBonus bonus,
    CharacterPassive? passive,
    ActionTarget? target,
  }) {
    if (target != null) {
      return _damageBonusConditionMet(
        bonus: bonus,
        context: context,
        passive: passive,
        target: target,
      );
    }

    if (plan.definition.targetResolutionMode ==
            AbilityTargetResolutionMode.shared &&
        context.targets.length > 1) {
      return context.targets.any(
        (currentTarget) => _damageBonusConditionMet(
          bonus: bonus,
          context: context,
          passive: passive,
          target: currentTarget,
        ),
      );
    }

    return _damageBonusConditionMet(
      bonus: bonus,
      context: context,
      passive: passive,
      target: null,
    );
  }

  bool _optionalCriticalDamageBonusAvailable({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required CriticalDamageBonus bonus,
    ActionTarget? target,
  }) {
    bool conditionMet(ActionTarget? currentTarget) {
      if (!bonus.hasCondition) {
        return true;
      }

      final result = const FormulaEvaluator().evaluate(
        bonus.condition!,
        context: context.buildFormulaContext(target: currentTarget),
      );

      return result.valid && result.value != 0;
    }

    if (target != null) {
      return conditionMet(target);
    }

    if (plan.definition.targetResolutionMode ==
            AbilityTargetResolutionMode.shared &&
        context.targets.length > 1) {
      return context.targets.any(conditionMet);
    }

    return conditionMet(null);
  }

  List<ActionOptionalGroup> availableOptionalGroups({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    final costsByGroup = <String, List<ActionCost>>{};

    final abilityPartsByGroup = <String, List<AbilityEffectPart>>{};

    final sourcesByGroup = <String, List<ActionOptionalSource>>{};

    final labelsByGroup = <String, String>{};

    // ===========================================================================
    // 1. OPTIONALS DE LA HABILIDAD
    // ===========================================================================

    for (final effect in plan.content.effects) {
      if (!_abilityEffectEnabledForContext(effect, context)) {
        continue;
      }

      for (final part in effect.parts) {
        if (!part.optional) {
          continue;
        }

        final available = _optionalAbilityPartAvailable(
          plan: plan,
          context: context,
          part: part,
          target: target,
        );

        if (!available) {
          continue;
        }

        final groupId = part.effectiveOptionalGroupId;

        costsByGroup.putIfAbsent(groupId, () => <ActionCost>[]);

        costsByGroup[groupId]!.addAll(part.costs);

        abilityPartsByGroup.putIfAbsent(groupId, () => <AbilityEffectPart>[]);

        abilityPartsByGroup[groupId]!.add(part);

        sourcesByGroup.putIfAbsent(groupId, () => <ActionOptionalSource>[]);

        sourcesByGroup[groupId]!.add(
          ActionOptionalSource(
            type: ActionOptionalSourceType.abilityPart,
            id: part.id,
            label: part.effectiveOptionalLabel,
          ),
        );

        labelsByGroup.putIfAbsent(groupId, () => part.effectiveOptionalLabel);
      }
    }

    // ===========================================================================
    // 2. DAMAGE BONUS OPCIONAL
    // ===========================================================================

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (!bonus.optional) {
        continue;
      }

      if (!bonus.hasDamage) {
        continue;
      }

      if (!_optionalDamageBonusAvailable(
        plan: plan,
        context: context,
        bonus: bonus,
        passive: passive,
        target: target,
      )) {
        continue;
      }

      final groupId = bonus.effectiveOptionalGroupId;

      costsByGroup.putIfAbsent(groupId, () => <ActionCost>[]);

      costsByGroup[groupId]!.addAll(bonus.costs);

      sourcesByGroup.putIfAbsent(groupId, () => <ActionOptionalSource>[]);

      sourcesByGroup[groupId]!.add(
        ActionOptionalSource(
          type: ActionOptionalSourceType.damageBonus,
          id: bonus.id,
          label: bonus.effectiveOptionalLabel,
        ),
      );

      labelsByGroup.putIfAbsent(groupId, () => bonus.effectiveOptionalLabel);
    }

    // ===========================================================================
    // 3. CRITICAL DAMAGE BONUS OPCIONAL
    //
    // Aquí solo declaramos que existe una opción.
    //
    // Que realmente aporte dados dependerá posteriormente de:
    // crítico + condición + chance.
    // ===========================================================================

    for (final bonus in _activeCriticalDamageBonusesForPlan(plan)) {
      if (!bonus.optional) {
        continue;
      }

      if (!bonus.canTrigger) {
        continue;
      }

      if (!_optionalCriticalDamageBonusAvailable(
        plan: plan,
        context: context,
        bonus: bonus,
        target: target,
      )) {
        continue;
      }

      final groupId = bonus.effectiveOptionalGroupId;

      sourcesByGroup.putIfAbsent(groupId, () => <ActionOptionalSource>[]);

      sourcesByGroup[groupId]!.add(
        ActionOptionalSource(
          type: ActionOptionalSourceType.criticalDamageBonus,
          id: bonus.id,
          label: bonus.effectiveOptionalLabel,
        ),
      );

      labelsByGroup.putIfAbsent(groupId, () => bonus.effectiveOptionalLabel);
    }

    // ===========================================================================
    // 4. CONSTRUIR GRUPOS
    // ===========================================================================

    final allGroupIds = <String>{
      ...abilityPartsByGroup.keys,
      ...sourcesByGroup.keys,
    };

    final costResolver = ActionCostResolver(character: character);

    final result = <ActionOptionalGroup>[];

    for (final groupId in allGroupIds) {
      final parts = abilityPartsByGroup[groupId] ?? const <AbilityEffectPart>[];

      final sources = sourcesByGroup[groupId] ?? const <ActionOptionalSource>[];

      final costs = costsByGroup[groupId] ?? const <ActionCost>[];

      result.add(
        ActionOptionalGroup(
          id: groupId,

          label: labelsByGroup[groupId] ?? 'Componente opcional',

          parts: List<AbilityEffectPart>.unmodifiable(parts),

          sources: List<ActionOptionalSource>.unmodifiable(sources),

          costs: List<ActionCost>.unmodifiable(
            costResolver.combineCosts(costs),
          ),
        ),
      );
    }

    return List<ActionOptionalGroup>.unmodifiable(result);
  }

  ActionCostValidationResult validateOptionalGroupSelection({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required ActionOptionalGroup group,
    ActionTarget? target,
  }) {
    final costResolver = ActionCostResolver(character: character);

    final costs = <ActionCost>[...plan.costs];

    // ===========================================================================
    // PARTES YA SELECCIONADAS
    // ===========================================================================

    switch (plan.definition.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        final addedPartIds = <String>{};

        for (final currentTarget in context.targets) {
          final selected = selectedParts(
            plan: plan,
            context: context,
            target: currentTarget,
          );

          for (final part in selected) {
            if (!addedPartIds.add(part.id)) {
              continue;
            }

            costs.addAll(part.costs);
          }
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

    // ===========================================================================
    // BONUSES YA SELECCIONADOS
    // ===========================================================================

    costs.addAll(collectSelectedBonusCosts(plan: plan, context: context));

    // ===========================================================================
    // NUEVO GRUPO
    // ===========================================================================

    final alreadySelected = target != null
        ? context.isOptionalGroupSelectedForTarget(target.id, group.id)
        : context.isOptionalGroupSelected(group.id);

    if (!alreadySelected) {
      costs.addAll(group.costs);
    }

    return costResolver.validate(costResolver.combineCosts(costs));
  }

  ActionCriticalProfile buildCriticalProfileForAbility(
    CharacterAbility ability, {
    bool forcedCritical = false,
    bool? empowered,
  }) {
    return buildCriticalProfile(
      minimumRollSources: character.criticalMinimumRollSourcesForAbility(
        ability,
      ),
      forcedCritical: forcedCritical,
      empowered: empowered ?? character.empoweredCriticalForAbility(ability),
      empoweredMultiplier: character.empoweredCriticalMultiplierForAbility(
        ability,
      ),
      empoweredFormula: character.empoweredCriticalFormulaForAbility(ability),
      currentTurn: character.combatTurnSequence <= 0
          ? 1
          : character.combatTurnSequence,
      resources: character.empoweredCriticalResourceValues,
      resourceMaximums: character.empoweredCriticalResourceMaximumValues,
      counters: character.empoweredCriticalCounterValues,
      charges: character.empoweredCriticalChargesForAbility(ability),
      maxCharges: character.empoweredCriticalMaxChargesForAbility(ability),
    );
  }

  ActionCriticalProfile buildCriticalProfileForWeapon(
    Weapon weapon, {
    bool forcedCritical = false,
    bool? empowered,
  }) {
    return buildCriticalProfile(
      minimumRollSources: character.criticalMinimumRollSourcesForWeapon(weapon),
      forcedCritical: forcedCritical,
      empowered: empowered ?? character.empoweredCriticalForWeapon(weapon),
      empoweredMultiplier: character.empoweredCriticalMultiplierForWeapon(
        weapon,
      ),
      empoweredFormula: character.empoweredCriticalFormulaForWeapon(weapon),
      currentTurn: character.combatTurnSequence <= 0
          ? 1
          : character.combatTurnSequence,
      resources: character.empoweredCriticalResourceValues,
      resourceMaximums: character.empoweredCriticalResourceMaximumValues,
      counters: character.empoweredCriticalCounterValues,
      charges: character.empoweredCriticalChargesForWeapon(weapon),
      maxCharges: character.empoweredCriticalMaxChargesForWeapon(weapon),
    );
  }

  // ===========================================================================
  // RESOLUTION SCOPES
  //
  // El Flow no necesita conocer la diferencia mecánica entre:
  //
  // shared
  // independent
  //
  // Solo recibe una lista de scopes que debe orquestar.
  //
  // shared:
  //   scope "shared"
  //   target = null
  //
  // independent:
  //   un scope por target
  // ===========================================================================

  bool resolutionScopeHasAnyHit({
    required PreparedActionResolution prepared,
    required ActionResolutionScope scope,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
  }) {
    // ===========================================================================
    // SIN ATAQUE
    // ===========================================================================

    if (!prepared.definition.requiresAttackRoll) {
      return true;
    }

    final target = scope.target;

    // ===========================================================================
    // SCOPE CON TARGET CONCRETO
    //
    // Normalmente corresponde a resolución independent.
    // ===========================================================================

    if (target != null) {
      if (!target.participatesInAttackRoll) {
        return true;
      }

      final attackResult = attackResultsByTargetId[target.id];

      // Si aún no conocemos el resultado, no bloqueamos prematuramente.
      return attackResult?.hit ?? true;
    }

    // ===========================================================================
    // SCOPE COMPARTIDO
    //
    // Un componente requireHit sigue siendo viable si:
    //
    // - algún target no participa en la tirada de ataque, o
    // - al menos un target impactó, o
    // - todavía falta conocer algún resultado.
    // ===========================================================================

    for (final currentTarget in prepared.context.targets) {
      if (!currentTarget.participatesInAttackRoll) {
        return true;
      }

      final attackResult = attackResultsByTargetId[currentTarget.id];

      if (attackResult == null || attackResult.hit) {
        return true;
      }
    }

    return false;
  }

  List<CriticalDamageBonus> _activeCriticalDamageBonusesForPlan(
    ActionResolutionPlan plan,
  ) {
    // =========================================================================
    // CONTENIDO INTRÍNSECO
    //
    // Para armas, los críticos propios ya fueron capturados por
    // ActionContent.fromWeapon(). El Resolver no vuelve a consultar Weapon.
    // =========================================================================

    final intrinsicBonuses = plan.content.criticalDamageBonuses;

    // =========================================================================
    // MODIFICADORES GLOBALES DEL PERSONAJE
    //
    // Pasivas y efectos activos se combinan con el contenido de la acción.
    // =========================================================================

    final globalBonuses = character.activeGlobalCriticalDamageBonuses;

    return List<CriticalDamageBonus>.unmodifiable([
      ...intrinsicBonuses,
      ...globalBonuses,
    ]);
  }

  ActionDiceRequest _filterPreparedDiceRequestForScope({
    required PreparedActionResolution prepared,
    required ActionResolutionScope scope,
    required ActionDiceRequest request,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
  }) {
    final hasAnyHit = resolutionScopeHasAnyHit(
      prepared: prepared,
      scope: scope,
      attackResultsByTargetId: attackResultsByTargetId,
    );

    // Si todavía hay al menos un target válido para requireHit,
    // no necesitamos modificar el request.
    if (hasAnyHit) {
      return request;
    }

    // Todos los targets relevantes fallaron.
    //
    // Conservamos únicamente componentes que ignoran hit/miss.
    final filteredParts = request.parts
        .where((part) => part.hitBehavior == ActionHitBehavior.ignoreHit)
        .toList(growable: false);

    return ActionDiceRequest(
      parts: List<ActionDiceRequestPart>.unmodifiable(filteredParts),
      criticalProfile: request.criticalProfile,
    );
  }

  List<ActionResolutionScope> resolutionScopes({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
  }) {
    switch (plan.definition.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        return const [(id: 'shared', target: null)];

      case AbilityTargetResolutionMode.independent:
        return List<ActionResolutionScope>.unmodifiable(
          context.targets.map((target) => (id: target.id, target: target)),
        );
    }
  }

  List<ActionResolutionScope> preparedResolutionScopes(
    PreparedActionResolution prepared,
  ) {
    return resolutionScopes(plan: prepared.plan, context: prepared.context);
  }

  List<ActionChanceCheck> collectPreparedCriticalChanceChecksForScope({
    required PreparedActionResolution prepared,
    required bool critical,
    required ActionResolutionScope scope,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    if (!critical) {
      return const [];
    }

    if (!resolutionScopeHasAnyHit(
      prepared: prepared,
      scope: scope,
      attackResultsByTargetId: attackResultsByTargetId,
    )) {
      return const [];
    }

    return collectCriticalChanceChecks(
      plan: prepared.plan,
      critical: true,
      context: prepared.context,
      target: scope.target,
    );
  }

  ActionDiceRequest buildPreparedDiceRequestForScope({
    required PreparedActionResolution prepared,
    required ActionResolutionScope scope,
    ActionAttackResult? attackResult,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
    Set<String> successfulChanceCheckIds = const {},
  }) {
    final target = scope.target;

    final request = buildPreparedDiceRequest(
      prepared: prepared,
      attackResult: attackResult,
      target: target,
      targetAttackResult: target == null
          ? null
          : attackResultsByTargetId[target.id],
      successfulChanceCheckIds: successfulChanceCheckIds,
    );

    return _filterPreparedDiceRequestForScope(
      prepared: prepared,
      scope: scope,
      request: request,
      attackResultsByTargetId: attackResultsByTargetId,
    );
  }

  ActionResolutionResult buildPreparedResolutionFromScopes({
    required PreparedActionResolution prepared,
    required Map<String, ActionDiceResult> diceResultsByScopeId,
    ActionAttackResult? attackResult,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
    Map<String, List<ActionChanceResult>> chanceResultsByScopeId = const {},
    List<ActionSavingThrowResult> savingThrowResults = const [],
  }) {
    switch (prepared.definition.targetResolutionMode) {
      // =======================================================================
      // SHARED
      // =======================================================================

      case AbilityTargetResolutionMode.shared:
        final diceResult = diceResultsByScopeId['shared'];

        if (diceResult == null) {
          throw StateError(
            'Falta el resultado de dados de la resolución compartida.',
          );
        }

        return buildPreparedSharedResolution(
          prepared: prepared,
          diceResult: diceResult,
          attackResult: attackResult,
          attackResultsByTargetId: attackResultsByTargetId,
          chanceResults:
              chanceResultsByScopeId['shared'] ?? const <ActionChanceResult>[],
          savingThrowResults: savingThrowResults,
        );

      // =======================================================================
      // INDEPENDENT
      // =======================================================================

      case AbilityTargetResolutionMode.independent:
        final diceResultsByTargetId = <String, ActionDiceResult>{};

        final chanceResultsByTargetId = <String, List<ActionChanceResult>>{};

        for (final target in prepared.context.targets) {
          final diceResult = diceResultsByScopeId[target.id];

          if (diceResult == null) {
            throw StateError(
              'Falta el resultado de dados para el objetivo ${target.id}.',
            );
          }

          diceResultsByTargetId[target.id] = diceResult;

          chanceResultsByTargetId[target.id] =
              chanceResultsByScopeId[target.id] ?? const <ActionChanceResult>[];
        }

        return buildPreparedIndependentResolution(
          prepared: prepared,
          diceResultsByTargetId: Map<String, ActionDiceResult>.unmodifiable(
            diceResultsByTargetId,
          ),
          attackResult: attackResult,
          attackResultsByTargetId: attackResultsByTargetId,
          chanceResultsByTargetId:
              Map<String, List<ActionChanceResult>>.unmodifiable(
                chanceResultsByTargetId,
              ),
          savingThrowResults: savingThrowResults,
        );
    }
  }

  ActionDiceRequest buildPreparedDiceRequest({
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
    ActionTargetAttackResult? targetAttackResult,
    Set<String> successfulChanceCheckIds = const {},
    ActionTarget? target,
  }) {
    return buildDiceRequest(
      plan: prepared.plan,
      context: prepared.context,
      criticalProfile: prepared.criticalProfile,
      target: target,
      targetAttackResult: targetAttackResult,
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
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    if (prepared.definition.targetResolutionMode !=
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
      costs: collectResolvedActionCosts(
        plan: prepared.plan,
        context: prepared.context,
        attackResultsByTargetId: attackResultsByTargetId,
      ),
      attackResultsByTargetId: attackResultsByTargetId,
    );
  }

  ActionResolutionResult buildPreparedIndependentResolution({
    required PreparedActionResolution prepared,
    required Map<String, ActionDiceResult> diceResultsByTargetId,
    ActionAttackResult? attackResult,
    Map<String, List<ActionChanceResult>> chanceResultsByTargetId = const {},
    List<ActionSavingThrowResult> savingThrowResults = const [],
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    if (prepared.definition.targetResolutionMode !=
        AbilityTargetResolutionMode.independent) {
      throw StateError('Esta operación requiere resolución independiente.');
    }

    return buildResolutionResult(
      plan: prepared.plan,
      context: prepared.context,
      criticalProfile: prepared.criticalProfile,
      independentDiceResults: diceResultsByTargetId,
      attackResult: attackResult,
      chanceResultsByTargetId: chanceResultsByTargetId,
      savingThrowResults: savingThrowResults,
      costs: collectResolvedActionCosts(
        plan: prepared.plan,
        context: prepared.context,
        attackResultsByTargetId: attackResultsByTargetId,
      ),
      attackResultsByTargetId: attackResultsByTargetId,
    );
  }

  List<ActionCost> collectResolvedActionCosts({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) {
    final costs = <ActionCost>[
      // ========================================================================
      // COSTES BASE DE LA HABILIDAD
      // ========================================================================
      ...plan.costs,
    ];

    // IMPORTANTE:
    //
    // Los costes de partes opcionales se cobran únicamente si la parte
    // sobrevivió a todas las condiciones finales de resolución.
    //
    // Eso incluye:
    // - condición,
    // - selección opcional,
    // - hit / miss.
    //
    // Por tanto, una parte con requireHit que falle por miss
    // NO añade su coste final.
    switch (plan.definition.targetResolutionMode) {
      // =========================================================================
      // SHARED
      //
      // Un componente compartido se paga una sola vez
      // si realmente sobrevivió para al menos un target.
      // =========================================================================

      case AbilityTargetResolutionMode.shared:
        final addedPartIds = <String>{};

        for (final target in context.targets) {
          final targetAttackResult = attackResultsByTargetId[target.id];

          final selected = selectedParts(
            plan: plan,
            context: context,
            target: target,
            attackResult: targetAttackResult,
          );

          for (final part in selected) {
            if (!addedPartIds.add(part.id)) {
              continue;
            }

            costs.addAll(part.costs);
          }
        }

        break;

      // =========================================================================
      // INDEPENDENT
      //
      // Cada target tiene su propia selección y puede generar su propio coste.
      // =========================================================================

      case AbilityTargetResolutionMode.independent:
        for (final target in context.targets) {
          final targetAttackResult = attackResultsByTargetId[target.id];

          final selected = selectedParts(
            plan: plan,
            context: context,
            target: target,
            attackResult: targetAttackResult,
          );

          for (final part in selected) {
            costs.addAll(part.costs);
          }
        }

        break;
    }
    // ===========================================================================
    // DAMAGE BONUS
    //
    // El coste definitivo se cobra únicamente si el bonus realmente sobrevivió.
    //
    // SHARED:
    //   una vez si aplica a al menos un target.
    //
    // INDEPENDENT:
    //   una vez por target donde aplica.
    // ===========================================================================

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (bonus.costs.isEmpty) {
        continue;
      }

      switch (plan.definition.targetResolutionMode) {
        // =========================================================================
        // SHARED
        // =========================================================================

        case AbilityTargetResolutionMode.shared:
          var survives = false;

          for (final target in context.targets) {
            final targetAttackResult = attackResultsByTargetId[target.id];

            if (!_damageBonusSurvivesForTarget(
              plan: plan,
              context: context,
              bonus: bonus,
              passive: passive,
              target: target,
              attackResult: targetAttackResult,
            )) {
              continue;
            }

            survives = true;
            break;
          }

          if (survives) {
            costs.addAll(bonus.costs);
          }

          break;

        // =========================================================================
        // INDEPENDENT
        // =========================================================================

        case AbilityTargetResolutionMode.independent:
          for (final target in context.targets) {
            final targetAttackResult = attackResultsByTargetId[target.id];

            if (!_damageBonusSurvivesForTarget(
              plan: plan,
              context: context,
              bonus: bonus,
              passive: passive,
              target: target,
              attackResult: targetAttackResult,
            )) {
              continue;
            }

            costs.addAll(bonus.costs);
          }

          break;
      }
    }
    // ===========================================================================
    // HEALING BONUS
    //
    // Actualmente es una contribución global a la acción.
    //
    // Por tanto su coste se paga una única vez por acción,
    // independientemente del número de targets.
    // ===========================================================================

    if (plan.content.heals) {
      for (final active in character.activeHealingBonuses) {
        final bonus = active.bonus;

        if (!bonus.hasHealing || bonus.costs.isEmpty) {
          continue;
        }

        costs.addAll(bonus.costs);
      }
    }

    return List<ActionCost>.unmodifiable(
      ActionCostResolver(character: character).combineCosts(costs),
    );
  }

  String _modifierSourceLabel({
    required Map<AbilityType, int> abilityModifierMultipliers,
    required int flatBonus,
    required bool hasFormula,
  }) {
    final pieces = <String>[];

    // =========================================================================
    // ATRIBUTOS
    // =========================================================================

    for (final entry in abilityModifierMultipliers.entries) {
      final multiplier = entry.value;

      if (multiplier == 0) {
        continue;
      }

      final abilityLabel = _abilityTypeShortLabel(entry.key);

      if (multiplier == 1) {
        pieces.add(abilityLabel);
      } else {
        pieces.add('$abilityLabel ×$multiplier');
      }
    }

    // =========================================================================
    // BONUS FIJO
    // =========================================================================

    if (flatBonus != 0) {
      pieces.add('Fijo');
    }

    // =========================================================================
    // FÓRMULA
    // =========================================================================

    if (hasFormula) {
      pieces.add('Fórmula');
    }

    return pieces.join(' + ');
  }
}
