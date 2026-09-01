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
import '../models/action_effect_result.dart';
import '../models/passive.dart';
import '../models/action_hit_behavior.dart';
import '../models/critical_damage_bonus.dart';
import '../models/character_effect_triggered_external_outcome.dart';

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

    if (prepared.ability.requiresAttackRoll) {
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
    bool targetParticipatesInAttackRoll = true,
  }) {
    if (!ability.requiresAttackRoll) {
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
    required CharacterAbility ability,
    required ActionLinkedEffect linkedEffect,
    ActionTarget? target,
    ActionTargetAttackResult? targetAttackResult,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
    bool auxiliarySelf = false,
  }) {
    if (!ability.requiresAttackRoll) {
      return true;
    }

    final behavior = linkedEffect.effectiveHitBehavior;

    if (behavior == ActionHitBehavior.ignoreHit) {
      return true;
    }

    if (!auxiliarySelf) {
      return _passesHitGate(
        ability: ability,
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
            ability: plan.ability,
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
    required CharacterAbility ability,
    required ActionLinkedEffect linkedEffect,
  }) {
    final explicitId = linkedEffect.normalizedSourceEffectId;

    // ===========================================================================
    // SOURCE EXPLÍCITO
    // ===========================================================================

    if (explicitId != null) {
      for (final effect in ability.effects) {
        if (effect.id == explicitId) {
          return effect;
        }
      }

      // El ID existe en los datos pero ya no existe
      // en la habilidad.
      return null;
    }

    // ===========================================================================
    // COMPATIBILIDAD LEGACY
    //
    // Antiguamente no se guardaba sourceEffectId.
    //
    // Si solo existe un único AbilityEffect con salvación,
    // podemos inferir inequívocamente que era el origen.
    // ===========================================================================

    final savingEffects = ability.effects
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
          ability: prepared.ability,
          behavior: ActionHitBehavior.requireHit,
          attackResult: attackResult,
          targetParticipatesInAttackRoll: target.participatesInAttackRoll,
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

      final sourceEffect = _linkedEffectSourceEffect(
        ability: prepared.ability,
        linkedEffect: linkedEffect,
      );

      if (sourceEffect == null ||
          sourceEffect.id != effect.id ||
          !sourceEffect.usesSavingThrow) {
        continue;
      }

      if (!_passesLinkedEffectHitGate(
        ability: prepared.ability,
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

      if (!_passesLinkedEffectHitGate(
        ability: ability,
        linkedEffect: linkedEffect,
        target: target,
        targetAttackResult: attackResult,
      )) {
        continue;
      }

      // =======================================================================
      // 3. SAVING THROW
      // =======================================================================

      if (!_passesLinkedEffectSaveGate(
        ability: ability,
        linkedEffect: linkedEffect,
        target: target,
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

  bool _passesLinkedEffectSaveGate({
    required CharacterAbility ability,
    required ActionLinkedEffect linkedEffect,
    required List<ActionSavingThrowResult> savingThrowResults,
    ActionTarget? target,
    bool auxiliarySelf = false,
  }) {
    // ===========================================================================
    // IGNORAR SAVE
    // ===========================================================================

    if (linkedEffect.saveBehavior == ActionLinkedEffectSaveBehavior.ignore) {
      return true;
    }

    // ===========================================================================
    // SELF AUXILIAR
    //
    // El personaje que ejecuta la acción no debe utilizar
    // la salvación de un objetivo externo.
    // ===========================================================================

    if (auxiliarySelf) {
      return true;
    }

    if (target == null) {
      return true;
    }

    // ===========================================================================
    // SOURCE EFFECT
    // ===========================================================================

    final sourceEffect = _linkedEffectSourceEffect(
      ability: ability,
      linkedEffect: linkedEffect,
    );

    if (sourceEffect == null || !sourceEffect.usesSavingThrow) {
      return true;
    }

    // ===========================================================================
    // RESULTADO EXACTO
    //
    // Deben coincidir:
    // - target
    // - effect origen
    // ===========================================================================

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

    // No hubo una salvación aplicable.
    if (save == null) {
      return true;
    }

    // Si falla, el efecto vinculado sigue vivo.
    if (!save.saved) {
      return true;
    }

    // ===========================================================================
    // SAVE EXITOSO
    // ===========================================================================

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
    required CharacterAbility ability,
    required ActionResolutionContext context,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
    required List<ActionSavingThrowResult> savingThrowResults,
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

      if (!_passesLinkedEffectHitGate(
        ability: ability,
        linkedEffect: linkedEffect,
        attackResultsByTargetId: attackResultsByTargetId,
        auxiliarySelf: true,
      )) {
        continue;
      }

      // =========================================================================
      // SAVES
      // =========================================================================

      if (!_passesLinkedEffectSaveGate(
        ability: ability,
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
    required CharacterAbility ability,
    required ActionResolutionContext context,
    required Map<String, ActionTargetAttackResult> attackResultsByTargetId,
    required List<ActionSavingThrowResult> savingThrowResults,
  }) {
    final effects = _buildAuxiliarySelfLinkedEffects(
      ability: ability,
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

    final costs = <ActionCost>[
      // =========================================================================
      // VALIDACIÓN PREVIA
      //
      // Estos son costes POTENCIALES.
      //
      // Todavía no conocemos hit/miss, así que una parte requireHit seleccionada
      // debe considerarse pagable antes de permitir continuar.
      //
      // El coste definitivo se recalcula después mediante
      // collectResolvedActionCosts().
      // =========================================================================
      ...plan.costs,

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

  bool _isOptionalGroupSelectedForTargetResolution({
    required ActionResolutionPlan plan,
    required ActionResolutionContext context,
    required String groupId,
    ActionTarget? target,
  }) {
    switch (plan.ability.targetResolutionMode) {
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

  List<ActionExternalRequirement>
  orderedPreResolutionExternalRequirementsForTarget({
    required CharacterAbility ability,
    required ActionResolutionContext context,
    required ActionTarget target,
  }) {
    final requirements = orderedPreResolutionExternalRequirements(
      ability: ability,
    );

    if (requirements.isEmpty) {
      return const [];
    }

    final result = <ActionExternalRequirement>[];

    for (final requirement in requirements) {
      // =======================================================================
      // YA PODEMOS RESOLVERLO CON INFORMACIÓN CONOCIDA
      //
      // Esto además registra la respuesta correspondiente en el contexto.
      // =======================================================================

      final resolved = tryResolveKnownExternalRequirement(
        context: context,
        target: target,
        requirement: requirement,
      );

      if (resolved) {
        continue;
      }

      // =======================================================================
      // NECESITA PREGUNTA EXTERNA
      // =======================================================================

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
      savingThrowResults: savingThrowResults,
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
      savingThrowResults: savingThrowResults,
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

  bool _hasUnsupportedSharedTargetSpecificSources(CharacterAbility ability) {
    if (!_abilityDealsDamage(ability)) {
      return false;
    }

    // ===========================================================================
    // DAMAGE BONUS
    //
    // AbilityEffectPart target-specific ya está soportado mediante:
    // superset shared + filtrado posterior.
    //
    // DamageBonus todavía se construye directamente dentro del request y
    // puede tener condición/fórmula dependiente del target.
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
    // CRITICAL DAMAGE BONUS
    // ===========================================================================

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

    // ===========================================================================
    // HEALING BONUS
    //
    // Igual que DamageBonus:
    // si la fórmula depende del target, un único request shared
    // no puede representar valores distintos por objetivo.
    // ===========================================================================

    if (_abilityHeals(ability)) {
      for (final bonus in character.activeHealingBonuses) {
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

    // ===========================================================================
    // CONDITIONS DE AbilityEffectPart
    //
    // YA soportadas:
    //
    // - request shared = superset
    // - una única tirada
    // - filtrado posterior por target
    // ===========================================================================

    if (!_hasUnsupportedSharedTargetSpecificSources(prepared.ability)) {
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
    final List<AbilityEffectPart> selected;

    if (target != null) {
      // Resolución concreta de un target.
      selected = selectedParts(
        plan: plan,
        context: context,
        target: target,
        attackResult: targetAttackResult,
      );
    } else if (plan.ability.targetResolutionMode ==
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
        for (final effect in plan.ability.effects)
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
            baseModifier: baseModifier,
            modifier: transformed.modifier,
            modifierLabel: _abilityTypeShortLabel(plan.ability.abilityType),
            automaticValue: transformed.automaticValue,
            automaticValueLabel: transformed.automaticValue != 0
                ? _criticalAutomaticValueLabel(effectiveCriticalType)
                : '',
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

      final modifierLabel = _abilityModifierMultipliersLabel(extraMultipliers);

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

            baseModifier: baseModifier,
            modifier: transformed.modifier,
            modifierLabel: modifierLabel,

            automaticValue: transformed.automaticValue,

            automaticValueLabel: transformed.automaticValue != 0
                ? _criticalAutomaticValueLabel(effectiveCriticalType)
                : '',

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
        plan: plan,
      );
    }

    if (_abilityHeals(plan.ability)) {
      _appendHealingBonuses(parts: parts, context: context, target: target);
    }

    if (critical && _abilityDealsDamage(plan.ability)) {
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
    required ActionResolutionPlan plan,
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
          baseModifier: baseModifier,
          modifier: transformed.modifier,
          modifierLabel: modifierLabel,
          automaticValue: transformed.automaticValue,
          automaticValueLabel: transformed.automaticValue != 0
              ? _criticalAutomaticValueLabel(effectiveCriticalType)
              : '',
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

      final modifierLabel = _healingBonusModifierLabel(bonus);

      parts.add(
        ActionDiceRequestPart(
          id: 'healing_bonus:${bonus.id}',
          hitBehavior: ActionHitBehavior.ignoreHit,
          effectId: 'healing_bonus',
          effectName: bonus.name.isNotEmpty ? bonus.name : 'Curación adicional',
          effectType: AbilityEffectType.healing,

          dicePools: List<DicePool>.unmodifiable(bonus.dicePools),

          baseModifier: modifier,
          modifier: modifier,
          modifierLabel: modifierLabel,

          sourceType: ActionDiceSourceType.effect,
          sourceId: bonus.id,
          sourceName: bonus.name,
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
    required CharacterAbility ability,
  }) {
    return orderedPreResolutionExternalRequirements(ability: ability);
  }

  List<ActionExternalRequirement> orderedPreResolutionExternalRequirements({
    required CharacterAbility ability,
  }) {
    return _orderExternalRequirements(
      collectPreResolutionExternalRequirements(ability: ability),
    );
  }

  List<ActionExternalRequirement> orderedPostResolutionExternalRequirements({
    required CharacterAbility ability,
    required Set<PassiveTriggerEvent> events,
  }) {
    return _orderExternalRequirements(
      collectPostResolutionExternalRequirements(
        ability: ability,
        events: events,
      ),
    );
  }

  List<ActionExternalRequirement>
  orderedPostResolutionExternalRequirementsForTarget({
    required CharacterAbility ability,
    required ActionResolutionContext context,
    required ActionTarget target,
    required Set<PassiveTriggerEvent> events,
  }) {
    final requirements = orderedPostResolutionExternalRequirements(
      ability: ability,
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
    required CharacterAbility ability,
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

  void validatePassiveTriggerTargetScopes({required CharacterAbility ability}) {
    final possibleEvents = _possiblePassiveEventsForAbility(ability);

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

    switch (plan.ability.targetResolutionMode) {
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

    return ActionResolutionPlan(
      ability: ability,
      automaticParts: automaticParts,
      optionalParts: optionalParts,
      externalRequirements: collectPreResolutionExternalRequirements(
        ability: ability,
      ),
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
          ability: plan.ability,
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

    switch (plan.ability.targetResolutionMode) {
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

    switch (plan.ability.targetResolutionMode) {
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

    if (plan.ability.targetResolutionMode ==
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

    if (plan.ability.targetResolutionMode ==
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

    if (plan.ability.targetResolutionMode ==
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

    final costs = <ActionCost>[...plan.costs];

    // ===========================================================================
    // COSTES YA SELECCIONADOS
    // ===========================================================================

    switch (plan.ability.targetResolutionMode) {
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
    // GRUPO NUEVO
    //
    // Solo añadimos su coste si todavía no está seleccionado en el scope
    // correspondiente.
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

    if (!prepared.ability.requiresAttackRoll) {
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
    switch (plan.ability.targetResolutionMode) {
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
    switch (prepared.ability.targetResolutionMode) {
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
