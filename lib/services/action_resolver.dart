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
import '../models/action_effect_result.dart';
import '../models/passive.dart';
import '../models/action_hit_behavior.dart';
import '../models/critical_damage_bonus.dart';

import 'action_critical_dice_transformer.dart';
import 'formula_evaluator.dart';
import 'action_result_applier.dart';
import 'action_chance_resolver.dart';
import 'action_cost_resolver.dart';
import 'action_dice_resolver.dart';

class ActionResolver {
  final Character character;

  const ActionResolver({required this.character});

  bool preparedActionRequiresDiceMode(PreparedActionResolution prepared) {
    if (prepared.ability.requiresAttackRoll) {
      return true;
    }

    if (collectSavingThrowRequests(prepared: prepared).isNotEmpty) {
      return true;
    }

    final request = buildPreparedDiceRequest(
      prepared: prepared,
      successfulChanceCheckIds: const {},
    );

    if (request.parts.any((part) => part.requiresRoll)) {
      return true;
    }

    if (collectCriticalChanceChecks(
      critical: true,
      context: prepared.context,
    ).isNotEmpty) {
      return true;
    }

    return false;
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
    required DamageBonus bonus,
    required ActionResolutionContext context,
    ActionTarget? target,
  }) {
    if (!bonus.optional) {
      return true;
    }

    final groupId = bonus.effectiveOptionalGroupId;

    if (target == null) {
      return context.selectedOptionalGroupIds.contains(groupId);
    }

    return context.isOptionalGroupSelectedForTarget(target.id, groupId);
  }

  // ===========================================================================
  // GATING · HIT / MISS
  // ===========================================================================

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
    required CharacterAbility ability,
    required ActionHitBehavior behavior,
    ActionTargetAttackResult? attackResult,
  }) {
    if (!ability.requiresAttackRoll) {
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

  bool _passesAuxiliarySelfHitGate({
    required CharacterAbility ability,
    required ActionLinkedEffect linkedEffect,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
  }) {
    // ===========================================================================
    // SIN ATAQUE
    // ===========================================================================

    if (!ability.requiresAttackRoll) {
      return true;
    }

    // ===========================================================================
    // IGNORA HIT / MISS
    // ===========================================================================

    if (linkedEffect.effectiveHitBehavior == ActionHitBehavior.ignoreHit) {
      return true;
    }

    // ===========================================================================
    // REQUIRE HIT
    //
    // El self auxiliar no pertenece a un target externo concreto.
    //
    // Si la acción tiene varios objetivos, basta con que haya impactado
    // al menos uno para considerar cumplido "requireHit".
    // ===========================================================================

    return attackResultsByTargetId.values.any((result) => result.hit);
  }

  ActionDiceResult _filterDiceResultForTarget({
    required CharacterAbility ability,
    required ActionDiceResult diceResult,
    ActionTargetAttackResult? attackResult,
  }) {
    final parts = diceResult.parts
        .where(
          (partResult) => _passesHitGate(
            ability: ability,
            behavior: partResult.request.hitBehavior,
            attackResult: attackResult,
          ),
        )
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
          ability: prepared.ability,
          behavior: ActionHitBehavior.requireHit,
          attackResult: attackResult,
        )) {
      return true;
    }

    // ===========================================================================
    // 3. LINKED EFFECTS CONTROLADOS POR ESTE SAVE
    // ===========================================================================

    for (final linkedEffect in prepared.ability.linkedEffects) {
      if (linkedEffect.saveBehavior == ActionLinkedEffectSaveBehavior.ignore) {
        continue;
      }

      if (!_linkedEffectTargetsTarget(
        linkedEffect: linkedEffect,
        target: target,
      )) {
        continue;
      }

      final sourceEffectId = linkedEffect.normalizedSourceEffectId;

      if (sourceEffectId != effect.id) {
        continue;
      }

      if (!_passesHitGate(
        ability: prepared.ability,
        behavior: linkedEffect.effectiveHitBehavior,
        attackResult: attackResult,
      )) {
        continue;
      }

      return true;
    }

    return false;
  }

  List<ActionEffectResult> _buildLinkedEffectResultsForTarget({
    required CharacterAbility ability,
    required ActionTarget target,
    required ActionTargetAttackResult? attackResult,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    if (ability.linkedEffects.isEmpty) {
      return const [];
    }

    final results = <ActionEffectResult>[];

    for (final linkedEffect in ability.linkedEffects) {
      // =======================================================================
      // 1. TARGET
      // =======================================================================

      switch (linkedEffect.target) {
        case ActionLinkedEffectTarget.actionTarget:
          // El target normal ya viene representado por este ActionTarget.
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

      // =======================================================================
      // 2. HIT / MISS
      //
      // Una única fuente de verdad.
      // =======================================================================

      if (!_passesHitGate(
        ability: ability,
        behavior: linkedEffect.effectiveHitBehavior,
        attackResult: attackResult,
      )) {
        continue;
      }

      // =======================================================================
      // 3. SAVING THROW
      // =======================================================================

      if (!_linkedEffectPassesSavingThrow(
        linkedEffect: linkedEffect,
        target: target,
        ability: ability,
        savingThrowResults: savingThrowResults,
      )) {
        continue;
      }

      // =======================================================================
      // 4. RESULTADO
      // =======================================================================

      results.add(ActionEffectResult(linkedEffect: linkedEffect));
    }

    return List<ActionEffectResult>.unmodifiable(results);
  }

  bool _linkedEffectPassesSavingThrow({
    required ActionLinkedEffect linkedEffect,
    required CharacterAbility ability,
    required ActionTarget target,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    // ===========================================================================
    // IGNORAR SALVACIONES
    // ===========================================================================

    if (linkedEffect.saveBehavior == ActionLinkedEffectSaveBehavior.ignore) {
      return true;
    }

    // ===========================================================================
    // ENCONTRAR EFFECT ID
    // ===========================================================================

    String? sourceEffectId = linkedEffect.normalizedSourceEffectId;

    // ---------------------------------------------------------------------------
    // COMPATIBILIDAD CON HABILIDADES ANTIGUAS
    //
    // Antes ActionLinkedEffect no guardaba sourceEffectId.
    //
    // Si la habilidad solo tiene UN AbilityEffect con salvación,
    // podemos inferirlo sin ambigüedad.
    // ---------------------------------------------------------------------------

    if (sourceEffectId == null) {
      final savingEffects = ability.effects
          .where((effect) => effect.usesSavingThrow)
          .toList(growable: false);

      if (savingEffects.length == 1) {
        sourceEffectId = savingEffects.first.id;
      }
    }

    // Si no existe asociación inequívoca,
    // no dejamos que una salvación cualquiera
    // cancele el efecto.
    if (sourceEffectId == null) {
      return true;
    }

    // ===========================================================================
    // BUSCAR RESULTADO EXACTO
    // ===========================================================================

    ActionSavingThrowResult? save;

    for (final candidate in savingThrowResults) {
      if (candidate.request.targetId != target.id) {
        continue;
      }

      if (candidate.request.effectId != sourceEffectId) {
        continue;
      }

      save = candidate;

      break;
    }

    // No había salvación aplicable.
    if (save == null) {
      return true;
    }

    // Falló la salvación.
    if (!save.saved) {
      return true;
    }

    // ===========================================================================
    // SALVACIÓN EXITOSA
    // ===========================================================================

    switch (linkedEffect.saveBehavior) {
      case ActionLinkedEffectSaveBehavior.ignore:
        return true;

      case ActionLinkedEffectSaveBehavior.preventOnSuccess:
        return false;

      case ActionLinkedEffectSaveBehavior.followSource:
        switch (save.request.successEffect) {
          case SaveSuccessEffect.full:
            return true;

          case SaveSuccessEffect.half:
            return true;

          case SaveSuccessEffect.none:
            return false;
        }
    }
  }

  List<ActionEffectResult> _buildAuxiliarySelfLinkedEffects({
    required CharacterAbility ability,
    required ActionResolutionContext context,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
  }) {
    // ===========================================================================
    // SELF YA ES TARGET NORMAL
    //
    // Si self ya forma parte de la resolución normal,
    // _buildLinkedEffectResultsForTarget() se ocupa de él.
    // ===========================================================================

    if (context.targets.any((target) => target.isSelf)) {
      return const [];
    }

    final results = <ActionEffectResult>[];

    for (final linkedEffect in ability.linkedEffects) {
      // =========================================================================
      // SOLO SELF
      // =========================================================================

      if (linkedEffect.target != ActionLinkedEffectTarget.self) {
        continue;
      }

      // =========================================================================
      // HIT / MISS
      // =========================================================================

      if (!_passesAuxiliarySelfHitGate(
        ability: ability,
        linkedEffect: linkedEffect,
        attackResultsByTargetId: attackResultsByTargetId,
      )) {
        continue;
      }

      // =========================================================================
      // SAVES
      //
      // Un self auxiliar NO utiliza la salvación de un enemigo externo.
      //
      // Ejemplo:
      //
      // Golpe ígneo
      // ├─ enemigo: CON save
      // └─ atacante: obtiene Furia
      //
      // El save del enemigo no controla la Furia del atacante.
      // =========================================================================

      results.add(ActionEffectResult(linkedEffect: linkedEffect));
    }

    return List<ActionEffectResult>.unmodifiable(results);
  }

  ActionTargetResult? _buildAuxiliarySelfTargetResult({
    required CharacterAbility ability,
    required ActionResolutionContext context,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
  }) {
    final effects = _buildAuxiliarySelfLinkedEffects(
      ability: ability,
      context: context,
      attackResultsByTargetId: attackResultsByTargetId,
    );

    if (effects.isEmpty) {
      return null;
    }

    return ActionTargetResult(
      target: const ActionTarget.self(),

      // Target auxiliar:
      // no tiene dados propios.
      diceResult: const ActionDiceResult(parts: []),

      // No participa en la tirada de ataque.
      attackResult: null,

      // Tampoco tiene salvaciones propias.
      savingThrows: const [],

      effects: effects,
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

      for (final effect in prepared.ability.effects) {
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
            dc: character.abilityEffectSaveDc(prepared.ability, effect),
            successEffect: effect.saveSuccessEffect,
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
    required ActionResolutionContext context,
    ActionTarget? target,
    Iterable<CriticalDamageBonus>? bonuses,
  }) {
    if (!critical) {
      return const [];
    }

    final checks = <ActionChanceCheck>[];

    final activeBonuses = bonuses ?? character.activeCriticalDamageBonuses();

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
        final groupId = bonus.effectiveOptionalGroupId;

        final selected = target != null
            ? context.isOptionalGroupSelectedForTarget(target.id, groupId)
            : context.isOptionalGroupSelected(groupId);

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

  ({int damage, int healing}) _resolveTargetFinalValues({
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
    );
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
        ability: plan.ability,
        diceResult: diceResult,
        attackResult: targetAttackResult,
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
            ability: plan.ability,
            target: target,
            savingThrowResults: targetSavingThrows,
            attackResult: targetAttackResult,
          ),

          resolvedDamage: finalValues.damage,

          resolvedHealing: finalValues.healing,
        ),
      );
    }

    // ===========================================================================
    // TARGETS AUXILIARES
    // ===========================================================================

    final auxiliarySelf = _buildAuxiliarySelfTargetResult(
      ability: plan.ability,
      context: context,
      attackResultsByTargetId: attackResultsByTargetId,
    );

    if (auxiliarySelf != null) {
      targetResults.add(auxiliarySelf);
    }

    return ActionResolutionResult(
      ability: plan.ability,
      targetResolutionMode: AbilityTargetResolutionMode.shared,
      targetResults: targetResults,
      attackResult: attackResult,
      chanceResults: List<ActionChanceResult>.unmodifiable(chanceResults),
      chanceResultsByTargetId: const {},
      criticalProfile: criticalProfile,
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
        ability: plan.ability,
        diceResult: rawDiceResult,
        attackResult: targetAttackResult,
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
            ability: plan.ability,
            target: target,
            savingThrowResults: targetSavingThrows,
            attackResult: targetAttackResult,
          ),

          resolvedDamage: finalValues.damage,

          resolvedHealing: finalValues.healing,
        ),
      );
    }

    // ===========================================================================
    // TARGET SELF AUXILIAR
    // ===========================================================================

    final auxiliarySelf = _buildAuxiliarySelfTargetResult(
      ability: plan.ability,
      context: context,
      attackResultsByTargetId: attackResultsByTargetId,
    );

    if (auxiliarySelf != null) {
      targetResults.add(auxiliarySelf);
    }

    return ActionResolutionResult(
      ability: plan.ability,
      targetResolutionMode: AbilityTargetResolutionMode.independent,
      targetResults: targetResults,
      attackResult: attackResult,
      criticalProfile: criticalProfile,

      // Independent no tiene un único resultado de chance compartido.
      chanceResults: const [],

      chanceResultsByTargetId:
          Map<String, List<ActionChanceResult>>.unmodifiable({
            for (final entry in chanceResultsByTargetId.entries)
              entry.key: List<ActionChanceResult>.unmodifiable(entry.value),
          }),

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
    Map<String, List<ActionChanceResult>> chanceResultsByTargetId = const {},
    List<ActionCost> costs = const [],
    List<ActionSavingThrowResult> savingThrowResults = const [],
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
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
          attackResultsByTargetId: attackResultsByTargetId,
        );

      case AbilityTargetResolutionMode.independent:
        return buildIndependentResolutionResult(
          plan: plan,
          context: context,
          diceResultsByTargetId: independentDiceResults,
          criticalProfile: criticalProfile,
          attackResult: attackResult,
          chanceResultsByTargetId: chanceResultsByTargetId,
          costs: costs,
          savingThrowResults: savingThrowResults,
          attackResultsByTargetId: attackResultsByTargetId,
        );
    }
  }

  void appendCriticalExtraDice({
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

    final activeBonuses = bonuses ?? character.activeCriticalDamageBonuses();

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
        final groupId = bonus.effectiveOptionalGroupId;

        final selected = target == null
            ? context.selectedOptionalGroupIds.contains(groupId)
            : context.isOptionalGroupSelectedForTarget(target.id, groupId);

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

  void validatePreparedTargetResolution(PreparedActionResolution prepared) {
    if (prepared.ability.targetResolutionMode !=
        AbilityTargetResolutionMode.shared) {
      return;
    }

    if (prepared.context.targets.length <= 1) {
      return;
    }

    if (!hasTargetSpecificConditions(prepared.ability)) {
      return;
    }

    throw StateError(
      'Una resolución compartida con condiciones '
      'específicas por objetivo no puede resolverse '
      'con varios objetivos. Usa resolución independiente.',
    );
  }

  int preparedAttackModifier(PreparedActionResolution prepared) {
    return character.characterAbilityAttackBonus(prepared.ability);
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
    final selected = selectedParts(
      plan: plan,
      context: context,
      target: target,
      attackResult: targetAttackResult,
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

        final participatesInCritical =
            critical &&
            plan.ability.requiresAttackRoll &&
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
        );

        parts.add(
          ActionDiceRequestPart(
            id: '${effect.id}:${part.id}',
            effectId: effect.id,
            effectName: effect.name,
            effectType: effect.effectType,
            abilityPart: part,
            dicePools: transformed.dicePools,
            modifier: transformed.modifier,
            automaticValue: transformed.automaticValue,

            hitBehavior: part.hitBehavior,

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

        final participatesInCritical =
            critical &&
            plan.ability.requiresAttackRoll &&
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
        );

        parts.add(
          ActionDiceRequestPart(
            id: '${effect.id}:extra',
            hitBehavior: ActionHitBehavior.requireHit,
            effectId: effect.id,
            effectName: effect.name,
            effectType: effect.effectType,

            dicePools: transformed.dicePools,
            modifier: transformed.modifier,
            automaticValue: transformed.automaticValue,

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
      appendCriticalExtraDice(
        parts: parts,
        critical: critical,
        context: context,
        target: target,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );
    }

    return ActionDiceRequest(parts: parts, criticalProfile: criticalProfile);
  }

  int savingThrowModifierForRequest(
    ActionSavingThrowRequest request, {
    Map<String, int> externalModifiers = const {},
  }) {
    if (request.targetId == 'self') {
      return character.savingThrowBonus(request.ability);
    }

    return externalModifiers[request.id] ?? 0;
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
    required List<ActionDiceRequestPart> parts,
    required ActionResolutionContext context,
    required ActionCriticalType criticalType,
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

      final effectiveCriticalType = bonus.participatesInCritical
          ? criticalType
          : ActionCriticalType.none;

      final transformed = ActionCriticalDiceTransformer.transform(
        dicePools: bonus.dicePools,
        baseModifier: baseModifier,
        criticalType: effectiveCriticalType,
      );

      parts.add(
        ActionDiceRequestPart(
          id: 'damage_bonus:${passive?.id ?? 'effect'}:${bonus.id}',
          hitBehavior: bonus.hitBehavior,
          effectId: 'damage_bonus',
          effectName: bonus.name.isNotEmpty ? bonus.name : 'Daño adicional',
          effectType: AbilityEffectType.damage,

          dicePools: transformed.dicePools,
          modifier: transformed.modifier,
          automaticValue: transformed.automaticValue,

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
          hitBehavior: ActionHitBehavior.ignoreHit,
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
    // 2. REQUIREMENTS DE BONUS DE DAÑO / CRÍTICO
    //
    // Estas condiciones también se evalúan dentro del nuevo ActionResolver y
    // pueden depender de información temporal del objetivo.
    // =========================================================================

    if (_abilityDealsDamage(ability)) {
      for (final active in character.activeDamageBonuses) {
        final bonus = active.bonus;

        // -------------------------------------------------------------------------
        // CONDICIÓN
        // -------------------------------------------------------------------------

        if (bonus.hasCondition) {
          requirements.addAll(
            _externalRequirementsFromExpression(bonus.condition!.expression),
          );
        }

        // -------------------------------------------------------------------------
        // FÓRMULA DE VALOR
        // -------------------------------------------------------------------------

        if (bonus.hasFormula) {
          requirements.addAll(
            _externalRequirementsFromExpression(bonus.formula!.expression),
          );
        }
      }

      // -------------------------------------------------------------------------
      // CRITICAL DAMAGE BONUS
      // -------------------------------------------------------------------------

      if (ability.requiresAttackRoll) {
        for (final bonus in character.activeCriticalDamageBonuses()) {
          // -----------------------------------------------------------------------
          // CONDICIÓN
          // -----------------------------------------------------------------------

          if (bonus.hasCondition) {
            requirements.addAll(
              _externalRequirementsFromExpression(bonus.condition!.expression),
            );
          }

          // -----------------------------------------------------------------------
          // FÓRMULA DE VALOR
          // -----------------------------------------------------------------------

          if (bonus.hasFormula) {
            requirements.addAll(
              _externalRequirementsFromExpression(bonus.formula!.expression),
            );
          }
        }
      }
    }

    // =========================================================================
    // 3. REQUIREMENTS DE PASIVAS QUE PUEDEN REACCIONAR
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

    if (ability.requiresAttackRoll) {
      events.add(PassiveTriggerEvent.attackHit);

      events.add(PassiveTriggerEvent.attackMiss);
    }

    if (_abilityDealsDamage(ability)) {
      events.add(PassiveTriggerEvent.damageDealt);

      if (ability.requiresAttackRoll) {
        events.add(PassiveTriggerEvent.criticalHit);
      }
    }

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

    requirements.addAll(_extractNormalizedHealthRequirements(normalized));

    return ActionExternalRequirementSet(requirements).requirements;
  }

  bool _expressionContainsVariable(String expression, String variableName) {
    final pattern = RegExp(
      r'(^|[^A-Za-z0-9_])' + RegExp.escape(variableName) + r'([^A-Za-z0-9_]|$)',
    );

    return pattern.hasMatch(expression);
  }

  List<ActionExternalRequirement> _extractNormalizedHealthRequirements(
    String expression,
  ) {
    final result = <ActionExternalRequirement>[];

    final pattern = RegExp(
      r'\btarget_health_percent_(lt|lte|gt|gte)_'
      r'(\d+(?:\.\d+)?)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(expression)) {
      final operatorName = match.group(1)?.toLowerCase();

      final threshold = double.tryParse(match.group(2) ?? '');

      if (operatorName == null || threshold == null) {
        continue;
      }

      final safeThreshold = threshold.clamp(0.0, 100.0).toDouble();

      final thresholdText = safeThreshold == safeThreshold.roundToDouble()
          ? safeThreshold.toInt().toString()
          : safeThreshold.toString();

      switch (operatorName) {
        case 'lt':
          result.add(
            ActionExternalRequirement.percentageBelow(
              variableName: 'target_health_percent',
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
              variableName: 'target_health_percent',
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
              variableName: 'target_health_percent',
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
              variableName: 'target_health_percent',
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
    ActionTargetAttackResult? attackResult,
  }) {
    final result = <AbilityEffectPart>[];

    for (final effect in plan.ability.effects) {
      for (final part in effect.parts) {
        // =======================================================================
        // 1. CONDICIÓN + OPCIONALIDAD
        // =======================================================================

        final shouldUse = context.shouldUseAbilityEffectPart(
          part,
          target: target,
        );

        if (!shouldUse) {
          continue;
        }

        // =======================================================================
        // 2. HIT / MISS
        // =======================================================================

        if (!_passesHitGate(
          ability: plan.ability,
          behavior: part.hitBehavior,
          attackResult: attackResult,
        )) {
          continue;
        }

        result.add(part);
      }
    }

    return List<AbilityEffectPart>.unmodifiable(result);
  }

  List<ActionChanceResult> resolveCriticalChancesDigital({
    required PreparedActionResolution prepared,
    required bool critical,
  }) {
    final checks = collectCriticalChanceChecks(
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

    switch (prepared.ability.targetResolutionMode) {
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
    final abilityHasTargetConditions = ability.effects.any(
      (effect) =>
          effect.parts.any((part) => part.externalRequirements.isNotEmpty),
    );

    if (abilityHasTargetConditions) {
      return true;
    }

    if (!_abilityDealsDamage(ability)) {
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

    if (ability.requiresAttackRoll) {
      for (final bonus in character.activeCriticalDamageBonuses()) {
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
    final abilityPartsByGroup = <String, List<AbilityEffectPart>>{};

    final sourcesByGroup = <String, List<ActionOptionalSource>>{};

    final labelsByGroup = <String, String>{};

    // ===========================================================================
    // 1. OPTIONALS DE LA HABILIDAD
    // ===========================================================================

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

      if (!_damageBonusConditionMet(
        bonus: bonus,
        context: context,
        passive: passive,
        target: target,
      )) {
        continue;
      }

      final groupId = bonus.effectiveOptionalGroupId;

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

    for (final bonus in character.activeCriticalDamageBonuses()) {
      if (!bonus.optional) {
        continue;
      }

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

      final costs = <ActionCost>[];

      // Por ahora los DamageBonus/CriticalDamageBonus
      // no tienen costes propios.
      //
      // Los costes existentes vienen de AbilityEffectPart.
      for (final part in parts) {
        costs.addAll(part.costs);
      }

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
    bool? empowered,
  }) {
    return buildCriticalProfile(
      minimumRollSources: character.criticalMinimumRollSourcesForAbility(
        ability,
      ),
      forcedCritical: forcedCritical,
      empowered: empowered ?? character.empoweredCriticalForAbility(ability),
    );
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
    switch (plan.ability.targetResolutionMode) {
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

    return List<ActionCost>.unmodifiable(
      ActionCostResolver(character: character).combineCosts(costs),
    );
  }
}
