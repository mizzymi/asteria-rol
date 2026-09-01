import '../models/action_external_requirement.dart';
import '../models/passive.dart';
import '../models/ability.dart';
import '../models/action_hit_behavior.dart';
import '../models/action_dice_request.dart';
import '../models/action_dice_result.dart';
import '../models/action_attack_roll_mode.dart';
import '../models/action_critical_profile.dart';
import '../models/character.dart';
import '../models/weapon.dart';
import '../models/weapon_attack_resolution.dart';
import '../models/damage_bonus.dart';
import '../models/dice_pool.dart';
import '../models/action_chance_check.dart';
import '../models/action_resolution_context.dart';
import '../models/action_dice_mode.dart';
import '../models/action_optional_group.dart';
import '../models/action_cost.dart';
import 'action_cost_resolver.dart';

import 'action_chance_resolver.dart';
import 'action_critical_dice_transformer.dart';
import 'action_resolver.dart';
import 'action_dice_resolver.dart';
import 'formula_evaluator.dart';
import 'action_external_requirement_parser.dart';

class WeaponActionResolver {
  final Character character;

  final ActionDiceResolver diceResolver = const ActionDiceResolver();

  ActionTarget? _targetForContext(ActionResolutionContext context) {
    if (context.targets.isEmpty) {
      return null;
    }

    return context.targets.first;
  }

  List<ActionExternalRequirement> collectPreResolutionExternalRequirements({
    required Weapon weapon,
  }) {
    final requirements = <ActionExternalRequirement>[];

    const parser = ActionExternalRequirementParser();

    // ===========================================================================
    // DAMAGE BONUSES
    // ===========================================================================

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;

      if (!bonus.hasDamage) {
        continue;
      }

      if (bonus.hasCondition) {
        requirements.addAll(parser.fromExpression(bonus.condition!.expression));
      }

      if (bonus.hasFormula) {
        requirements.addAll(parser.fromExpression(bonus.formula!.expression));
      }
    }

    // ===========================================================================
    // CRITICAL DAMAGE BONUSES
    // ===========================================================================

    for (final bonus in character.activeCriticalDamageBonuses(weapon)) {
      if (!bonus.canTrigger) {
        continue;
      }

      if (bonus.hasCondition) {
        requirements.addAll(parser.fromExpression(bonus.condition!.expression));
      }

      if (bonus.hasFormula) {
        requirements.addAll(parser.fromExpression(bonus.formula!.expression));
      }
    }

