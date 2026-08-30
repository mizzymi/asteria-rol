import '../models/ability.dart';
import '../models/action_hit_behavior.dart';
import '../models/action_dice_request.dart';
import '../models/action_dice_result.dart';
import '../models/action_attack_roll_mode.dart';
import '../models/action_critical_profile.dart';
import '../models/character.dart';
import '../models/weapon.dart';
import '../models/weapon_attack_resolution.dart';
import '../models/dice_pool.dart';
import '../models/action_chance_check.dart';
import '../models/action_resolution_context.dart';
import '../models/action_dice_mode.dart';

import 'action_chance_resolver.dart';
import 'action_critical_dice_transformer.dart';
import 'action_resolver.dart';
import 'action_dice_resolver.dart';

class WeaponActionResolver {
  final Character character;

  final ActionDiceResolver diceResolver = const ActionDiceResolver();

  // ===========================================================================
  // CHANCE DE BONUS CRÍTICOS
  // ===========================================================================

  List<ActionChanceCheck> collectCriticalChanceChecks({
    required Weapon weapon,
    required ActionCriticalType criticalType,
    required ActionResolutionContext context,
  }) {
    final critical = criticalType != ActionCriticalType.none;

    if (!critical) {
      return const [];
    }

    final resolver = ActionResolver(character: character);

    return resolver.collectCriticalChanceChecks(
      critical: true,
      context: context,
      bonuses: character.activeCriticalDamageBonuses(weapon),
    );
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

    for (final active in character.activeDamageBonuses) {
      final bonus = active.bonus;

      if (!bonus.hasDamage) {
        continue;
      }

      final baseModifier = character.damageBonusModifier(
        bonus,
        passive: active.passive,
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
          id: 'weapon_bonus:${weapon.id}:${bonus.id}',
          effectId: bonus.id,
          effectName: bonus.effectiveOptionalLabel,
          effectType: AbilityEffectType.damage,
          dicePools: transformed.dicePools,
          modifier: transformed.modifier,
          automaticValue: transformed.automaticValue,
          sourceType: active.passive != null
              ? ActionDiceSourceType.passive
              : ActionDiceSourceType.effect,
          sourceId: active.passive?.id ?? bonus.id,
          sourceName: active.passive?.name ?? bonus.name,
          damageType: bonus.damageType,
          hitBehavior: bonus.hitBehavior,
        ),
      );
    }

    if (criticalType != ActionCriticalType.none && context != null) {
      final actionResolver = ActionResolver(character: character);

      actionResolver.appendCriticalExtraDice(
        parts: parts,
        critical: true,
        context: context,
        successfulChanceCheckIds: successfulChanceCheckIds,
        bonuses: character.activeCriticalDamageBonuses(weapon),
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