    return ActionExternalRequirementSet(requirements).requirements;
  }

  List<ActionExternalRequirement> orderedPreResolutionExternalRequirements({
    required Weapon weapon,
  }) {
    final requirements = collectPreResolutionExternalRequirements(
      weapon: weapon,
    );

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

  List<ActionExternalRequirement>
  orderedPreResolutionExternalRequirementsForTarget({
    required Weapon weapon,
    required ActionResolutionContext context,
    required ActionTarget target,
  }) {
    final requirements = orderedPreResolutionExternalRequirements(
      weapon: weapon,
    );

    if (requirements.isEmpty) {
      return const [];
    }

    final actionResolver = ActionResolver(character: character);

    final pending = <ActionExternalRequirement>[];

    for (final requirement in requirements) {
      final resolved = actionResolver.tryResolveKnownExternalRequirement(
        context: context,
        target: target,
        requirement: requirement,
      );

      if (resolved) {
        continue;
      }

      pending.add(requirement);
    }

    return List<ActionExternalRequirement>.unmodifiable(pending);
  }

  ActionDiceResult resolveDamageDigitalRequest(ActionDiceRequest request) {
    return diceResolver.rollDigital(request);
  }

  ActionDiceResult resolveDamagePhysicalRequest({
    required ActionDiceRequest request,
    required List<ActionPhysicalDiceInput> inputs,
  }) {
    return diceResolver.resolvePhysical(request: request, inputs: inputs);
  }

  // ===========================================================================
  // CHANCE DE BONUS CRÍTICOS
  // ===========================================================================

  List<ActionChanceCheck> collectCriticalChanceChecks({
    required Weapon weapon,
    required ActionCriticalType criticalType,
    required ActionResolutionContext context,
  }) {
    if (criticalType == ActionCriticalType.none) {
      return const [];
    }

    final checks = <ActionChanceCheck>[];

    final bonuses = character.activeCriticalDamageBonuses(weapon);

    for (final bonus in bonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      // =======================================================================
      // CONDICIÓN
      //
      // El daño de arma actualmente trabaja con un único contexto global
      // de target. No existe ActionResolutionPlan de habilidad.
      // =======================================================================

      if (bonus.hasCondition) {
        final result = const FormulaEvaluator().evaluate(
          bonus.condition!,
          context: context.buildFormulaContext(
            target: _targetForContext(context),
          ),
        );

        if (!result.valid || result.value == 0) {
          continue;
        }
      }

      // =======================================================================
      // OPCIONAL
      //
      // Las armas no utilizan selección per-target de habilidad.
      // Conservamos la selección global del contexto.
      // =======================================================================

      if (bonus.optional) {
        if (!context.isOptionalGroupSelected(bonus.effectiveOptionalGroupId)) {
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

    return List<ActionChanceCheck>.unmodifiable(checks);
  }

  List<ActionChanceResult> rollCriticalChanceChecksDigital({
    required ActionCriticalType criticalType,
    required ActionResolutionContext context,
    required Weapon weapon,
  }) {
    final checks = collectCriticalChanceChecks(
      criticalType: criticalType,
      context: context,
      weapon: weapon,
    );

    if (checks.isEmpty) {
      return const [];
    }

    final resolver = ActionChanceResolver();

    return List<ActionChanceResult>.unmodifiable(
      checks.map(resolver.rollDigital),
    );
  }

  List<ActionChanceResult> resolveCriticalChanceChecksPhysical({
    required ActionCriticalType criticalType,
    required ActionResolutionContext context,
    required Map<String, int> rollsByCheckId,
    required Weapon weapon,
  }) {
    final checks = collectCriticalChanceChecks(
      criticalType: criticalType,
      context: context,
      weapon: weapon,
    );

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

  ActionDiceResult rollDamageDigital({
    required Weapon weapon,
    ActionCriticalType criticalType = ActionCriticalType.none,
    ActionResolutionContext? context,
  }) {
    var successfulChanceIds = const <String>{};

    if (criticalType != ActionCriticalType.none && context != null) {
      final chanceResults = rollCriticalChanceChecksDigital(
        criticalType: criticalType,
        context: context,
        weapon: weapon,
      );

      successfulChanceIds = ActionResolver(
        character: character,
      ).successfulChanceCheckIds(chanceResults);
    }

    final request = buildDamageRequest(
      weapon: weapon,
      criticalType: criticalType,
      context: context,
      successfulChanceCheckIds: successfulChanceIds,
    );

    return diceResolver.rollDigital(request);
  }

  ActionDiceResult resolveDamagePhysical({
    required Weapon weapon,
    ActionCriticalType criticalType = ActionCriticalType.none,
    required List<ActionPhysicalDiceInput> inputs,
  }) {
    final request = buildDamageRequest(
      weapon: weapon,
      criticalType: criticalType,
    );

    return diceResolver.resolvePhysical(request: request, inputs: inputs);
  }

  WeaponActionResolver({required this.character});

  // ===========================================================================
  // ATAQUE DIGITAL
  // ===========================================================================

  WeaponAttackResolution rollAttackDigital({
    required Weapon weapon,
    required AttackRollMode mode,
  }) {
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

    return _resolveAttackFromRolls(
      weapon: weapon,
      mode: mode,
      diceMode: ActionDiceMode.digital,
      firstRoll: firstRoll,
      secondRoll: secondRoll,
    );
  }

  // ===========================================================================
  // ATAQUE FÍSICO
  // ===========================================================================

  WeaponAttackResolution resolveAttackPhysical({
    required Weapon weapon,
    required AttackRollMode mode,
    required int firstRoll,
    int? secondRoll,
  }) {
    _validateD20(firstRoll);

    switch (mode) {
      case AttackRollMode.normal:
        break;

      case AttackRollMode.advantage:
      case AttackRollMode.disadvantage:
        if (secondRoll == null) {
          throw StateError(
            'La ventaja/desventaja necesita dos resultados de d20.',
          );
        }

        _validateD20(secondRoll);
        break;
    }

    return _resolveAttackFromRolls(
      weapon: weapon,
      mode: mode,
      diceMode: ActionDiceMode.physical,
      firstRoll: firstRoll,
      secondRoll: secondRoll,
    );
  }

  // ===========================================================================
  // RESOLUCIÓN COMPARTIDA DEL ATAQUE
  // ===========================================================================

  WeaponAttackResolution _resolveAttackFromRolls({
    required Weapon weapon,
    required AttackRollMode mode,
    required ActionDiceMode diceMode,
    required int firstRoll,
    int? secondRoll,
  }) {
    final actionResolver = ActionResolver(character: character);

    final naturalRoll = actionResolver.selectNaturalAttackRoll(
      mode: mode,
      firstRoll: firstRoll,
      secondRoll: secondRoll,
    );

    final criticalProfile = _criticalProfileForWeapon(weapon);

    final attackResult = actionResolver.resolveAttackRoll(
      naturalRoll: naturalRoll,
      modifier: character.attackBonus(weapon),
      criticalProfile: criticalProfile,
    );

    return WeaponAttackResolution(
      mode: mode,
      diceMode: diceMode,
      firstRoll: firstRoll,
      secondRoll: secondRoll,
      attackResult: attackResult,
    );
  }

  // ===========================================================================
  // VALIDACIÓN D20 FÍSICO
  // ===========================================================================

  void _validateD20(int value) {
    if (value < 1 || value > 20) {
      throw StateError('Resultado $value inválido para d20.');
    }
  }

  // ===========================================================================
  // DAÑO
  // ===========================================================================
  List<ActionOptionalGroup> availableOptionalGroups({
    required Weapon weapon,
    required ActionResolutionContext context,
  }) {
    final costsByGroup = <String, List<ActionCost>>{};
    final sourcesByGroup = <String, List<ActionOptionalSource>>{};
    final labelsByGroup = <String, String>{};

    // ===========================================================================
    // DAMAGE BONUS
    // ===========================================================================

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (!bonus.optional || !bonus.hasDamage) {
        continue;
      }

      if (!_damageBonusConditionMet(
        context: context,
        bonus: bonus,
        passive: passive,
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
    // CRITICAL DAMAGE BONUS
    //
    // Aquí solo declaramos la opción.
    // Que finalmente se use dependerá de que haya crítico y chance.
    // ===========================================================================

    for (final bonus in character.activeCriticalDamageBonuses(weapon)) {
      if (!bonus.optional || !bonus.canTrigger) {
        continue;
      }

      if (bonus.hasCondition) {
        final result = const FormulaEvaluator().evaluate(
          bonus.condition!,
          context: context.buildFormulaContext(
            target: _targetForContext(context),
          ),
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

    final result = <ActionOptionalGroup>[];

    for (final entry in sourcesByGroup.entries) {
      result.add(
        ActionOptionalGroup(
          id: entry.key,
          label: labelsByGroup[entry.key] ?? 'Componente opcional',
          parts: const [],
          sources: List<ActionOptionalSource>.unmodifiable(entry.value),
          costs: List<ActionCost>.unmodifiable(
            ActionCostResolver(
              character: character,
            ).combineCosts(costsByGroup[entry.key] ?? const <ActionCost>[]),
          ),
        ),
      );
    }

    return List<ActionOptionalGroup>.unmodifiable(result);
  }

  bool _damageBonusSurvives({
    required ActionResolutionContext context,
    required DamageBonus bonus,
    CharacterPassive? passive,
    bool? hit,
  }) {
    if (!bonus.hasDamage) {
      return false;
    }

    if (!_damageBonusConditionMet(
      context: context,
      bonus: bonus,
      passive: passive,
    )) {
      return false;
    }

    if (!_damageBonusSelected(context: context, bonus: bonus)) {
      return false;
    }

    switch (bonus.hitBehavior) {
      case ActionHitBehavior.ignoreHit:
        return true;

      case ActionHitBehavior.requireHit:
        // Antes de resolver el ataque:
        // todavía puede llegar a aplicarse.
        if (hit == null) {
          return true;
        }

        return hit;
    }
  }

  List<ActionCost> collectPotentialDamageBonusCosts({
    required ActionResolutionContext context,
  }) {
    final costs = <ActionCost>[];

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (bonus.costs.isEmpty) {
        continue;
      }

      if (!_damageBonusSurvives(
        context: context,
        bonus: bonus,
        passive: passive,
        hit: null,
      )) {
        continue;
      }

      costs.addAll(bonus.costs);
    }

    return List<ActionCost>.unmodifiable(
      ActionCostResolver(character: character).combineCosts(costs),
    );
  }

  List<ActionCost> collectResolvedDamageBonusCosts({
    required ActionResolutionContext context,
    required bool hit,
  }) {
    final costs = <ActionCost>[];

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;
      final passive = active.passive;

      if (bonus.costs.isEmpty) {
        continue;
      }

      if (!_damageBonusSurvives(
        context: context,
        bonus: bonus,
        passive: passive,
        hit: hit,
      )) {
        continue;
      }

      costs.addAll(bonus.costs);
    }

    return List<ActionCost>.unmodifiable(
      ActionCostResolver(character: character).combineCosts(costs),
    );
  }

  void _appendCriticalDamageBonuses({
    required List<ActionDiceRequestPart> parts,
    required Weapon weapon,
    required ActionCriticalType criticalType,
    required ActionResolutionContext context,
    required Set<String> successfulChanceCheckIds,
  }) {
    if (criticalType == ActionCriticalType.none) {
      return;
    }

    final bonuses = character.activeCriticalDamageBonuses(weapon);

    for (final bonus in bonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      // =======================================================================
      // CONDICIÓN
      // =======================================================================

      if (bonus.hasCondition) {
        final result = const FormulaEvaluator().evaluate(
          bonus.condition!,
          context: context.buildFormulaContext(
            target: _targetForContext(context),
          ),
        );

        if (!result.valid || result.value == 0) {
          continue;
        }
      }

      // =======================================================================
      // OPCIONAL
      // =======================================================================

      if (bonus.optional &&
          !context.isOptionalGroupSelected(bonus.effectiveOptionalGroupId)) {
        continue;
      }

      // =======================================================================
      // CHANCE
      // =======================================================================

      final chanceCheckId = 'critical_bonus:${bonus.id}';

      if (!bonus.alwaysTriggers &&
          !successfulChanceCheckIds.contains(chanceCheckId)) {
        continue;
      }

      // =======================================================================
      // MODIFICADOR
      // =======================================================================

      final modifier = character.criticalDamageBonusModifier(
        bonus,
        formulaContext: context.buildFormulaContext(
          target: _targetForContext(context),
        ),
      );

      // =======================================================================
      // REQUEST PART
      // =======================================================================

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

  bool _damageBonusConditionMet({
    required ActionResolutionContext context,
    required DamageBonus bonus,
    CharacterPassive? passive,
  }) {
    if (!bonus.hasCondition) {
      return true;
    }

    final result = const FormulaEvaluator().evaluate(
      bonus.condition!,
      context: context.buildFormulaContext(
        passive: passive,
        target: _targetForContext(context),
      ),
    );

    return result.valid && result.value != 0;
  }

  bool _damageBonusSelected({
    required ActionResolutionContext context,
    required DamageBonus bonus,
  }) {
    if (!bonus.optional) {
      return true;
    }

    return context.isOptionalGroupSelected(bonus.effectiveOptionalGroupId);
  }

  ActionDiceRequest buildDamageRequest({
    required Weapon weapon,
    required ActionCriticalType criticalType,
    ActionResolutionContext? context,
    Set<String> successfulChanceCheckIds = const {},
  }) {
    final parts = <ActionDiceRequestPart>[];

    for (final damage in weapon.damages) {
      final baseModifier = character.weaponDamageModifier(weapon, damage);

      final effectiveCriticalType = damage.participatesInCritical
          ? criticalType
          : ActionCriticalType.none;

      final transformed = ActionCriticalDiceTransformer.transform(
        dicePools: damage.dicePools,
        baseModifier: baseModifier,
        criticalType: effectiveCriticalType,
      );

      parts.add(
        ActionDiceRequestPart(
          id: 'weapon:${weapon.id}:${damage.id}',

          effectId: damage.id,

          effectName: damage.name,

          effectType: AbilityEffectType.damage,

          dicePools: transformed.dicePools,

          modifier: transformed.modifier,

          automaticValue: transformed.automaticValue,

          sourceType: ActionDiceSourceType.weapon,

          sourceId: weapon.id,

          sourceName: weapon.name,

          damageType: damage.damageType,

          hitBehavior: ActionHitBehavior.requireHit,
        ),
      );

      // Dados extra que aparecen POR crítico.
      if (criticalType != ActionCriticalType.none &&
          damage.criticalDicePools.isNotEmpty) {
        parts.add(
          ActionDiceRequestPart(
            id: 'weapon_critical:${weapon.id}:${damage.id}',

            effectId: damage.id,

            effectName: '${damage.name} · crítico',

            effectType: AbilityEffectType.damage,

            dicePools: List<DicePool>.unmodifiable(damage.criticalDicePools),

            modifier: 0,

            kind: ActionDicePartKind.criticalExtra,

            sourceType: ActionDiceSourceType.criticalBonus,

            sourceId: damage.id,

            sourceName: damage.name,

            damageType: damage.damageType,

            hitBehavior: ActionHitBehavior.requireHit,
          ),
        );
      }
    }

    if (context != null) {
      for (final active in character.activeDamageBonuses) {
        final bonus = active.bonus;
        final passive = active.passive;

        if (!bonus.hasDamage) {
          continue;
        }

        if (!_damageBonusConditionMet(
          context: context,
          bonus: bonus,
          passive: passive,
        )) {
          continue;
        }

        if (!_damageBonusSelected(context: context, bonus: bonus)) {
          continue;
        }

        final effectiveDicePools = <DicePool>[...bonus.dicePools];

        if (passive != null && bonus.chargeScaling.hasScaling) {
          effectiveDicePools.addAll(
            bonus.chargeScaling.scaledDicePools(passive.currentCharges),
          );
        }

        final baseModifier = character.damageBonusModifier(
          bonus,
          passive: passive,
          formulaContext: context.buildFormulaContext(
            passive: passive,
            target: _targetForContext(context),
          ),
        );

        final effectiveCriticalType = bonus.participatesInCritical
            ? criticalType
            : ActionCriticalType.none;

        final transformed = ActionCriticalDiceTransformer.transform(
          dicePools: effectiveDicePools,
          baseModifier: baseModifier,
          criticalType: effectiveCriticalType,
        );

        parts.add(
          ActionDiceRequestPart(
            id: 'weapon_bonus:${weapon.id}:${bonus.id}',
            effectId: bonus.id,
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
            hitBehavior: bonus.hitBehavior,
          ),
        );
      }
    }

    if (criticalType != ActionCriticalType.none && context != null) {
      _appendCriticalDamageBonuses(
        parts: parts,
        weapon: weapon,
        criticalType: criticalType,
        context: context,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );
    }

    return ActionDiceRequest(parts: List.unmodifiable(parts));
  }

  // ===========================================================================
  // CRÍTICO
  // ===========================================================================

  ActionCriticalProfile _criticalProfileForWeapon(Weapon weapon) {
    return ActionCriticalProfile(
      minimumNaturalRoll: ActionCriticalProfile.effectiveMinimumRoll(
        character.criticalMinimumRollSourcesForWeapon(weapon),
      ),
      empowered: character.empoweredCriticalForWeapon(weapon),
    );
  }
}
